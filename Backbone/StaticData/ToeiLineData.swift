import Foundation

// MARK: - Toei Line Data

private func st(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "Station:Toei.\(line).\(suffix)",
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

private func direction(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                       ascending: Bool,
                       weekday: ServicePattern, holiday: ServicePattern,
                       origins: [IntermediateOrigin] = []) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:Toei.\(line).\(suffix)",
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
        junctionStationId: "Station:Toei.\(junction)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

enum ToeiLineData {

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.kotsu.metro.tokyo.jp/subway/unkou/unkou_all.html",
        statusPageURLEn: "https://www.kotsu.metro.tokyo.jp/eng/",
        xAccount: "@toeikotsu",
        checkMethodJa: "都営交通「運行情報」ページ、都営交通アプリ、またはX（@toeikotsu）で確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Toei Transportation service information page, the Toei app, or X (@toeikotsu). Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        asakusa, mita, shinjuku, oedo, nipporiToneri, arakawa,
    ]

    private static func toeiWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 7), ("07:00", 4), ("09:30", 6), ("17:00", 4.5), ("20:00", 6), ("22:00", 8),
        ])
    }
    private static func toeiHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 7), ("07:00", 6), ("10:00", 6), ("20:00", 6.5), ("22:00", 8),
        ])
    }

    // MARK: - Asakusa Line (A)

    static let asakusa = StaticTrainLine(
        id: "Railway:Toei.Asakusa",
        nameJa: "都営浅草線",
        nameEn: "Toei Asakusa Line",
        operatorId: "Operator:Toei",
        colorHex: "#E85298",
        stations: [
            st("Asakusa", "NishiMagome", "西馬込", "Nishi-magome", "A01", 35.5866, 139.7053),
            st("Asakusa", "Magome", "馬込", "Magome", "A02", 35.5910, 139.7118),
            st("Asakusa", "Nakanobu", "中延", "Nakanobu", "A03", 35.6057, 139.7130),
            st("Asakusa", "Togoshi", "戸越", "Togoshi", "A04", 35.6160, 139.7150),
            st("Asakusa", "Gotanda", "五反田", "Gotanda", "A05", 35.6262, 139.7233),
            st("Asakusa", "Takanawadai", "高輪台", "Takanawadai", "A06", 35.6325, 139.7330),
            st("Asakusa", "Sengakuji", "泉岳寺", "Sengakuji", "A07", 35.6387, 139.7402),
            st("Asakusa", "Mita", "三田", "Mita", "A08", 35.6484, 139.7476),
            st("Asakusa", "Daimon", "大門", "Daimon", "A09", 35.6567, 139.7546),
            st("Asakusa", "Shimbashi", "新橋", "Shimbashi", "A10", 35.6663, 139.7583),
            st("Asakusa", "HigashiGinza", "東銀座", "Higashi-ginza", "A11", 35.6698, 139.7674),
            st("Asakusa", "Takaracho", "宝町", "Takaracho", "A12", 35.6754, 139.7710),
            st("Asakusa", "Nihombashi", "日本橋", "Nihombashi", "A13", 35.6824, 139.7742),
            st("Asakusa", "Ningyocho", "人形町", "Ningyocho", "A14", 35.6864, 139.7825),
            st("Asakusa", "HigashiNihombashi", "東日本橋", "Higashi-nihombashi", "A15", 35.6922, 139.7851),
            st("Asakusa", "Asakusabashi", "浅草橋", "Asakusabashi", "A16", 35.6986, 139.7862),
            st("Asakusa", "Kuramae", "蔵前", "Kuramae", "A17", 35.7035, 139.7905),
            st("Asakusa", "Asakusa", "浅草", "Asakusa", "A18", 35.7107, 139.7970),
            st("Asakusa", "HonjoAzumabashi", "本所吾妻橋", "Honjo-azumabashi", "A19", 35.7098, 139.8049),
            st("Asakusa", "Oshiage", "押上", "Oshiage 'SKYTREE'", "A20", 35.7103, 139.8129),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2,
        ],
        directions: [
            direction("Asakusa", "Oshiage", "押上方面", "For Oshiage", ascending: true,
                      weekday: toeiWeekday("05:00", "23:49"), holiday: toeiHoliday("05:00", "23:49"),
                      origins: [
                          origin("Station:Toei.Asakusa.Sengakuji",
                                 ["05:00", "05:31", "05:41", "05:49", "05:55", "06:14", "06:21", "06:35", "06:45", "06:57", "07:03", "07:11", "07:14", "07:20", "07:23", "07:27", "07:33", "07:39", "07:42", "07:49", "07:55", "08:00", "08:06", "08:11", "08:17", "08:22", "08:28", "08:33", "08:38", "08:43", "08:49", "08:53", "09:02", "09:07", "09:13", "09:16", "09:20", "09:27", "09:30", "09:32", "09:37", "09:41", "09:45", "09:51", "09:55", "10:00", "10:06", "10:12", "10:23", "10:31", "10:37", "10:43", "10:51", "10:57", "11:03", "11:13", "11:17", "11:22", "11:34", "11:38", "11:43", "11:53", "11:58", "12:03", "12:13", "12:18", "12:23", "12:32", "12:37", "12:42", "12:53", "12:58", "13:03", "13:13", "13:18", "13:23", "13:33", "13:38", "13:43", "13:52", "13:57", "14:02", "14:13", "14:18", "14:23", "14:33", "14:38", "14:43", "14:53", "14:58", "15:03", "15:12", "15:17", "15:22", "15:32", "15:37", "15:42", "15:52", "15:56", "16:04", "16:10", "16:15", "16:21", "16:36", "16:41", "16:49", "16:53", "16:59", "17:05", "17:09", "17:17", "17:22", "17:26", "17:34", "17:37", "17:42", "17:49", "17:54", "18:00", "18:04", "18:08", "18:14", "18:20", "18:23", "18:30", "18:34", "18:43", "18:51", "18:58", "19:10", "19:14", "19:18", "19:27", "19:32", "19:38", "19:48", "19:52", "20:01", "20:06", "20:10", "20:18", "20:23", "20:28", "20:32", "20:43", "21:05", "21:11", "21:17", "21:24", "21:31", "21:44", "21:51", "21:58", "22:05", "22:15", "22:25", "22:34", "22:40", "23:03", "23:17", "23:34", "24:02"],
                                 ["05:00", "05:31", "05:42", "05:50", "05:59", "06:19", "06:39", "06:49", "06:55", "07:00", "07:06", "07:11", "07:21", "07:26", "07:40", "07:45", "07:50", "08:00", "08:05", "08:10", "08:20", "08:25", "08:30", "08:40", "08:45", "08:50", "09:02", "09:07", "09:11", "09:20", "09:25", "09:30", "09:35", "09:39", "09:47", "09:52", "09:57", "10:03", "10:12", "10:18", "10:23", "10:32", "10:38", "10:43", "10:52", "10:57", "11:02", "11:13", "11:18", "11:23", "11:34", "11:38", "11:43", "11:53", "11:58", "12:03", "12:13", "12:18", "12:23", "12:32", "12:37", "12:42", "12:53", "12:58", "13:03", "13:13", "13:18", "13:23", "13:33", "13:38", "13:43", "13:52", "13:57", "14:02", "14:13", "14:18", "14:23", "14:33", "14:38", "14:43", "14:53", "14:58", "15:03", "15:12", "15:17", "15:22", "15:33", "15:38", "15:43", "15:53", "15:58", "16:03", "16:13", "16:18", "16:23", "16:32", "16:37", "16:42", "16:53", "16:58", "17:03", "17:13", "17:18", "17:24", "17:33", "17:38", "17:43", "17:53", "17:58", "18:03", "18:14", "18:18", "18:23", "18:33", "18:38", "18:44", "18:52", "18:57", "19:02", "19:12", "19:17", "19:22", "19:32", "19:35", "19:40", "19:50", "19:55", "20:00", "20:10", "20:15", "20:20", "20:30", "20:35", "20:40", "20:50", "20:55", "21:00", "21:11", "21:20", "21:30", "21:40", "21:45", "21:51", "22:02", "22:21", "22:33", "22:53", "23:04", "23:13", "23:34", "23:47"]),
                          origin("Station:Toei.Asakusa.Asakusabashi",
                                 ["05:00"],
                                 ["05:00"])
                      ]
            ),
            direction("Asakusa", "NishiMagome", "西馬込方面", "For Nishi-magome", ascending: false,
                      weekday: toeiWeekday("05:00", "24:22"), holiday: toeiHoliday("05:00", "24:22"),
                      origins: [
                          origin("Station:Toei.Asakusa.Sengakuji",
                                 ["05:25", "05:38", "06:08", "06:26", "06:53", "07:18", "07:28", "07:34", "07:41", "07:50", "09:00", "09:28", "09:42", "09:53", "10:03", "10:24", "10:46", "11:07", "11:27", "11:47", "12:07", "12:26", "12:47", "13:07", "13:27", "13:46", "14:07", "14:27", "14:47", "15:06", "15:27", "15:46", "16:22", "16:32", "16:38", "17:06", "17:15", "17:40", "17:52", "18:03", "18:08", "18:14", "18:30", "18:36", "18:45", "18:57", "19:16", "19:20", "19:25", "19:50", "20:00", "20:14", "20:31", "20:37", "20:46", "21:05", "21:13", "21:18", "21:33", "21:47", "21:56", "22:06", "22:29", "22:39", "22:48", "23:03", "23:12", "23:31", "23:49", "24:19"],
                                 ["05:25", "05:38", "05:49", "06:08", "06:28", "06:49", "07:00", "07:12", "07:18", "07:29", "07:34", "07:39", "07:49", "07:54", "07:59", "08:09", "08:14", "08:31", "08:35", "08:40", "08:51", "08:55", "09:02", "09:15", "09:21", "09:31", "09:37", "09:46", "10:04", "10:11", "10:22", "10:27", "10:48", "11:06", "11:24", "11:32", "11:47", "12:07", "12:26", "12:47", "13:07", "13:27", "13:46", "14:07", "14:27", "14:47", "15:06", "15:27", "15:47", "16:07", "16:26", "16:47", "17:07", "17:12", "17:27", "17:32", "17:43", "17:48", "18:06", "18:12", "18:26", "18:32", "18:46", "18:52", "19:03", "19:10", "19:26", "19:32", "19:43", "19:49", "20:03", "20:11", "20:23", "20:31", "20:43", "20:52", "21:00", "21:07", "21:24", "21:31", "21:56", "22:11", "22:20", "22:30", "22:50", "23:02", "23:11", "23:21", "23:40", "23:49", "23:59"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Asakusa.Oshiage", .ascending,
                    "京成押上線・京成本線", "Keisei Oshiage & Main Lines",
                    "青砥・成田空港方面", "for Aoto & Narita Airport",
                    to: "Railway:Keisei.Oshiage"),
            through("Asakusa.Sengakuji", .descending,
                    "京急線", "Keikyu Line",
                    "羽田空港・横浜方面", "for Haneda Airport & Yokohama",
                    to: "Railway:Keikyu.Main"),
        ]
    )

    // MARK: - Mita Line (I)

    static let mita = StaticTrainLine(
        id: "Railway:Toei.Mita",
        nameJa: "都営三田線",
        nameEn: "Toei Mita Line",
        operatorId: "Operator:Toei",
        colorHex: "#0079C2",
        stations: [
            st("Mita", "Meguro", "目黒", "Meguro", "I01", 35.6340, 139.7157),
            st("Mita", "Shirokanedai", "白金台", "Shirokanedai", "I02", 35.6376, 139.7263),
            st("Mita", "ShirokaneTakanawa", "白金高輪", "Shirokane-takanawa", "I03", 35.6431, 139.7343),
            st("Mita", "Mita", "三田", "Mita", "I04", 35.6484, 139.7476),
            st("Mita", "Shibakoen", "芝公園", "Shibakoen", "I05", 35.6544, 139.7497),
            st("Mita", "Onarimon", "御成門", "Onarimon", "I06", 35.6618, 139.7506),
            st("Mita", "Uchisaiwaicho", "内幸町", "Uchisaiwaicho", "I07", 35.6698, 139.7548),
            st("Mita", "Hibiya", "日比谷", "Hibiya", "I08", 35.6748, 139.7595),
            st("Mita", "Otemachi", "大手町", "Otemachi", "I09", 35.6875, 139.7625),
            st("Mita", "Jimbocho", "神保町", "Jimbocho", "I10", 35.6958, 139.7578),
            st("Mita", "Suidobashi", "水道橋", "Suidobashi", "I11", 35.7020, 139.7530),
            st("Mita", "Kasuga", "春日", "Kasuga", "I12", 35.7125, 139.7525),
            st("Mita", "Hakusan", "白山", "Hakusan", "I13", 35.7222, 139.7518),
            st("Mita", "Sengoku", "千石", "Sengoku", "I14", 35.7282, 139.7448),
            st("Mita", "Sugamo", "巣鴨", "Sugamo", "I15", 35.7335, 139.7394),
            st("Mita", "NishiSugamo", "西巣鴨", "Nishi-sugamo", "I16", 35.7422, 139.7298),
            st("Mita", "ShinItabashi", "新板橋", "Shin-itabashi", "I17", 35.7478, 139.7192),
            st("Mita", "Itabashikuyakushomae", "板橋区役所前", "Itabashikuyakushomae", "I18", 35.7512, 139.7092),
            st("Mita", "Itabashihoncho", "板橋本町", "Itabashihoncho", "I19", 35.7578, 139.7002),
            st("Mita", "Motohasunuma", "本蓮沼", "Motohasunuma", "I20", 35.7652, 139.6942),
            st("Mita", "ShimuraSakaue", "志村坂上", "Shimura-sakaue", "I21", 35.7722, 139.6872),
            st("Mita", "ShimuraSanchome", "志村三丁目", "Shimura-sanchome", "I22", 35.7788, 139.6792),
            st("Mita", "Hasune", "蓮根", "Hasune", "I23", 35.7878, 139.6722),
            st("Mita", "Nishidai", "西台", "Nishidai", "I24", 35.7922, 139.6652),
            st("Mita", "Takashimadaira", "高島平", "Takashimadaira", "I25", 35.7948, 139.6562),
            st("Mita", "ShinTakashimadaira", "新高島平", "Shin-takashimadaira", "I26", 35.7962, 139.6472),
            st("Mita", "NishiTakashimadaira", "西高島平", "Nishi-takashimadaira", "I27", 35.7982, 139.6378),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 1, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2,
        ],
        directions: [
            direction("Mita", "NishiTakashimadaira", "西高島平方面", "For Nishi-takashimadaira", ascending: true,
                      weekday: toeiWeekday("05:12", "23:55"), holiday: toeiHoliday("05:12", "23:54"),
                      origins: [
                          origin("Station:Toei.Mita.ShirokaneTakanawa",
                                 ["05:00", "05:44", "06:18", "06:46", "07:59", "08:06", "08:22", "08:29", "08:34", "08:41", "08:46", "08:56", "09:03", "09:10", "09:19", "09:33", "09:47", "09:59", "10:07", "10:19", "10:47", "11:17", "11:23", "11:47", "11:53", "12:18", "12:23", "12:48", "12:54", "13:18", "13:24", "13:48", "13:54", "14:18", "14:24", "14:48", "14:54", "15:18", "15:24", "15:48", "15:54", "16:18", "16:25", "16:49", "16:55", "17:16", "17:21", "17:26", "17:41", "17:45", "17:59", "18:04", "18:09", "18:22", "18:26", "18:41", "18:51", "19:06", "19:17", "19:31", "19:45", "19:55", "20:04", "20:41", "21:07", "21:14", "21:34", "21:54", "22:08", "22:59", "23:22", "23:52"],
                                 ["05:00", "05:44", "06:16", "06:53", "07:07", "07:14", "07:42", "07:56", "08:15", "08:20", "08:25", "08:34", "08:50", "09:08", "09:19", "09:24", "09:47", "09:53", "10:17", "10:23", "10:48", "10:54", "11:18", "11:24", "11:48", "11:54", "12:18", "12:23", "12:48", "12:54", "13:18", "13:24", "13:48", "13:54", "14:18", "14:24", "14:48", "14:54", "15:18", "15:24", "15:48", "15:54", "16:18", "16:24", "16:48", "16:54", "17:18", "17:24", "17:48", "17:54", "18:18", "18:24", "18:48", "18:54", "19:19", "19:32", "20:00", "20:13", "20:21", "20:42", "21:21", "21:49", "21:55", "22:28", "22:59", "23:06", "23:31", "23:38", "23:45"]),
                          origin("Station:Toei.Mita.Takashimadaira",
                                 ["16:27", "20:50"],
                                 ["09:41", "18:57"])
                      ]
            ),
            direction("Mita", "Meguro", "目黒方面", "For Meguro", ascending: false,
                      weekday: toeiWeekday("05:10", "23:45"), holiday: toeiHoliday("05:10", "23:45"),
                      origins: [
                          origin("Station:Toei.Mita.Onarimon",
                                 ["05:13"],
                                 ["05:13"]),
                          origin("Station:Toei.Mita.ShinItabashi",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:Toei.Mita.Takashimadaira",
                                 ["05:00", "05:50", "06:13", "07:12", "07:28", "07:37", "07:47", "07:59", "08:06", "16:19", "16:43", "16:57", "17:10", "17:29"],
                                 ["05:00", "06:52", "07:31", "07:52", "08:19", "21:26"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Mita.Meguro", .descending,
                    "東急目黒線・新横浜線", "Tokyu Meguro & Shin-Yokohama Lines",
                    "日吉・新横浜方面", "for Hiyoshi & Shin-Yokohama",
                    to: "Railway:Tokyu.Meguro"),
        ]
    )

    // MARK: - Shinjuku Line (S)

    static let shinjuku = StaticTrainLine(
        id: "Railway:Toei.Shinjuku",
        nameJa: "都営新宿線",
        nameEn: "Toei Shinjuku Line",
        operatorId: "Operator:Toei",
        colorHex: "#6CBB5A",
        stations: [
            st("Shinjuku", "Shinjuku", "新宿", "Shinjuku", "S01", 35.6895, 139.6988),
            st("Shinjuku", "ShinjukuSanchome", "新宿三丁目", "Shinjuku-sanchome", "S02", 35.6909, 139.7047),
            st("Shinjuku", "Akebonobashi", "曙橋", "Akebonobashi", "S03", 35.6922, 139.7232),
            st("Shinjuku", "Ichigaya", "市ケ谷", "Ichigaya", "S04", 35.6914, 139.7357),
            st("Shinjuku", "Kudanshita", "九段下", "Kudanshita", "S05", 35.6957, 139.7515),
            st("Shinjuku", "Jimbocho", "神保町", "Jimbocho", "S06", 35.6958, 139.7578),
            st("Shinjuku", "Ogawamachi", "小川町", "Ogawamachi", "S07", 35.6952, 139.7662),
            st("Shinjuku", "Iwamotocho", "岩本町", "Iwamotocho", "S08", 35.6942, 139.7752),
            st("Shinjuku", "BakuroYokoyama", "馬喰横山", "Bakuro-yokoyama", "S09", 35.6922, 139.7828),
            st("Shinjuku", "Hamacho", "浜町", "Hamacho", "S10", 35.6888, 139.7887),
            st("Shinjuku", "Morishita", "森下", "Morishita", "S11", 35.6877, 139.7970),
            st("Shinjuku", "Kikukawa", "菊川", "Kikukawa", "S12", 35.6868, 139.8072),
            st("Shinjuku", "Sumiyoshi", "住吉", "Sumiyoshi", "S13", 35.6890, 139.8143),
            st("Shinjuku", "NishiOjima", "西大島", "Nishi-ojima", "S14", 35.6902, 139.8330),
            st("Shinjuku", "Ojima", "大島", "Ojima", "S15", 35.6898, 139.8432),
            st("Shinjuku", "HigashiOjima", "東大島", "Higashi-ojima", "S16", 35.6902, 139.8528),
            st("Shinjuku", "Funabori", "船堀", "Funabori", "S17", 35.6842, 139.8642),
            st("Shinjuku", "Ichinoe", "一之江", "Ichinoe", "S18", 35.6788, 139.8762),
            st("Shinjuku", "Mizue", "瑞江", "Mizue", "S19", 35.6858, 139.8930),
            st("Shinjuku", "Shinozaki", "篠崎", "Shinozaki", "S20", 35.7042, 139.9012),
            st("Shinjuku", "Motoyawata", "本八幡", "Motoyawata", "S21", 35.7210, 139.9278),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3,
        ],
        directions: [
            direction("Shinjuku", "Motoyawata", "本八幡方面", "For Motoyawata", ascending: true,
                      weekday: toeiWeekday("05:00", "24:10"), holiday: toeiHoliday("05:00", "24:10"),
                      origins: [
                          origin("Station:Toei.Shinjuku.Ojima",
                                 ["05:01", "05:12", "07:09", "07:36", "08:03"],
                                 ["05:01", "05:12"])
                      ]
            ),
            direction("Shinjuku", "Shinjuku", "新宿方面", "For Shinjuku", ascending: false,
                      weekday: toeiWeekday("05:00", "24:09"), holiday: toeiHoliday("05:00", "24:09"),
                      origins: [
                          origin("Station:Toei.Shinjuku.Iwamotocho",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:Toei.Shinjuku.Ojima",
                                 ["05:00", "07:20", "07:28", "09:31", "16:23", "16:36", "17:05", "17:11", "17:18", "17:27"],
                                 ["05:00", "07:06", "07:25"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Shinjuku.Shinjuku", .descending,
                    "京王新線・京王線", "Keio New Line & Keio Line",
                    "笹塚・橋本方面", "for Sasazuka & Hashimoto",
                    to: "Railway:Keio.Keio"),
        ]
    )

    // MARK: - Oedo Line (E)
    // Route is shaped like a "6": modelled as a single linear line in the
    // actual running order (Hikarigaoka -> loop via Roppongi/Daimon/Ryogoku -> Shinjuku-nishiguchi).

    static let oedo = StaticTrainLine(
        id: "Railway:Toei.Oedo",
        nameJa: "都営大江戸線",
        nameEn: "Toei Oedo Line",
        operatorId: "Operator:Toei",
        colorHex: "#B6007A",
        stations: [
            st("Oedo", "Hikarigaoka", "光が丘", "Hikarigaoka", "E38", 35.7583, 139.6289),
            st("Oedo", "NerimaKasugacho", "練馬春日町", "Nerima-kasugacho", "E37", 35.7498, 139.6392),
            st("Oedo", "Toshimaen", "豊島園", "Toshimaen", "E36", 35.7418, 139.6483),
            st("Oedo", "Nerima", "練馬", "Nerima", "E35", 35.7375, 139.6535),
            st("Oedo", "ShinEgota", "新江古田", "Shin-egota", "E34", 35.7282, 139.6662),
            st("Oedo", "OchiaiMinamiNagasaki", "落合南長崎", "Ochiai-minami-nagasaki", "E33", 35.7212, 139.6772),
            st("Oedo", "Nakai", "中井", "Nakai", "E32", 35.7138, 139.6870),
            st("Oedo", "HigashiNakano", "東中野", "Higashi-nakano", "E31", 35.7062, 139.6835),
            st("Oedo", "NakanoSakaue", "中野坂上", "Nakano-sakaue", "E30", 35.6975, 139.6827),
            st("Oedo", "NishiShinjukuGochome", "西新宿五丁目", "Nishi-shinjuku-gochome", "E29", 35.6900, 139.6868),
            st("Oedo", "Tochomae", "都庁前", "Tochomae", "E28", 35.6895, 139.6925),
            st("Oedo", "Shinjuku", "新宿", "Shinjuku", "E27", 35.6885, 139.6985),
            st("Oedo", "Yoyogi", "代々木", "Yoyogi", "E26", 35.6832, 139.7020),
            st("Oedo", "KokuritsuKyogijo", "国立競技場", "Kokuritsu-kyogijo", "E25", 35.6795, 139.7145),
            st("Oedo", "AoyamaItchome", "青山一丁目", "Aoyama-itchome", "E24", 35.6726, 139.7244),
            st("Oedo", "Roppongi", "六本木", "Roppongi", "E23", 35.6630, 139.7315),
            st("Oedo", "AzabuJuban", "麻布十番", "Azabu-juban", "E22", 35.6544, 139.7368),
            st("Oedo", "Akabanebashi", "赤羽橋", "Akabanebashi", "E21", 35.6545, 139.7438),
            st("Oedo", "Daimon", "大門", "Daimon", "E20", 35.6567, 139.7546),
            st("Oedo", "Shiodome", "汐留", "Shiodome", "E19", 35.6625, 139.7597),
            st("Oedo", "Tsukijishijo", "築地市場", "Tsukijishijo", "E18", 35.6650, 139.7668),
            st("Oedo", "Kachidoki", "勝どき", "Kachidoki", "E17", 35.6590, 139.7768),
            st("Oedo", "Tsukishima", "月島", "Tsukishima", "E16", 35.6640, 139.7838),
            st("Oedo", "MonzenNakacho", "門前仲町", "Monzen-nakacho", "E15", 35.6718, 139.7957),
            st("Oedo", "KiyosumiShirakawa", "清澄白河", "Kiyosumi-shirakawa", "E14", 35.6816, 139.7994),
            st("Oedo", "Morishita", "森下", "Morishita", "E13", 35.6877, 139.7970),
            st("Oedo", "Ryogoku", "両国", "Ryogoku", "E12", 35.6975, 139.7935),
            st("Oedo", "Kuramae", "蔵前", "Kuramae", "E11", 35.7040, 139.7895),
            st("Oedo", "ShinOkachimachi", "新御徒町", "Shin-okachimachi", "E10", 35.7074, 139.7828),
            st("Oedo", "UenoOkachimachi", "上野御徒町", "Ueno-okachimachi", "E09", 35.7077, 139.7745),
            st("Oedo", "HongoSanchome", "本郷三丁目", "Hongo-sanchome", "E08", 35.7070, 139.7600),
            st("Oedo", "Kasuga", "春日", "Kasuga", "E07", 35.7125, 139.7525),
            st("Oedo", "Iidabashi", "飯田橋", "Iidabashi", "E06", 35.7015, 139.7445),
            st("Oedo", "UshigomeKagurazaka", "牛込神楽坂", "Ushigome-kagurazaka", "E05", 35.7005, 139.7368),
            st("Oedo", "UshigomeYanagicho", "牛込柳町", "Ushigome-yanagicho", "E04", 35.6985, 139.7278),
            st("Oedo", "WakamatsuKawada", "若松河田", "Wakamatsu-kawada", "E03", 35.6975, 139.7188),
            st("Oedo", "HigashiShinjuku", "東新宿", "Higashi-shinjuku", "E02", 35.6983, 139.7073),
            st("Oedo", "ShinjukuNishiguchi", "新宿西口", "Shinjuku-nishiguchi", "E01", 35.6935, 139.6992),
        ],
        hopTimesMinutes: [
            2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25,
            2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25, 2.25,
        ],
        directions: [
            direction("Oedo", "Ryogoku", "六本木・両国方面", "For Roppongi & Ryogoku", ascending: true,
                      weekday: toeiWeekday("05:00", "24:17"), holiday: toeiHoliday("05:00", "24:17"),
                      origins: [
                          origin("Station:Toei.Oedo.Tochomae",
                                 ["09:01", "19:27", "20:03", "20:52", "23:09", "24:01", "24:13", "24:25"],
                                 ["08:30", "08:54", "19:10", "22:02", "22:22", "22:36", "24:00", "24:12", "24:25"])
                      ]
            ),
            direction("Oedo", "Hikarigaoka", "都庁前・光が丘方面", "For Tochomae & Hikarigaoka", ascending: false,
                      weekday: toeiWeekday("05:09", "24:27"), holiday: toeiHoliday("05:09", "24:27"),
                      origins: [
                          origin("Station:Toei.Oedo.Tochomae",
                                 ["05:00", "05:03", "05:08", "05:22", "05:36", "05:48", "06:02", "06:11", "06:18", "06:26", "06:34", "06:41", "06:47", "06:53", "06:59", "07:06", "07:13", "07:19", "07:25", "07:29", "07:33", "07:36", "07:40", "07:43", "07:47", "07:50", "07:54", "07:57", "08:01", "08:04", "08:08", "08:13", "08:18", "08:23", "08:28", "08:32", "08:38", "08:42", "08:48", "08:52", "08:57", "09:04", "09:09", "09:14", "09:19", "09:24", "09:29", "09:34", "09:39", "09:44", "09:49", "09:54", "10:00", "10:06", "10:12", "10:18", "10:24", "10:30", "10:36", "10:42", "10:48", "10:54", "11:00", "11:06", "11:12", "11:18", "11:24", "11:30", "11:36", "11:42", "11:48", "11:54", "12:00", "12:06", "12:12", "12:18", "12:24", "12:30", "12:36", "12:42", "12:48", "12:54", "13:00", "13:06", "13:12", "13:18", "13:24", "13:30", "13:36", "13:42", "13:48", "13:54", "14:00", "14:06", "14:12", "14:18", "14:24", "14:30", "14:36", "14:42", "14:48", "14:54", "15:00", "15:06", "15:12", "15:18", "15:24", "15:30", "15:36", "15:42", "15:48", "15:54", "16:00", "16:06", "16:12", "16:17", "16:23", "16:28", "16:32", "16:35", "16:41", "16:46", "16:51", "16:56", "17:01", "17:05", "17:10", "17:14", "17:19", "17:23", "17:27", "17:32", "17:36", "17:40", "17:45", "17:49", "17:54", "17:58", "18:03", "18:08", "18:13", "18:18", "18:23", "18:28", "18:32", "18:37", "18:43", "18:48", "18:53", "18:58", "19:03", "19:08", "19:13", "19:18", "19:24", "19:30", "19:36", "19:42", "19:48", "19:53", "19:59", "20:07", "20:13", "20:19", "20:25", "20:31", "20:37", "20:43", "20:48", "20:55", "21:01", "21:07", "21:13", "21:19", "21:25", "21:31", "21:38", "21:45", "21:53", "21:59", "22:06", "22:13", "22:20", "22:28", "22:34", "22:41", "22:48", "22:55", "22:59", "23:14", "23:23", "23:32", "23:47"],
                                 ["05:00", "05:03", "05:08", "05:22", "05:36", "05:48", "06:00", "06:09", "06:18", "06:27", "06:37", "06:44", "06:50", "06:55", "07:00", "07:06", "07:12", "07:18", "07:24", "07:30", "07:35", "07:40", "07:45", "07:50", "07:55", "08:00", "08:05", "08:10", "08:15", "08:20", "08:25", "08:34", "08:39", "08:45", "08:50", "08:58", "09:03", "09:09", "09:15", "09:21", "09:26", "09:32", "09:38", "09:43", "09:49", "09:55", "10:01", "10:06", "10:12", "10:18", "10:24", "10:30", "10:36", "10:42", "10:48", "10:54", "11:00", "11:06", "11:12", "11:18", "11:24", "11:30", "11:36", "11:42", "11:48", "11:54", "12:00", "12:06", "12:12", "12:18", "12:24", "12:30", "12:36", "12:42", "12:48", "12:54", "13:00", "13:06", "13:12", "13:18", "13:24", "13:30", "13:36", "13:42", "13:48", "13:54", "14:00", "14:06", "14:12", "14:18", "14:24", "14:30", "14:36", "14:42", "14:48", "14:54", "15:00", "15:06", "15:12", "15:18", "15:24", "15:30", "15:36", "15:42", "15:48", "15:54", "16:00", "16:06", "16:12", "16:18", "16:24", "16:30", "16:36", "16:42", "16:48", "16:54", "17:00", "17:06", "17:12", "17:18", "17:24", "17:30", "17:36", "17:42", "17:48", "17:54", "18:00", "18:06", "18:12", "18:18", "18:24", "18:30", "18:36", "18:42", "18:48", "18:54", "19:00", "19:06", "19:14", "19:21", "19:28", "19:35", "19:42", "19:49", "19:56", "20:03", "20:10", "20:17", "20:24", "20:31", "20:38", "20:45", "20:52", "20:59", "21:06", "21:13", "21:21", "21:29", "21:38", "21:47", "21:55", "22:08", "22:14", "22:28", "22:42", "22:53", "23:03", "23:15", "23:24", "23:32", "23:47"]),
                          origin("Station:Toei.Oedo.Shiodome",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:Toei.Oedo.KiyosumiShirakawa",
                                 ["05:00", "05:05", "05:17", "05:18", "05:26", "05:39", "05:43", "05:46", "05:58", "06:01", "06:11", "06:13", "06:24", "06:25", "06:35", "06:43", "06:51", "06:59", "07:00", "07:05", "07:08", "07:12", "07:14", "07:19", "07:20", "07:26", "07:26", "07:32", "07:38", "07:39", "07:47", "08:40", "15:22", "16:44", "16:52", "16:58"],
                                 ["05:00", "05:05", "05:17", "05:18", "05:26", "05:39", "05:43", "05:48", "05:58", "06:01", "06:10", "06:13", "06:22", "06:26", "06:33", "06:39", "06:43", "06:51", "06:52", "06:59", "07:01", "07:26"]),
                          origin("Station:Toei.Oedo.ShinOkachimachi",
                                 ["05:00", "05:03"],
                                 ["05:00", "05:03"])
                      ]
            ),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Nippori-Toneri Liner (NT)

    static let nipporiToneri = StaticTrainLine(
        id: "Railway:Toei.NipporiToneri",
        nameJa: "日暮里・舎人ライナー",
        nameEn: "Nippori-Toneri Liner",
        operatorId: "Operator:Toei",
        colorHex: "#EF5BA1",
        stations: [
            st("NipporiToneri", "Nippori", "日暮里", "Nippori", "NT01", 35.7278, 139.7708),
            st("NipporiToneri", "NishiNippori", "西日暮里", "Nishi-nippori", "NT02", 35.7324, 139.7669),
            st("NipporiToneri", "AkadoShogakkomae", "赤土小学校前", "Akado-shogakkomae", "NT03", 35.7418, 139.7682),
            st("NipporiToneri", "Kumanomae", "熊野前", "Kumanomae", "NT04", 35.7485, 139.7699),
            st("NipporiToneri", "AdachiOdai", "足立小台", "Adachi-odai", "NT05", 35.7555, 139.7735),
            st("NipporiToneri", "OgiOhashi", "扇大橋", "Ogi-ohashi", "NT06", 35.7638, 139.7752),
            st("NipporiToneri", "Koya", "高野", "Koya", "NT07", 35.7688, 139.7745),
            st("NipporiToneri", "Kohoku", "江北", "Kohoku", "NT08", 35.7758, 139.7745),
            st("NipporiToneri", "NishiaraidaishiNishi", "西新井大師西", "Nishiaraidaishi-nishi", "NT09", 35.7828, 139.7692),
            st("NipporiToneri", "Yazaike", "谷在家", "Yazaike", "NT10", 35.7898, 139.7658),
            st("NipporiToneri", "ToneriKoen", "舎人公園", "Toneri-koen", "NT11", 35.7968, 139.7658),
            st("NipporiToneri", "Toneri", "舎人", "Toneri", "NT12", 35.8048, 139.7662),
            st("NipporiToneri", "MinumadaiShinsuikoen", "見沼代親水公園", "Minumadai-shinsuikoen", "NT13", 35.8125, 139.7660),
        ],
        hopTimesMinutes: [2, 2, 2, 2, 1, 1, 2, 2, 1, 2, 1, 2],
        directions: [
            direction("NipporiToneri", "MinumadaiShinsuikoen", "見沼代親水公園方面", "For Minumadai-shinsuikoen", ascending: true,
                      weekday: pattern("05:33", "24:30", [
                          ("05:33", 8), ("07:00", 3), ("09:30", 7), ("17:00", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:33", "24:03", [
                          ("05:33", 8), ("07:00", 7), ("10:00", 7.5), ("20:00", 8), ("22:00", 10),
                      ]),
                      origins: [
                          origin("Station:Toei.NipporiToneri.ToneriKoen",
                                 ["05:36"],
                                 ["05:36"])
                      ]
            ),
            direction("NipporiToneri", "Nippori", "日暮里方面", "For Nippori", ascending: false,
                      // Last departures are 舎人公園行 short turns (コ on the official
                      // timetable), which run well past the last full-line 日暮里行.
                      weekday: pattern("05:08", "24:54", [
                          ("05:08", 8), ("07:00", 3), ("09:30", 7), ("17:00", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:08", "24:27", [
                          ("05:08", 8), ("07:00", 7), ("10:00", 7.5), ("20:00", 8), ("22:00", 10),
                      ])),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Arakawa Line / Tokyo Sakura Tram (SA)

    static let arakawa = StaticTrainLine(
        id: "Railway:Toei.Arakawa",
        nameJa: "都電荒川線",
        nameEn: "Toden Arakawa Line",
        operatorId: "Operator:Toei",
        colorHex: "#EE86A7",
        stations: [
            st("Arakawa", "Minowabashi", "三ノ輪橋", "Minowabashi", "SA01", 35.7321, 139.7915),
            st("Arakawa", "ArakawaItchumae", "荒川一中前", "Arakawa-itchumae", "SA02", 35.7337, 139.7889),
            st("Arakawa", "ArakawaKuyakushomae", "荒川区役所前", "Arakawa-kuyakushomae", "SA03", 35.7350, 139.7864),
            st("Arakawa", "ArakawaNichome", "荒川二丁目", "Arakawa-nichome", "SA04", 35.7386, 139.7847),
            st("Arakawa", "ArakawaNanachome", "荒川七丁目", "Arakawa-nanachome", "SA05", 35.7419, 139.7842),
            st("Arakawa", "MachiyaEkimae", "町屋駅前", "Machiya-ekimae", "SA06", 35.7428, 139.7808),
            st("Arakawa", "MachiyaNichome", "町屋二丁目", "Machiya-nichome", "SA07", 35.7437, 139.7769),
            st("Arakawa", "HigashiOguSanchome", "東尾久三丁目", "Higashi-ogu-sanchome", "SA08", 35.7454, 139.7744),
            st("Arakawa", "Kumanomae", "熊野前", "Kumanomae", "SA09", 35.7492, 139.7692),
            st("Arakawa", "Miyanomae", "宮ノ前", "Miyanomae", "SA10", 35.7501, 139.7650),
            st("Arakawa", "Odai", "小台", "Odai", "SA11", 35.7505, 139.7616),
            st("Arakawa", "ArakawaYuenchimae", "荒川遊園地前", "Arakawa-yuenchimae", "SA12", 35.7507, 139.7577),
            st("Arakawa", "ArakawaShakomae", "荒川車庫前", "Arakawa-shakomae", "SA13", 35.7509, 139.7528),
            st("Arakawa", "Kajiwara", "梶原", "Kajiwara", "SA14", 35.7511, 139.7475),
            st("Arakawa", "Sakaecho", "栄町", "Sakaecho", "SA15", 35.7509, 139.7422),
            st("Arakawa", "OjiEkimae", "王子駅前", "Oji-ekimae", "SA16", 35.7527, 139.7383),
            st("Arakawa", "Asukayama", "飛鳥山", "Asukayama", "SA17", 35.7502, 139.7374),
            st("Arakawa", "TakinogawaItchome", "滝野川一丁目", "Takinogawa-itchome", "SA18", 35.7474, 139.7354),
            st("Arakawa", "NishigaharaYonchome", "西ヶ原四丁目", "Nishigahara-yonchome", "SA19", 35.7444, 139.7328),
            st("Arakawa", "ShinKoshinzuka", "新庚申塚", "Shin-koshinzuka", "SA20", 35.7413, 139.7304),
            st("Arakawa", "Koshinzuka", "庚申塚", "Koshinzuka", "SA21", 35.7395, 139.7296),
            st("Arakawa", "Sugamoshinden", "巣鴨新田", "Sugamoshinden", "SA22", 35.7354, 139.7278),
            st("Arakawa", "OtsukaEkimae", "大塚駅前", "Otsuka-ekimae", "SA23", 35.7316, 139.7293),
            st("Arakawa", "Mukohara", "向原", "Mukohara", "SA24", 35.7289, 139.7249),
            st("Arakawa", "HigashiIkebukuroYonchome", "東池袋四丁目", "Higashi-ikebukuro-yonchome", "SA25", 35.7254, 139.7204),
            st("Arakawa", "TodenZoshigaya", "都電雑司ヶ谷", "Toden-zoshigaya", "SA26", 35.7243, 139.7180),
            st("Arakawa", "Kishibojimmae", "鬼子母神前", "Kishibojimmae", "SA27", 35.7203, 139.7150),
            st("Arakawa", "Gakushuinshita", "学習院下", "Gakushuinshita", "SA28", 35.7162, 139.7125),
            st("Arakawa", "Omokagebashi", "面影橋", "Omokagebashi", "SA29", 35.7129, 139.7145),
            st("Arakawa", "Waseda", "早稲田", "Waseda", "SA30", 35.7118, 139.7189),
        ],
        hopTimesMinutes: [
            1, 1, 2, 2, 2, 2, 1, 2, 2, 1, 1, 2, 2, 2, 2,
            2, 2, 2, 2, 1, 2, 2, 2, 2, 1, 2, 2, 2, 2,
        ],
        directions: [
            direction("Arakawa", "Waseda", "早稲田方面", "For Waseda", ascending: true,
                      // Last trams are 荒川車庫前行 (車) / 王子駅前行 (王) short turns.
                      weekday: pattern("05:48", "23:14", [
                          ("05:48", 6), ("07:00", 4), ("10:00", 6.5), ("16:00", 5), ("19:00", 7),
                      ]),
                      holiday: pattern("05:48", "23:14", [
                          ("05:48", 7), ("10:00", 6.5), ("19:00", 8),
                      ]),
                      origins: [
                          origin("Station:Toei.Arakawa.MachiyaEkimae",
                                 ["05:47", "06:23", "06:43", "06:58", "07:32", "07:52", "15:34", "19:37", "19:56", "20:18", "20:55", "21:07", "21:34"],
                                 []),
                          origin("Station:Toei.Arakawa.ArakawaShakomae",
                                 ["05:25", "05:27", "05:29", "05:39", "05:43", "05:52", "06:05", "06:18", "06:29", "06:34", "06:44", "07:01", "07:20", "07:36", "07:57", "14:43", "15:15"],
                                 [])
                      ]
            ),
            direction("Arakawa", "Minowabashi", "三ノ輪橋方面", "For Minowabashi", ascending: false,
                      weekday: pattern("06:00", "23:04", [
                          ("06:00", 6), ("07:00", 4), ("10:00", 6.5), ("16:00", 5), ("19:00", 7),
                      ]),
                      holiday: pattern("06:00", "23:04", [
                          ("06:00", 7), ("10:00", 6.5), ("19:00", 8),
                      ]),
                      origins: [
                          origin("Station:Toei.Arakawa.ArakawaShakomae",
                                 ["05:26", "05:31", "06:05", "06:16", "06:26", "06:31", "06:39", "06:42", "06:52", "06:57", "07:06", "07:14", "07:25", "07:32", "15:13", "15:26", "15:51"],
                                 []),
                          origin("Station:Toei.Arakawa.OjiEkimae",
                                 ["05:35", "05:54", "06:16", "07:11", "07:29", "22:15", "23:16", "23:28"],
                                 []),
                          origin("Station:Toei.Arakawa.OtsukaEkimae",
                                 ["05:49", "08:00", "08:24", "08:45", "18:59", "19:23", "19:40", "20:08", "20:36", "22:44", "23:11"],
                                 [])
                      ]
            ),
        ],
        delayInfo: delayInfo
    )
}
