import Foundation

// MARK: - Tsukuba Express Line Data (MIR)

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

enum TsukubaExpressLineData {

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.mir.co.jp/",
        statusPageURLEn: "https://www.mir.co.jp/en/",
        xAccount: nil,
        checkMethodJa: "つくばエクスプレス（首都圏新都市鉄道）の運行情報ページで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Tsukuba Express (Metropolitan Intercity Railway) service information page. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        tsukubaExpress,
    ]

    static let tsukubaExpress = StaticTrainLine(
        id: "Railway:MIR.TsukubaExpress",
        nameJa: "つくばエクスプレス",
        nameEn: "Tsukuba Express",
        operatorId: "Operator:MIR",
        colorHex: "#000084",
        stations: [
            st("MIR.TsukubaExpress", "Akihabara", "秋葉原", "Akihabara", "TX01", 35.69894, 139.77428),
            st("MIR.TsukubaExpress", "ShinOkachimachi", "新御徒町", "Shin-okachimachi", "TX02", 35.70711, 139.78194),
            st("MIR.TsukubaExpress", "Asakusa", "浅草", "Asakusa", "TX03", 35.714, 139.79239),
            st("MIR.TsukubaExpress", "MinamiSenju", "南千住", "Minami-senju", "TX04", 35.73344, 139.79911),
            st("MIR.TsukubaExpress", "KitaSenju", "北千住", "Kita-senju", "TX05", 35.74975, 139.80533),
            st("MIR.TsukubaExpress", "Aoi", "青井", "Aoi", "TX06", 35.7725, 139.82033),
            st("MIR.TsukubaExpress", "Rokucho", "六町", "Rokucho", "TX07", 35.78492, 139.82181),
            st("MIR.TsukubaExpress", "Yashio", "八潮", "Yashio", "TX08", 35.80786, 139.84483),
            st("MIR.TsukubaExpress", "MisatoChuo", "三郷中央", "Misato-chuo", "TX09", 35.82417, 139.87806),
            st("MIR.TsukubaExpress", "MinamiNagareyama", "南流山", "Minami-nagareyama", "TX10", 35.83786, 139.90433),
            st("MIR.TsukubaExpress", "NagareyamaCentralPark", "流山セントラルパーク", "Nagareyama-centralpark", "TX11", 35.85447, 139.91522),
            st("MIR.TsukubaExpress", "NagareyamaOtakanomori", "流山おおたかの森", "Nagareyama-otakanomori", "TX12", 35.87186, 139.92506),
            st("MIR.TsukubaExpress", "KashiwanohaCampus", "柏の葉キャンパス", "Kashiwanoha-campus", "TX13", 35.89336, 139.9525),
            st("MIR.TsukubaExpress", "KashiwaTanaka", "柏たなか", "Kashiwa-tanaka", "TX14", 35.911, 139.9575),
            st("MIR.TsukubaExpress", "Moriya", "守谷", "Moriya", "TX15", 35.95069, 139.99225),
            st("MIR.TsukubaExpress", "Miraidaira", "みらい平", "Miraidaira", "TX16", 35.99475, 140.03831),
            st("MIR.TsukubaExpress", "Midorino", "みどりの", "Midorino", "TX17", 36.02994, 140.05625),
            st("MIR.TsukubaExpress", "BampakuKinenKoen", "万博記念公園", "Bampaku-kinen-koen", "TX18", 36.05847, 140.05944),
            st("MIR.TsukubaExpress", "KenkyuGakuen", "研究学園", "Kenkyu-gakuen", "TX19", 36.08217, 140.08239),
            st("MIR.TsukubaExpress", "Tsukuba", "つくば", "Tsukuba", "TX20", 36.08256, 140.11169),
        ],
        hopTimesMinutes: [
            3, 3, 3, 3, 3, 2, 4, 4, 3, 2, 3, 3, 2, 4, 5, 3, 3, 4, 3,
        ],
        directions: [
            direction("MIR.TsukubaExpress", "Tsukuba", "つくば方面", "For Tsukuba",
                      ascending: true,
                      weekday: pattern("05:08", "24:07", [("05:08", 11), ("06:00", 4), ("07:00", 3), ("08:00", 2), ("09:00", 4), ("10:00", 5), ("11:00", 7), ("17:00", 4), ("18:00", 3), ("19:00", 4), ("20:00", 5), ("21:00", 6), ("23:00", 9)]),
                      holiday: pattern("05:08", "24:07", [("05:08", 11), ("06:00", 5), ("08:00", 4), ("09:00", 5), ("10:00", 7), ("22:00", 8), ("23:00", 10)]),
                      origins: [
                          origin("Station:MIR.TsukubaExpress.Moriya",
                                 ["05:20", "05:39", "06:00"],
                                 ["05:20", "05:39"]),
                      ]
            ),
            direction("MIR.TsukubaExpress", "Akihabara", "秋葉原方面", "For Akihabara",
                      ascending: false,
                      weekday: pattern("05:06", "24:00", [("05:06", 15), ("06:00", 8), ("08:00", 10), ("09:00", 8), ("16:00", 9), ("18:00", 8), ("20:00", 9), ("21:00", 12)]),
                      holiday: pattern("05:06", "24:00", [("05:06", 15), ("06:00", 9), ("08:00", 13), ("09:00", 8), ("21:00", 12), ("22:00", 15), ("23:00", 12)]),
                      origins: [
                          origin("Station:MIR.TsukubaExpress.Yashio",
                                 ["05:03", "05:17", "06:10", "06:25", "06:40", "07:20", "07:50", "08:02", "08:18", "08:35", "08:52"],
                                 ["05:03", "05:17", "08:08"]),
                          origin("Station:MIR.TsukubaExpress.Moriya",
                                 ["05:04", "05:09", "05:20", "05:31", "05:41", "05:52", "05:57", "06:06", "06:13", "06:22", "06:27", "06:34", "06:38", "06:44", "06:47", "06:55", "06:59", "07:04", "07:10", "07:15", "07:18", "07:23", "07:29", "07:34", "07:37", "07:43", "07:48", "07:51", "07:57", "07:59", "08:06", "08:14", "08:22", "08:30", "08:40", "08:49", "09:06", "09:21", "09:37", "09:47", "10:09", "10:17", "10:39", "10:47", "11:09", "11:17", "11:39", "11:47", "12:09", "12:17", "12:39", "12:47", "13:09", "13:17", "13:39", "13:47", "14:09", "14:17", "14:39", "14:47", "15:09", "15:17", "15:39", "15:47", "16:09", "16:17", "16:34", "16:42", "16:51", "17:01", "17:11", "17:19", "17:23", "17:34", "17:44", "17:52", "17:55", "18:03", "18:06", "18:13", "18:24", "18:31", "18:36", "18:54", "19:01", "19:06", "19:24", "19:35", "19:54", "20:16", "20:25", "20:47", "20:58", "21:10", "21:34", "21:48", "22:00", "22:12", "22:25", "22:48", "22:59"],
                                 ["05:04", "05:09", "05:20", "05:31", "05:41", "05:52", "06:01", "06:12", "06:16", "06:34", "06:49", "06:57", "07:04", "07:19", "07:27", "07:34", "07:49", "07:57", "08:04", "08:19", "08:27", "08:34", "08:49", "08:57", "09:09", "09:17", "09:39", "09:47", "10:09", "10:17", "10:39", "10:47", "11:09", "11:17", "11:39", "11:47", "12:09", "12:17", "12:39", "12:47", "13:09", "13:17", "13:39", "13:47", "14:09", "14:17", "14:39", "14:47", "15:09", "15:17", "15:39", "15:47", "16:09", "16:17", "16:39", "16:47", "17:09", "17:17", "17:39", "17:47", "18:09", "18:17", "18:39", "18:47", "19:09", "19:17", "19:39", "19:47", "20:09", "20:17", "20:39", "20:47", "21:17", "21:41", "22:08", "22:28", "23:08"]),
                      ]
            ),
        ],
        delayInfo: delayInfo
    )
}
