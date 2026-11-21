import Foundation
import Testing
@testable import Backbone

@Suite("Journeys across midnight")
struct JourneyMidnightTests {
    private func lastTrainJourney(on day: ServiceDay, calendar: ScheduleCalendar) throws -> Journey {
        let line = Fixtures.line()
        let service = try #require(StaticTimetableGenerator.services(for: line, calendar: calendar).first)
        return Journey(
            id: UUID(),
            service: service,
            line: line.trainLine,
            boardingStationId: Fixtures.stations[0].id,
            alightingStationId: Fixtures.stations[2].id,
            startedAt: day.date(atRailSeconds: 23 * 3600),
            serviceDay: day
        )
    }

    @Test func generatedTimesRunPastTwentyFour() throws {
        let journey = try lastTrainJourney(on: ServiceDay(year: 2026, month: 11, day: 20), calendar: .weekday)
        #expect(journey.journeyTimetable.map { $0.arrivalTime ?? $0.departureTime } == ["23:55", "24:05", "24:15"])
    }

    @Test func scheduledTimesLandOnTheNextCalendarDate() throws {
        let journey = try lastTrainJourney(on: ServiceDay(year: 2026, month: 11, day: 20), calendar: .weekday)
        let times = journey.scheduledTimes
        #expect(times.departure == Fixtures.jst(2026, 11, 20, 23, 55))
        #expect(times.arrival == Fixtures.jst(2026, 11, 21, 0, 15))
        #expect(journey.scheduledStationTimes == [
            Fixtures.jst(2026, 11, 20, 23, 55),
            Fixtures.jst(2026, 11, 21, 0, 5),
            Fixtures.jst(2026, 11, 21, 0, 15),
        ])
    }

    @Test func railSecondsKeepCountingAfterMidnight() throws {
        let journey = try lastTrainJourney(on: ServiceDay(year: 2026, month: 11, day: 20), calendar: .weekday)
        let midway = Fixtures.jst(2026, 11, 21, 0, 10)
        #expect(journey.railSeconds(at: midway) == 24 * 3600 + 10 * 60)
        let bravo = try #require(journey.journeyTimetable[1].arrivalSeconds())
        let charlie = try #require(journey.journeyTimetable[2].arrivalSeconds())
        #expect(bravo < journey.railSeconds(at: midway))
        #expect(journey.railSeconds(at: midway) < charlie)
        #expect(journey.railDate(charlie) == Fixtures.jst(2026, 11, 21, 0, 15))
    }

    @Test func journeyStartedAfterMidnightKeepsItsServiceDay() throws {
        let day = ServiceDay(containing: Fixtures.jst(2026, 11, 24, 0, 2))
        #expect(day.key == 20261123)
        let journey = try lastTrainJourney(on: day, calendar: day.scheduleCalendar)
        #expect(journey.scheduledTimes.departure == Fixtures.jst(2026, 11, 23, 23, 40))
        #expect(journey.scheduledTimes.arrival == Fixtures.jst(2026, 11, 24, 0, 0))
    }

    @Test func journeyRoundTripsThroughCodable() throws {
        let journey = try lastTrainJourney(on: ServiceDay(year: 2026, month: 11, day: 20), calendar: .weekday)
        let decoded = try JSONDecoder().decode(Journey.self, from: JSONEncoder().encode(journey))
        #expect(decoded.serviceDay == journey.serviceDay)
        #expect(decoded.scheduledTimes.arrival == Fixtures.jst(2026, 11, 21, 0, 15))
    }
}
