import Foundation

// MARK: - Sotetsu Line Data

private func st(_ path: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "odpt.Station:\(path).\(suffix)",
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
                       weekday: ServicePattern, holiday: ServicePattern) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:\(path).\(suffix)",
        nameJa: ja, nameEn: en,
        isAscending: ascending,
        weekday: weekday, saturdayHoliday: holiday
    )
}

private func through(_ junction: String, _ end: ThroughService.LineEnd,
                     _ lineJa: String, _ lineEn: String,
                     _ towardJa: String, _ towardEn: String,
                     to connectingLineId: String? = nil) -> ThroughService {
    ThroughService(
        junctionStationId: "odpt.Station:\(junction)",
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
        id: "odpt.Railway:Sotetsu.Main",
        nameJa: "相鉄本線",
        nameEn: "Sotetsu Main Line",
        operatorId: "odpt.Operator:Sotetsu",
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
                      ])),
            direction("Sotetsu.Main", "Yokohama", "横浜方面", "For Yokohama",
                      ascending: false,
                      weekday: pattern("05:01", "23:58", [
                          ("05:01", 8), ("06:30", 4), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:01", "23:58", [
                          ("05:01", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ])),
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
