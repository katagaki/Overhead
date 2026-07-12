import Foundation

// MARK: - Tokyo Metro Line Data

private func st(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "Station:TokyoMetro.\(line).\(suffix)",
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
                       origins: [IntermediateOrigin] = [],
                       expressWeekday: [ExactRun] = [],
                       expressHoliday: [ExactRun] = []) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:TokyoMetro.\(line).\(suffix)",
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

// Express 当駅始発/through origin with typed exact runs (ODPT), for skip-stop
// trains entering or starting at a mid-line station.
private func originRuns(_ stationId: String, _ weekday: [ExactRun], _ holiday: [ExactRun]) -> IntermediateOrigin {
    IntermediateOrigin(stationId: stationId, weekdayRuns: weekday, saturdayHolidayRuns: holiday)
}

private func through(_ junction: String, _ end: ThroughService.LineEnd,
                     _ lineJa: String, _ lineEn: String,
                     _ towardJa: String, _ towardEn: String,
                     to connectingLineId: String? = nil) -> ThroughService {
    ThroughService(
        junctionStationId: "Station:TokyoMetro.\(junction)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

enum TokyoMetroLineData {

    // MARK: Delay Check

    // Delays of 15+ minutes are posted on the service information page
    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.tokyometro.jp/unkou/",
        statusPageURLEn: "https://www.tokyometro.jp/lang_en/unkou/index.html",
        xAccount: "@tokyometro_info",
        checkMethodJa: "東京メトロ「運行情報」ページ、公式アプリ、またはX（@tokyometro_info）で確認できます。15分以上の遅れ・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Tokyo Metro Service Information page, the official app, or X (@tokyometro_info). Delays or suspensions of 15 minutes or more are posted."
    )

    static let lines: [StaticTrainLine] = [
        ginza, marunouchi, marunouchiBranch, hibiya, tozai, chiyoda,
        yurakucho, hanzomon, namboku, fukutoshin,
    ]

    // Typical Tokyo Metro headway bands. First/last departures are set per
    // direction below (verified against published timetables, 2026).
    private static let metroWeekdayBands: [(String, Double)] = [
        ("05:00", 6), ("07:00", 3), ("09:30", 5), ("17:00", 3.5), ("20:00", 5), ("22:00", 6.5),
    ]
    private static let metroHolidayBands: [(String, Double)] = [
        ("05:00", 6), ("07:00", 5), ("10:00", 5), ("20:00", 5.5), ("22:00", 7),
    ]
    private static let quietWeekdayBands: [(String, Double)] = [
        ("05:00", 7), ("07:00", 3.5), ("09:30", 6), ("17:00", 4), ("20:00", 6), ("22:00", 7),
    ]
    private static let quietHolidayBands: [(String, Double)] = [
        ("05:00", 7), ("07:00", 6), ("10:00", 6), ("20:00", 6.5), ("22:00", 7.5),
    ]

    private static func metroWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, metroWeekdayBands)
    }
    private static func metroHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, metroHolidayBands)
    }
    private static func quietWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, quietWeekdayBands)
    }
    private static func quietHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, quietHolidayBands)
    }

    // Hibiya-specific bands (verified against ekitan/Yahoo, 2026-07-08):
    // rush runs ~2.5 min (23-24 trains/h), and after ~23:50 only sparse
    // short-turn trains remain (広尾/南千住行き every 13-17 min until 24:28).
    private static let hibiyaWeekdayBands: [(String, Double)] = [
        ("05:00", 6), ("07:00", 2.5), ("09:30", 5), ("17:00", 3.5), ("20:00", 5), ("22:00", 6.5), ("23:45", 14),
    ]
    private static let hibiyaHolidayBands: [(String, Double)] = [
        ("05:00", 6), ("07:00", 5), ("10:00", 5), ("20:00", 5.5), ("22:00", 7), ("23:45", 15),
    ]

    private static func hibiyaWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, hibiyaWeekdayBands)
    }
    private static func hibiyaHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, hibiyaHolidayBands)
    }

    // MARK: - Ginza Line (G)

    static let ginza = StaticTrainLine(
        id: "Railway:TokyoMetro.Ginza",
        nameJa: "銀座線",
        nameEn: "Ginza Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#F7931D",
        stations: [
            st("Ginza", "Shibuya", "渋谷", "Shibuya", "G01", 35.6580, 139.7016),
            st("Ginza", "Omotesando", "表参道", "Omote-sando", "G02", 35.6654, 139.7122),
            st("Ginza", "Gaiemmae", "外苑前", "Gaiemmae", "G03", 35.6706, 139.7178),
            st("Ginza", "AoyamaItchome", "青山一丁目", "Aoyama-itchome", "G04", 35.6726, 139.7244),
            st("Ginza", "AkasakaMitsuke", "赤坂見附", "Akasaka-mitsuke", "G05", 35.6770, 139.7370),
            st("Ginza", "TameikeSanno", "溜池山王", "Tameike-sanno", "G06", 35.6739, 139.7413),
            st("Ginza", "Toranomon", "虎ノ門", "Toranomon", "G07", 35.6700, 139.7496),
            st("Ginza", "Shimbashi", "新橋", "Shimbashi", "G08", 35.6660, 139.7583),
            st("Ginza", "Ginza", "銀座", "Ginza", "G09", 35.6717, 139.7640),
            st("Ginza", "Kyobashi", "京橋", "Kyobashi", "G10", 35.6767, 139.7701),
            st("Ginza", "Nihombashi", "日本橋", "Nihombashi", "G11", 35.6824, 139.7742),
            st("Ginza", "Mitsukoshimae", "三越前", "Mitsukoshimae", "G12", 35.6866, 139.7730),
            st("Ginza", "Kanda", "神田", "Kanda", "G13", 35.6910, 139.7708),
            st("Ginza", "Suehirocho", "末広町", "Suehirocho", "G14", 35.7023, 139.7715),
            st("Ginza", "UenoHirokoji", "上野広小路", "Ueno-hirokoji", "G15", 35.7076, 139.7727),
            st("Ginza", "Ueno", "上野", "Ueno", "G16", 35.7115, 139.7772),
            st("Ginza", "Inaricho", "稲荷町", "Inaricho", "G17", 35.7115, 139.7827),
            st("Ginza", "Tawaramachi", "田原町", "Tawaramachi", "G18", 35.7100, 139.7905),
            st("Ginza", "Asakusa", "浅草", "Asakusa", "G19", 35.7109, 139.7966),
        ],
        hopTimesMinutes: [
            2, 2, 1, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 1, 2, 2, 1, 2,
        ],
        directions: [
            direction("Ginza", "Asakusa", "浅草方面", "For Asakusa", ascending: true,
                      weekday: metroWeekday("05:01", "24:02"), holiday: metroHoliday("05:01", "24:02"),
                      origins: [
                          origin("Station:TokyoMetro.Ginza.Toranomon",
                                 ["06:10"],
                                 []),
                          origin("Station:TokyoMetro.Ginza.Shimbashi",
                                 [],
                                 ["06:09"]),
                          origin("Station:TokyoMetro.Ginza.Ueno",
                                 ["05:15", "06:04"],
                                 ["05:15", "06:04"])
                      ]
            ),
            direction("Ginza", "Shibuya", "渋谷方面", "For Shibuya", ascending: false,
                      weekday: metroWeekday("05:01", "24:10"), holiday: metroHoliday("05:01", "24:14"),
                      origins: [
                          origin("Station:TokyoMetro.Ginza.TameikeSanno",
                                 ["06:29"],
                                 ["07:41"]),
                          origin("Station:TokyoMetro.Ginza.Ueno",
                                 ["06:27", "06:36", "07:03", "07:12", "07:20", "07:27", "07:32", "07:36", "07:43", "07:50", "07:57", "08:09", "15:47", "15:59", "16:11", "16:23", "16:33", "16:40", "16:50", "16:59", "17:07"],
                                 ["07:51", "08:35", "09:14", "09:35"])
                      ]
            ),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Marunouchi Line (M)

    static let marunouchi = StaticTrainLine(
        id: "Railway:TokyoMetro.Marunouchi",
        nameJa: "丸ノ内線",
        nameEn: "Marunouchi Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#E60012",
        stations: [
            st("Marunouchi", "Ogikubo", "荻窪", "Ogikubo", "M01", 35.7047, 139.6202),
            st("Marunouchi", "MinamiAsagaya", "南阿佐ケ谷", "Minami-Asagaya", "M02", 35.6998, 139.6356),
            st("Marunouchi", "ShinKoenji", "新高円寺", "Shin-Koenji", "M03", 35.6980, 139.6494),
            st("Marunouchi", "HigashiKoenji", "東高円寺", "Higashi-Koenji", "M04", 35.6976, 139.6605),
            st("Marunouchi", "ShinNakano", "新中野", "Shin-Nakano", "M05", 35.6972, 139.6707),
            st("Marunouchi", "NakanoSakaue", "中野坂上", "Nakano-sakaue", "M06", 35.6975, 139.6827),
            st("Marunouchi", "NishiShinjuku", "西新宿", "Nishi-shinjuku", "M07", 35.6945, 139.6926),
            st("Marunouchi", "Shinjuku", "新宿", "Shinjuku", "M08", 35.6907, 139.6996),
            st("Marunouchi", "ShinjukuSanchome", "新宿三丁目", "Shinjuku-sanchome", "M09", 35.6909, 139.7047),
            st("Marunouchi", "ShinjukuGyoemmae", "新宿御苑前", "Shinjuku-gyoemmae", "M10", 35.6887, 139.7109),
            st("Marunouchi", "YotsuyaSanchome", "四谷三丁目", "Yotsuya-sanchome", "M11", 35.6878, 139.7204),
            st("Marunouchi", "Yotsuya", "四ツ谷", "Yotsuya", "M12", 35.6858, 139.7290),
            st("Marunouchi", "AkasakaMitsuke", "赤坂見附", "Akasaka-mitsuke", "M13", 35.6770, 139.7370),
            st("Marunouchi", "KokkaiGijidomae", "国会議事堂前", "Kokkai-gijidomae", "M14", 35.6743, 139.7451),
            st("Marunouchi", "Kasumigaseki", "霞ケ関", "Kasumigaseki", "M15", 35.6750, 139.7518),
            st("Marunouchi", "Ginza", "銀座", "Ginza", "M16", 35.6717, 139.7640),
            st("Marunouchi", "Tokyo", "東京", "Tokyo", "M17", 35.6805, 139.7660),
            st("Marunouchi", "Otemachi", "大手町", "Otemachi", "M18", 35.6867, 139.7654),
            st("Marunouchi", "Awajicho", "淡路町", "Awajicho", "M19", 35.6950, 139.7677),
            st("Marunouchi", "Ochanomizu", "御茶ノ水", "Ochanomizu", "M20", 35.6998, 139.7649),
            st("Marunouchi", "HongoSanchome", "本郷三丁目", "Hongo-sanchome", "M21", 35.7068, 139.7597),
            st("Marunouchi", "Korakuen", "後楽園", "Korakuen", "M22", 35.7080, 139.7512),
            st("Marunouchi", "Myogadani", "茗荷谷", "Myogadani", "M23", 35.7175, 139.7371),
            st("Marunouchi", "ShinOtsuka", "新大塚", "Shin-otsuka", "M24", 35.7262, 139.7292),
            st("Marunouchi", "Ikebukuro", "池袋", "Ikebukuro", "M25", 35.7300, 139.7110),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 3,
        ],
        directions: [
            direction("Marunouchi", "Ikebukuro", "池袋方面", "For Ikebukuro", ascending: true,
                      weekday: metroWeekday("05:01", "24:11"), holiday: metroHoliday("05:01", "24:11"),
                      origins: [
                          origin("Station:TokyoMetro.Marunouchi.NakanoSakaue",
                                 ["05:04", "05:17", "05:31", "05:43", "05:55", "06:05", "06:13", "06:21", "06:29", "06:43", "06:50", "06:56", "07:02", "07:07", "07:13", "07:18", "07:27", "07:32", "07:37", "07:43", "07:48", "07:54", "08:05", "08:12", "08:18", "08:25", "08:32", "08:39", "08:45", "08:49", "08:54", "08:58", "09:03", "09:10", "09:17", "09:28", "09:38", "09:49", "10:21", "11:01", "11:21", "12:01", "12:26", "13:01", "13:26", "14:01", "14:26", "15:01", "15:20", "15:26", "15:33", "15:44", "15:54", "16:05", "16:12", "16:17", "16:24", "16:29", "16:34", "16:39", "16:46", "16:51", "17:01", "17:08", "17:21", "17:28", "17:41", "17:48", "18:01", "18:08", "18:21", "18:28", "18:41", "18:48", "19:01", "19:08", "19:21", "19:28", "19:41", "19:49"],
                                 ["05:04", "05:17", "06:01", "06:19", "06:55", "07:19", "08:26", "08:56", "09:26", "10:01", "10:26", "11:01", "11:26", "12:01", "12:26", "13:01", "13:26", "14:01", "14:26", "15:01", "15:26", "16:01", "16:26", "17:01", "17:26", "18:01", "18:26", "19:01", "19:26", "20:01", "20:26", "21:01", "21:26", "22:05"]),
                          origin("Station:TokyoMetro.Marunouchi.Shinjuku",
                                 ["05:00", "06:41"],
                                 ["05:00", "06:41"]),
                          origin("Station:TokyoMetro.Marunouchi.Korakuen",
                                 ["05:36"],
                                 ["05:51"]),
                          origin("Station:TokyoMetro.Marunouchi.Myogadani",
                                 ["05:00", "05:20", "05:51", "05:56", "06:15", "06:34", "06:44", "06:54", "07:06", "07:14", "07:22", "07:30", "07:44", "07:58", "08:14", "15:23", "15:38", "15:52", "16:04", "16:14", "16:24", "16:32", "16:42", "16:54"],
                                 ["05:00", "05:20", "06:08", "06:26", "07:22", "07:44"])
                      ]
            ),
            direction("Marunouchi", "Ogikubo", "荻窪方面", "For Ogikubo", ascending: false,
                      weekday: metroWeekday("05:00", "24:20"), holiday: metroHoliday("05:00", "24:20"),
                      origins: [
                          origin("Station:TokyoMetro.Marunouchi.NakanoSakaue",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:TokyoMetro.Marunouchi.ShinjukuSanchome",
                                 ["05:14", "05:26", "24:16"],
                                 ["05:14", "05:26", "24:16"]),
                          origin("Station:TokyoMetro.Marunouchi.Myogadani",
                                 ["05:13"],
                                 ["05:13"])
                      ]
            ),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Marunouchi Line Honancho Branch (Mb)

    static let marunouchiBranch = StaticTrainLine(
        id: "Railway:TokyoMetro.MarunouchiBranch",
        nameJa: "丸ノ内線(方南町支線)",
        nameEn: "Marunouchi Line Honancho Branch",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#E60012",
        stations: [
            st("MarunouchiBranch", "Honancho", "方南町", "Honancho", "Mb03", 35.6836, 139.6588),
            st("MarunouchiBranch", "NakanoFujimicho", "中野富士見町", "Nakano-fujimicho", "Mb04", 35.6866, 139.6693),
            st("MarunouchiBranch", "NakanoShimbashi", "中野新橋", "Nakano-shimbashi", "Mb05", 35.6907, 139.6764),
            st("MarunouchiBranch", "NakanoSakaue", "中野坂上", "Nakano-sakaue", "M06", 35.6975, 139.6827),
        ],
        hopTimesMinutes: [
            2, 2, 2,
        ],
        directions: [
            direction("MarunouchiBranch", "NakanoSakaue", "中野坂上方面", "For Nakano-sakaue", ascending: true,
                      weekday: pattern("05:00", "24:09", [
                          ("05:00", 9), ("07:00", 8), ("09:30", 9), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:00", "24:09", [
                          ("05:00", 10), ("10:00", 10), ("22:00", 12),
                      ]),
                      origins: [
                          origin("Station:TokyoMetro.MarunouchiBranch.NakanoFujimicho",
                                 ["05:00", "05:12", "06:08", "06:24", "06:38", "06:51", "07:08", "07:23", "07:29", "07:38", "15:21", "15:27", "16:08", "16:18", "16:29"],
                                 ["05:00", "05:12"])
                      ]
            ),
            direction("MarunouchiBranch", "Honancho", "方南町方面", "For Honancho", ascending: false,
                      weekday: pattern("05:09", "24:26", [
                          ("05:09", 9), ("07:00", 8.5), ("09:30", 10), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:09", "24:26", [
                          ("05:09", 10), ("10:00", 10), ("22:00", 12),
                      ]),
                      origins: [
                          origin("Station:TokyoMetro.MarunouchiBranch.NakanoFujimicho",
                                 ["05:20"],
                                 ["05:42"])
                      ]
            ),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Hibiya Line (H)

    static let hibiya = StaticTrainLine(
        id: "Railway:TokyoMetro.Hibiya",
        nameJa: "日比谷線",
        nameEn: "Hibiya Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#B5B5AC",
        stations: [
            st("Hibiya", "NakaMeguro", "中目黒", "Naka-meguro", "H01", 35.6442, 139.6990),
            st("Hibiya", "Ebisu", "恵比寿", "Ebisu", "H02", 35.6470, 139.7100),
            st("Hibiya", "Hiroo", "広尾", "Hiro-o", "H03", 35.6524, 139.7220),
            st("Hibiya", "Roppongi", "六本木", "Roppongi", "H04", 35.6633, 139.7313),
            st("Hibiya", "Kamiyacho", "神谷町", "Kamiyacho", "H05", 35.6629, 139.7450),
            st("Hibiya", "ToranomonHills", "虎ノ門ヒルズ", "Toranomon Hills", "H06", 35.6670, 139.7497),
            st("Hibiya", "Kasumigaseki", "霞ケ関", "Kasumigaseki", "H07", 35.6750, 139.7518),
            st("Hibiya", "Hibiya", "日比谷", "Hibiya", "H08", 35.6748, 139.7595),
            st("Hibiya", "Ginza", "銀座", "Ginza", "H09", 35.6717, 139.7640),
            st("Hibiya", "HigashiGinza", "東銀座", "Higashi-ginza", "H10", 35.6698, 139.7674),
            st("Hibiya", "Tsukiji", "築地", "Tsukiji", "H11", 35.6663, 139.7722),
            st("Hibiya", "Hatchobori", "八丁堀", "Hatchobori", "H12", 35.6748, 139.7777),
            st("Hibiya", "Kayabacho", "茅場町", "Kayabacho", "H13", 35.6796, 139.7787),
            st("Hibiya", "Ningyocho", "人形町", "Ningyocho", "H14", 35.6864, 139.7825),
            st("Hibiya", "Kodemmacho", "小伝馬町", "Kodemmacho", "H15", 35.6907, 139.7779),
            st("Hibiya", "Akihabara", "秋葉原", "Akihabara", "H16", 35.6986, 139.7740),
            st("Hibiya", "NakaOkachimachi", "仲御徒町", "Naka-okachimachi", "H17", 35.7078, 139.7753),
            st("Hibiya", "Ueno", "上野", "Ueno", "H18", 35.7118, 139.7776),
            st("Hibiya", "Iriya", "入谷", "Iriya", "H19", 35.7208, 139.7847),
            st("Hibiya", "Minowa", "三ノ輪", "Minowa", "H20", 35.7290, 139.7918),
            st("Hibiya", "MinamiSenju", "南千住", "Minami-senju", "H21", 35.7333, 139.7995),
            st("Hibiya", "KitaSenju", "北千住", "Kita-senju", "H22", 35.7497, 139.8047),
        ],
        hopTimesMinutes: [
            2, 2, 3, 2, 1, 2, 2, 1, 1, 2, 2, 1, 2, 2, 2, 2, 1, 2, 2, 2, 3,
        ],
        directions: [
            direction("Hibiya", "KitaSenju", "北千住方面", "For Kita-senju", ascending: true,
                      weekday: hibiyaWeekday("05:00", "24:28"), holiday: hibiyaHoliday("05:00", "24:28"),
                      origins: [
                          origin("Station:TokyoMetro.Hibiya.Kasumigaseki",
                                 ["05:00", "17:02", "18:02", "19:02", "20:02", "21:02"],
                                 ["05:00", "16:02", "17:02", "18:02", "19:02", "20:02"]),
                          origin("Station:TokyoMetro.Hibiya.MinamiSenju",
                                 ["05:02", "05:09", "05:34", "06:02", "06:20", "06:33", "06:38", "06:46", "16:55"],
                                 ["05:02", "05:09", "06:21"])
                      ]
            ),
            direction("Hibiya", "NakaMeguro", "中目黒方面", "For Naka-meguro", ascending: false,
                      weekday: hibiyaWeekday("05:00", "24:28"), holiday: hibiyaHoliday("05:00", "24:27"),
                      origins: [
                          origin("Station:TokyoMetro.Hibiya.Ebisu",
                                 ["05:33", "05:48", "06:04"],
                                 ["05:33", "05:46", "06:27"]),
                          origin("Station:TokyoMetro.Hibiya.Hatchobori",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:TokyoMetro.Hibiya.MinamiSenju",
                                 ["06:13", "16:05", "16:14", "16:32", "17:01", "17:12"],
                                 [])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Hibiya.KitaSenju", .ascending,
                    "東武スカイツリーライン", "Tobu Skytree Line",
                    "東武動物公園・南栗橋方面", "for Tobu-Dobutsu-Koen & Minami-Kurihashi",
                    to: "Railway:Tobu.TobuSkytree"),
        ]
    )

    // MARK: - Tozai Line (T)

    static let tozai = StaticTrainLine(
        id: "Railway:TokyoMetro.Tozai",
        nameJa: "東西線",
        nameEn: "Tozai Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#00A7DB",
        stations: [
            st("Tozai", "Nakano", "中野", "Nakano", "T01", 35.7056, 139.6659),
            st("Tozai", "Ochiai", "落合", "Ochiai", "T02", 35.7090, 139.6863),
            st("Tozai", "Takadanobaba", "高田馬場", "Takadanobaba", "T03", 35.7132, 139.7040),
            st("Tozai", "Waseda", "早稲田", "Waseda", "T04", 35.7089, 139.7187),
            st("Tozai", "Kagurazaka", "神楽坂", "Kagurazaka", "T05", 35.7035, 139.7332),
            st("Tozai", "Iidabashi", "飯田橋", "Iidabashi", "T06", 35.7018, 139.7452),
            st("Tozai", "Kudanshita", "九段下", "Kudanshita", "T07", 35.6957, 139.7515),
            st("Tozai", "Takebashi", "竹橋", "Takebashi", "T08", 35.6913, 139.7580),
            st("Tozai", "Otemachi", "大手町", "Otemachi", "T09", 35.6857, 139.7659),
            st("Tozai", "Nihombashi", "日本橋", "Nihombashi", "T10", 35.6820, 139.7740),
            st("Tozai", "Kayabacho", "茅場町", "Kayabacho", "T11", 35.6796, 139.7787),
            st("Tozai", "MonzenNakacho", "門前仲町", "Monzen-nakacho", "T12", 35.6718, 139.7957),
            st("Tozai", "Kiba", "木場", "Kiba", "T13", 35.6694, 139.8065),
            st("Tozai", "Toyocho", "東陽町", "Toyocho", "T14", 35.6695, 139.8170),
            st("Tozai", "MinamiSunamachi", "南砂町", "Minami-sunamachi", "T15", 35.6688, 139.8330),
            st("Tozai", "NishiKasai", "西葛西", "Nishi-kasai", "T16", 35.6645, 139.8590),
            st("Tozai", "Kasai", "葛西", "Kasai", "T17", 35.6636, 139.8722),
            st("Tozai", "Urayasu", "浦安", "Urayasu", "T18", 35.6657, 139.8927),
            st("Tozai", "MinamiGyotoku", "南行徳", "Minami-gyotoku", "T19", 35.6585, 139.9098),
            st("Tozai", "Gyotoku", "行徳", "Gyotoku", "T20", 35.6663, 139.9270),
            st("Tozai", "Myoden", "妙典", "Myoden", "T21", 35.6767, 139.9385),
            st("Tozai", "BarakiNakayama", "原木中山", "Baraki-nakayama", "T22", 35.6893, 139.9493),
            st("Tozai", "NishiFunabashi", "西船橋", "Nishi-funabashi", "T23", 35.7075, 139.9594),
        ],
        hopTimesMinutes: [
            3, 2, 2, 2, 2, 1, 2, 2, 2, 1, 3, 2, 2, 2, 3, 2, 3, 2, 2, 2, 2, 3,
        ],
        directions: [
            direction("Tozai", "NishiFunabashi", "西船橋方面", "For Nishi-funabashi", ascending: true,
                      weekday: pattern("05:00", "23:52", [
                          ("05:00", 6), ("07:00", 2.5), ("09:30", 5), ("17:00", 3), ("20:00", 5), ("22:00", 6.5),
                      ]),
                      holiday: metroHoliday("05:00", "23:52"),
                      origins: [
                          origin("Station:TokyoMetro.Tozai.Toyocho",
                                 ["04:58", "05:11", "05:37", "05:49", "05:58", "06:08", "06:17", "06:32", "06:43", "06:53", "06:59", "07:11"],
                                 ["04:58", "05:11", "07:13", "07:48"])
                      ],
                      expressWeekday: tozaiAscExpressWd,
                      expressHoliday: tozaiAscExpressHol
            ),
            direction("Tozai", "Nakano", "中野方面", "For Nakano", ascending: false,
                      weekday: pattern("05:00", "24:09", [
                          ("05:00", 6), ("07:00", 2.5), ("09:30", 5), ("17:00", 3), ("20:00", 5), ("22:00", 6.5),
                      ]),
                      holiday: metroHoliday("05:00", "24:09"),
                      origins: [
                          origin("Station:TokyoMetro.Tozai.Toyocho",
                                 ["05:00", "05:09", "05:17", "05:28", "05:53", "06:01", "06:11", "06:22", "15:44", "16:01", "16:15", "16:39", "16:59", "17:15", "17:24", "17:43", "18:06"],
                                 ["05:00", "05:10", "05:18", "05:28", "05:54"]),
                          origin("Station:TokyoMetro.Tozai.Urayasu",
                                 ["06:34"],
                                 []),
                          origin("Station:TokyoMetro.Tozai.Myoden",
                                 ["06:33", "06:52", "07:24", "07:34", "07:43", "07:48", "07:55", "08:06", "08:16", "08:25", "08:38", "08:48", "09:07", "16:05", "17:27"],
                                 ["08:29"])
                      ],
                      expressWeekday: tozaiDescExpressWd,
                      expressHoliday: tozaiDescExpressHol
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Tozai.Nakano", .descending,
                    "JR中央・総武線各駅停車", "JR Chuo-Sobu Local Line",
                    "三鷹方面", "for Mitaka",
                    to: "Railway:JR-East.ChuoSobuLocal"),
            through("Tozai.NishiFunabashi", .ascending,
                    "東葉高速線", "Toyo Rapid Line",
                    "東葉勝田台方面", "for Toyo-Katsutadai"),
            through("Tozai.NishiFunabashi", .ascending,
                    "JR総武線各駅停車", "JR Sobu Local Line",
                    "津田沼方面", "for Tsudanuma",
                    to: "Railway:JR-East.ChuoSobuLocal"),
        ]
    )

    // MARK: - Chiyoda Line (C)

    static let chiyoda = StaticTrainLine(
        id: "Railway:TokyoMetro.Chiyoda",
        nameJa: "千代田線",
        nameEn: "Chiyoda Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#00A854",
        stations: [
            st("Chiyoda", "YoyogiUehara", "代々木上原", "Yoyogi-uehara", "C01", 35.6690, 139.6799),
            st("Chiyoda", "YoyogiKoen", "代々木公園", "Yoyogi-koen", "C02", 35.6697, 139.6900),
            st("Chiyoda", "MeijiJingumae", "明治神宮前", "Meiji-jingumae 'Harajuku'", "C03", 35.6685, 139.7063),
            st("Chiyoda", "Omotesando", "表参道", "Omote-sando", "C04", 35.6654, 139.7122),
            st("Chiyoda", "Nogizaka", "乃木坂", "Nogizaka", "C05", 35.6665, 139.7263),
            st("Chiyoda", "Akasaka", "赤坂", "Akasaka", "C06", 35.6722, 139.7363),
            st("Chiyoda", "KokkaiGijidomae", "国会議事堂前", "Kokkai-gijidomae", "C07", 35.6743, 139.7451),
            st("Chiyoda", "Kasumigaseki", "霞ケ関", "Kasumigaseki", "C08", 35.6750, 139.7518),
            st("Chiyoda", "Hibiya", "日比谷", "Hibiya", "C09", 35.6748, 139.7595),
            st("Chiyoda", "Nijubashimae", "二重橋前", "Nijubashimae 'Marunouchi'", "C10", 35.6813, 139.7617),
            st("Chiyoda", "Otemachi", "大手町", "Otemachi", "C11", 35.6860, 139.7650),
            st("Chiyoda", "ShinOchanomizu", "新御茶ノ水", "Shin-ochanomizu", "C12", 35.6990, 139.7657),
            st("Chiyoda", "Yushima", "湯島", "Yushima", "C13", 35.7075, 139.7692),
            st("Chiyoda", "Nezu", "根津", "Nezu", "C14", 35.7172, 139.7657),
            st("Chiyoda", "Sendagi", "千駄木", "Sendagi", "C15", 35.7250, 139.7637),
            st("Chiyoda", "NishiNippori", "西日暮里", "Nishi-nippori", "C16", 35.7324, 139.7669),
            st("Chiyoda", "Machiya", "町屋", "Machiya", "C17", 35.7424, 139.7809),
            st("Chiyoda", "KitaSenju", "北千住", "Kita-senju", "C18", 35.7497, 139.8047),
            st("Chiyoda", "Ayase", "綾瀬", "Ayase", "C19", 35.7620, 139.8247),
            st("Chiyoda", "KitaAyase", "北綾瀬", "Kita-ayase", "C20", 35.7756, 139.8320),
        ],
        hopTimesMinutes: [
            2, 2, 1, 2, 2, 2, 1, 2, 1, 2, 2, 2, 2, 1, 2, 2, 3, 3, 3,
        ],
        directions: [
            direction("Chiyoda", "KitaAyase", "北綾瀬方面", "For Kita-ayase", ascending: true,
                      weekday: metroWeekday("05:00", "24:00"), holiday: metroHoliday("05:00", "23:55"),
                      origins: [
                          origin("Station:TokyoMetro.Chiyoda.Kasumigaseki",
                                 ["06:16", "07:02", "07:35", "07:50", "17:12", "17:39", "18:19", "18:28", "19:09", "20:12"],
                                 ["07:32"]),
                          origin("Station:TokyoMetro.Chiyoda.Yushima",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:TokyoMetro.Chiyoda.KitaSenju",
                                 ["04:54", "24:48"],
                                 ["04:54", "24:48"]),
                          origin("Station:TokyoMetro.Chiyoda.Ayase",
                                 ["05:07", "05:27", "05:45", "06:00", "06:19", "06:38", "06:50", "07:02", "07:19", "07:36", "07:52", "08:12", "08:28", "08:40", "08:56", "09:19", "09:32", "09:46", "10:21", "10:35", "10:57", "11:16", "11:46", "12:26", "12:46", "13:06", "13:36", "14:06", "14:26", "14:46", "15:16", "15:48", "16:26", "17:05", "17:30", "17:43", "17:55", "18:30", "18:54", "19:02", "19:15", "19:28", "19:47", "20:01", "20:06", "20:13", "20:26", "20:34", "20:40", "20:52", "21:08", "21:22", "21:34", "21:54", "22:21", "22:37", "22:49", "23:03", "23:19", "23:34", "23:49", "24:09", "24:22"],
                                 ["05:13", "05:33", "05:55", "06:14", "06:32", "06:48", "07:03", "07:16", "07:43", "07:59", "08:11", "08:41", "08:53", "09:14", "09:29", "09:37", "09:54", "10:11", "10:27", "10:40", "10:57", "11:17", "11:36", "12:16", "12:36", "12:56", "13:16", "13:36", "13:56", "14:16", "14:36", "14:56", "15:18", "15:38", "15:58", "16:28", "16:48", "17:18", "17:38", "17:58", "18:18", "19:03", "19:18", "19:48", "20:19", "20:43", "21:02", "21:17", "21:30", "21:45", "22:12", "22:29", "22:41", "22:55", "23:09", "23:23", "23:44", "24:04", "24:25"])
                      ]
            ),
            direction("Chiyoda", "YoyogiUehara", "代々木上原方面", "For Yoyogi-uehara", ascending: false,
                      weekday: metroWeekday("05:00", "24:15"), holiday: metroHoliday("05:00", "24:13"),
                      origins: [
                          origin("Station:TokyoMetro.Chiyoda.Otemachi",
                                 ["17:30", "19:30", "20:30", "21:30"],
                                 []),
                          origin("Station:TokyoMetro.Chiyoda.KitaSenju",
                                 ["09:47", "18:14"],
                                 ["08:33", "10:33", "15:22", "19:35", "20:35"]),
                          origin("Station:TokyoMetro.Chiyoda.Ayase",
                                 ["04:38", "05:00", "05:23", "05:42", "05:58", "06:11", "06:16", "06:29", "06:33", "06:42", "06:50", "06:54", "07:00", "07:03", "07:06", "07:11", "07:14", "07:17", "07:22", "07:27", "07:29", "07:32", "07:34", "07:36", "07:39", "07:41", "07:45", "07:48", "07:50", "07:52", "07:54", "07:57", "08:01", "08:03", "08:05", "08:08", "08:10", "08:13", "08:15", "08:20", "08:22", "08:24", "08:26", "08:29", "08:31", "08:33", "08:37", "08:40", "08:43", "08:46", "08:49", "08:52", "08:56", "08:59", "09:06", "09:10", "09:13", "09:17", "09:24", "09:27", "09:31", "09:35", "09:40", "09:45", "09:51", "09:56", "10:01", "10:07", "10:18", "10:28", "10:33", "10:38", "10:43", "10:48", "10:53", "10:58", "11:08", "11:13", "11:18", "11:28", "11:33", "11:38", "11:48", "11:58", "12:03", "12:08", "12:18", "12:28", "12:38", "12:43", "12:48", "12:58", "13:03", "13:08", "13:18", "13:23", "13:28", "13:38", "13:48", "13:53", "13:58", "14:08", "14:18", "14:23", "14:28", "14:38", "14:43", "14:48", "14:58", "15:03", "15:08", "15:17", "15:27", "15:32", "15:37", "15:46", "15:51", "16:00", "16:04", "16:08", "16:16", "16:21", "16:30", "16:39", "16:43", "16:48", "16:58", "17:07", "17:17", "17:22", "17:26", "17:34", "17:40", "17:46", "17:54", "17:58", "18:06", "18:12", "18:25", "18:33", "18:42", "18:46", "18:55", "18:59", "19:03", "19:06", "19:12", "19:21", "19:25", "19:29", "19:34", "19:38", "19:42", "19:46", "19:50", "19:54", "19:58", "20:03", "20:07", "20:12", "20:17", "20:22", "20:27", "20:32", "20:37", "20:42", "20:47", "20:52", "20:57", "21:02", "21:06", "21:16", "21:20", "21:25", "21:30", "21:35", "21:46", "21:51", "21:57", "22:08", "22:14", "22:21", "22:34", "22:41", "22:46", "22:52", "22:57", "23:04", "23:12", "23:20", "23:31", "23:42", "23:51", "24:05", "24:27"],
                                 ["04:38", "05:00", "05:23", "05:42", "05:52", "06:03", "06:12", "06:20", "06:30", "06:40", "06:48", "06:57", "07:03", "07:14", "07:19", "07:24", "07:29", "07:39", "07:44", "07:53", "07:59", "08:04", "08:09", "08:15", "08:20", "08:26", "08:32", "08:43", "08:53", "08:58", "09:03", "09:08", "09:17", "09:27", "09:32", "09:42", "09:48", "09:58", "10:08", "10:12", "10:21", "10:25", "10:31", "10:42", "10:47", "10:53", "10:58", "11:08", "11:13", "11:18", "11:28", "11:33", "11:38", "11:48", "11:53", "11:58", "12:08", "12:18", "12:28", "12:33", "12:38", "12:48", "12:53", "12:58", "13:08", "13:13", "13:18", "13:28", "13:33", "13:38", "13:48", "13:53", "13:58", "14:08", "14:13", "14:18", "14:28", "14:33", "14:38", "14:48", "14:53", "14:58", "15:08", "15:12", "15:15", "15:21", "15:31", "15:36", "15:41", "15:51", "15:56", "16:01", "16:11", "16:16", "16:21", "16:31", "16:41", "16:46", "16:51", "17:01", "17:06", "17:11", "17:21", "17:31", "17:36", "17:41", "17:51", "17:56", "18:01", "18:11", "18:16", "18:21", "18:31", "18:36", "18:41", "18:51", "19:02", "19:12", "19:17", "19:27", "19:34", "19:38", "19:49", "20:00", "20:06", "20:11", "20:22", "20:34", "20:40", "20:52", "20:59", "21:16", "21:24", "21:32", "21:40", "21:56", "22:04", "22:20", "22:40", "22:50", "22:59", "23:08", "23:21", "23:31", "23:41", "23:51", "24:04", "24:27"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Chiyoda.Ayase", .ascending,
                    "JR常磐線各駅停車", "JR Joban Local Line",
                    "取手方面", "for Toride",
                    to: "Railway:JR-East.JobanLocal"),
            through("Chiyoda.YoyogiUehara", .descending,
                    "小田急小田原線", "Odakyu Odawara Line",
                    "本厚木・伊勢原方面", "for Hon-Atsugi & Isehara",
                    to: "Railway:Odakyu.Odawara"),
        ]
    )

    // MARK: - Yurakucho Line (Y)

    static let yurakucho = StaticTrainLine(
        id: "Railway:TokyoMetro.Yurakucho",
        nameJa: "有楽町線",
        nameEn: "Yurakucho Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#C1A470",
        stations: [
            st("Yurakucho", "Wakoshi", "和光市", "Wakoshi", "Y01", 35.7887, 139.6122),
            st("Yurakucho", "ChikatetsuNarimasu", "地下鉄成増", "Chikatetsu-narimasu", "Y02", 35.7775, 139.6317),
            st("Yurakucho", "ChikatetsuAkatsuka", "地下鉄赤塚", "Chikatetsu-akatsuka", "Y03", 35.7709, 139.6447),
            st("Yurakucho", "Heiwadai", "平和台", "Heiwadai", "Y04", 35.7578, 139.6530),
            st("Yurakucho", "Hikawadai", "氷川台", "Hikawadai", "Y05", 35.7483, 139.6633),
            st("Yurakucho", "KotakeMukaihara", "小竹向原", "Kotake-mukaihara", "Y06", 35.7433, 139.6788),
            st("Yurakucho", "Senkawa", "千川", "Senkawa", "Y07", 35.7382, 139.6898),
            st("Yurakucho", "Kanamecho", "要町", "Kanamecho", "Y08", 35.7323, 139.6992),
            st("Yurakucho", "Ikebukuro", "池袋", "Ikebukuro", "Y09", 35.7292, 139.7125),
            st("Yurakucho", "HigashiIkebukuro", "東池袋", "Higashi-ikebukuro", "Y10", 35.7204, 139.7193),
            st("Yurakucho", "Gokokuji", "護国寺", "Gokokuji", "Y11", 35.7180, 139.7287),
            st("Yurakucho", "Edogawabashi", "江戸川橋", "Edogawabashi", "Y12", 35.7074, 139.7355),
            st("Yurakucho", "Iidabashi", "飯田橋", "Iidabashi", "Y13", 35.7018, 139.7452),
            st("Yurakucho", "Ichigaya", "市ケ谷", "Ichigaya", "Y14", 35.6912, 139.7360),
            st("Yurakucho", "Kojimachi", "麹町", "Kojimachi", "Y15", 35.6840, 139.7392),
            st("Yurakucho", "Nagatacho", "永田町", "Nagatacho", "Y16", 35.6787, 139.7413),
            st("Yurakucho", "Sakuradamon", "桜田門", "Sakuradamon", "Y17", 35.6770, 139.7517),
            st("Yurakucho", "Yurakucho", "有楽町", "Yurakucho", "Y18", 35.6746, 139.7630),
            st("Yurakucho", "GinzaItchome", "銀座一丁目", "Ginza-itchome", "Y19", 35.6741, 139.7668),
            st("Yurakucho", "Shintomicho", "新富町", "Shintomicho", "Y20", 35.6708, 139.7723),
            st("Yurakucho", "Tsukishima", "月島", "Tsukishima", "Y21", 35.6640, 139.7838),
            st("Yurakucho", "Toyosu", "豊洲", "Toyosu", "Y22", 35.6549, 139.7964),
            st("Yurakucho", "Tatsumi", "辰巳", "Tatsumi", "Y23", 35.6454, 139.8104),
            st("Yurakucho", "ShinKiba", "新木場", "Shin-kiba", "Y24", 35.6460, 139.8268),
        ],
        hopTimesMinutes: [
            3, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 3, 2, 1, 2, 2, 1, 2, 2, 2, 3, 3,
        ],
        directions: [
            // Last departure 23:46 is an Ikebukuro-bound through train from
            // the Tobu Tojo Line, on all calendars
            direction("Yurakucho", "ShinKiba", "新木場方面", "For Shin-kiba", ascending: true,
                      weekday: quietWeekday("05:00", "23:46"), holiday: quietHoliday("05:00", "23:46"),
                      origins: [
                          origin("Station:TokyoMetro.Yurakucho.KotakeMukaihara",
                                 ["05:03", "06:02", "06:32", "07:00", "07:19", "07:26", "07:37", "07:41", "07:53", "08:02", "08:08", "08:11", "08:22", "08:32", "08:38", "08:46", "08:56", "09:02", "09:29", "09:47", "10:13", "11:12", "11:18", "11:31", "11:48", "12:01", "12:18", "12:31", "12:48", "13:01", "13:18", "13:31", "13:48", "14:01", "14:18", "14:31", "14:48", "15:01", "15:18", "15:31", "15:48", "16:01", "16:11", "16:31", "16:50", "17:02", "17:12", "17:32", "17:41", "17:56", "18:05", "18:16", "18:31", "18:46", "19:04", "19:14", "19:25", "19:36", "19:43", "19:57", "20:07", "20:33", "20:47", "21:10", "21:15", "21:38", "21:44", "22:02", "22:07", "22:33", "22:47", "23:26"],
                                 ["05:03", "06:01", "06:17", "06:37", "06:49", "07:26", "07:41", "07:52", "08:08", "08:34", "08:57", "09:08", "09:37", "10:05", "10:26", "10:31", "10:47", "11:01", "11:18", "11:31", "11:42", "11:48", "12:01", "12:18", "12:31", "12:48", "13:01", "13:18", "13:31", "13:48", "14:01", "14:18", "14:31", "14:48", "15:01", "15:18", "15:31", "15:48", "16:01", "16:18", "16:31", "16:47", "17:01", "17:18", "17:31", "17:41", "17:56", "18:31", "18:43", "18:55", "19:47", "20:49", "21:17", "21:46", "22:11", "22:49", "23:15", "23:30", "23:44"]),
                          origin("Station:TokyoMetro.Yurakucho.Ikebukuro",
                                 ["05:00", "07:01", "07:47", "08:09", "08:45", "09:59"],
                                 ["05:00"]),
                          origin("Station:TokyoMetro.Yurakucho.Yurakucho",
                                 ["05:01"],
                                 ["05:01"])
                      ]
            ),
            direction("Yurakucho", "Wakoshi", "和光市方面", "For Wakoshi", ascending: false,
                      weekday: quietWeekday("05:00", "24:01"), holiday: quietHoliday("05:00", "24:01"),
                      origins: [
                          origin("Station:TokyoMetro.Yurakucho.Ichigaya",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:TokyoMetro.Yurakucho.Toyosu",
                                 ["17:29", "18:29", "19:29", "20:30", "21:30"],
                                 [])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Yurakucho.Wakoshi", .descending,
                    "東武東上線", "Tobu Tojo Line",
                    "川越市・森林公園方面", "for Kawagoeshi & Shinrin-Koen",
                    to: "Railway:Tobu.Tojo"),
            through("Yurakucho.KotakeMukaihara", .descending,
                    "西武有楽町線・池袋線", "Seibu Yurakucho & Ikebukuro Lines",
                    "所沢・飯能方面", "for Tokorozawa & Hanno",
                    to: "Railway:Seibu.SeibuYurakucho"),
        ]
    )

    // MARK: - Hanzomon Line (Z)

    static let hanzomon = StaticTrainLine(
        id: "Railway:TokyoMetro.Hanzomon",
        nameJa: "半蔵門線",
        nameEn: "Hanzomon Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#8B76D0",
        stations: [
            st("Hanzomon", "Shibuya", "渋谷", "Shibuya", "Z01", 35.6580, 139.7016),
            st("Hanzomon", "Omotesando", "表参道", "Omote-sando", "Z02", 35.6654, 139.7122),
            st("Hanzomon", "AoyamaItchome", "青山一丁目", "Aoyama-itchome", "Z03", 35.6726, 139.7244),
            st("Hanzomon", "Nagatacho", "永田町", "Nagatacho", "Z04", 35.6787, 139.7413),
            st("Hanzomon", "Hanzomon", "半蔵門", "Hanzomon", "Z05", 35.6852, 139.7413),
            st("Hanzomon", "Kudanshita", "九段下", "Kudanshita", "Z06", 35.6957, 139.7515),
            st("Hanzomon", "Jimbocho", "神保町", "Jimbocho", "Z07", 35.6958, 139.7578),
            st("Hanzomon", "Otemachi", "大手町", "Otemachi", "Z08", 35.6868, 139.7647),
            st("Hanzomon", "Mitsukoshimae", "三越前", "Mitsukoshimae", "Z09", 35.6866, 139.7730),
            st("Hanzomon", "Suitengumae", "水天宮前", "Suitengumae", "Z10", 35.6830, 139.7853),
            st("Hanzomon", "KiyosumiShirakawa", "清澄白河", "Kiyosumi-shirakawa", "Z11", 35.6816, 139.7994),
            st("Hanzomon", "Sumiyoshi", "住吉", "Sumiyoshi", "Z12", 35.6890, 139.8143),
            st("Hanzomon", "Kinshicho", "錦糸町", "Kinshicho", "Z13", 35.6967, 139.8140),
            st("Hanzomon", "Oshiage", "押上", "Oshiage 'SKYTREE'", "Z14", 35.7103, 139.8129),
        ],
        hopTimesMinutes: [
            2, 2, 3, 1, 2, 1, 2, 2, 2, 2, 3, 2, 3,
        ],
        directions: [
            direction("Hanzomon", "Oshiage", "押上方面", "For Oshiage", ascending: true,
                      weekday: quietWeekday("05:15", "24:12"), holiday: quietHoliday("05:15", "24:15"),
                      origins: [
                          origin("Station:TokyoMetro.Hanzomon.Hanzomon",
                                 ["05:08"],
                                 ["05:07"]),
                          origin("Station:TokyoMetro.Hanzomon.KiyosumiShirakawa",
                                 ["05:06"],
                                 ["05:06"])
                      ]
            ),
            direction("Hanzomon", "Shibuya", "渋谷方面", "For Shibuya", ascending: false,
                      weekday: quietWeekday("05:06", "24:18"), holiday: quietHoliday("05:06", "23:53"),
                      origins: [
                          origin("Station:TokyoMetro.Hanzomon.Hanzomon",
                                 ["07:38"],
                                 []),
                          origin("Station:TokyoMetro.Hanzomon.Suitengumae",
                                 ["05:02"],
                                 ["05:02"]),
                          origin("Station:TokyoMetro.Hanzomon.KiyosumiShirakawa",
                                 ["07:05", "07:30", "07:39", "07:45", "07:57", "08:06", "08:17", "08:27", "08:36"],
                                 []),
                          origin("Station:TokyoMetro.Hanzomon.Sumiyoshi",
                                 ["05:57", "17:52"],
                                 ["06:13"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Hanzomon.Shibuya", .descending,
                    "東急田園都市線", "Tokyu Den-en-toshi Line",
                    "中央林間方面", "for Chuo-Rinkan",
                    to: "Railway:Tokyu.DenEnToshi"),
            through("Hanzomon.Oshiage", .ascending,
                    "東武スカイツリーライン", "Tobu Skytree Line",
                    "久喜・南栗橋方面", "for Kuki & Minami-Kurihashi",
                    to: "Railway:Tobu.TobuSkytree"),
        ]
    )

    // MARK: - Namboku Line (N)

    static let namboku = StaticTrainLine(
        id: "Railway:TokyoMetro.Namboku",
        nameJa: "南北線",
        nameEn: "Namboku Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#00ADA9",
        stations: [
            st("Namboku", "Meguro", "目黒", "Meguro", "N01", 35.6340, 139.7157),
            st("Namboku", "Shirokanedai", "白金台", "Shirokanedai", "N02", 35.6376, 139.7263),
            st("Namboku", "ShirokaneTakanawa", "白金高輪", "Shirokane-takanawa", "N03", 35.6431, 139.7343),
            st("Namboku", "AzabuJuban", "麻布十番", "Azabu-juban", "N04", 35.6544, 139.7368),
            st("Namboku", "RoppongiItchome", "六本木一丁目", "Roppongi-itchome", "N05", 35.6635, 139.7392),
            st("Namboku", "TameikeSanno", "溜池山王", "Tameike-sanno", "N06", 35.6739, 139.7413),
            st("Namboku", "Nagatacho", "永田町", "Nagatacho", "N07", 35.6787, 139.7413),
            st("Namboku", "Yotsuya", "四ツ谷", "Yotsuya", "N08", 35.6857, 139.7292),
            st("Namboku", "Ichigaya", "市ケ谷", "Ichigaya", "N09", 35.6912, 139.7360),
            st("Namboku", "Iidabashi", "飯田橋", "Iidabashi", "N10", 35.7018, 139.7452),
            st("Namboku", "Korakuen", "後楽園", "Korakuen", "N11", 35.7080, 139.7512),
            st("Namboku", "Todaimae", "東大前", "Todaimae", "N12", 35.7175, 139.7578),
            st("Namboku", "HonKomagome", "本駒込", "Hon-komagome", "N13", 35.7245, 139.7540),
            st("Namboku", "Komagome", "駒込", "Komagome", "N14", 35.7365, 139.7460),
            st("Namboku", "Nishigahara", "西ケ原", "Nishigahara", "N15", 35.7419, 139.7393),
            st("Namboku", "Oji", "王子", "Oji", "N16", 35.7526, 139.7380),
            st("Namboku", "OjiKamiya", "王子神谷", "Oji-kamiya", "N17", 35.7645, 139.7420),
            st("Namboku", "Shimo", "志茂", "Shimo", "N18", 35.7736, 139.7305),
            st("Namboku", "AkabaneIwabuchi", "赤羽岩淵", "Akabane-iwabuchi", "N19", 35.7830, 139.7218),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        ],
        directions: [
            direction("Namboku", "AkabaneIwabuchi", "赤羽岩淵方面", "For Akabane-iwabuchi", ascending: true,
                      weekday: quietWeekday("05:16", "23:59"), holiday: quietHoliday("05:16", "23:59"),
                      origins: [
                          origin("Station:TokyoMetro.Namboku.ShirokaneTakanawa",
                                 ["05:07", "05:34", "08:18", "08:37", "08:53", "09:01", "09:13", "09:23", "09:31", "09:42", "09:53", "10:06", "10:11", "10:21", "10:33", "10:39", "10:51", "11:03", "11:09", "11:33", "11:39", "12:03", "12:09", "12:33", "12:39", "13:03", "13:09", "13:33", "13:39", "14:03", "14:09", "14:33", "14:39", "15:03", "15:09", "15:33", "15:39", "16:03", "16:09", "16:33", "16:39", "17:04", "17:10", "17:49", "18:14", "18:44", "18:58", "19:13", "19:28", "19:58", "20:27", "20:48", "20:56", "21:29", "21:49", "22:15", "22:30", "22:43", "22:50", "23:15", "23:29", "23:36", "24:00"],
                                 ["05:07", "05:34", "06:06", "06:37", "06:46", "07:21", "07:28", "07:34", "08:09", "08:30", "08:40", "08:45", "08:55", "09:05", "09:14", "09:33", "09:39", "10:03", "10:09", "10:33", "10:39", "11:03", "11:09", "11:33", "11:39", "12:03", "12:09", "12:33", "12:39", "13:03", "13:09", "13:33", "13:39", "14:03", "14:09", "14:33", "14:39", "15:03", "15:09", "15:33", "15:39", "16:03", "16:09", "16:33", "16:39", "17:03", "17:09", "17:33", "17:39", "18:03", "18:09", "18:33", "18:39", "19:03", "19:09", "19:23", "19:43", "19:56", "20:25", "20:47", "21:11", "21:40", "22:03", "22:19", "22:33", "22:48", "22:55", "23:13", "23:22", "23:46", "23:55"]),
                          origin("Station:TokyoMetro.Namboku.AzabuJuban",
                                 ["09:01", "09:18"],
                                 []),
                          origin("Station:TokyoMetro.Namboku.Ichigaya",
                                 ["05:03", "06:10", "07:05", "07:15"],
                                 ["05:03"]),
                          origin("Station:TokyoMetro.Namboku.OjiKamiya",
                                 ["05:09"],
                                 ["05:09"])
                      ]
            ),
            direction("Namboku", "Meguro", "目黒方面", "For Meguro", ascending: false,
                      weekday: quietWeekday("05:01", "24:26"), holiday: quietHoliday("05:01", "24:16"),
                      origins: [
                          origin("Station:TokyoMetro.Namboku.TameikeSanno",
                                 ["05:03"],
                                 ["05:03"]),
                          origin("Station:TokyoMetro.Namboku.Komagome",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:TokyoMetro.Namboku.OjiKamiya",
                                 ["06:34", "08:13", "16:48", "17:33", "18:31"],
                                 ["07:31", "07:47"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Namboku.AkabaneIwabuchi", .ascending,
                    "埼玉高速鉄道線", "Saitama Rapid Railway Line",
                    "浦和美園方面", "for Urawa-Misono",
                    to: "Railway:SaitamaRailway.SaitamaRailway"),
            through("Namboku.Meguro", .descending,
                    "東急目黒線・新横浜線", "Tokyu Meguro & Shin-Yokohama Lines",
                    "日吉・新横浜方面", "for Hiyoshi & Shin-Yokohama",
                    to: "Railway:Tokyu.Meguro"),
        ]
    )

    // MARK: - Fukutoshin Line (F)

    static let fukutoshin = StaticTrainLine(
        id: "Railway:TokyoMetro.Fukutoshin",
        nameJa: "副都心線",
        nameEn: "Fukutoshin Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#9C5E31",
        stations: [
            st("Fukutoshin", "Wakoshi", "和光市", "Wakoshi", "F01", 35.7887, 139.6122),
            st("Fukutoshin", "ChikatetsuNarimasu", "地下鉄成増", "Chikatetsu-narimasu", "F02", 35.7775, 139.6317),
            st("Fukutoshin", "ChikatetsuAkatsuka", "地下鉄赤塚", "Chikatetsu-akatsuka", "F03", 35.7709, 139.6447),
            st("Fukutoshin", "Heiwadai", "平和台", "Heiwadai", "F04", 35.7578, 139.6530),
            st("Fukutoshin", "Hikawadai", "氷川台", "Hikawadai", "F05", 35.7483, 139.6633),
            st("Fukutoshin", "KotakeMukaihara", "小竹向原", "Kotake-mukaihara", "F06", 35.7433, 139.6788),
            st("Fukutoshin", "Senkawa", "千川", "Senkawa", "F07", 35.7382, 139.6898),
            st("Fukutoshin", "Kanamecho", "要町", "Kanamecho", "F08", 35.7323, 139.6992),
            st("Fukutoshin", "Ikebukuro", "池袋", "Ikebukuro", "F09", 35.7296, 139.7100),
            st("Fukutoshin", "Zoshigaya", "雑司が谷", "Zoshigaya", "F10", 35.7205, 139.7147),
            st("Fukutoshin", "NishiWaseda", "西早稲田", "Nishi-waseda", "F11", 35.7084, 139.7093),
            st("Fukutoshin", "HigashiShinjuku", "東新宿", "Higashi-shinjuku", "F12", 35.6983, 139.7073),
            st("Fukutoshin", "ShinjukuSanchome", "新宿三丁目", "Shinjuku-sanchome", "F13", 35.6909, 139.7047),
            st("Fukutoshin", "KitaSando", "北参道", "Kita-sando", "F14", 35.6790, 139.7048),
            st("Fukutoshin", "MeijiJingumae", "明治神宮前", "Meiji-jingumae 'Harajuku'", "F15", 35.6685, 139.7063),
            st("Fukutoshin", "Shibuya", "渋谷", "Shibuya", "F16", 35.6580, 139.7016),
        ],
        hopTimesMinutes: [
            3, 2, 2, 2, 2, 2, 1, 2, 3, 2, 2, 2, 2, 2, 3,
        ],
        directions: [
            direction("Fukutoshin", "Shibuya", "渋谷方面", "For Shibuya", ascending: true,
                      weekday: quietWeekday("05:05", "23:55"), holiday: quietHoliday("05:05", "23:55"),
                      origins: [
                          origin("Station:TokyoMetro.Fukutoshin.KotakeMukaihara",
                                 ["05:00", "06:16", "06:50", "07:12", "07:33", "07:45", "07:47", "08:00", "08:14", "08:17", "08:30", "08:43", "08:52", "09:13", "09:16", "09:21", "09:36", "09:56", "10:05", "10:16", "10:22", "10:31", "10:41", "10:46", "10:52", "11:01", "11:22", "11:41", "11:52", "12:11", "12:22", "12:41", "12:52", "13:11", "13:22", "13:41", "13:52", "14:11", "14:22", "14:41", "14:52", "15:11", "15:22", "15:41", "15:55", "16:16", "16:25", "16:37", "16:55", "17:19", "17:27", "17:46", "18:13", "18:26", "18:41", "18:56", "19:21", "19:50", "20:12", "20:21", "20:27", "20:44", "20:57", "21:31", "22:17", "23:02", "23:20", "23:45", "23:54"],
                                 ["05:00", "07:01", "07:17", "07:30", "08:00", "08:15", "08:21", "08:41", "08:52", "09:16", "09:22", "09:31", "09:43", "09:51", "09:54", "10:11", "10:16", "10:22", "10:41", "10:52", "11:11", "11:22", "11:52", "12:11", "12:22", "12:41", "12:52", "13:11", "13:22", "13:41", "13:52", "14:11", "14:22", "14:41", "14:52", "15:11", "15:22", "15:41", "15:52", "16:09", "16:22", "16:41", "16:52", "17:11", "17:22", "17:48", "18:01", "18:12", "18:16", "18:22", "19:01", "19:07", "19:11", "19:17", "19:31", "19:37", "19:51", "20:01", "20:07", "20:17", "20:31", "20:37", "20:57", "21:11", "21:30", "21:36", "21:55", "22:25", "22:31", "23:00", "23:53"]),
                          origin("Station:TokyoMetro.Fukutoshin.Senkawa",
                                 ["08:27", "08:50"],
                                 []),
                          origin("Station:TokyoMetro.Fukutoshin.Ikebukuro",
                                 ["09:15", "11:32", "12:02", "12:32", "13:02", "13:32", "14:02", "14:32", "15:02", "15:34", "16:04", "16:50", "17:28"],
                                 ["08:35", "09:05", "09:46", "10:30", "11:02", "11:32", "12:02", "12:32", "13:02", "13:32", "14:02", "14:32", "15:02", "15:32", "16:02", "16:20", "16:44", "17:50", "18:16", "18:34", "19:15"]),
                          origin("Station:TokyoMetro.Fukutoshin.ShinjukuSanchome",
                                 ["05:07", "07:08", "07:23", "07:38", "08:06", "08:17", "08:31", "08:46", "09:14", "10:14", "17:15", "17:29", "17:55", "18:15", "18:39", "18:54", "19:25", "19:55", "20:25", "20:55", "21:25"],
                                 ["05:07", "07:43"])
                      ,
                          originRuns("Station:TokyoMetro.Fukutoshin.KotakeMukaihara",
                                     fukutoshinAscExpressWd_org5, fukutoshinAscExpressHol_org5)
                      ],
                      expressWeekday: fukutoshinAscExpressWd,
                      expressHoliday: fukutoshinAscExpressHol
            ),
            direction("Fukutoshin", "Wakoshi", "和光市方面", "For Wakoshi", ascending: false,
                      weekday: quietWeekday("05:05", "24:20"), holiday: quietHoliday("05:05", "24:20"),
                      expressWeekday: fukutoshinDescExpressWd,
                      expressHoliday: fukutoshinDescExpressHol),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Fukutoshin.Shibuya", .ascending,
                    "東急東横線・みなとみらい線", "Tokyu Toyoko & Minatomirai Lines",
                    "横浜・元町・中華街方面", "for Yokohama & Motomachi-Chukagai",
                    to: "Railway:Tokyu.Toyoko"),
            through("Fukutoshin.Wakoshi", .descending,
                    "東武東上線", "Tobu Tojo Line",
                    "川越市・森林公園方面", "for Kawagoeshi & Shinrin-Koen",
                    to: "Railway:Tobu.Tojo"),
            through("Fukutoshin.KotakeMukaihara", .descending,
                    "西武有楽町線・池袋線", "Seibu Yurakucho & Ikebukuro Lines",
                    "所沢・飯能方面", "for Tokorozawa & Hanno",
                    to: "Railway:Seibu.SeibuYurakucho"),
        ]
    )

    // MARK: - Tozai Express Runs (ODPT, July-2026)

private static let tozaiAscExpressHol: [ExactRun] = [
    ExactRun("08:40", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("08:56", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("09:14", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("09:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("09:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("09:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("10:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("10:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("10:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("10:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("11:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("11:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("11:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("11:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("12:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("12:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("12:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("12:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("13:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("13:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("13:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("13:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("14:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("14:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("14:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("14:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("15:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("15:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("15:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("15:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("16:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("16:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("16:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("16:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("17:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("17:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("17:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("17:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("18:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("18:29", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("18:44", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("19:00", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("19:20", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("19:40", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("20:02", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("20:31", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("21:00", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("21:30", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
]
private static let tozaiAscExpressWd: [ExactRun] = [
    ExactRun("06:05", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("06:26", startsHere: false, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("06:46", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("06:57", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("07:10", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("07:20", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("07:29", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("07:36", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("07:45", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("07:56", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("08:07", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("08:18", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("08:26", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("08:33", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("08:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("08:54", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("09:08", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("09:20", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("09:32", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("09:42", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("09:51", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("10:05", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("10:15", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("10:30", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("10:44", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("10:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("11:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("11:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("11:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("11:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("12:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("12:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("12:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("12:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("13:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("13:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("13:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("13:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("14:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("14:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("14:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("14:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("15:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("15:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("15:43", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("15:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("16:12", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("16:32", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("16:45", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("17:02", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("17:11", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("17:22", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("17:31", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("17:40", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("17:53", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("18:02", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("18:11", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("18:19", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("18:31", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("18:41", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("18:47", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("19:00", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("19:12", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("19:23", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("19:33", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("19:47", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("19:58", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("20:12", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("20:22", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("20:35", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("20:47", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("21:01", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("21:13", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("21:23", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("21:35", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("21:47", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("21:59", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("22:12", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("22:28", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("22:47", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
    ExactRun("23:07", continuesBeyond: true, trainType: .rapid, stopIndices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 22]),
]
private static let tozaiDescExpressHol: [ExactRun] = [
    ExactRun("07:56", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:16", trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:40", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:52", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:09", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("11:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("11:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("11:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("11:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("12:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("12:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("12:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("12:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("13:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("13:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("13:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("13:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("14:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("14:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("14:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("14:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("15:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("15:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("15:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("15:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("16:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("16:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("16:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("16:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:55", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:13", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:35", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:57", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("20:26", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("20:57", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
]
private static let tozaiDescExpressWd: [ExactRun] = [
    ExactRun("06:32", startsHere: false, continuesBeyond: true, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("06:41", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("06:45", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("06:54", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:02", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:11", startsHere: false, continuesBeyond: true, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:19", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:27", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:32", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:37", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:42", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:49", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:55", startsHere: false, continuesBeyond: true, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:00", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:09", startsHere: false, continuesBeyond: true, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:17", startsHere: false, continuesBeyond: true, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:24", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:32", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:42", startsHere: false, continuesBeyond: true, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:47", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:55", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:08", startsHere: false, trainType: .commuterRapid, stopIndices: [22, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:18", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:30", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:42", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:54", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("11:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("11:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("11:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("11:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("12:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("12:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("12:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("12:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("13:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("13:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("13:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("13:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("14:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("14:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("14:38", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("14:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("15:08", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("15:23", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("15:38", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("15:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("16:11", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("16:20", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("16:37", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("16:54", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:07", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:19", trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:35", trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:46", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:58", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:08", trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:26", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:43", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:53", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:06", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:18", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:30", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:44", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:55", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("20:09", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("20:22", startsHere: false, continuesBeyond: true, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("20:34", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("20:47", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("21:01", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("21:16", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("21:32", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("21:49", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("22:09", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("22:28", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ExactRun("22:52", startsHere: false, trainType: .rapid, stopIndices: [22, 17, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
]

    // MARK: - Fukutoshin Express Runs (ODPT, July-2026)

private static let fukutoshinAscExpressHol: [ExactRun] = [
    ExactRun("05:41", continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("06:11", continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("06:31", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("06:45", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("07:25", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("07:38", continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("07:55", continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("08:27", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("08:55", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("09:25", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("09:55", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("10:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("10:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("11:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("11:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("12:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("12:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("13:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("13:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("14:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("14:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("15:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("15:54", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("16:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("16:54", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("17:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("17:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("18:23", continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("18:45", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("19:15", continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("19:46", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("20:10", continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("20:52", continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("21:39", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("21:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("22:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
]
private static let fukutoshinAscExpressHol_org5: [ExactRun] = [
    ExactRun("07:17", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("08:21", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("08:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("09:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("09:51", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("10:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("10:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("11:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("11:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("12:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("12:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("13:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("13:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("14:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("14:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("15:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("15:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("16:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("16:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("17:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("17:48", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("18:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("19:07", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("19:37", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("20:07", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("20:37", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("20:57", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("21:36", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
]
private static let fukutoshinAscExpressWd: [ExactRun] = [
    ExactRun("06:21", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("06:42", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("07:15", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("07:23", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("07:37", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("07:53", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("08:08", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("08:27", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("08:53", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("09:37", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("09:53", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("10:24", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("10:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("11:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("11:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("12:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("12:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("13:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("13:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("14:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("14:56", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("15:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("15:59", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [0, 5, 8, 12, 14, 15]),
    ExactRun("16:29", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("16:58", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("17:28", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("17:43", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("17:59", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("18:36", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("18:59", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("19:15", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("19:27", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("19:44", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("20:29", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("20:59", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("21:14", continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("21:29", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("21:54", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
    ExactRun("22:30", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [0, 1, 2, 3, 4, 5, 8, 12, 14, 15]),
]
private static let fukutoshinAscExpressWd_org5: [ExactRun] = [
    ExactRun("06:16", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("06:50", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("07:12", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("07:45", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("08:00", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("08:14", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("08:30", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("08:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("09:21", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("09:36", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("10:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("10:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("11:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("11:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("12:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("12:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("13:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("13:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("14:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("14:52", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("15:22", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("15:55", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("16:25", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("16:55", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("17:27", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("18:26", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("18:41", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("20:12", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("20:27", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
    ExactRun("20:57", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [5, 8, 12, 14, 15]),
]
private static let fukutoshinDescExpressHol: [ExactRun] = [
    ExactRun("06:12", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("06:41", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("07:11", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("07:26", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("07:41", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("07:55", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("08:11", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("08:41", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("08:56", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("09:11", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("09:26", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("09:41", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("09:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("10:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("10:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("10:40", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("10:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("11:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("11:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("11:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("11:56", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("12:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("12:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("12:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("12:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("13:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("13:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("13:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("13:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("14:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("14:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("14:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("14:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("15:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("15:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("15:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("15:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("16:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("16:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("16:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("16:56", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("17:26", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("17:41", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("17:57", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("18:14", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("18:27", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("18:42", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("18:57", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("19:12", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("19:27", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("19:42", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("19:57", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("20:12", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("20:42", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("21:12", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("21:42", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("22:08", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("22:42", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
]
private static let fukutoshinDescExpressWd: [ExactRun] = [
    ExactRun("06:12", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("06:29", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("06:48", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:00", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:32", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:42", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("07:57", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:08", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:13", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:23", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("08:28", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:38", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("08:43", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("08:48", terminusStationId: "Station:TokyoMetro.Fukutoshin.Ikebukuro", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8]),
    ExactRun("08:58", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("09:19", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:33", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("09:47", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:00", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:11", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("10:26", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("10:41", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("10:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("11:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("11:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("11:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("11:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("12:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("12:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("12:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("12:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("13:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("13:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("13:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("13:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("14:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("14:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("14:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("14:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("15:10", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("15:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("15:40", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("15:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("16:11", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("16:25", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("16:40", startsHere: false, trainType: .express, stopIndices: [15, 14, 12, 8, 5, 0]),
    ExactRun("16:55", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("17:11", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:21", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("17:37", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("17:52", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:07", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("18:22", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("18:37", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("18:52", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("19:07", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("19:22", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("19:37", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("19:52", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("20:07", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("20:22", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("20:37", terminusStationId: "Station:TokyoMetro.Fukutoshin.KotakeMukaihara", startsHere: false, continuesBeyond: true, trainType: .express, stopIndices: [15, 14, 12, 8, 5]),
    ExactRun("20:52", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("21:12", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("21:22", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("21:37", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("22:06", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("22:52", startsHere: false, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
    ExactRun("23:21", startsHere: false, continuesBeyond: true, trainType: .commuterExpress, stopIndices: [15, 14, 12, 8, 5, 4, 3, 2, 1, 0]),
]
}
