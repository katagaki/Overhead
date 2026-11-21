import Foundation
import Testing
@testable import Backbone

@Suite("Weekday, Saturday and holiday calendars")
struct ScheduleCalendarTests {
    @Test(arguments: [
        (2026, 11, 20, ScheduleCalendar.weekday),        // Friday
        (2026, 11, 21, ScheduleCalendar.saturdayHoliday), // Saturday
        (2026, 11, 22, ScheduleCalendar.saturdayHoliday), // Sunday
        (2026, 11, 23, ScheduleCalendar.saturdayHoliday), // 勤労感謝の日 (Monday)
        (2026, 11, 24, ScheduleCalendar.weekday),        // Tuesday
        (2026, 1, 2, ScheduleCalendar.saturdayHoliday),   // New Year period (Friday)
        (2026, 1, 12, ScheduleCalendar.saturdayHoliday),  // 成人の日, second Monday
        (2026, 3, 20, ScheduleCalendar.saturdayHoliday),  // 春分の日
        (2026, 5, 6, ScheduleCalendar.saturdayHoliday),   // 振替休日 for Sunday 5/3
        (2026, 5, 7, ScheduleCalendar.weekday),
        (2026, 9, 21, ScheduleCalendar.saturdayHoliday),  // 敬老の日
        (2026, 9, 22, ScheduleCalendar.saturdayHoliday),  // 国民の休日 between two holidays
        (2026, 9, 23, ScheduleCalendar.saturdayHoliday),  // 秋分の日
        (2026, 12, 29, ScheduleCalendar.weekday),
        (2026, 12, 30, ScheduleCalendar.saturdayHoliday),
    ])
    func calendarForDay(year: Int, month: Int, day: Int, expected: ScheduleCalendar) {
        #expect(ServiceDay(year: year, month: month, day: day).scheduleCalendar == expected)
    }

    @Test func earlyMorningAfterAHolidayRunsTheHolidayTimetable() {
        // 00:30 Tuesday is still Monday 勤労感謝の日's service day.
        #expect(ScheduleCalendar.current(at: Fixtures.jst(2026, 11, 24, 0, 30)) == .saturdayHoliday)
        #expect(ScheduleCalendar.current(at: Fixtures.jst(2026, 11, 24, 4, 0)) == .weekday)
    }

    @Test func earlyMorningAfterAWeekdayRunsTheWeekdayTimetable() {
        // 01:00 Saturday is still Friday's service day.
        #expect(ScheduleCalendar.current(at: Fixtures.jst(2026, 11, 21, 1, 0)) == .weekday)
        #expect(ScheduleCalendar.current(at: Fixtures.jst(2026, 11, 21, 5, 0)) == .saturdayHoliday)
    }

    @Test func generatorPicksTheCalendarsPattern() {
        let line = Fixtures.line(weekday: ["23:55"], saturdayHoliday: ["23:40"])
        let weekday = StaticTimetableGenerator.services(for: line, calendar: .weekday)
        let holiday = StaticTimetableGenerator.services(for: line, calendar: .saturdayHoliday)
        #expect(weekday.map { $0.timetable.first?.departureTime } == ["23:55"])
        #expect(holiday.map { $0.timetable.first?.departureTime } == ["23:40"])
    }
}
