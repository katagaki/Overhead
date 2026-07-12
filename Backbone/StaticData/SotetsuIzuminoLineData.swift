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
                      holiday: pattern("05:02", "24:47", [("05:02", 15), ("06:00", 13), ("07:00", 10), ("22:00", 12), ("23:00", 16), ("24:00", 20)]),
                      expressWeekday: izuminoAscExpressWd,
                      expressHoliday: izuminoAscExpressHol
            ),
            direction("Sotetsu.Izumino", "Futamatagawa", "二俣川・横浜方面", "For Futamata-gawa & Yokohama",
                      ascending: false,
                      weekday: pattern("05:00", "24:15", [("05:00", 23), ("06:00", 6), ("07:00", 5), ("08:00", 7), ("09:00", 10), ("18:00", 8), ("19:00", 10), ("21:00", 12), ("22:00", 11), ("23:00", 17)]),
                      holiday: pattern("05:00", "24:15", [("05:00", 23), ("06:00", 10), ("21:00", 8), ("22:00", 12), ("23:00", 17)]),
                      origins: [
                          origin("Station:Sotetsu.Izumino.Izumino",
                                 ["04:43"],
                                 ["04:43"]),
                      ],
                      expressWeekday: izuminoDescExpressWd,
                      expressHoliday: izuminoDescExpressHol
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

    // MARK: - Izumino Express Runs (ODPT, July-2026)

private static let izuminoAscExpressHol: [ExactRun] = [
    ExactRun("07:12", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("07:33", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("07:53", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("08:00", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
    ExactRun("09:43", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("10:13", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("10:43", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("11:13", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("13:13", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("14:13", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("15:43", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("17:03", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("20:23", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("21:13", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("22:15", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("23:18", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("24:06", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
]
private static let izuminoAscExpressWd: [ExactRun] = [
    ExactRun("05:50", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
    ExactRun("06:20", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("06:37", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("06:45", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
    ExactRun("06:54", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("07:02", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("07:07", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
    ExactRun("07:12", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("07:38", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("07:42", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
    ExactRun("07:56", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("08:08", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
    ExactRun("08:13", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("08:30", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("08:34", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
    ExactRun("08:40", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("10:13", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("15:13", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("16:13", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("17:50", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("18:06", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
    ExactRun("18:09", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("18:35", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("19:10", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
    ExactRun("19:18", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("19:40", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
    ExactRun("19:48", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7]),
    ExactRun("20:10", startsHere: false, trainType: .limitedExpress, stopIndices: [0, 4, 7]),
]
private static let izuminoDescExpressHol: [ExactRun] = [
    ExactRun("06:48", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:18", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:48", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:33", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("09:38", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:08", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:38", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("13:38", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("14:38", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:28", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:18", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("21:49", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("22:17", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("22:59", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
]
private static let izuminoDescExpressWd: [ExactRun] = [
    ExactRun("06:26", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("06:44", continuesBeyond: true, trainType: .commuterLimitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("07:02", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:12", continuesBeyond: true, trainType: .commuterLimitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("07:17", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:32", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:47", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:03", continuesBeyond: true, trainType: .commuterLimitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("08:18", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:23", continuesBeyond: true, trainType: .commuterLimitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("08:41", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:51", continuesBeyond: true, trainType: .commuterLimitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("09:00", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:58", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:38", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("15:38", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("16:08", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:34", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:12", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("18:13", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:32", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("18:50", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("18:57", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:32", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("19:43", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:50", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("20:16", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("20:50", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("21:34", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [7, 4, 0]),
    ExactRun("23:00", continuesBeyond: true, trainType: .rapid, stopIndices: [7, 6, 5, 4, 3, 2, 1, 0]),
]

}
