import Foundation

// MARK: - Tokyu Line Data

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
        junctionStationId: "Station:\(junction)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

enum TokyuLineData {

    // MARK: Delay Check

    // Delays of 15+ minutes are posted on the Tokyu Train Operation Information page
    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.tokyu.co.jp/unten2/unten.html",
        statusPageURLEn: "https://www.tokyu.co.jp/global/",
        xAccount: "@tokyu_official",
        checkMethodJa: "東急電鉄「運行情報」ページ、東急線アプリ、またはX（@tokyu_official）で確認できます。15分以上の遅れ・運転見合わせが発生または見込まれる場合に掲載されます。",
        checkMethodEn: "Check the Tokyu train operation information page, the Tokyu Lines app, or X (@tokyu_official). Delays or suspensions of 15 minutes or more are posted."
    )

    static let lines: [StaticTrainLine] = [
        toyoko, denentoshi, meguro,
    ]

    // MARK: - Tokyu Toyoko Line (TY)

    static let toyoko = StaticTrainLine(
        id: "Railway:Tokyu.Toyoko",
        nameJa: "東急東横線",
        nameEn: "Tokyu Toyoko Line",
        operatorId: "Operator:Tokyu",
        colorHex: "#DA0442",
        stations: [
            st("Tokyu.Toyoko", "Shibuya", "渋谷", "Shibuya", "TY01", 35.6580, 139.7016),
            st("Tokyu.Toyoko", "Daikanyama", "代官山", "Daikanyama", "TY02", 35.6485, 139.7030),
            st("Tokyu.Toyoko", "Nakameguro", "中目黒", "Nakameguro", "TY03", 35.6440, 139.6990),
            st("Tokyu.Toyoko", "Yutenji", "祐天寺", "Yutenji", "TY04", 35.6404, 139.6934),
            st("Tokyu.Toyoko", "GakugeiDaigaku", "学芸大学", "Gakugei-daigaku", "TY05", 35.6280, 139.6855),
            st("Tokyu.Toyoko", "ToritsuDaigaku", "都立大学", "Toritsu-daigaku", "TY06", 35.6237, 139.6852),
            st("Tokyu.Toyoko", "Jiyugaoka", "自由が丘", "Jiyugaoka", "TY07", 35.6076, 139.6690),
            st("Tokyu.Toyoko", "DenenChofu", "田園調布", "Den-en-chofu", "TY08", 35.5990, 139.6660),
            st("Tokyu.Toyoko", "Tamagawa", "多摩川", "Tamagawa", "TY09", 35.5920, 139.6660),
            st("Tokyu.Toyoko", "ShinMaruko", "新丸子", "Shin-maruko", "TY10", 35.5810, 139.6595),
            st("Tokyu.Toyoko", "MusashiKosugi", "武蔵小杉", "Musashi-Kosugi", "TY11", 35.5766, 139.6597),
            st("Tokyu.Toyoko", "Motosumiyoshi", "元住吉", "Motosumiyoshi", "TY12", 35.5680, 139.6510),
            st("Tokyu.Toyoko", "Hiyoshi", "日吉", "Hiyoshi", "TY13", 35.5540, 139.6470),
            st("Tokyu.Toyoko", "Tsunashima", "綱島", "Tsunashima", "TY14", 35.5350, 139.6330),
            st("Tokyu.Toyoko", "Okurayama", "大倉山", "Okurayama", "TY15", 35.5240, 139.6300),
            st("Tokyu.Toyoko", "Kikuna", "菊名", "Kikuna", "TY16", 35.5093, 139.6303),
            st("Tokyu.Toyoko", "Myorenji", "妙蓮寺", "Myorenji", "TY17", 35.5020, 139.6260),
            st("Tokyu.Toyoko", "Hakuraku", "白楽", "Hakuraku", "TY18", 35.4930, 139.6250),
            st("Tokyu.Toyoko", "HigashiHakuraku", "東白楽", "Higashi-hakuraku", "TY19", 35.4870, 139.6250),
            st("Tokyu.Toyoko", "Tammachi", "反町", "Tammachi", "TY20", 35.4770, 139.6260),
            st("Tokyu.Toyoko", "Yokohama", "横浜", "Yokohama", "TY21", 35.4657, 139.6224),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        ],
        directions: [
            direction("Tokyu.Toyoko", "Yokohama", "横浜・元町・中華街方面", "For Yokohama & Motomachi-Chukagai",
                      ascending: true,
                      weekday: pattern("05:00", "24:21", [
                          ("05:00", 7), ("06:30", 4), ("09:30", 5), ("16:30", 4), ("20:00", 5), ("22:00", 7),
                      ]),
                      holiday: pattern("05:00", "24:21", [
                          ("05:00", 7), ("07:00", 5), ("10:00", 5), ("20:00", 7),
                      ])),
            direction("Tokyu.Toyoko", "Shibuya", "渋谷・和光市方面", "For Shibuya & Wakoshi",
                      ascending: false,
                      weekday: pattern("05:00", "24:12", [
                          ("05:00", 7), ("06:30", 4), ("09:30", 5), ("16:30", 4), ("20:00", 5), ("22:00", 7),
                      ]),
                      holiday: pattern("05:00", "24:12", [
                          ("05:00", 7), ("07:00", 5), ("10:00", 5), ("20:00", 7),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Tokyu.Toyoko.Shibuya", .descending,
                    "東京メトロ副都心線", "Tokyo Metro Fukutoshin Line",
                    "池袋・和光市方面", "for Ikebukuro & Wakoshi",
                    to: "Railway:TokyoMetro.Fukutoshin"),
            through("Tokyu.Toyoko.Yokohama", .ascending,
                    "みなとみらい線", "Minatomirai Line",
                    "元町・中華街方面", "for Motomachi-Chukagai",
                    to: "Railway:Minatomirai.Minatomirai"),
        ]
    )

    // MARK: - Tokyu Den-en-toshi Line (DT)

    static let denentoshi = StaticTrainLine(
        id: "Railway:Tokyu.DenEnToshi",
        nameJa: "東急田園都市線",
        nameEn: "Tokyu Den-en-toshi Line",
        operatorId: "Operator:Tokyu",
        colorHex: "#20A288",
        stations: [
            st("Tokyu.DenEnToshi", "Shibuya", "渋谷", "Shibuya", "DT01", 35.6580, 139.7016),
            st("Tokyu.DenEnToshi", "IkejiriOhashi", "池尻大橋", "Ikejiri-ohashi", "DT02", 35.6500, 139.6870),
            st("Tokyu.DenEnToshi", "Sangenjaya", "三軒茶屋", "Sangen-jaya", "DT03", 35.6435, 139.6706),
            st("Tokyu.DenEnToshi", "KomazawaDaigaku", "駒沢大学", "Komazawa-daigaku", "DT04", 35.6270, 139.6620),
            st("Tokyu.DenEnToshi", "SakuraShimmachi", "桜新町", "Sakura-shimmachi", "DT05", 35.6280, 139.6470),
            st("Tokyu.DenEnToshi", "Yoga", "用賀", "Yoga", "DT06", 35.6260, 139.6330),
            st("Tokyu.DenEnToshi", "FutakoTamagawa", "二子玉川", "Futako-tamagawa", "DT07", 35.6120, 139.6265),
            st("Tokyu.DenEnToshi", "FutakoShinchi", "二子新地", "Futako-shinchi", "DT08", 35.6050, 139.6180),
            st("Tokyu.DenEnToshi", "Takatsu", "高津", "Takatsu", "DT09", 35.6010, 139.6150),
            st("Tokyu.DenEnToshi", "Mizonokuchi", "溝の口", "Mizonokuchi", "DT10", 35.5998, 139.6103),
            st("Tokyu.DenEnToshi", "Kajigaya", "梶が谷", "Kajigaya", "DT11", 35.5910, 139.5990),
            st("Tokyu.DenEnToshi", "Miyazakidai", "宮崎台", "Miyazakidai", "DT12", 35.5870, 139.5880),
            st("Tokyu.DenEnToshi", "Miyamaedaira", "宮前平", "Miyamaedaira", "DT13", 35.5850, 139.5780),
            st("Tokyu.DenEnToshi", "Saginuma", "鷺沼", "Saginuma", "DT14", 35.5810, 139.5680),
            st("Tokyu.DenEnToshi", "TamaPlaza", "たまプラーザ", "Tama-plaza", "DT15", 35.5720, 139.5560),
            st("Tokyu.DenEnToshi", "Azamino", "あざみ野", "Azamino", "DT16", 35.5700, 139.5430),
            st("Tokyu.DenEnToshi", "Eda", "江田", "Eda", "DT17", 35.5620, 139.5360),
            st("Tokyu.DenEnToshi", "Ichigao", "市が尾", "Ichigao", "DT18", 35.5560, 139.5270),
            st("Tokyu.DenEnToshi", "Fujigaoka", "藤が丘", "Fujigaoka", "DT19", 35.5470, 139.5180),
            st("Tokyu.DenEnToshi", "Aobadai", "青葉台", "Aobadai", "DT20", 35.5440, 139.5080),
            st("Tokyu.DenEnToshi", "Tana", "田奈", "Tana", "DT21", 35.5390, 139.4980),
            st("Tokyu.DenEnToshi", "Nagatsuta", "長津田", "Nagatsuta", "DT22", 35.5318, 139.4944),
            st("Tokyu.DenEnToshi", "Tsukushino", "つくし野", "Tsukushino", "DT23", 35.5230, 139.4830),
            st("Tokyu.DenEnToshi", "Suzukakedai", "すずかけ台", "Suzukakedai", "DT24", 35.5170, 139.4720),
            st("Tokyu.DenEnToshi", "MinamiMachida", "南町田グランベリーパーク", "Minami-machida Grandberry Park", "DT25", 35.5130, 139.4620),
            st("Tokyu.DenEnToshi", "Tsukimino", "つきみ野", "Tsukimino", "DT26", 35.5030, 139.4530),
            st("Tokyu.DenEnToshi", "ChuoRinkan", "中央林間", "Chuo-rinkan", "DT27", 35.5076, 139.4453),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        ],
        directions: [
            direction("Tokyu.DenEnToshi", "ChuoRinkan", "中央林間方面", "For Chuo-Rinkan",
                      ascending: true,
                      weekday: pattern("05:05", "23:58", [
                          ("05:05", 6), ("06:30", 3), ("09:30", 6), ("16:30", 4), ("20:00", 5), ("22:00", 7),
                      ]),
                      holiday: pattern("05:05", "23:58", [
                          ("05:05", 7), ("07:00", 6), ("10:00", 6), ("20:00", 7),
                      ])),
            direction("Tokyu.DenEnToshi", "Shibuya", "渋谷・大手町方面", "For Shibuya & Otemachi",
                      ascending: false,
                      weekday: pattern("05:00", "24:10", [
                          ("05:00", 6), ("06:30", 3), ("09:30", 6), ("16:30", 4), ("20:00", 5), ("22:00", 7),
                      ]),
                      holiday: pattern("05:00", "24:10", [
                          ("05:00", 7), ("07:00", 6), ("10:00", 6), ("20:00", 7),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Tokyu.DenEnToshi.Shibuya", .descending,
                    "東京メトロ半蔵門線", "Tokyo Metro Hanzomon Line",
                    "大手町・押上方面", "for Otemachi & Oshiage",
                    to: "Railway:TokyoMetro.Hanzomon"),
        ]
    )

    // MARK: - Tokyu Meguro Line (MG)

    static let meguro = StaticTrainLine(
        id: "Railway:Tokyu.Meguro",
        nameJa: "東急目黒線",
        nameEn: "Tokyu Meguro Line",
        operatorId: "Operator:Tokyu",
        colorHex: "#009CD2",
        stations: [
            st("Tokyu.Meguro", "Meguro", "目黒", "Meguro", "MG01", 35.6340, 139.7157),
            st("Tokyu.Meguro", "Fudomae", "不動前", "Fudo-mae", "MG02", 35.6260, 139.7120),
            st("Tokyu.Meguro", "MusashiKoyama", "武蔵小山", "Musashi-Koyama", "MG03", 35.6210, 139.7020),
            st("Tokyu.Meguro", "NishiKoyama", "西小山", "Nishi-Koyama", "MG04", 35.6170, 139.6960),
            st("Tokyu.Meguro", "Senzoku", "洗足", "Senzoku", "MG05", 35.6140, 139.6890),
            st("Tokyu.Meguro", "Ookayama", "大岡山", "Ookayama", "MG06", 35.6070, 139.6850),
            st("Tokyu.Meguro", "Okusawa", "奥沢", "Okusawa", "MG07", 35.6040, 139.6770),
            st("Tokyu.Meguro", "DenenChofu", "田園調布", "Den-en-chofu", "MG08", 35.5990, 139.6660),
            st("Tokyu.Meguro", "Tamagawa", "多摩川", "Tamagawa", "MG09", 35.5920, 139.6660),
            st("Tokyu.Meguro", "ShinMaruko", "新丸子", "Shin-maruko", "MG10", 35.5810, 139.6595),
            st("Tokyu.Meguro", "MusashiKosugi", "武蔵小杉", "Musashi-Kosugi", "MG11", 35.5766, 139.6597),
            st("Tokyu.Meguro", "Motosumiyoshi", "元住吉", "Motosumiyoshi", "MG12", 35.5680, 139.6510),
            st("Tokyu.Meguro", "Hiyoshi", "日吉", "Hiyoshi", "MG13", 35.5540, 139.6470),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        ],
        directions: [
            direction("Tokyu.Meguro", "Hiyoshi", "日吉・新横浜方面", "For Hiyoshi & Shin-Yokohama",
                      ascending: true,
                      weekday: pattern("05:00", "24:02", [
                          ("05:00", 8), ("06:30", 4), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:00", "24:02", [
                          ("05:00", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ])),
            direction("Tokyu.Meguro", "Meguro", "目黒・大手町方面", "For Meguro & Otemachi",
                      ascending: false,
                      weekday: pattern("05:10", "24:29", [
                          ("05:10", 8), ("06:30", 4), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:10", "24:29", [
                          ("05:10", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Tokyu.Meguro.Meguro", .descending,
                    "東京メトロ南北線", "Tokyo Metro Namboku Line",
                    "四ツ谷・赤羽岩淵方面", "for Yotsuya & Akabane-Iwabuchi",
                    to: "Railway:TokyoMetro.Namboku"),
            through("Tokyu.Meguro.Meguro", .descending,
                    "都営三田線", "Toei Mita Line",
                    "大手町・西高島平方面", "for Otemachi & Nishi-Takashimadaira",
                    to: "Railway:Toei.Mita"),
            through("Tokyu.Meguro.Hiyoshi", .ascending,
                    "東急新横浜線", "Tokyu Shin-Yokohama Line",
                    "新横浜・相鉄線方面", "for Shin-Yokohama & the Sotetsu Line"),
        ]
    )
}
