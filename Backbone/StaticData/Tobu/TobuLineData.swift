import Foundation

// MARK: - Tobu Line Data

enum TobuLineData {

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

// 当駅始発 origin with EXACT departure times from ODPT (odpt:originStation).
static func origin(_ stationId: String, _ weekday: [String], _ holiday: [String]) -> IntermediateOrigin {
    IntermediateOrigin(stationId: stationId, weekday: weekday, saturdayHoliday: holiday)
}

// Express 当駅始発/through origin with typed exact runs (ODPT), for skip-stop
// trains entering or starting at a mid-line station.
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

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.tobu.co.jp/service_status/",
        statusPageURLEn: "https://www.tobu.co.jp/en/",
        xAccount: "@TobuRailway_JP",
        checkMethodJa: "東武鉄道「運行情報」ページ、東武線アプリ、またはX（@TobuRailway_JP）で確認できます。おおむね10分以上の遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Tobu Railway service status page, the Tobu app, or X (@TobuRailway_JP). Delays of roughly 10 minutes or more and suspensions are posted."
    )

    static let lines: [StaticTrainLine] = [
        skytree, tojo, kameido, daishi, urbanPark, nikko,
    ]

}
