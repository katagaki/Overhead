import Foundation

// MARK: - Tokyo Metro Line Data

enum TokyoMetroLineData {

static func st(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "Station:TokyoMetro.\(line).\(suffix)",
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

static func direction(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                       ascending: Bool,
                       weekday: ServicePattern, holiday: ServicePattern,
                       origins: [IntermediateOrigin] = [],
                       expressWeekday: [ExactRun] = [],
                       expressHoliday: [ExactRun] = []) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:TokyoMetro.\(line).\(suffix)",
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
        junctionStationId: "Station:TokyoMetro.\(junction)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

    // MARK: Delay Check

    // Delays of 15+ minutes are posted on the service information page
    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.tokyometro.jp/unkou/",
        statusPageURLEn: "https://www.tokyometro.jp/lang_en/unkou/index.html",
        xAccount: "@tokyometro_info",
        checkMethodJa: "東京メトロ「運行情報」ページ、公式アプリ、またはX（@tokyometro_info）で確認できます。15分以上の遅れ・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Tokyo Metro Service Information page, the official app, or X (@tokyometro_info). Delays or suspensions of 15 minutes or more are posted."
    )

    static let lines: [StaticTrainLine] = [
        ginza, marunouchi, marunouchiBranch, hibiya, tozai, chiyoda,
        yurakucho, hanzomon, namboku, fukutoshin,
    ]

    // Typical Tokyo Metro headway bands. First/last departures are set per
    // direction below (verified against published timetables, 2026).
    static let metroWeekdayBands: [(String, Double)] = [
        ("05:00", 6), ("07:00", 3), ("09:30", 5), ("17:00", 3.5), ("20:00", 5), ("22:00", 6.5),
    ]

    static let metroHolidayBands: [(String, Double)] = [
        ("05:00", 6), ("07:00", 5), ("10:00", 5), ("20:00", 5.5), ("22:00", 7),
    ]

    static let quietWeekdayBands: [(String, Double)] = [
        ("05:00", 7), ("07:00", 3.5), ("09:30", 6), ("17:00", 4), ("20:00", 6), ("22:00", 7),
    ]

    static let quietHolidayBands: [(String, Double)] = [
        ("05:00", 7), ("07:00", 6), ("10:00", 6), ("20:00", 6.5), ("22:00", 7.5),
    ]

    static func metroWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, metroWeekdayBands)
    }

    static func metroHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, metroHolidayBands)
    }

    static func quietWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, quietWeekdayBands)
    }

    static func quietHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, quietHolidayBands)
    }

}
