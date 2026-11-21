import Foundation
import Testing
@testable import Backbone

@Suite("Schedule revisions by service day")
struct ScheduleRevisionTests {
    private func revision(_ validFrom: String, weekday: [String]) -> ScheduleRevision {
        var revision = ScheduleRevision(validFrom: validFrom)
        revision.directions = [Fixtures.direction(weekday: weekday, saturdayHoliday: ["23:40"])]
        return revision
    }

    private func firstWeekdayDeparture(_ line: StaticTrainLine) -> String? {
        StaticTimetableGenerator.services(for: line, calendar: .weekday).first?.timetable.first?.departureTime
    }

    @Test func revisionAppliesFromItsFirstServiceDay() {
        let line = Fixtures.line(revisions: [revision("2026-11-22", weekday: ["23:30"])])
        #expect(firstWeekdayDeparture(line.applyingRevisions(onDayKey: 20261121)) == "23:55")
        #expect(firstWeekdayDeparture(line.applyingRevisions(onDayKey: 20261122)) == "23:30")
    }

    @Test func earlyMorningBeforeTheRevisionDayStillUsesTheOldTimetable() {
        let line = Fixtures.line(revisions: [revision("2026-11-22", weekday: ["23:30"])])
        let dayKey = StaticTrainData.dayKey(for: Fixtures.jst(2026, 11, 22, 2, 0))
        #expect(dayKey == 20261121)
        #expect(firstWeekdayDeparture(line.applyingRevisions(onDayKey: dayKey)) == "23:55")
    }

    @Test func laterRevisionsApplyInOrder() {
        let line = Fixtures.line(revisions: [
            revision("2026-12-10", weekday: ["23:20"]),
            revision("2026-11-22", weekday: ["23:30"]),
        ])
        #expect(firstWeekdayDeparture(line.applyingRevisions(onDayKey: 20261201)) == "23:30")
        #expect(firstWeekdayDeparture(line.applyingRevisions(onDayKey: 20261210)) == "23:20")
    }

    @Test(arguments: ["2026-13-01", "2026-11", "next week", "2026-02-32"])
    func malformedDatesNeverApply(validFrom: String) {
        #expect(ScheduleRevision(validFrom: validFrom).validFromDayKey == nil)
        let line = Fixtures.line(revisions: [revision(validFrom, weekday: ["23:30"])])
        #expect(firstWeekdayDeparture(line.applyingRevisions(onDayKey: 99991231)) == "23:55")
    }
}
