import Foundation

// MARK: - Odakyu Line Data

enum OdakyuLineData {

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

// Express 当駅始発/through origin with typed exact runs (ODPT times), for
// skip-stop trains that start at or enter a mid-line station. Stops resolve
// from the line's stopPatterns[type].
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
        statusPageURL: "https://www.odakyu.jp/train/unkou/",
        statusPageURLEn: "https://www.odakyu.jp/english/",
        xAccount: "@odakyuline_info",
        checkMethodJa: "小田急電鉄「運行情報」ページ、小田急アプリ、またはX（@odakyuline_info）で確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Odakyu train information page, the Odakyu app, or X (@odakyuline_info). Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        odawara, enoshima, tama,
    ]

}
