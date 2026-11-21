import SwiftUI
import Backbone

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
    let reduceMotion: Bool

    var language: TrainLCDLanguage {
        LCDLanguageRotation.current(at: date, reduceMotion: reduceMotion)
    }

    /// Alternates every `period` seconds; held steady under Reduce Motion.
    func isLit(period: TimeInterval) -> Bool {
        reduceMotion || Int(date.timeIntervalSinceReferenceDate / period) % 2 == 0
    }
}

/// The clock every LCD style animates from; stops ticking while paused.
struct LCDTimeline<Content: View>: View {
    private let interval: TimeInterval
    private let animated: Bool
    private let content: (LCDTimelineContext) -> Content

    @Environment(\.lcdClockPaused) private var paused
    @Environment(\.motionReduced) private var reduceMotion

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
        if animated && !reduceMotion {
            TimelineView(.animation(minimumInterval: interval, paused: paused)) { context in
                content(LCDTimelineContext(date: RailClock.adjusted(context.date), reduceMotion: false))
            }
        } else {
            // Under Reduce Motion, scrolling styles step through static pages instead.
            let step = animated ? Self.reducedMotionStep : interval
            TimelineView(PausablePeriodicSchedule(interval: step, paused: paused)) { context in
                content(LCDTimelineContext(date: RailClock.adjusted(context.date), reduceMotion: reduceMotion))
            }
        }
    }

    private static var reducedMotionStep: TimeInterval { 0.5 }
}

private struct PausablePeriodicSchedule: TimelineSchedule {
    let interval: TimeInterval
    let paused: Bool

    func entries(from startDate: Date, mode _: TimelineScheduleMode) -> AnyIterator<Date> {
        var next: Date? = startDate
        return AnyIterator {
            defer { next = paused ? nil : next?.addingTimeInterval(interval) }
            return next
        }
    }
}

/// Static windows for Reduce Motion over a dot raster too wide to show at once,
/// cut at blank columns so no glyph is split.
enum LCDRasterPaging {
    static func windows(width: Int, visible: Int, isBlank: (Int) -> Bool) -> [Range<Int>] {
        var windows: [Range<Int>] = []
        var start = 0
        while start < width {
            while start < width && isBlank(start) { start += 1 }
            guard start < width else { break }
            var end = min(start + visible, width)
            if end < width {
                var cut = end
                while cut > start + visible / 2 && !isBlank(cut) { cut -= 1 }
                if cut > start + visible / 2 { end = cut }
            }
            while end > start && isBlank(end - 1) { end -= 1 }
            windows.append(start..<end)
            start = end
        }
        return windows.isEmpty ? [0..<min(width, visible)] : windows
    }
}

/// Static pages for Reduce Motion over a styled ticker message, broken between
/// words or CJK characters so each page fits the window.
enum LCDTextPaging {
    struct Run {
        let text: String
        let style: Int
    }

    static let pageSeconds = 3.5

    private static let clinging: Set<Character> = ["、", "。", "，", "．", "・", "」", "）", ".", ",", ":"]

    static func pages(_ runs: [Run], width: CGFloat, measure: (Run) -> CGFloat) -> [[Run]] {
        var tokens: [Run] = []
        for run in runs {
            var word = ""
            func flush() {
                if !word.isEmpty { tokens.append(Run(text: word, style: run.style)) }
                word = ""
            }
            for character in run.text {
                if character == " " || character == "　" {
                    word.append(character)
                    flush()
                } else if clinging.contains(character) {
                    if !word.isEmpty {
                        word.append(character)
                    } else if let last = tokens.last, last.style == run.style {
                        tokens[tokens.count - 1] = Run(text: last.text + String(character), style: run.style)
                    } else {
                        word.append(character)
                    }
                } else if character.isASCII {
                    word.append(character)
                } else {
                    flush()
                    word.append(character)
                    flush()
                }
            }
            flush()
        }

        var pages: [[Run]] = []
        var page: [Run] = []
        var used: CGFloat = 0
        for token in tokens {
            var token = token
            if page.isEmpty {
                let trimmed = String(token.text.drop { $0 == " " || $0 == "　" })
                guard !trimmed.isEmpty else { continue }
                token = Run(text: trimmed, style: token.style)
            }
            let tokenWidth = measure(token)
            if !page.isEmpty && used + tokenWidth > width {
                pages.append(page)
                page = []
                used = 0
                let trimmed = String(token.text.drop { $0 == " " || $0 == "　" })
                guard !trimmed.isEmpty else { continue }
                token = Run(text: trimmed, style: token.style)
            }
            if let last = page.last, last.style == token.style {
                page[page.count - 1] = Run(text: last.text + token.text, style: token.style)
            } else {
                page.append(token)
            }
            used += measure(token)
        }
        if !page.isEmpty { pages.append(page) }
        return pages
    }
}
