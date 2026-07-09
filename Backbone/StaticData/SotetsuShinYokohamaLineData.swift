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
        colorHex: "#00205C",
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
                      holiday: pattern("05:32", "24:14", [("05:32", 7), ("06:00", 8), ("07:00", 6), ("10:00", 10), ("15:00", 9), ("16:00", 8), ("18:00", 6), ("19:00", 7), ("20:00", 6), ("21:00", 9), ("22:00", 8), ("23:00", 16)])
            ),
            direction("Sotetsu.SotetsuShinYokohama", "Nishiya", "西谷・海老名方面", "For Nishiya & Ebina",
                      ascending: false,
                      weekday: pattern("05:18", "24:23", [("05:18", 20), ("06:00", 15), ("07:00", 10), ("08:00", 11), ("09:00", 7), ("10:00", 9), ("11:00", 21), ("12:00", 15), ("16:00", 14), ("17:00", 8), ("19:00", 9), ("21:00", 10), ("23:00", 8), ("24:00", 20)]),
                      holiday: pattern("05:18", "24:19", [("05:18", 12), ("06:00", 16), ("07:00", 12), ("08:00", 9), ("09:00", 10), ("10:00", 11), ("11:00", 15), ("17:00", 8), ("18:00", 10), ("20:00", 14), ("21:00", 19), ("22:00", 14), ("23:00", 17), ("24:00", 16)])
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
}
