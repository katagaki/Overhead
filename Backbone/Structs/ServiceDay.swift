import Foundation

public enum RailClock {

    public static var now: Date { adjusted(Date()) }

    /// Moves a wall-clock reading (e.g. a TimelineView tick) onto the rail clock.
    public static func adjusted(_ date: Date) -> Date {
#if DEBUG
        date.addingTimeInterval(debugOffset)
#else
        date
#endif
    }

    /// The real moment a rail-clock date happens, for dates handed to the system.
    public static func real(_ date: Date) -> Date {
#if DEBUG
        date.addingTimeInterval(-debugOffset)
#else
        date
#endif
    }

#if DEBUG
    /// `-debugNow 2026-11-22T00:05:00+09:00` starts the clock there and lets it run.
    public static let debugOffset: TimeInterval = {
        guard let raw = UserDefaults.standard.string(forKey: "debugNow"),
              let target = ISO8601DateFormatter().date(from: raw)
        else { return 0 }
        return target.timeIntervalSince(launchDate)
    }()

    private static let launchDate = Date()
#endif
}

/// The operating day a timetable belongs to: 00:00–03:59 JST is 24:00–27:59 of the day before.
public struct ServiceDay: Hashable, Comparable, Codable, Sendable {

    public static let rolloverHour = 4

    public let year: Int
    public let month: Int
    public let day: Int

    static let tokyo: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return cal
    }()

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(containing date: Date) {
        let shifted = date.addingTimeInterval(-TimeInterval(Self.rolloverHour * 3600))
        let c = Self.tokyo.dateComponents([.year, .month, .day], from: shifted)
        self.init(year: c.year ?? 1970, month: c.month ?? 1, day: c.day ?? 1)
    }

    public static var today: ServiceDay { ServiceDay(containing: RailClock.now) }

    /// yyyyMMdd
    public var key: Int { year * 10000 + month * 100 + day }

    /// 00:00 JST on the service day's calendar date; rail seconds count from here.
    public var start: Date {
        Self.tokyo.date(from: DateComponents(year: year, month: month, day: day)) ?? Date(timeIntervalSince1970: 0)
    }

    public func date(atRailSeconds seconds: Int) -> Date {
        start.addingTimeInterval(TimeInterval(seconds))
    }

    /// Negative before this day starts, 86400+ once the clock passes midnight.
    public func railSeconds(at date: Date) -> Int {
        Int(date.timeIntervalSince(start).rounded(.down))
    }

    /// Seconds into the service day `date` falls on.
    public static func railSeconds(at date: Date) -> Int {
        ServiceDay(containing: date).railSeconds(at: date)
    }

    public func adding(days: Int) -> ServiceDay {
        ServiceDay(containing: start.addingTimeInterval(TimeInterval(days * 86400 + Self.rolloverHour * 3600)))
    }

    public var scheduleCalendar: ScheduleCalendar {
        let weekday = Self.tokyo.component(.weekday, from: start)
        // 1 = Sunday, 7 = Saturday
        if weekday == 1 || weekday == 7 { return .saturdayHoliday }
        return ScheduleCalendar.runsOnHolidaySchedule(year: year, month: month, day: day)
            ? .saturdayHoliday : .weekday
    }

    public static func < (lhs: ServiceDay, rhs: ServiceDay) -> Bool { lhs.key < rhs.key }
}
