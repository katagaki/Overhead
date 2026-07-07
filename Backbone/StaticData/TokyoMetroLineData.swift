import Foundation

// MARK: - Tokyo Metro Line Data

private func st(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "odpt.Station:TokyoMetro.\(line).\(suffix)",
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
                       weekday: ServicePattern, holiday: ServicePattern) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:TokyoMetro.\(line).\(suffix)",
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
        junctionStationId: "odpt.Station:TokyoMetro.\(junction)",
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

    // MARK: - Ginza Line (G)

    static let ginza = StaticTrainLine(
        id: "odpt.Railway:TokyoMetro.Ginza",
        nameJa: "銀座線",
        nameEn: "Ginza Line",
        operatorId: "odpt.Operator:TokyoMetro",
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
                      weekday: metroWeekday("05:01", "24:02"), holiday: metroHoliday("05:01", "24:02")),
            direction("Ginza", "Shibuya", "渋谷方面", "For Shibuya", ascending: false,
                      weekday: metroWeekday("05:01", "24:10"), holiday: metroHoliday("05:01", "24:14")),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Marunouchi Line (M)

    static let marunouchi = StaticTrainLine(
        id: "odpt.Railway:TokyoMetro.Marunouchi",
        nameJa: "丸ノ内線",
        nameEn: "Marunouchi Line",
        operatorId: "odpt.Operator:TokyoMetro",
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
                      weekday: metroWeekday("05:01", "24:11"), holiday: metroHoliday("05:01", "24:11")),
            direction("Marunouchi", "Ogikubo", "荻窪方面", "For Ogikubo", ascending: false,
                      weekday: metroWeekday("05:00", "24:20"), holiday: metroHoliday("05:00", "24:20")),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Marunouchi Line Honancho Branch (Mb)

    static let marunouchiBranch = StaticTrainLine(
        id: "odpt.Railway:TokyoMetro.MarunouchiBranch",
        nameJa: "丸ノ内線(方南町支線)",
        nameEn: "Marunouchi Line Honancho Branch",
        operatorId: "odpt.Operator:TokyoMetro",
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
                      ])),
            direction("MarunouchiBranch", "Honancho", "方南町方面", "For Honancho", ascending: false,
                      weekday: pattern("05:09", "24:26", [
                          ("05:09", 9), ("07:00", 8.5), ("09:30", 10), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:09", "24:26", [
                          ("05:09", 10), ("10:00", 10), ("22:00", 12),
                      ])),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Hibiya Line (H)

    static let hibiya = StaticTrainLine(
        id: "odpt.Railway:TokyoMetro.Hibiya",
        nameJa: "日比谷線",
        nameEn: "Hibiya Line",
        operatorId: "odpt.Operator:TokyoMetro",
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
                      weekday: metroWeekday("05:00", "24:28"), holiday: metroHoliday("05:00", "24:28")),
            direction("Hibiya", "NakaMeguro", "中目黒方面", "For Naka-meguro", ascending: false,
                      weekday: metroWeekday("05:00", "24:28"), holiday: metroHoliday("05:00", "24:27")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Hibiya.KitaSenju", .ascending,
                    "東武スカイツリーライン", "Tobu Skytree Line",
                    "東武動物公園・南栗橋方面", "for Tobu-Dobutsu-Koen & Minami-Kurihashi",
                    to: "odpt.Railway:Tobu.TobuSkytree"),
        ]
    )

    // MARK: - Tozai Line (T)

    static let tozai = StaticTrainLine(
        id: "odpt.Railway:TokyoMetro.Tozai",
        nameJa: "東西線",
        nameEn: "Tozai Line",
        operatorId: "odpt.Operator:TokyoMetro",
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
                      holiday: metroHoliday("05:00", "23:52")),
            direction("Tozai", "Nakano", "中野方面", "For Nakano", ascending: false,
                      weekday: pattern("05:00", "24:09", [
                          ("05:00", 6), ("07:00", 2.5), ("09:30", 5), ("17:00", 3), ("20:00", 5), ("22:00", 6.5),
                      ]),
                      holiday: metroHoliday("05:00", "24:09")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Tozai.Nakano", .descending,
                    "JR中央・総武線各駅停車", "JR Chuo-Sobu Local Line",
                    "三鷹方面", "for Mitaka",
                    to: "odpt.Railway:JR-East.ChuoSobuLocal"),
            through("Tozai.NishiFunabashi", .ascending,
                    "東葉高速線", "Toyo Rapid Line",
                    "東葉勝田台方面", "for Toyo-Katsutadai"),
            through("Tozai.NishiFunabashi", .ascending,
                    "JR総武線各駅停車", "JR Sobu Local Line",
                    "津田沼方面", "for Tsudanuma",
                    to: "odpt.Railway:JR-East.ChuoSobuLocal"),
        ]
    )

    // MARK: - Chiyoda Line (C)

    static let chiyoda = StaticTrainLine(
        id: "odpt.Railway:TokyoMetro.Chiyoda",
        nameJa: "千代田線",
        nameEn: "Chiyoda Line",
        operatorId: "odpt.Operator:TokyoMetro",
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
                      weekday: metroWeekday("05:00", "24:00"), holiday: metroHoliday("05:00", "23:55")),
            direction("Chiyoda", "YoyogiUehara", "代々木上原方面", "For Yoyogi-uehara", ascending: false,
                      weekday: metroWeekday("05:00", "24:15"), holiday: metroHoliday("05:00", "24:13")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Chiyoda.Ayase", .ascending,
                    "JR常磐線各駅停車", "JR Joban Local Line",
                    "取手方面", "for Toride",
                    to: "odpt.Railway:JR-East.JobanLocal"),
            through("Chiyoda.YoyogiUehara", .descending,
                    "小田急小田原線", "Odakyu Odawara Line",
                    "本厚木・伊勢原方面", "for Hon-Atsugi & Isehara",
                    to: "odpt.Railway:Odakyu.Odawara"),
        ]
    )

    // MARK: - Yurakucho Line (Y)

    static let yurakucho = StaticTrainLine(
        id: "odpt.Railway:TokyoMetro.Yurakucho",
        nameJa: "有楽町線",
        nameEn: "Yurakucho Line",
        operatorId: "odpt.Operator:TokyoMetro",
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
            direction("Yurakucho", "ShinKiba", "新木場方面", "For Shin-kiba", ascending: true,
                      weekday: quietWeekday("05:00", "23:40"), holiday: quietHoliday("05:00", "23:23")),
            direction("Yurakucho", "Wakoshi", "和光市方面", "For Wakoshi", ascending: false,
                      weekday: quietWeekday("05:00", "24:01"), holiday: quietHoliday("05:00", "24:01")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Yurakucho.Wakoshi", .descending,
                    "東武東上線", "Tobu Tojo Line",
                    "川越市・森林公園方面", "for Kawagoeshi & Shinrin-Koen",
                    to: "odpt.Railway:Tobu.Tojo"),
            through("Yurakucho.KotakeMukaihara", .descending,
                    "西武有楽町線・池袋線", "Seibu Yurakucho & Ikebukuro Lines",
                    "所沢・飯能方面", "for Tokorozawa & Hanno"),
        ]
    )

    // MARK: - Hanzomon Line (Z)

    static let hanzomon = StaticTrainLine(
        id: "odpt.Railway:TokyoMetro.Hanzomon",
        nameJa: "半蔵門線",
        nameEn: "Hanzomon Line",
        operatorId: "odpt.Operator:TokyoMetro",
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
                      weekday: quietWeekday("05:15", "24:12"), holiday: quietHoliday("05:15", "24:15")),
            direction("Hanzomon", "Shibuya", "渋谷方面", "For Shibuya", ascending: false,
                      weekday: quietWeekday("05:06", "24:18"), holiday: quietHoliday("05:06", "23:53")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Hanzomon.Shibuya", .descending,
                    "東急田園都市線", "Tokyu Den-en-toshi Line",
                    "中央林間方面", "for Chuo-Rinkan"),
            through("Hanzomon.Oshiage", .ascending,
                    "東武スカイツリーライン", "Tobu Skytree Line",
                    "久喜・南栗橋方面", "for Kuki & Minami-Kurihashi",
                    to: "odpt.Railway:Tobu.TobuSkytree"),
        ]
    )

    // MARK: - Namboku Line (N)

    static let namboku = StaticTrainLine(
        id: "odpt.Railway:TokyoMetro.Namboku",
        nameJa: "南北線",
        nameEn: "Namboku Line",
        operatorId: "odpt.Operator:TokyoMetro",
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
                      weekday: quietWeekday("05:16", "24:00"), holiday: quietHoliday("05:16", "24:00")),
            direction("Namboku", "Meguro", "目黒方面", "For Meguro", ascending: false,
                      weekday: quietWeekday("05:01", "24:26"), holiday: quietHoliday("05:01", "24:16")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Namboku.AkabaneIwabuchi", .ascending,
                    "埼玉高速鉄道線", "Saitama Rapid Railway Line",
                    "浦和美園方面", "for Urawa-Misono"),
            through("Namboku.Meguro", .descending,
                    "東急目黒線・新横浜線", "Tokyu Meguro & Shin-Yokohama Lines",
                    "日吉・新横浜方面", "for Hiyoshi & Shin-Yokohama"),
        ]
    )

    // MARK: - Fukutoshin Line (F)

    static let fukutoshin = StaticTrainLine(
        id: "odpt.Railway:TokyoMetro.Fukutoshin",
        nameJa: "副都心線",
        nameEn: "Fukutoshin Line",
        operatorId: "odpt.Operator:TokyoMetro",
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
                      weekday: quietWeekday("05:05", "23:55"), holiday: quietHoliday("05:05", "23:55")),
            direction("Fukutoshin", "Wakoshi", "和光市方面", "For Wakoshi", ascending: false,
                      weekday: quietWeekday("05:05", "24:20"), holiday: quietHoliday("05:05", "24:20")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Fukutoshin.Shibuya", .ascending,
                    "東急東横線・みなとみらい線", "Tokyu Toyoko & Minatomirai Lines",
                    "横浜・元町・中華街方面", "for Yokohama & Motomachi-Chukagai"),
            through("Fukutoshin.Wakoshi", .descending,
                    "東武東上線", "Tobu Tojo Line",
                    "川越市・森林公園方面", "for Kawagoeshi & Shinrin-Koen",
                    to: "odpt.Railway:Tobu.Tojo"),
            through("Fukutoshin.KotakeMukaihara", .descending,
                    "西武有楽町線・池袋線", "Seibu Yurakucho & Ikebukuro Lines",
                    "所沢・飯能方面", "for Tokorozawa & Hanno"),
        ]
    )
}
