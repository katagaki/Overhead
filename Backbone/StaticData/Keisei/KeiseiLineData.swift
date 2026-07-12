import Foundation

// MARK: - Keisei Line Data

enum KeiseiLineData {

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
                       weekday: ServicePattern, holiday: ServicePattern) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:\(path).\(suffix)",
        nameJa: ja, nameEn: en,
        isAscending: ascending,
        weekday: weekday, saturdayHoliday: holiday
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

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.keisei.co.jp/traininfo/index.php",
        statusPageURLEn: "https://www.keisei.co.jp/keisei/tetudou/skyliner/us/traffic/",
        xAccount: "@keiseirailway",
        checkMethodJa: "京成電鉄「運行情報」ページ、京成アプリ、またはX（@keiseirailway）で確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Keisei train information page, the Keisei app, or X (@keiseirailway). Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        main, oshiage, kanamachi, chiba, chihara, higashiNarita, skyAccess,
    ]

}
