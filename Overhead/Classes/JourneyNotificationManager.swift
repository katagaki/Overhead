import Foundation
import UserNotifications
import Backbone

/// Local alerts fired ahead of each transfer and the final stop.
/// Schedule-driven, so untimed journeys get nothing — same guard as the Live Activity.
@MainActor
final class JourneyNotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = JourneyNotificationManager()

    static let enabledKey = "notifications.enabled"
    static let leadMinutesKey = "notifications.leadMinutes"
    static let leadMinuteOptions = [1, 2, 3, 5]
    static let defaultLeadMinutes = 2

    private static let identifierPrefix = "journey."

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    private var leadTime: TimeInterval {
        let stored = UserDefaults.standard.integer(forKey: Self.leadMinutesKey)
        return TimeInterval((stored == 0 ? Self.defaultLeadMinutes : stored) * 60)
    }

    /// Read at schedule time rather than cached, so changing the sound applies to
    /// alerts that have not fired yet. `nil` fires the alert silently; a missing
    /// file falls back to the system sound rather than going quiet by accident.
    private static var alertSound: UNNotificationSound? {
        let choice = NotificationSound.current
        guard !choice.isSilent else { return nil }
        guard let fileName = choice.fileName,
              Bundle.main.url(forResource: fileName, withExtension: nil) != nil else {
            return .default
        }
        return UNNotificationSound(named: UNNotificationSoundName(fileName))
    }

    // MARK: - Scheduling

    /// Replaces any pending alerts with ones for this journey.
    /// `transferLines` maps a transfer station's ID to the line boarded there.
    func schedule(journey: Journey, transferLines: [String: TrainLine] = [:]) {
        let planned = plannedRequests(journey: journey, transferLines: transferLines)
        // Ordered: identifiers are reused, so a late cancel would drop the new alerts.
        Task {
            await cancelPending()
            guard !planned.isEmpty, await requestAuthorization() else { return }
            for request in planned {
                try? await center.add(request)
            }
        }
    }

    /// Empty when alerts are off or the journey has no usable schedule.
    private func plannedRequests(
        journey: Journey,
        transferLines: [String: TrainLine]
    ) -> [UNNotificationRequest] {
        guard isEnabled, journey.hasSchedule else { return [] }
        let stations = journey.journeyStations
        let times = journey.scheduledStationTimes
        guard stations.count > 1, stations.count == times.count else { return [] }
        return requests(stations: stations, times: times, journey: journey, transferLines: transferLines)
    }

    /// Awaits the pending list so the removal can't act on a stale snapshot.
    private func cancelPending() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelAll() {
        Task { await cancelPending() }
    }

    private func requests(
        stations: [Station],
        times: [Date],
        journey: Journey,
        transferLines: [String: TrainLine]
    ) -> [UNNotificationRequest] {
        var requests: [UNNotificationRequest] = []
        let lead = leadTime

        // Only lands when the user planned a departure ahead of time; otherwise it's already past.
        if let origin = stations.first, let departure = times.first {
            requests.append(contentsOf: request(
                id: "depart",
                fireAt: departure.addingTimeInterval(-lead),
                title: String(localized: "Notification.Departure.Title"),
                body: String(localized: "Notification.Departure.Body \(origin.localizedName) \(departure.formatted(date: .omitted, time: .shortened))")
            ))
        }

        let transferIds = Set(journey.transferStationIds)
        for (index, station) in stations.enumerated() where transferIds.contains(station.id) {
            let body: String
            if let line = transferLines[station.id] {
                body = String(localized: "Notification.Transfer.Body \(station.localizedName) \(line.localizedName)")
            } else {
                body = String(localized: "Notification.Transfer.BodyNoLine \(station.localizedName)")
            }
            requests.append(contentsOf: request(
                id: "transfer.\(index)",
                fireAt: times[index].addingTimeInterval(-lead),
                title: String(localized: "Notification.Transfer.Title"),
                body: body
            ))
        }

        if let destination = stations.last, let arrival = times.last {
            requests.append(contentsOf: request(
                id: "alight",
                fireAt: arrival.addingTimeInterval(-lead),
                title: String(localized: "Notification.Alight.Title"),
                body: String(localized: "Notification.Alight.Body \(destination.localizedName)")
            ))
        }

        return requests
    }

    /// Empty when the moment has already passed.
    private func request(id: String, fireAt: Date, title: String, body: String) -> [UNNotificationRequest] {
        let interval = fireAt.timeIntervalSinceNow
        guard interval > 0 else { return [] }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = Self.alertSound

        return [UNNotificationRequest(
            identifier: Self.identifierPrefix + id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )]
    }

    // MARK: - Authorization

    private func requestAuthorization() async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        default:
            return false
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // The journey LCD may be open on another screen, so still show a banner.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Without this the foreground banner plays the default sound even when
        // the scheduled alert was built silent.
        NotificationSound.current.isSilent ? [.banner] : [.banner, .sound]
    }
}
