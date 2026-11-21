import Foundation
@testable import Backbone

enum Fixtures {
    static let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    /// A JST wall-clock moment.
    static func jst(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tokyo
        return calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        ))!
    }

    static let stations = [
        Station(id: "Station:Test.A", name: "甲", nameEn: "Alpha", stationCode: "T01", latitude: nil, longitude: nil),
        Station(id: "Station:Test.B", name: "乙", nameEn: "Bravo", stationCode: "T02", latitude: nil, longitude: nil),
        Station(id: "Station:Test.C", name: "丙", nameEn: "Charlie", stationCode: "T03", latitude: nil, longitude: nil),
    ]

    static func pattern(_ departures: [String]) -> ServicePattern {
        ServicePattern(
            first: departures.first ?? "05:00",
            last: departures.last ?? "05:00",
            bands: [],
            exactRuns: departures.map { ExactRun($0) }
        )
    }

    static let delayInfo = DelayCheckInfo(
        statusPageURLText: LocalizedText(ja: ""),
        xAccount: nil,
        checkMethodText: LocalizedText(ja: "")
    )

    /// Three stations ten minutes apart, one direction, with a weekday and a holiday last train.
    static func line(
        weekday: [String] = ["23:55"],
        saturdayHoliday: [String] = ["23:40"],
        revisions: [ScheduleRevision]? = nil
    ) -> StaticTrainLine {
        StaticTrainLine(
            id: "Railway:Test.Line",
            nameJa: "試験線",
            nameEn: "Test Line",
            operatorId: "Operator:Test",
            colorHex: "#336699",
            stations: stations,
            hopTimesMinutes: [10, 10],
            directions: [direction(weekday: weekday, saturdayHoliday: saturdayHoliday)],
            delayInfo: delayInfo,
            scheduleRevisions: revisions
        )
    }

    static func direction(weekday: [String], saturdayHoliday: [String]) -> StaticLineDirection {
        StaticLineDirection(
            id: "static.RailDirection:Test.Line.C",
            nameJa: "丙方面",
            nameEn: "For Charlie",
            isAscending: true,
            weekday: pattern(weekday),
            saturdayHoliday: pattern(saturdayHoliday)
        )
    }
}
