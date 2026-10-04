import SwiftUI

private struct LCDClockPausedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Freezes LCD animation; the app stays alive in the background on a journey.
    var lcdClockPaused: Bool {
        get { self[LCDClockPausedKey.self] }
        set { self[LCDClockPausedKey.self] = newValue }
    }
}

struct LCDTimelineContext {
    let date: Date
}

/// The clock every LCD style animates from; stops ticking while paused.
struct LCDTimeline<Content: View>: View {
    private let interval: TimeInterval
    private let animated: Bool
    private let content: (LCDTimelineContext) -> Content

    @Environment(\.lcdClockPaused) private var paused

    /// Wall-clock steps, for flips and blinks.
    init(every interval: TimeInterval,
         @ViewBuilder content: @escaping (LCDTimelineContext) -> Content) {
        self.interval = interval
        self.animated = false
        self.content = content
    }

    /// Display-linked, for scrolling.
    init(animationInterval interval: TimeInterval,
         @ViewBuilder content: @escaping (LCDTimelineContext) -> Content) {
        self.interval = interval
        self.animated = true
        self.content = content
    }

    var body: some View {
        if animated {
            TimelineView(.animation(minimumInterval: interval, paused: paused)) { context in
                content(LCDTimelineContext(date: context.date))
            }
        } else {
            TimelineView(PausablePeriodicSchedule(interval: interval, paused: paused)) { context in
                content(LCDTimelineContext(date: context.date))
            }
        }
    }
}

private struct PausablePeriodicSchedule: TimelineSchedule {
    let interval: TimeInterval
    let paused: Bool

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var next: Date? = startDate
        return AnyIterator {
            defer { next = paused ? nil : next?.addingTimeInterval(interval) }
            return next
        }
    }
}
