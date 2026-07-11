import Foundation

// MARK: - Yokohama Municipal Subway Green Line Data

private func st(_ path: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "Station:\(path).\(suffix)",
        name: ja, nameEn: en, stationCode: code,
        latitude: lat, longitude: lon
    )
}

private func pattern(_ first: String, _ last: String, _ bands: [(String, Double)]) -> ServicePattern {
    ServicePattern(
        first: first, last: last,
        bands: bands.map { HeadwayBand(from: $0.0, headwayMinutes: $0.1) }
    )
}

private func direction(_ path: String, _ suffix: String, _ ja: String, _ en: String,
                       ascending: Bool,
                       weekday: ServicePattern, holiday: ServicePattern,
                       origins: [IntermediateOrigin] = []) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:\(path).\(suffix)",
        nameJa: ja, nameEn: en,
        isAscending: ascending,
        weekday: weekday, saturdayHoliday: holiday,
        intermediateOrigins: origins
    )
}

// 当駅始発 origin with EXACT departure times from ODPT (odpt:originStation).
private func origin(_ stationId: String, _ weekday: [String], _ holiday: [String]) -> IntermediateOrigin {
    IntermediateOrigin(stationId: stationId, weekday: weekday, saturdayHoliday: holiday)
}

enum YokohamaGreenLineData {

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.city.yokohama.lg.jp/kotsu/",
        statusPageURLEn: "https://www.city.yokohama.lg.jp/lang/residents/en/",
        xAccount: nil,
        checkMethodJa: "横浜市交通局の公式サイトで運行情報を確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Yokohama City Transportation Bureau website for service information. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        yokohamaGreen,
    ]

    static let yokohamaGreen = StaticTrainLine(
        id: "Railway:YokohamaMunicipal.Green",
        nameJa: "横浜市営地下鉄グリーンライン",
        nameEn: "Yokohama Municipal Subway Green Line",
        operatorId: "Operator:YokohamaMunicipal",
        colorHex: "#4BA672",
        stations: [
            st("YokohamaMunicipal.Green", "Nakayama", "中山", "Nakayama", "G01", 35.515143, 139.540439),
            st("YokohamaMunicipal.Green", "Kawawacho", "川和町", "Kawawacho", "G02", 35.528382, 139.549265),
            st("YokohamaMunicipal.Green", "TsuzukiFureainooka", "都筑ふれあいの丘", "Tsuzuki-fureainooka", "G03", 35.536637, 139.561611),
            st("YokohamaMunicipal.Green", "CenterMinami", "センター南", "Center-minami", "G04", 35.545633, 139.574713),
            st("YokohamaMunicipal.Green", "CenterKita", "センター北", "Center-kita", "G05", 35.553383, 139.579045),
            st("YokohamaMunicipal.Green", "KitaYamata", "北山田", "Kita-yamata", "G06", 35.56095, 139.592827),
            st("YokohamaMunicipal.Green", "HigashiYamata", "東山田", "Higashi-yamata", "G07", 35.554184, 139.604928),
            st("YokohamaMunicipal.Green", "Takata", "高田", "Takata", "G08", 35.549594, 139.620231),
            st("YokohamaMunicipal.Green", "HiyoshiHoncho", "日吉本町", "Hiyoshi-honcho", "G09", 35.549961, 139.633413),
            st("YokohamaMunicipal.Green", "Hiyoshi", "日吉", "Hiyoshi", "G10", 35.553207, 139.647449),
        ],
        hopTimesMinutes: [2, 2, 2, 1, 2, 2, 2, 1, 2],
        directions: [
            direction("YokohamaMunicipal.Green", "Hiyoshi", "日吉方面", "For Hiyoshi", ascending: true,
                      weekday: pattern("05:08", "24:13", [
                          ("05:00", 10), ("06:00", 4), ("09:00", 8), ("10:00", 10), ("16:00", 8), ("17:00", 6), ("22:00", 7), ("23:00", 10), ("24:00", 12),
                      ]),
                      holiday: pattern("05:08", "24:02", [
                          ("05:00", 10), ("06:00", 7), ("09:00", 8), ("10:00", 9), ("11:00", 10), ("16:00", 8), ("21:00", 10), ("23:00", 14),
                      ]),
                      origins: [
                          origin("Station:YokohamaMunicipal.Green.TsuzukiFureainooka",
                                 ["05:59"],
                                 []),
                      ]),
            direction("YokohamaMunicipal.Green", "Nakayama", "中山方面", "For Nakayama", ascending: false,
                      weekday: pattern("05:15", "24:38", [
                          ("05:00", 10), ("06:00", 6), ("07:00", 4), ("09:00", 8), ("10:00", 10), ("16:00", 8), ("17:00", 6), ("22:00", 8), ("23:00", 10), ("24:00", 12),
                      ]),
                      holiday: pattern("05:15", "24:28", [
                          ("05:00", 10), ("06:00", 8), ("07:00", 7), ("09:00", 8), ("10:00", 10), ("16:00", 8), ("21:00", 10), ("22:00", 12), ("23:00", 13), ("24:00", 18),
                      ]),
                      origins: [
                          origin("Station:YokohamaMunicipal.Green.Kawawacho",
                                 ["05:13", "05:24"],
                                 ["05:13", "05:24"]),
                      ]),
        ],
        delayInfo: delayInfo
    )
}
