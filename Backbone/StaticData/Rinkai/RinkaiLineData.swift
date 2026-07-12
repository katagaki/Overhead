import Foundation

// MARK: - Rinkai Line Data (TWR)

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

private func through(_ junction: String, _ end: ThroughService.LineEnd,
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

enum RinkaiLineData {

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.twr.co.jp/",
        statusPageURLEn: "https://www.twr.co.jp/en/",
        xAccount: nil,
        checkMethodJa: "東京臨海高速鉄道（りんかい線）の運行情報ページで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Tokyo Waterfront Area Rapid Transit (Rinkai Line) service information page. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        rinkai,
    ]

    static let rinkai = StaticTrainLine(
        id: "Railway:TWR.Rinkai",
        nameJa: "りんかい線",
        nameEn: "Rinkai Line",
        operatorId: "Operator:TWR",
        colorHex: "#222D65",
        stations: [
            st("TWR.Rinkai", "ShinKiba", "新木場", "Shin-kiba", "R1", 35.64604, 139.82678),
            st("TWR.Rinkai", "Shinonome", "東雲", "Shinonome", "R2", 35.6406, 139.80328),
            st("TWR.Rinkai", "KokusaiTenjijo", "国際展示場", "Kokusai-tenjijo", "R3", 35.63457, 139.79163),
            st("TWR.Rinkai", "TokyoTeleport", "東京テレポート", "Tokyo Teleport", "R4", 35.62754, 139.77885),
            st("TWR.Rinkai", "TennozuIsle", "天王洲アイル", "Tennozu Isle", "R5", 35.62038, 139.75084),
            st("TWR.Rinkai", "ShinagawaSeaside", "品川シーサイド", "Shinagawa Seaside", "R6", 35.60897, 139.74967),
            st("TWR.Rinkai", "Oimachi", "大井町", "Oimachi", "R7", 35.60741, 139.73474),
            st("TWR.Rinkai", "Osaki", "大崎", "Osaki", "R8", 35.62002, 139.7282),
        ],
        hopTimesMinutes: [
            3, 2, 2, 4, 2, 3, 3,
        ],
        directions: [
            direction("TWR.Rinkai", "Osaki", "大崎・新宿方面", "For Osaki & Shinjuku",
                      ascending: true,
                      weekday: pattern("05:39", "23:54", [("05:39", 12), ("06:00", 9), ("07:00", 7), ("08:00", 6), ("09:00", 5), ("10:00", 7), ("11:00", 9), ("12:00", 8), ("13:00", 9), ("15:00", 8), ("16:00", 7), ("17:00", 6), ("19:00", 7), ("20:00", 8), ("22:00", 11), ("23:00", 15)]),
                      holiday: pattern("05:39", "23:54", [("05:39", 12), ("06:00", 8), ("08:00", 7), ("09:00", 6), ("10:00", 8), ("13:00", 9), ("15:00", 7), ("16:00", 8), ("19:00", 9), ("21:00", 8), ("22:00", 10), ("23:00", 12)]),
                      origins: [
                          origin("Station:TWR.Rinkai.TokyoTeleport",
                                 ["05:19"],
                                 ["05:19"]),
                      ]
            ),
            direction("TWR.Rinkai", "ShinKiba", "新木場方面", "For Shin-kiba",
                      ascending: false,
                      weekday: pattern("05:39", "24:18", [("05:39", 25), ("06:00", 13), ("07:00", 6), ("08:00", 5), ("09:00", 6), ("10:00", 7), ("11:00", 10), ("12:00", 9), ("13:00", 8), ("14:00", 9), ("16:00", 7), ("20:00", 6), ("21:00", 8), ("22:00", 10), ("23:00", 15), ("24:00", 17)]),
                      holiday: pattern("05:39", "24:18", [("05:39", 25), ("06:00", 11), ("07:00", 6), ("08:00", 8), ("11:00", 10), ("13:00", 7), ("14:00", 8), ("15:00", 9), ("17:00", 6), ("18:00", 8), ("19:00", 9), ("20:00", 8), ("22:00", 10), ("23:00", 15), ("24:00", 17)]),
                      origins: [
                          origin("Station:TWR.Rinkai.TokyoTeleport",
                                 ["05:27", "05:37", "06:07", "06:23", "06:38", "16:07", "17:03"],
                                 ["05:27", "05:37", "06:07", "06:22", "06:55"]),
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("TWR.Rinkai.Osaki", .ascending,
                    "ＪＲ埼京線", "JR Saikyo Line",
                    "新宿・大宮方面", "for Shinjuku & Omiya",
                    to: "Railway:JR-East.SaikyoKawagoe"),
        ]
    )
}
