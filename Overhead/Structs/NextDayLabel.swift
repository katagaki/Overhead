import SwiftUI
import Backbone

/// Marks a train from the next service day: 明日 when it leaves on tomorrow's date,
/// 翌日 when it is still today's date (after midnight) or further out.
nonisolated enum NextDayLabel {
    private static let tokyo: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()

    static func key(departing date: Date, now: Date = RailClock.now) -> LocalizedStringKey {
        let tomorrow = now.addingTimeInterval(86400)
        return tokyo.isDate(date, inSameDayAs: tomorrow) ? "Candidate.Tomorrow" : "Candidate.NextDay"
    }
}
