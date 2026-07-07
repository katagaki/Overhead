import Foundation
import ActivityKit
import SwiftUI
import Backbone

// MARK: - Live Activity Attributes

struct TrainJourneyAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var currentStationIndex: Int?
        var nextStationName: String
        var nextStationNameEn: String
        var delayMinutes: Int
        var estimatedArrivalTimestamp: Double
        var statusRaw: String
        var trackingModeRaw: String          // "GPS", "Timetable", "Blended"
        var lastRefreshTimestamp: Double      // When delay data was last fetched
        // Scheduled departure from the boarding station (delay-adjusted).
        // Together with the arrival timestamp this drives timer-based views
        // that keep advancing while the app is suspended (no GPS needed).
        var departureTimestamp: Double

        var status: TrainPositionState.Status {
            TrainPositionState.Status(rawValue: statusRaw) ?? .onTime
        }

        var isDelayed: Bool { delayMinutes > 0 }

        var isTimetableMode: Bool { trackingModeRaw == "Timetable" }

        var estimatedArrival: Date {
            Date(timeIntervalSince1970: estimatedArrivalTimestamp)
        }

        var departure: Date {
            Date(timeIntervalSince1970: departureTimestamp)
        }

        /// Timer interval covering the scheduled ride, clamped to stay valid.
        var journeyInterval: ClosedRange<Date> {
            let start = departure
            let end = max(estimatedArrival, start.addingTimeInterval(60))
            return start...end
        }

        var lastRefresh: Date {
            Date(timeIntervalSince1970: lastRefreshTimestamp)
        }
    }

    let lineName: String
    let lineNameEn: String
    let lineColorHex: String
    let lineSymbol: String
    let originName: String
    let originNameEn: String
    let destinationName: String
    let destinationNameEn: String
    let trainType: String
    let stationNames: [String]
    let stationNamesEn: [String]
    let stationCount: Int
    // Whether the train stops at each station (false = express skip)
    let stationStops: [Bool]
    let refreshURLString: String
}

// MARK: - Live Activity Manager

final class LiveActivityManager {

    static let shared = LiveActivityManager()
    private init() {}

    // Opened by the Live Activity refresh button
    static let refreshURLScheme = "overhead://refresh-delay"

    private(set) var currentActivity: Activity<TrainJourneyAttributes>?
    private var lastDelayFetchTime = Date()
    // Scheduled departure/arrival of the active journey (before delay adjustment),
    // used to compute the timer interval for self-updating Live Activity views.
    private var scheduledDeparture: Date?
    private var scheduledArrival: Date?

    var hasActiveActivity: Bool { currentActivity != nil }

    func startActivity(
        journey: Journey,
        positionState: TrainPositionState,
        lineColorHex: String
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let stations = journey.journeyStations
        let timetableIds = Set(journey.journeyTimetable.map(\.stationId))
        let stationStops = stations.map { timetableIds.contains($0.id) }

        let attributes = TrainJourneyAttributes(
            lineName: journey.line.name,
            lineNameEn: journey.line.nameEn,
            lineColorHex: lineColorHex,
            lineSymbol: journey.line.lineSymbol,
            originName: stations.first?.name ?? "",
            originNameEn: stations.first?.nameEn ?? "",
            destinationName: stations.last?.name ?? "",
            destinationNameEn: stations.last?.nameEn ?? "",
            trainType: journey.service.trainType.displayNameJa,
            stationNames: stations.map(\.name),
            stationNamesEn: stations.map(\.nameEn),
            stationCount: stations.count,
            stationStops: stationStops,
            refreshURLString: Self.refreshURLScheme
        )

        lastDelayFetchTime = Date()
        (scheduledDeparture, scheduledArrival) = Self.scheduledTimes(for: journey)
        let state = contentState(from: positionState)

        do {
            let content = ActivityContent(state: state, staleDate: staleDate(for: state))
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil  // No server — all updates are local
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateActivity(positionState: TrainPositionState) {
        guard let activity = currentActivity else { return }
        let state = contentState(from: positionState)
        let content = ActivityContent(state: state, staleDate: staleDate(for: state))

        Task {
            await activity.update(content)
        }
    }

    // The activity keeps advancing on its own via timer-driven views, so it
    // only truly goes stale well after the scheduled arrival.
    private func staleDate(for state: TrainJourneyAttributes.ContentState) -> Date {
        max(state.estimatedArrival.addingTimeInterval(600), Date().addingTimeInterval(600))
    }

    func markDelayRefreshed() {
        lastDelayFetchTime = Date()
    }

    func endActivity() {
        guard let activity = currentActivity else { return }
        let finalState = TrainJourneyAttributes.ContentState(
            progress: 1.0,
            currentStationIndex: nil,
            nextStationName: "",
            nextStationNameEn: "",
            delayMinutes: 0,
            estimatedArrivalTimestamp: Date().timeIntervalSince1970,
            statusRaw: TrainPositionState.Status.arrived.rawValue,
            trackingModeRaw: "Timetable",
            lastRefreshTimestamp: Date().timeIntervalSince1970,
            departureTimestamp: (scheduledDeparture ?? Date()).timeIntervalSince1970
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        Task {
            await activity.end(content, dismissalPolicy: .after(.now + 300))
        }
        currentActivity = nil
        scheduledDeparture = nil
        scheduledArrival = nil
    }

    private func contentState(from state: TrainPositionState) -> TrainJourneyAttributes.ContentState {
        let delaySeconds = TimeInterval(state.delayMinutes * 60)
        let departure = (scheduledDeparture ?? Date()).addingTimeInterval(delaySeconds)
        return .init(
            progress: state.progress,
            currentStationIndex: state.currentStationIndex,
            nextStationName: state.nextStationName,
            nextStationNameEn: state.nextStationNameEn,
            delayMinutes: state.delayMinutes,
            estimatedArrivalTimestamp: state.estimatedArrival.timeIntervalSince1970,
            statusRaw: state.status.rawValue,
            trackingModeRaw: state.trackingModeRaw,
            lastRefreshTimestamp: lastDelayFetchTime.timeIntervalSince1970,
            departureTimestamp: departure.timeIntervalSince1970
        )
    }

    /// Scheduled departure and arrival dates from the journey's timetable.
    private static func scheduledTimes(for journey: Journey) -> (departure: Date?, arrival: Date?) {
        let timetable = journey.journeyTimetable
        let depSec = timetable.first.flatMap { $0.departureSeconds() ?? $0.arrivalSeconds() }
        let arrSec = timetable.last.flatMap { $0.arrivalSeconds() ?? $0.departureSeconds() }
        return (depSec.map(dateFromRailSeconds), arrSec.map(dateFromRailSeconds))
    }

    private static func dateFromRailSeconds(_ seconds: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = seconds / 3600
        comps.minute = (seconds % 3600) / 60
        comps.second = seconds % 60
        if comps.hour! >= 24 {
            comps.hour! -= 24
            if let d = cal.date(from: comps) {
                return cal.date(byAdding: .day, value: 1, to: d) ?? d
            }
        }
        return cal.date(from: comps) ?? Date()
    }
}
