import Foundation
import BackgroundTasks
import Network
import UserNotifications
import Backbone

/// Refreshes the downloaded line data while the app is closed. Opt-in, and
/// silent unless the user also asks to be told what landed.
///
/// `BGProcessingTask` buys minutes rather than seconds, which a full-catalog
/// sync needs, and `requiresExternalPower` concentrates runs into the overnight
/// charging window. The system decides when it actually fires — usually within
/// a day for an app in regular use, sometimes not for several — so nothing here
/// promises a nightly run.
@MainActor
final class LineDataAutoUpdater {

    static let shared = LineDataAutoUpdater()

    static let taskIdentifier = "com.tsubuzaki.Overhead.dataRefresh"
    static let enabledKey = "lineData.autoUpdate"
    static let notifyKey = "lineData.autoUpdate.notify"

    /// Far enough out that a finished run does not queue its successor into the
    /// same night.
    private static let earliestDelay: TimeInterval = 6 * 60 * 60
    private static let notificationIdentifier = "lineData.updated"
    /// Lines named outright in the notification; the rest are counted.
    private static let namedLineLimit = 3

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Settings

    var isEnabled: Bool { defaults.bool(forKey: Self.enabledKey) }
    var notifiesOnUpdate: Bool { defaults.bool(forKey: Self.notifyKey) }

    /// Called when either toggle moves. Turning auto-update off takes the
    /// notification toggle with it, so the disabled row cannot stay on.
    func settingsChanged() {
        if isEnabled {
            schedule()
        } else {
            defaults.set(false, forKey: Self.notifyKey)
            cancel()
        }
    }

    /// Asks once, the first time the user turns the notification on. Returns
    /// false when the user has said no, so the toggle can go back.
    func requestNotificationAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert])) ?? false
        default:
            return false
        }
    }

    // MARK: - Scheduling

    /// Must run before the app finishes launching, so it lives on the app's
    /// `init()` rather than on a view's `task`.
    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier, using: nil
        ) { task in
            let work = Task { @MainActor in
                let updater = LineDataAutoUpdater.shared
                let outcome = await updater.run()
                updater.notify(outcome)
                updater.schedule()
                task.setTaskCompleted(success: outcome != .deferred && !Task.isCancelled)
            }
            task.expirationHandler = { work.cancel() }
        }
    }

    /// Idempotent: the pending request is replaced rather than stacked. A
    /// background task never reschedules itself, so this is also the last thing
    /// a run does.
    func schedule() {
        cancel()
        guard isEnabled, defaults.bool(forKey: "lineData.onboarded") else { return }
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        // "Any network", not Wi-Fi — that part is ours to enforce at task start.
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = true
        request.earliestBeginDate = Date().addingTimeInterval(Self.earliestDelay)
        try? BGTaskScheduler.shared.submit(request)
    }

    func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
    }

    // MARK: - The run

    private enum Outcome: Equatable {
        /// Conditions were wrong; nothing was attempted.
        case deferred
        case nothingToDo
        case installed([String])
    }

    private func run() async -> Outcome {
        guard isEnabled, defaults.bool(forKey: "lineData.onboarded") else { return .nothingToDo }
        guard await Self.isOnUnmeteredNetwork() else { return .deferred }

        let installer = LineDataInstaller.shared
        guard !installer.isBusy else { return .deferred }

        installer.restrictsToUnmeteredNetworks = true
        defer { installer.restrictsToUnmeteredNetworks = false }

        do { try await installer.refreshCatalog() } catch { return .deferred }
        guard installer.hasPendingWork else { return .nothingToDo }

        // A failure part-way through still installs the lines it reached, and
        // the ones it did not are what the next run picks up — so the outcome
        // comes from what is left outstanding rather than from the throw.
        let names = installer.pending.map(\.line.localizedName)
        var failed = false
        do { try await installer.sync() } catch { failed = true }
        let remaining = Set(installer.pending.map(\.line.localizedName))
        let landed = names.filter { !remaining.contains($0) }
        if landed.isEmpty { return failed ? .deferred : .nothingToDo }
        return .installed(landed)
    }

    // MARK: - Wi-Fi gate

    /// `requiresNetworkConnectivity` cannot ask for Wi-Fi, so the check happens
    /// here: an expensive or constrained path means the user is on cellular or
    /// Low Data Mode, and the run waits for a better night.
    private static func isOnUnmeteredNetwork() async -> Bool {
        let path = await currentPath()
        return path.status == .satisfied && !path.isExpensive && !path.isConstrained
    }

    private static func currentPath() async -> NWPath {
        let monitor = NWPathMonitor()
        return await withCheckedContinuation { continuation in
            let delivered = Locked(false)
            monitor.pathUpdateHandler = { path in
                guard delivered.take() else { return }
                monitor.cancel()
                continuation.resume(returning: path)
            }
            monitor.start(queue: .global(qos: .utility))
        }
    }

    // MARK: - Notification

    private func notify(_ outcome: Outcome) {
        guard case .installed(let names) = outcome, notifiesOnUpdate else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.LineData.Title")
        content.body = String(localized: "Notification.LineData.Body \(Self.summary(of: names))")
        // Nothing here is worth waking a phone for; the news keeps until morning.
        content.interruptionLevel = .passive
        content.sound = nil

        UNUserNotificationCenter.current().add(UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: nil
        ))
    }

    /// Named lines first, then a count for the tail, joined the way the
    /// language joins lists.
    private static func summary(of names: [String]) -> String {
        var parts = Array(names.prefix(namedLineLimit))
        let others = names.count - parts.count
        if others > 0 {
            parts.append(String(localized: "Notification.LineData.MoreLines \(others)"))
        }
        return ListFormatter.localizedString(byJoining: parts)
    }
}

/// One-shot guard for a callback that must resume a continuation exactly once.
private final class Locked: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Bool

    init(_ value: Bool) { self.value = value }

    /// True the first time only.
    func take() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !value else { return false }
        value = true
        return true
    }
}
