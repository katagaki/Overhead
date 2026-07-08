import Foundation

// MARK: - Sotetsu Line Data

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

enum SotetsuLineData {

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.sotetsu.co.jp/train/status/",
        statusPageURLEn: "https://www.sotetsu.co.jp/en/",
        xAccount: nil,
        checkMethodJa: "相模鉄道「運行状況」ページまたは相鉄線アプリで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Sotetsu train status page or the Sotetsu Line app. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        main,
    ]

    // MARK: - Sotetsu Main Line (SO)

    static let main = StaticTrainLine(
        id: "Railway:Sotetsu.Main",
        nameJa: "相鉄本線",
        nameEn: "Sotetsu Main Line",
        operatorId: "Operator:Sotetsu",
        colorHex: "#00205C",
        stations: [
            st("Sotetsu.Main", "Yokohama", "横浜", "Yokohama", "SO01", 35.4657, 139.6224),
            st("Sotetsu.Main", "Hiranumabashi", "平沼橋", "Hiranumabashi", "SO02", 35.4597, 139.6157),
            st("Sotetsu.Main", "NishiYokohama", "西横浜", "Nishi-yokohama", "SO03", 35.4557, 139.6067),
            st("Sotetsu.Main", "Tennocho", "天王町", "Tennocho", "SO04", 35.4527, 139.5987),
            st("Sotetsu.Main", "Hoshikawa", "星川", "Hoshikawa", "SO05", 35.4527, 139.5897),
            st("Sotetsu.Main", "Wadamachi", "和田町", "Wadamachi", "SO06", 35.4547, 139.5797),
            st("Sotetsu.Main", "Kamihoshikawa", "上星川", "Kami-hoshikawa", "SO07", 35.4587, 139.5697),
            st("Sotetsu.Main", "Nishiya", "西谷", "Nishiya", "SO08", 35.4637, 139.5567),
            st("Sotetsu.Main", "Tsurugamine", "鶴ヶ峰", "Tsurugamine", "SO09", 35.4677, 139.5457),
            st("Sotetsu.Main", "Futamatagawa", "二俣川", "Futamata-gawa", "SO10", 35.4617, 139.5307),
            st("Sotetsu.Main", "Kibogaoka", "希望ヶ丘", "Kibogaoka", "SO11", 35.4587, 139.5177),
            st("Sotetsu.Main", "Mitsukyo", "三ツ境", "Mitsukyo", "SO12", 35.4617, 139.5027),
            st("Sotetsu.Main", "Seya", "瀬谷", "Seya", "SO13", 35.4667, 139.4877),
            st("Sotetsu.Main", "Yamato", "大和", "Yamato", "SO14", 35.4697, 139.4617),
            st("Sotetsu.Main", "SagamiOtsuka", "相模大塚", "Sagami-otsuka", "SO15", 35.4707, 139.4447),
            st("Sotetsu.Main", "Sagamino", "さがみ野", "Sagamino", "SO16", 35.4717, 139.4317),
            st("Sotetsu.Main", "Kashiwadai", "かしわ台", "Kashiwadai", "SO17", 35.4737, 139.4177),
            st("Sotetsu.Main", "Ebina", "海老名", "Ebina", "SO18", 35.4527, 139.3907),
        ],
        hopTimesMinutes: [
            2, 2, 2, 1, 2, 2, 2, 2, 3, 2, 2, 2, 3, 2, 2, 2, 3,
        ],
        directions: [
            direction("Sotetsu.Main", "Ebina", "二俣川・海老名方面", "For Futamata-gawa & Ebina",
                      ascending: true,
                      weekday: pattern("05:21", "24:15", [
                          ("05:21", 8), ("06:30", 4), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:21", "24:15", [
                          ("05:21", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ]),
                      origins: [
                          origin("Station:Sotetsu.Main.Nishiya",
                                 ["05:25", "05:45", "05:56", "06:27", "06:39", "06:51", "07:01", "07:16", "07:22", "07:34", "07:38", "07:44", "07:52", "07:56", "08:02", "08:10", "08:16", "08:25", "08:28", "08:32", "08:37", "08:42", "08:55", "08:58", "09:07", "09:20", "09:22", "09:32", "09:38", "09:42", "09:54", "09:59", "10:03", "10:25", "10:29", "10:35", "10:46", "10:55", "11:05", "11:12", "11:16", "11:32", "11:46", "11:54", "12:02", "12:08", "12:22", "12:24", "12:32", "12:46", "12:54", "13:02", "13:16", "13:24", "13:32", "13:46", "13:54", "14:02", "14:16", "14:24", "14:32", "14:46", "14:54", "15:02", "15:16", "15:24", "15:32", "15:46", "15:54", "16:02", "16:16", "16:24", "16:36", "16:44", "16:55", "17:01", "17:15", "17:23", "17:31", "17:36", "17:40", "17:56", "17:58", "18:01", "18:09", "18:17", "18:22", "18:28", "18:35", "18:38", "18:43", "18:58", "19:01", "19:05", "19:10", "19:18", "19:22", "19:29", "19:35", "19:43", "19:47", "19:56", "20:02", "20:06", "20:19", "20:23", "20:32", "20:39", "20:42", "20:49", "20:55", "21:02", "21:06", "21:12", "21:23", "21:29", "21:35", "21:42", "21:53", "22:01", "22:05", "22:19", "22:30", "22:34", "22:41", "22:45", "23:00", "23:09", "23:12", "23:17", "23:25", "23:31", "23:36", "23:42", "23:53", "23:58", "24:00", "24:10", "24:31"],
                                 ["05:26", "05:45", "05:57", "06:08", "06:29", "06:45", "06:57", "07:00", "07:16", "07:21", "07:41", "07:45", "07:55", "08:06", "08:15", "08:25", "08:29", "08:36", "08:39", "08:46", "08:51", "08:54", "09:06", "09:18", "09:26", "09:33", "09:46", "09:54", "10:03", "10:16", "10:24", "10:35", "10:46", "10:55", "10:59", "11:03", "11:07", "11:22", "11:24", "11:32", "11:46", "11:54", "12:01", "12:05", "12:22", "12:24", "12:32", "12:46", "12:54", "13:02", "13:16", "13:24", "13:32", "13:46", "13:54", "14:02", "14:16", "14:24", "14:32", "14:46", "14:54", "15:02", "15:16", "15:24", "15:32", "15:46", "15:54", "16:02", "16:16", "16:24", "16:32", "16:46", "16:54", "17:03", "17:16", "17:25", "17:31", "17:35", "17:41", "17:46", "17:55", "18:05", "18:09", "18:11", "18:16", "18:25", "18:35", "18:41", "18:46", "18:55", "19:01", "19:06", "19:15", "19:21", "19:26", "19:31", "19:35", "19:41", "19:46", "19:55", "20:01", "20:06", "20:21", "20:26", "20:35", "20:46", "20:51", "21:01", "21:05", "21:18", "21:26", "21:38", "21:45", "21:56", "22:02", "22:05", "22:20", "22:26", "22:31", "22:43", "22:55", "23:07", "23:10", "23:36", "23:41", "23:55", "23:59", "24:10", "24:31"]),
                          origin("Station:Sotetsu.Main.Futamatagawa",
                                 ["05:20", "05:31"],
                                 ["05:20"]),
                          origin("Station:Sotetsu.Main.Seya",
                                 ["07:00"],
                                 [])
                      ]
            ),
            direction("Sotetsu.Main", "Yokohama", "横浜方面", "For Yokohama",
                      ascending: false,
                      weekday: pattern("05:01", "23:58", [
                          ("05:01", 8), ("06:30", 4), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:01", "23:58", [
                          ("05:01", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ]),
                      origins: [
                          origin("Station:Sotetsu.Main.Hoshikawa",
                                 ["17:35"],
                                 []),
                          origin("Station:Sotetsu.Main.Nishiya",
                                 ["06:45", "06:54", "07:02", "07:17", "07:25", "07:32", "07:40", "07:55", "08:02", "08:10", "08:17", "08:24", "08:52", "09:02", "09:13", "09:32", "09:53", "10:27", "10:58", "12:07", "12:37", "13:07", "13:37", "14:07", "14:37", "15:07", "15:37", "15:58", "16:08", "16:27", "17:00", "17:53", "18:04", "18:19", "18:33", "19:03", "19:30", "19:52", "20:15", "20:25", "20:53", "21:10", "21:42", "22:35", "23:26"],
                                 ["06:10", "06:50", "07:00", "07:10", "07:18", "07:47", "07:57", "08:17", "08:27", "09:07", "09:27", "09:37", "09:57", "10:07", "10:17", "10:27", "10:37", "10:59", "11:07", "11:37", "12:07", "12:37", "13:07", "13:37", "13:59", "14:07", "14:37", "14:59", "15:07", "15:37", "15:57", "16:27", "16:57", "17:27", "17:47", "17:57", "18:07", "18:37", "19:07", "19:17", "19:47", "20:37", "20:47", "21:17", "21:25", "21:47", "23:19", "23:29"]),
                          origin("Station:Sotetsu.Main.Futamatagawa",
                                 ["05:08", "05:24", "05:40", "06:13", "06:27", "06:35", "06:43", "06:54", "06:57", "07:03", "07:10", "07:14", "07:22", "07:26", "07:32", "07:37", "07:41", "07:47", "07:52", "07:56", "08:02", "08:07", "08:11", "08:17", "08:25", "08:32", "08:35", "08:42", "08:56", "08:59", "09:03", "09:14", "09:19", "09:26", "09:38", "09:48", "09:58", "10:10", "10:19", "10:30", "10:42", "10:46", "10:59", "11:11", "11:19", "11:32", "11:41", "11:46", "11:53", "12:11", "12:16", "12:23", "12:41", "12:46", "12:53", "13:11", "13:16", "13:23", "13:41", "13:46", "13:53", "14:11", "14:16", "14:23", "14:41", "14:46", "14:53", "15:11", "15:16", "15:23", "15:40", "15:46", "15:59", "16:11", "16:19", "16:27", "16:39", "16:43", "17:03", "17:11", "17:25", "17:33", "17:39", "17:55", "18:05", "18:16", "18:20", "18:25", "18:34", "18:40", "18:44", "18:52", "19:00", "19:03", "19:15", "19:24", "19:40", "19:44", "19:52", "20:00", "20:03", "20:12", "20:28", "20:30", "20:37", "20:46", "20:57", "21:02", "21:13", "21:26", "21:29", "21:43", "21:46", "22:01", "22:14", "22:27", "22:40", "22:49", "23:12", "23:17", "23:34", "23:39"],
                                 ["05:08", "05:24", "05:40", "06:15", "06:28", "06:44", "07:03", "07:10", "07:21", "07:31", "07:36", "07:51", "08:01", "08:06", "08:21", "08:31", "08:41", "08:45", "08:51", "09:01", "09:11", "09:16", "09:31", "09:41", "09:46", "09:59", "10:09", "10:14", "10:29", "10:41", "10:44", "10:59", "11:11", "11:16", "11:23", "11:41", "11:46", "11:53", "12:11", "12:16", "12:23", "12:41", "12:46", "12:53", "13:11", "13:16", "13:23", "13:41", "13:46", "13:59", "14:11", "14:16", "14:23", "14:41", "14:46", "14:59", "15:11", "15:16", "15:23", "15:41", "15:46", "16:01", "16:11", "16:20", "16:31", "16:41", "16:46", "17:01", "17:11", "17:16", "17:31", "17:41", "17:49", "17:56", "18:11", "18:21", "18:30", "18:36", "18:51", "19:01", "19:11", "19:21", "19:31", "19:36", "19:51", "20:01", "20:11", "20:21", "20:31", "20:41", "20:52", "21:01", "21:10", "21:30", "21:41", "21:54", "22:01", "22:08", "22:27", "22:35", "22:51", "23:02", "23:17", "23:45"]),
                          origin("Station:Sotetsu.Main.Yamato",
                                 ["05:34", "15:29", "17:50", "19:02"],
                                 ["05:36"]),
                          origin("Station:Sotetsu.Main.Kashiwadai",
                                 ["04:39", "05:00", "05:29", "05:40", "05:52", "06:05", "06:14", "06:29"],
                                 ["04:39", "05:32", "05:47"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Sotetsu.Main.Nishiya", .ascending,
                    "相鉄新横浜線", "Sotetsu Shin-Yokohama Line",
                    "新横浜・東急線・ＪＲ線方面", "for Shin-Yokohama and the Tokyu & JR Lines"),
            through("Sotetsu.Main.Futamatagawa", .ascending,
                    "相鉄いずみ野線", "Sotetsu Izumino Line",
                    "湘南台方面", "for Shonandai"),
        ]
    )
}
