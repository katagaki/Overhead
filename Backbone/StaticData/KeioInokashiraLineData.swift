import Foundation

// MARK: - Keio Inokashira Line Data

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

enum KeioInokashiraLineData {

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.keio.co.jp/unten/",
        statusPageURLEn: "https://www.keio.co.jp/english/",
        xAccount: nil,
        checkMethodJa: "京王電鉄「運行情報」ページで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Keio Corporation service information page. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        inokashira,
    ]

    static let inokashira = StaticTrainLine(
        id: "Railway:Keio.Inokashira",
        nameJa: "京王井の頭線",
        nameEn: "Keio Inokashira Line",
        operatorId: "Operator:Keio",
        colorHex: "#000088",
        stations: [
            st("Keio.Inokashira", "Shibuya", "渋谷", "Shibuya", "IN01", 35.658, 139.7008),
            st("Keio.Inokashira", "Shinsen", "神泉", "Shinsen", "IN02", 35.65717, 139.69313),
            st("Keio.Inokashira", "KomabaTodaimae", "駒場東大前", "Komaba-todaimae", "IN03", 35.65867, 139.68408),
            st("Keio.Inokashira", "Ikenoue", "池ノ上", "Ikenoue", "IN04", 35.66037, 139.67346),
            st("Keio.Inokashira", "ShimoKitazawa", "下北沢", "Shimo-kitazawa", "IN05", 35.6613, 139.668),
            st("Keio.Inokashira", "Shindaita", "新代田", "Shindaita", "IN06", 35.6625, 139.66139),
            st("Keio.Inokashira", "HigashiMatsubara", "東松原", "Higashi-matsubara", "IN07", 35.66264, 139.65569),
            st("Keio.Inokashira", "Meidaimae", "明大前", "Meidaimae", "IN08", 35.66908, 139.65038),
            st("Keio.Inokashira", "Eifukucho", "永福町", "Eifukucho", "IN09", 35.67622, 139.64267),
            st("Keio.Inokashira", "NishiEifuku", "西永福", "Nishi-eifuku", "IN10", 35.67888, 139.63516),
            st("Keio.Inokashira", "Hamadayama", "浜田山", "Hamadayama", "IN11", 35.68158, 139.62758),
            st("Keio.Inokashira", "Takaido", "高井戸", "Takaido", "IN12", 35.68326, 139.61523),
            st("Keio.Inokashira", "Fujimigaoka", "富士見ヶ丘", "Fujimigaoka", "IN13", 35.68481, 139.6072),
            st("Keio.Inokashira", "Kugayama", "久我山", "Kugayama", "IN14", 35.68814, 139.59932),
            st("Keio.Inokashira", "Mitakadai", "三鷹台", "Mitakadai", "IN15", 35.69205, 139.5893),
            st("Keio.Inokashira", "InokashiraKoen", "井の頭公園", "Inokashira-koen", "IN16", 35.6973, 139.58312),
            st("Keio.Inokashira", "Kichijoji", "吉祥寺", "Kichijoji", "IN17", 35.7032, 139.5797),
        ],
        hopTimesMinutes: [
            1, 2, 2, 2, 2, 1, 2, 3, 2, 2, 2, 2, 2, 2, 2, 1,
        ],
        directions: [
            direction("Keio.Inokashira", "Kichijoji", "吉祥寺方面", "For Kichijoji",
                      ascending: true,
                      weekday: pattern("05:00", "24:30", [("05:00", 12), ("06:00", 5), ("07:00", 3), ("08:00", 2), ("09:00", 3), ("11:00", 4), ("18:00", 3), ("19:00", 4), ("20:00", 3), ("21:00", 5), ("22:00", 4), ("23:00", 6)]),
                      holiday: pattern("05:00", "24:30", [("05:00", 14), ("06:00", 7), ("07:00", 4), ("10:00", 3), ("11:00", 6), ("12:00", 2), ("13:00", 6), ("14:00", 2), ("15:00", 6), ("16:00", 2), ("17:00", 6), ("18:00", 3), ("19:00", 5), ("22:00", 6), ("23:00", 5), ("24:00", 6)]),
                      origins: [
                          origin("Station:Keio.Inokashira.Fujimigaoka",
                                 ["04:41", "04:54", "05:09", "05:51", "06:01", "06:10", "06:30", "06:59", "07:11", "07:19", "17:08", "17:48"],
                                 ["04:41", "04:54", "05:09", "06:09", "06:19", "06:31", "06:34", "06:41", "06:56", "07:04"]),
                      ]
            ),
            direction("Keio.Inokashira", "Shibuya", "渋谷方面", "For Shibuya",
                      ascending: false,
                      weekday: pattern("04:52", "24:40", [("04:52", 13), ("05:00", 12), ("06:00", 4), ("07:00", 3), ("08:00", 4), ("09:00", 3), ("10:00", 7), ("11:00", 4), ("13:00", 2), ("14:00", 7), ("15:00", 4), ("17:00", 3), ("18:00", 4), ("19:00", 3), ("20:00", 4), ("22:00", 5), ("23:00", 6), ("24:00", 10)]),
                      holiday: pattern("04:52", "24:40", [("04:52", 13), ("05:00", 12), ("06:00", 6), ("07:00", 4), ("10:00", 6), ("11:00", 2), ("12:00", 6), ("13:00", 4), ("14:00", 5), ("15:00", 3), ("16:00", 5), ("17:00", 2), ("18:00", 6), ("19:00", 5), ("23:00", 7), ("24:00", 12)]),
                      origins: [
                          origin("Station:Keio.Inokashira.Fujimigaoka",
                                 ["04:35", "04:47", "05:56", "06:50", "07:15", "07:36", "07:42", "07:46", "08:01", "08:09", "08:13", "08:18", "08:22", "08:27", "08:32", "08:37", "08:42", "08:53", "16:30"],
                                 ["04:35", "04:47", "05:58"]),
                      ]
            ),
        ],
        delayInfo: delayInfo
    )
}
