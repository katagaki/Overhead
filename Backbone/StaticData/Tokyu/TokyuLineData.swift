import Foundation

// MARK: - Tokyu Line Data

enum TokyuLineData {

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
                       expressWeekday: [ExactRun] = [],
                       expressHoliday: [ExactRun] = []) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:\(path).\(suffix)",
        nameJa: ja, nameEn: en,
        isAscending: ascending,
        weekday: weekday, saturdayHoliday: holiday,
        expressWeekdayRuns: expressWeekday,
        expressSaturdayHolidayRuns: expressHoliday
    )
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

    // Delays of 15+ minutes are posted on the Tokyu Train Operation Information page
    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.tokyu.co.jp/unten2/unten.html",
        statusPageURLEn: "https://www.tokyu.co.jp/global/",
        xAccount: "@tokyu_official",
        checkMethodJa: "東急電鉄「運行情報」ページ、東急線アプリ、またはX（@tokyu_official）で確認できます。15分以上の遅れ・運転見合わせが発生または見込まれる場合に掲載されます。",
        checkMethodEn: "Check the Tokyu train operation information page, the Tokyu Lines app, or X (@tokyu_official). Delays or suspensions of 15 minutes or more are posted."
    )

    static let lines: [StaticTrainLine] = [
        toyoko, denentoshi, meguro,
    ]

}
