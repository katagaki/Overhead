import Foundation
import Testing
@testable import Backbone

@Suite("Service day and rail seconds")
struct ServiceDayTests {
    @Test func afterMidnightBelongsToThePreviousDay() {
        let day = ServiceDay(containing: Fixtures.jst(2026, 11, 22, 0, 5))
        #expect(day == ServiceDay(year: 2026, month: 11, day: 21))
        #expect(day.railSeconds(at: Fixtures.jst(2026, 11, 22, 0, 5)) == 24 * 3600 + 5 * 60)
    }

    @Test func lastSecondBeforeRolloverStaysOnThePreviousDay() {
        let date = Fixtures.jst(2026, 11, 22, 3, 59, 59)
        #expect(ServiceDay(containing: date).key == 20261121)
        #expect(ServiceDay.railSeconds(at: date) == 27 * 3600 + 59 * 60 + 59)
    }

    @Test func rolloverStartsANewDayAtFour() {
        let date = Fixtures.jst(2026, 11, 22, 4, 0)
        #expect(ServiceDay(containing: date).key == 20261122)
        #expect(ServiceDay.railSeconds(at: date) == 4 * 3600)
    }

    @Test func lateEveningIsPlainSeconds() {
        let date = Fixtures.jst(2026, 11, 21, 23, 59)
        #expect(ServiceDay(containing: date).key == 20261121)
        #expect(ServiceDay.railSeconds(at: date) == 23 * 3600 + 59 * 60)
    }

    @Test(arguments: [0, 1, 2, 3])
    func everyEarlyHourCountsPastTwentyFour(hour: Int) {
        let date = Fixtures.jst(2026, 1, 1, hour, 30)
        let day = ServiceDay(containing: date)
        #expect(day.key == 20251231)
        #expect(day.railSeconds(at: date) == (24 + hour) * 3600 + 30 * 60)
    }

    @Test func dateAtRailSecondsRoundTrips() {
        let day = ServiceDay(year: 2026, month: 11, day: 21)
        #expect(day.start == Fixtures.jst(2026, 11, 21))
        #expect(day.date(atRailSeconds: 25 * 3600 + 10 * 60) == Fixtures.jst(2026, 11, 22, 1, 10))
        #expect(day.railSeconds(at: day.date(atRailSeconds: 90_000)) == 90_000)
    }

    @Test func railSecondsBeforeTheDayStartsAreNegative() {
        let day = ServiceDay(year: 2026, month: 11, day: 21)
        #expect(day.railSeconds(at: Fixtures.jst(2026, 11, 20, 23, 0)) == -3600)
    }

    @Test func addingDaysCrossesMonthAndYear() {
        #expect(ServiceDay(year: 2026, month: 11, day: 30).adding(days: 1) == ServiceDay(year: 2026, month: 12, day: 1))
        #expect(ServiceDay(year: 2026, month: 12, day: 31).adding(days: 1) == ServiceDay(year: 2027, month: 1, day: 1))
        #expect(ServiceDay(year: 2027, month: 1, day: 1).adding(days: -1) == ServiceDay(year: 2026, month: 12, day: 31))
    }

    @Test func dayKeyMatchesServiceDay() {
        #expect(StaticTrainData.dayKey(for: Fixtures.jst(2026, 3, 1, 2, 0)) == 20260228)
        #expect(ServiceDay(year: 2026, month: 11, day: 21) < ServiceDay(year: 2026, month: 11, day: 22))
    }

    @Test func railTimeStringsSortPastMidnightLast() {
        #expect(TimetableEntry.parseRailTime("25:10") == 25 * 3600 + 10 * 60)
        #expect(TimetableEntry.railMinutes("00:30") == 24 * 60 + 30)
        #expect(TimetableEntry.railMinutes("03:59") == 27 * 60 + 59)
        #expect(TimetableEntry.railMinutes("04:00") == 4 * 60)
        #expect(TimetableEntry.railMinutes("24:30") == 24 * 60 + 30)
        #expect(TimetableEntry.parseRailTime("7") == nil)
    }

    @Test func railTimesOffersBothReadingsAfterMidnight() {
        let readings = StaticTrainLine.railTimes(at: Fixtures.jst(2026, 11, 24, 0, 30))
        #expect(readings.map(\.0) == ["24:30", "00:30"])
        // 24:30 belongs to Monday 11/23 (勤労感謝の日), 00:30 to Tuesday's timetable.
        #expect(readings.map(\.1) == [.saturdayHoliday, .weekday])
    }

    @Test func railTimesHasOneReadingInTheDay() {
        let readings = StaticTrainLine.railTimes(at: Fixtures.jst(2026, 11, 20, 8, 15))
        #expect(readings.map(\.0) == ["08:15"])
        #expect(readings.map(\.1) == [.weekday])
    }
}
