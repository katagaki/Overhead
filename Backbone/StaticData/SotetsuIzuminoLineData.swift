import Foundation

// MARK: - Sotetsu Izumino Line Data

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

enum SotetsuIzuminoLineData {

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.sotetsu.co.jp/train/status/",
        statusPageURLEn: "https://www.sotetsu.co.jp/en/",
        xAccount: nil,
        checkMethodJa: "相模鉄道「運行状況」ページまたは相鉄線アプリで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Sotetsu train status page or the Sotetsu Line app. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        izumino,
    ]

    static let izumino = StaticTrainLine(
        id: "Railway:Sotetsu.Izumino",
        nameJa: "相鉄いずみ野線",
        nameEn: "Sotetsu Izumino Line",
        operatorId: "Operator:Sotetsu",
        colorHex: "#35519D",
        stations: [
            st("Sotetsu.Izumino", "Futamatagawa", "二俣川", "Futamata-gawa", "SO10", 35.46338, 139.53232),
            st("Sotetsu.Izumino", "MinamiMakigahara", "南万騎が原", "Minami-makigahara", "SO31", 35.45234, 139.52636),
            st("Sotetsu.Izumino", "Ryokuentoshi", "緑園都市", "Ryokuentoshi", "SO32", 35.43932, 139.52198),
            st("Sotetsu.Izumino", "Yayoidai", "弥生台", "Yayoidai", "SO33", 35.42974, 139.50647),
            st("Sotetsu.Izumino", "Izumino", "いずみ野", "Izumino", "SO34", 35.42926, 139.495),
            st("Sotetsu.Izumino", "IzumiChuo", "いずみ中央", "Izumi-chuo", "SO35", 35.41505, 139.48727),
            st("Sotetsu.Izumino", "Yumegaoka", "ゆめが丘", "Yumegaoka", "SO36", 35.40546, 139.48244),
            st("Sotetsu.Izumino", "Shonandai", "湘南台", "Shonandai", "SO37", 35.39613, 139.46659),
        ],
        hopTimesMinutes: [
            2, 2, 3, 2, 3, 2, 3,
        ],
        directions: [
            direction("Sotetsu.Izumino", "Shonandai", "湘南台方面", "For Shonandai",
                      ascending: true,
                      weekday: pattern("05:02", "24:47", [("05:02", 10), ("06:00", 6), ("09:00", 10), ("18:00", 9), ("19:00", 8), ("20:00", 9), ("21:00", 10), ("22:00", 13), ("23:00", 14), ("24:00", 20)]),
                      holiday: pattern("05:02", "24:47", [("05:02", 15), ("06:00", 13), ("07:00", 10), ("22:00", 12), ("23:00", 16), ("24:00", 20)])
            ),
            direction("Sotetsu.Izumino", "Futamatagawa", "二俣川・横浜方面", "For Futamata-gawa & Yokohama",
                      ascending: false,
                      weekday: pattern("05:00", "24:15", [("05:00", 23), ("06:00", 6), ("07:00", 5), ("08:00", 7), ("09:00", 10), ("18:00", 8), ("19:00", 10), ("21:00", 12), ("22:00", 11), ("23:00", 17)]),
                      holiday: pattern("05:00", "24:15", [("05:00", 23), ("06:00", 10), ("21:00", 8), ("22:00", 12), ("23:00", 17)]),
                      origins: [
                          origin("Station:Sotetsu.Izumino.Izumino",
                                 ["04:43"],
                                 ["04:43"]),
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Sotetsu.Izumino.Futamatagawa", .descending,
                    "相鉄本線", "Sotetsu Main Line",
                    "横浜方面", "for Yokohama",
                    to: "Railway:Sotetsu.Main"),
        ]
    )
}
