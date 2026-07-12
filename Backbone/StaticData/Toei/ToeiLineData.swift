import Foundation

// MARK: - Toei Line Data

enum ToeiLineData {

static func st(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "Station:Toei.\(line).\(suffix)",
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
                       origins: [IntermediateOrigin] = []) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:Toei.\(line).\(suffix)",
        nameJa: ja, nameEn: en,
        isAscending: ascending,
        weekday: weekday, saturdayHoliday: holiday,
        intermediateOrigins: origins
    )
}

// 当駅始発 origin with EXACT departure times from ODPT (odpt:originStation).
static func origin(_ stationId: String, _ weekday: [String], _ holiday: [String]) -> IntermediateOrigin {
    IntermediateOrigin(stationId: stationId, weekday: weekday, saturdayHoliday: holiday)
}

static func through(_ junction: String, _ end: ThroughService.LineEnd,
                     _ lineJa: String, _ lineEn: String,
                     _ towardJa: String, _ towardEn: String,
                     to connectingLineId: String? = nil) -> ThroughService {
    ThroughService(
        junctionStationId: "Station:Toei.\(junction)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.kotsu.metro.tokyo.jp/subway/unkou/unkou_all.html",
        statusPageURLEn: "https://www.kotsu.metro.tokyo.jp/eng/",
        xAccount: "@toeikotsu",
        checkMethodJa: "都営交通「運行情報」ページ、都営交通アプリ、またはX（@toeikotsu）で確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Toei Transportation service information page, the Toei app, or X (@toeikotsu). Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        asakusa, mita, shinjuku, oedo, nipporiToneri, arakawa,
    ]

    static func toeiWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 7), ("07:00", 4), ("09:30", 6), ("17:00", 4.5), ("20:00", 6), ("22:00", 8),
        ])
    }

    static func toeiHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 7), ("07:00", 6), ("10:00", 6), ("20:00", 6.5), ("22:00", 8),
        ])
    }

}
