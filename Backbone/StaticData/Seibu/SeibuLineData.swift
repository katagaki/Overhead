import Foundation

// MARK: - Seibu Line Data

enum SeibuLineData {

static func st(_ path: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "Station:\(path).\(suffix)",
        name: ja, nameEn: en, stationCode: code,
        latitude: lat, longitude: lon
    )
}

static func pattern(_ first: String, _ last: String, _ bands: [(String, Double)]) -> ServicePattern {
    ServicePattern(
        first: first, last: last,
        bands: bands.map { HeadwayBand(from: $0.0, headwayMinutes: $0.1) }
    )
}

static func direction(_ path: String, _ suffix: String, _ ja: String, _ en: String,
                       ascending: Bool,
                       weekday: ServicePattern, holiday: ServicePattern,
                       origins: [IntermediateOrigin] = [],
                       expressWeekday: [ExactRun] = [],
                       expressHoliday: [ExactRun] = []) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:\(path).\(suffix)",
        nameJa: ja, nameEn: en,
        isAscending: ascending,
        weekday: weekday, saturdayHoliday: holiday,
        intermediateOrigins: origins,
        expressWeekdayRuns: expressWeekday,
        expressSaturdayHolidayRuns: expressHoliday
    )
}

// Express 当駅始発/through origin with typed exact runs (ODPT StationTimetable),
// for skip-stop trains starting at or entering a mid-line station.
static func originRuns(_ stationId: String, _ weekday: [ExactRun], _ holiday: [ExactRun]) -> IntermediateOrigin {
    IntermediateOrigin(stationId: stationId, weekdayRuns: weekday, saturdayHolidayRuns: holiday)
}

static func through(_ junction: String, _ end: ThroughService.LineEnd,
                     _ lineJa: String, _ lineEn: String,
                     _ towardJa: String, _ towardEn: String,
                     to connectingLineId: String? = nil) -> ThroughService {
    ThroughService(
        junctionStationId: "Station:\(junction)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.seiburailway.jp/railways/unkou/",
        statusPageURLEn: "https://www.seiburailway.jp/global/en/",
        xAccount: nil,
        checkMethodJa: "西武鉄道「運行情報」ページまたは西武線アプリで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Seibu Railway operation information page or the Seibu Lines app. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        ikebukuro, seibuYurakucho, shinjuku,
    ]

}
