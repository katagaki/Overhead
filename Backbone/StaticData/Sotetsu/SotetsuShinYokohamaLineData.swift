import Foundation

// MARK: - Sotetsu Shin-Yokohama Line Data

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

// Express through/当駅始発 origin with typed exact runs (ODPT), for skip-stop services.
private func originRuns(_ stationId: String, _ weekday: [ExactRun], _ holiday: [ExactRun]) -> IntermediateOrigin {
    IntermediateOrigin(stationId: stationId, weekdayRuns: weekday, saturdayHolidayRuns: holiday)
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

enum SotetsuShinYokohamaLineData {

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.sotetsu.co.jp/train/status/",
        statusPageURLEn: "https://www.sotetsu.co.jp/en/",
        xAccount: nil,
        checkMethodJa: "相模鉄道「運行状況」ページまたは相鉄線アプリで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Sotetsu train status page or the Sotetsu Line app. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        shinYokohama,
    ]

    static let shinYokohama = StaticTrainLine(
        id: "Railway:Sotetsu.SotetsuShinYokohama",
        nameJa: "相鉄新横浜線",
        nameEn: "Sotetsu Shin-Yokohama Line",
        operatorId: "Operator:Sotetsu",
        colorHex: "#35519D",
        stations: [
            st("Sotetsu.SotetsuShinYokohama", "Nishiya", "西谷", "Nishiya", "SO08", 35.47789, 139.56562),
            st("Sotetsu.SotetsuShinYokohama", "HazawaYokohamaKokudai", "羽沢横浜国大", "Hazawa-yokohama-kokudai", "SO51", 35.48102, 139.58614),
            st("Sotetsu.SotetsuShinYokohama", "ShinYokohama", "新横浜", "Shin-yokohama", "SO52", 35.50865, 139.61712),
        ],
        hopTimesMinutes: [
            3, 4,
        ],
        directions: [
            direction("Sotetsu.SotetsuShinYokohama", "ShinYokohama", "新横浜・東急線方面", "For Shin-Yokohama & Tokyu Line",
                      ascending: true,
                      weekday: pattern("05:23", "24:14", [("05:23", 6), ("07:00", 4), ("08:00", 5), ("09:00", 6), ("10:00", 10), ("16:00", 7), ("17:00", 6), ("19:00", 7), ("20:00", 5), ("21:00", 7), ("22:00", 8), ("23:00", 30)]),
                      holiday: pattern("05:32", "24:14", [("05:32", 7), ("06:00", 8), ("07:00", 6), ("10:00", 10), ("15:00", 9), ("16:00", 8), ("18:00", 6), ("19:00", 7), ("20:00", 6), ("21:00", 9), ("22:00", 8), ("23:00", 16)]),
                      expressWeekday: shinyokoAscExpressWd,
                      expressHoliday: shinyokoAscExpressHol
            ),
            direction("Sotetsu.SotetsuShinYokohama", "Nishiya", "西谷・海老名方面", "For Nishiya & Ebina",
                      ascending: false,
                      weekday: pattern("05:18", "24:23", [("05:18", 20), ("06:00", 15), ("07:00", 10), ("08:00", 11), ("09:00", 7), ("10:00", 9), ("11:00", 21), ("12:00", 15), ("16:00", 14), ("17:00", 8), ("19:00", 9), ("21:00", 10), ("23:00", 8), ("24:00", 20)]),
                      holiday: pattern("05:18", "24:19", [("05:18", 12), ("06:00", 16), ("07:00", 12), ("08:00", 9), ("09:00", 10), ("10:00", 11), ("11:00", 15), ("17:00", 8), ("18:00", 10), ("20:00", 14), ("21:00", 19), ("22:00", 14), ("23:00", 17), ("24:00", 16)]),
                      origins: [
                          originRuns("Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai",
                                     shinyokoDescExpressWd_org1, shinyokoDescExpressHol_org1)
                      ],
                      expressWeekday: shinyokoDescExpressWd,
                      expressHoliday: shinyokoDescExpressHol
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Sotetsu.SotetsuShinYokohama.Nishiya", .descending,
                    "相鉄本線", "Sotetsu Main Line",
                    "二俣川・海老名方面", "for Futamata-gawa & Ebina",
                    to: "Railway:Sotetsu.Main"),
            through("Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", .ascending,
                    "相鉄・ＪＲ直通線", "Sotetsu-JR Link Line",
                    "武蔵小杉・新宿方面", "for Musashi-Kosugi & Shinjuku"),
            through("Sotetsu.SotetsuShinYokohama.ShinYokohama", .ascending,
                    "東急新横浜線", "Tokyu Shin-Yokohama Line",
                    "日吉・渋谷・目黒方面", "for Hiyoshi, Shibuya & Meguro"),
        ]
    )

    // MARK: - Shin-Yokohama Express Runs (ODPT, July-2026)

private static let shinyokoAscExpressHol: [ExactRun] = [
    ExactRun("05:32", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("05:43", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("06:01", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("06:47", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("07:00", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("07:06", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("07:31", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("07:44", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("07:54", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("08:14", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("08:34", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("08:50", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("08:54", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("09:14", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("09:44", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("10:53", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("16:33", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("17:33", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("18:13", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("18:23", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("18:33", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("18:43", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("20:33", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("21:57", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("22:06", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("22:29", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("22:43", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
]
private static let shinyokoAscExpressWd: [ExactRun] = [
    ExactRun("05:32", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("05:43", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("06:01", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("06:13", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("06:31", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("06:50", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("06:58", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("07:04", startsHere: false, continuesBeyond: true, trainType: .commuterLimitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("07:08", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("07:29", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("07:33", startsHere: false, continuesBeyond: true, trainType: .commuterLimitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("07:45", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("07:59", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("08:14", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("08:22", startsHere: false, continuesBeyond: true, trainType: .commuterLimitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("08:27", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("08:40", startsHere: false, continuesBeyond: true, trainType: .commuterLimitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("08:50", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("09:08", startsHere: false, continuesBeyond: true, trainType: .commuterLimitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("10:33", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("16:03", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("16:41", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("16:57", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("17:27", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("17:43", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("18:10", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("18:32", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("18:39", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("18:49", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("19:04", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("19:07", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("19:14", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("19:22", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("19:48", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("20:03", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("20:07", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("20:21", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("20:34", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("20:44", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("21:06", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("21:15", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("21:50", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("22:01", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("22:17", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("22:29", terminusStationId: "Station:Sotetsu.SotetsuShinYokohama.HazawaYokohamaKokudai", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1]),
    ExactRun("22:42", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
    ExactRun("23:14", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [0, 1, 2]),
]
private static let shinyokoDescExpressHol: [ExactRun] = [
    ExactRun("05:38", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("06:01", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("06:53", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("07:46", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("17:17", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("17:47", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("18:27", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("18:47", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("19:07", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("19:27", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("19:47", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("20:27", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("20:57", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("21:57", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("22:46", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("22:59", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("23:45", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("24:03", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
]
private static let shinyokoDescExpressHol_org1: [ExactRun] = [
    ExactRun("07:41", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("08:09", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("08:22", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("08:48", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("10:50", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("12:02", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("17:32", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("17:59", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("18:21", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("21:41", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("22:16", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("22:38", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
]
private static let shinyokoDescExpressWd: [ExactRun] = [
    ExactRun("05:38", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("05:50", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("06:31", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("06:52", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("07:31", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("07:55", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("08:21", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("08:24", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("10:28", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("10:57", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("17:54", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("18:02", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("18:19", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("18:35", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("18:57", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("19:03", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("19:27", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("19:57", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("20:22", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("21:05", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("21:45", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("22:20", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("22:50", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("23:17", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("23:35", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
    ExactRun("24:03", continuesBeyond: true, trainType: .limitedExpress, stopIndices: [2, 1, 0]),
]
private static let shinyokoDescExpressWd_org1: [ExactRun] = [
    ExactRun("08:22", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("10:21", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("10:53", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("18:18", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("18:35", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("18:58", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("19:18", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("19:39", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("19:58", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("20:38", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("20:59", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("21:38", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
    ExactRun("22:16", startsHere: false, continuesBeyond: true, trainType: .limitedExpress, stopIndices: [1, 0]),
]

}
