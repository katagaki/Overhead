import Foundation

// MARK: - Keisei Line Data

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

private func through(_ path: String, _ junctionSuffix: String, _ end: ThroughService.LineEnd,
                     _ lineJa: String, _ lineEn: String,
                     _ towardJa: String, _ towardEn: String,
                     to connectingLineId: String? = nil) -> ThroughService {
    ThroughService(
        junctionStationId: "odpt.Station:\(path).\(junctionSuffix)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

enum KeiseiLineData {

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.keisei.co.jp/traininfo/index.php",
        statusPageURLEn: "https://www.keisei.co.jp/keisei/tetudou/skyliner/us/traffic/",
        xAccount: "@keiseirailway",
        checkMethodJa: "京成電鉄「運行情報」ページ、京成アプリ、またはX（@keiseirailway）で確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Keisei train information page, the Keisei app, or X (@keiseirailway). Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        main, oshiage, kanamachi, chiba, chihara, higashiNarita, skyAccess,
    ]

    private static let keiseiWeekday = pattern("05:00", "23:40", [
        ("05:00", 10), ("06:30", 6), ("09:30", 10), ("16:30", 8), ("20:00", 10), ("22:00", 12),
    ])
    private static let keiseiHoliday = pattern("05:00", "23:40", [
        ("05:00", 10), ("07:00", 8), ("10:00", 10), ("20:00", 11),
    ])

    // MARK: Keisei Main Line (KS)

    static let main = StaticTrainLine(
        id: "odpt.Railway:Keisei.Main",
        nameJa: "京成本線",
        nameEn: "Keisei Main Line",
        operatorId: "odpt.Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.Main", "KeiseiUeno", "京成上野", "Keisei-Ueno", "KS01", 35.7113, 139.7742),
            st("Keisei.Main", "Nippori", "日暮里", "Nippori", "KS02", 35.7280, 139.7710),
            st("Keisei.Main", "ShinMikawashima", "新三河島", "Shin-Mikawashima", "KS03", 35.7388, 139.7768),
            st("Keisei.Main", "Machiya", "町屋", "Machiya", "KS04", 35.7424, 139.7812),
            st("Keisei.Main", "SenjuOhashi", "千住大橋", "Senju-Ohashi", "KS05", 35.7418, 139.7935),
            st("Keisei.Main", "KeiseiSekiya", "京成関屋", "Keisei-Sekiya", "KS06", 35.7438, 139.8082),
            st("Keisei.Main", "HorikiriShobuen", "堀切菖蒲園", "Horikiri-Shobuen", "KS07", 35.7438, 139.8228),
            st("Keisei.Main", "Ohanajaya", "お花茶屋", "Ohanajaya", "KS08", 35.7478, 139.8338),
            st("Keisei.Main", "Aoto", "青砥", "Aoto", "KS09", 35.7448, 139.8552),
            st("Keisei.Main", "KeiseiTakasago", "京成高砂", "Keisei-Takasago", "KS10", 35.7498, 139.8658),
            st("Keisei.Main", "KeiseiKoiwa", "京成小岩", "Keisei-Koiwa", "KS11", 35.7438, 139.8808),
            st("Keisei.Main", "Edogawa", "江戸川", "Edogawa", "KS12", 35.7368, 139.8942),
            st("Keisei.Main", "Konodai", "国府台", "Konodai", "KS13", 35.7348, 139.9018),
            st("Keisei.Main", "Ichikawamama", "市川真間", "Ichikawamama", "KS14", 35.7328, 139.9108),
            st("Keisei.Main", "Sugano", "菅野", "Sugano", "KS15", 35.7288, 139.9208),
            st("Keisei.Main", "KeiseiYawata", "京成八幡", "Keisei-Yawata", "KS16", 35.7228, 139.9278),
            st("Keisei.Main", "Onigoe", "鬼越", "Onigoe", "KS17", 35.7218, 139.9368),
            st("Keisei.Main", "KeiseiNakayama", "京成中山", "Keisei-Nakayama", "KS18", 35.7178, 139.9438),
            st("Keisei.Main", "HigashiNakayama", "東中山", "Higashi-Nakayama", "KS19", 35.7148, 139.9498),
            st("Keisei.Main", "KeiseiNishifuna", "京成西船", "Keisei-Nishifuna", "KS20", 35.7118, 139.9548),
            st("Keisei.Main", "Kaijin", "海神", "Kaijin", "KS21", 35.7058, 139.9698),
            st("Keisei.Main", "KeiseiFunabashi", "京成船橋", "Keisei-Funabashi", "KS22", 35.7008, 139.9848),
            st("Keisei.Main", "Daijingushita", "大神宮下", "Daijingushita", "KS23", 35.6978, 139.9928),
            st("Keisei.Main", "Funabashikeibajo", "船橋競馬場", "Funabashikeibajo", "KS24", 35.6968, 140.0008),
            st("Keisei.Main", "Yatsu", "谷津", "Yatsu", "KS25", 35.6868, 140.0108),
            st("Keisei.Main", "KeiseiTsudanuma", "京成津田沼", "Keisei-Tsudanuma", "KS26", 35.6828, 140.0248),
            st("Keisei.Main", "KeiseiOkubo", "京成大久保", "Keisei-Okubo", "KS27", 35.6868, 140.0448),
            st("Keisei.Main", "Mimomi", "実籾", "Mimomi", "KS28", 35.6898, 140.0628),
            st("Keisei.Main", "Yachiyodai", "八千代台", "Yachiyodai", "KS29", 35.7058, 140.0808),
            st("Keisei.Main", "KeiseiOwada", "京成大和田", "Keisei-Owada", "KS30", 35.7128, 140.0958),
            st("Keisei.Main", "Katsutadai", "勝田台", "Katsutadai", "KS31", 35.7178, 140.1128),
            st("Keisei.Main", "Shizu", "志津", "Shizu", "KS32", 35.7158, 140.1308),
            st("Keisei.Main", "Yukarigaoka", "ユーカリが丘", "Yukarigaoka", "KS33", 35.7178, 140.1498),
            st("Keisei.Main", "KeiseiUsui", "京成臼井", "Keisei-Usui", "KS34", 35.7248, 140.1718),
            st("Keisei.Main", "KeiseiSakura", "京成佐倉", "Keisei-Sakura", "KS35", 35.7228, 140.2168),
            st("Keisei.Main", "Osakura", "大佐倉", "Osakura", "KS36", 35.7288, 140.2428),
            st("Keisei.Main", "KeiseiShisui", "京成酒々井", "Keisei-Shisui", "KS37", 35.7248, 140.2678),
            st("Keisei.Main", "Sogosando", "宗吾参道", "Sogosando", "KS38", 35.7348, 140.2868),
            st("Keisei.Main", "Kozunomori", "公津の杜", "Kozunomori", "KS39", 35.7568, 140.3038),
            st("Keisei.Main", "KeiseiNarita", "京成成田", "Keisei-Narita", "KS40", 35.7718, 140.3178),
            st("Keisei.Main", "AirportTerminal2", "空港第2ビル", "Narita Airport Terminal 2·3", "KS41", 35.7718, 140.3925),
            st("Keisei.Main", "NaritaAirport", "成田空港", "Narita Airport Terminal 1", "KS42", 35.7640, 140.3860),
        ],
        hopTimesMinutes: [
            4, 3, 1, 2, 2, 2, 2, 3, 2, 2, 2, 2, 1, 2, 2, 2, 1, 1, 2, 2,
            2, 2, 1, 2, 2, 3, 2, 3, 2, 2, 2, 2, 3, 4, 3, 3, 2, 2, 3, 8, 2,
        ],
        directions: [
            direction("Keisei.Main", "NaritaAirport", "成田空港方面", "For Narita Airport", ascending: true,
                      weekday: keiseiWeekday, holiday: keiseiHoliday),
            direction("Keisei.Main", "KeiseiUeno", "京成上野方面", "For Keisei-Ueno", ascending: false,
                      weekday: keiseiWeekday, holiday: keiseiHoliday),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.Main", "Aoto", .descending,
                    "京成押上線・都営浅草線", "Keisei Oshiage & Toei Asakusa Lines",
                    "押上・西馬込方面", "for Oshiage & Nishi-magome",
                    to: "odpt.Railway:Keisei.Oshiage"),
            through("Keisei.Main", "KeiseiTakasago", .ascending,
                    "成田スカイアクセス線", "Narita Sky Access Line",
                    "成田空港方面", "for Narita Airport",
                    to: "odpt.Railway:Keisei.NaritaSkyAccess"),
            through("Keisei.Main", "KeiseiTsudanuma", .ascending,
                    "京成千葉線", "Keisei Chiba Line",
                    "千葉中央方面", "for Chiba-Chuo",
                    to: "odpt.Railway:Keisei.Chiba"),
        ]
    )

    // MARK: Keisei Oshiage Line (KS)

    static let oshiage = StaticTrainLine(
        id: "odpt.Railway:Keisei.Oshiage",
        nameJa: "京成押上線",
        nameEn: "Keisei Oshiage Line",
        operatorId: "odpt.Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.Oshiage", "Oshiage", "押上", "Oshiage 'SKYTREE'", "KS45", 35.7103, 139.8129),
            st("Keisei.Oshiage", "KeiseiHikifune", "京成曳舟", "Keisei-Hikifune", "KS46", 35.7168, 139.8178),
            st("Keisei.Oshiage", "Yahiro", "八広", "Yahiro", "KS47", 35.7228, 139.8268),
            st("Keisei.Oshiage", "Yotsugi", "四ツ木", "Yotsugi", "KS48", 35.7315, 139.8370),
            st("Keisei.Oshiage", "KeiseiTateishi", "京成立石", "Keisei-Tateishi", "KS49", 35.7378, 139.8478),
            st("Keisei.Oshiage", "Aoto", "青砥", "Aoto", "KS09", 35.7448, 139.8552),
        ],
        hopTimesMinutes: [2, 2, 2, 2, 3],
        directions: [
            direction("Keisei.Oshiage", "Aoto", "青砥方面", "For Aoto", ascending: true,
                      weekday: pattern("05:00", "23:50", [
                          ("05:00", 8), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:00", "23:50", [
                          ("05:00", 8), ("07:00", 7), ("10:00", 8), ("20:00", 9),
                      ])),
            direction("Keisei.Oshiage", "Oshiage", "押上方面", "For Oshiage", ascending: false,
                      weekday: pattern("05:00", "23:50", [
                          ("05:00", 8), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:00", "23:50", [
                          ("05:00", 8), ("07:00", 7), ("10:00", 8), ("20:00", 9),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.Oshiage", "Aoto", .ascending,
                    "京成本線", "Keisei Main Line",
                    "京成船橋・成田空港方面", "for Keisei-Funabashi & Narita Airport",
                    to: "odpt.Railway:Keisei.Main"),
            through("Keisei.Oshiage", "Oshiage", .descending,
                    "都営浅草線・京急線", "Toei Asakusa & Keikyu Lines",
                    "羽田空港・西馬込方面", "for Haneda Airport & Nishi-magome",
                    to: "odpt.Railway:Toei.Asakusa"),
        ]
    )

    // MARK: Keisei Kanamachi Line (KS)

    static let kanamachi = StaticTrainLine(
        id: "odpt.Railway:Keisei.Kanamachi",
        nameJa: "京成金町線",
        nameEn: "Keisei Kanamachi Line",
        operatorId: "odpt.Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.Kanamachi", "KeiseiTakasago", "京成高砂", "Keisei-Takasago", "KS10", 35.7498, 139.8658),
            st("Keisei.Kanamachi", "Shibamata", "柴又", "Shibamata", "KS50", 35.7565, 139.8753),
            st("Keisei.Kanamachi", "KeiseiKanamachi", "京成金町", "Keisei-Kanamachi", "KS51", 35.7685, 139.8705),
        ],
        hopTimesMinutes: [2, 2],
        directions: [
            direction("Keisei.Kanamachi", "KeiseiKanamachi", "京成金町方面", "For Keisei-Kanamachi", ascending: true,
                      weekday: pattern("05:10", "23:55", [
                          ("05:10", 10), ("07:00", 8), ("09:30", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:10", "23:55", [
                          ("05:10", 10), ("22:00", 12),
                      ])),
            direction("Keisei.Kanamachi", "KeiseiTakasago", "京成高砂方面", "For Keisei-Takasago", ascending: false,
                      weekday: pattern("05:10", "23:55", [
                          ("05:10", 10), ("07:00", 8), ("09:30", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:10", "23:55", [
                          ("05:10", 10), ("22:00", 12),
                      ])),
        ],
        delayInfo: delayInfo
    )

    // MARK: Keisei Chiba Line (KS)

    private static let chibaWeekday = pattern("05:00", "23:45", [
        ("05:00", 10), ("06:30", 7), ("09:30", 10), ("17:00", 8), ("20:00", 10), ("22:00", 12),
    ])
    private static let chibaHoliday = pattern("05:00", "23:45", [
        ("05:00", 10), ("20:00", 12),
    ])

    static let chiba = StaticTrainLine(
        id: "odpt.Railway:Keisei.Chiba",
        nameJa: "京成千葉線",
        nameEn: "Keisei Chiba Line",
        operatorId: "odpt.Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.Chiba", "KeiseiTsudanuma", "京成津田沼", "Keisei-Tsudanuma", "KS26", 35.6828, 140.0248),
            st("Keisei.Chiba", "KeiseiMakuharihongo", "京成幕張本郷", "Keisei-Makuharihongo", "KS52", 35.6726, 140.0421),
            st("Keisei.Chiba", "KeiseiMakuhari", "京成幕張", "Keisei-Makuhari", "KS53", 35.6610, 140.0557),
            st("Keisei.Chiba", "Kemigawa", "検見川", "Kemigawa", "KS54", 35.6526, 140.0663),
            st("Keisei.Chiba", "KeiseiInage", "京成稲毛", "Keisei-Inage", "KS55", 35.6378, 140.0855),
            st("Keisei.Chiba", "Midoridai", "みどり台", "Midoridai", "KS56", 35.6248, 140.0977),
            st("Keisei.Chiba", "NishiNobuto", "西登戸", "Nishi-Nobuto", "KS57", 35.6176, 140.1028),
            st("Keisei.Chiba", "ShinChiba", "新千葉", "Shin-Chiba", "KS58", 35.6124, 140.1083),
            st("Keisei.Chiba", "KeiseiChiba", "京成千葉", "Keisei-Chiba", "KS59", 35.6117, 140.1144),
            st("Keisei.Chiba", "Chibachuo", "千葉中央", "Chiba-Chuo", "KS60", 35.6073, 140.1178),
        ],
        hopTimesMinutes: [3, 2, 2, 3, 2, 2, 1, 2, 2],
        directions: [
            direction("Keisei.Chiba", "Chibachuo", "千葉中央方面", "For Chiba-Chuo", ascending: true,
                      weekday: chibaWeekday, holiday: chibaHoliday),
            direction("Keisei.Chiba", "KeiseiTsudanuma", "京成津田沼方面", "For Keisei-Tsudanuma", ascending: false,
                      weekday: chibaWeekday, holiday: chibaHoliday),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.Chiba", "Chibachuo", .ascending,
                    "京成千原線", "Keisei Chihara Line",
                    "ちはら台方面", "for Chiharadai",
                    to: "odpt.Railway:Keisei.Chihara"),
            through("Keisei.Chiba", "KeiseiTsudanuma", .descending,
                    "京成本線", "Keisei Main Line",
                    "京成上野方面", "for Keisei-Ueno",
                    to: "odpt.Railway:Keisei.Main"),
            through("Keisei.Chiba", "KeiseiTsudanuma", .descending,
                    "京成松戸線", "Keisei Matsudo Line",
                    "松戸方面", "for Matsudo"),
        ]
    )

    // MARK: Keisei Chihara Line (KS)

    private static let chiharaWeekday = pattern("05:10", "23:30", [
        ("05:10", 15), ("07:00", 10), ("09:30", 20), ("17:00", 15), ("20:00", 20),
    ])
    private static let chiharaHoliday = pattern("05:10", "23:30", [
        ("05:10", 20),
    ])

    static let chihara = StaticTrainLine(
        id: "odpt.Railway:Keisei.Chihara",
        nameJa: "京成千原線",
        nameEn: "Keisei Chihara Line",
        operatorId: "odpt.Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.Chihara", "Chibachuo", "千葉中央", "Chiba-Chuo", "KS60", 35.6073, 140.1178),
            st("Keisei.Chihara", "Chibadera", "千葉寺", "Chibadera", "KS61", 35.5903, 140.1322),
            st("Keisei.Chihara", "Omoridai", "大森台", "Omoridai", "KS62", 35.5842, 140.1494),
            st("Keisei.Chihara", "Gakuemmae", "学園前", "Gakuemmae", "KS63", 35.5608, 140.1584),
            st("Keisei.Chihara", "Oyumino", "おゆみ野", "Oyumino", "KS64", 35.5500, 140.1663),
            st("Keisei.Chihara", "Chiharadai", "ちはら台", "Chiharadai", "KS65", 35.5338, 140.1702),
        ],
        hopTimesMinutes: [3, 2, 4, 2, 3],
        directions: [
            direction("Keisei.Chihara", "Chiharadai", "ちはら台方面", "For Chiharadai", ascending: true,
                      weekday: chiharaWeekday, holiday: chiharaHoliday),
            direction("Keisei.Chihara", "Chibachuo", "千葉中央方面", "For Chiba-Chuo", ascending: false,
                      weekday: chiharaWeekday, holiday: chiharaHoliday),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.Chihara", "Chibachuo", .descending,
                    "京成千葉線", "Keisei Chiba Line",
                    "京成津田沼方面", "for Keisei-Tsudanuma",
                    to: "odpt.Railway:Keisei.Chiba"),
        ]
    )

    // MARK: Keisei Higashi-Narita Line (KS)

    private static let higashiNaritaPattern = pattern("05:15", "22:50", [
        ("05:15", 40),
    ])

    static let higashiNarita = StaticTrainLine(
        id: "odpt.Railway:Keisei.HigashiNarita",
        nameJa: "京成東成田線",
        nameEn: "Keisei Higashi-Narita Line",
        operatorId: "odpt.Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.HigashiNarita", "KeiseiNarita", "京成成田", "Keisei-Narita", "KS40", 35.7718, 140.3178),
            st("Keisei.HigashiNarita", "HigashiNarita", "東成田", "Higashi-Narita", "KS44", 35.7701, 140.3872),
        ],
        hopTimesMinutes: [8],
        directions: [
            direction("Keisei.HigashiNarita", "HigashiNarita", "東成田方面", "For Higashi-Narita", ascending: true,
                      weekday: higashiNaritaPattern, holiday: higashiNaritaPattern),
            direction("Keisei.HigashiNarita", "KeiseiNarita", "京成成田方面", "For Keisei-Narita", ascending: false,
                      weekday: higashiNaritaPattern, holiday: higashiNaritaPattern),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.HigashiNarita", "HigashiNarita", .ascending,
                    "芝山鉄道線", "Shibayama Railway Line",
                    "芝山千代田方面", "for Shibayama-Chiyoda"),
        ]
    )

    // MARK: Narita Sky Access Line (KS)

    private static let skyAccessWeekday = pattern("05:00", "23:00", [
        ("05:00", 40), ("06:30", 30), ("09:00", 40), ("17:00", 30), ("20:00", 40),
    ])
    private static let skyAccessHoliday = pattern("05:00", "23:00", [
        ("05:00", 40),
    ])

    static let skyAccess = StaticTrainLine(
        id: "odpt.Railway:Keisei.NaritaSkyAccess",
        nameJa: "成田スカイアクセス線",
        nameEn: "Narita Sky Access Line",
        operatorId: "odpt.Operator:Keisei",
        colorHex: "#EC7B02",
        stations: [
            st("Keisei.NaritaSkyAccess", "KeiseiTakasago", "京成高砂", "Keisei-Takasago", "KS10", 35.7498, 139.8658),
            st("Keisei.NaritaSkyAccess", "HigashiMatsudo", "東松戸", "Higashi-Matsudo", "HS05", 35.7699, 139.9429),
            st("Keisei.NaritaSkyAccess", "ShinKamagaya", "新鎌ヶ谷", "Shin-Kamagaya", "HS08", 35.7795, 139.9983),
            st("Keisei.NaritaSkyAccess", "ChibaNewTown", "千葉ニュータウン中央", "Chiba New Town Chuo", "HS12", 35.8002, 140.1164),
            st("Keisei.NaritaSkyAccess", "ImbaNihonIdai", "印旛日本医大", "Imba-Nihon-Idai", "HS14", 35.7876, 140.2033),
            st("Keisei.NaritaSkyAccess", "NaritaYukawa", "成田湯川", "Narita-Yukawa", "KS43", 35.7996, 140.2911),
            st("Keisei.NaritaSkyAccess", "AirportTerminal2", "空港第2ビル", "Narita Airport Terminal 2·3", "KS41", 35.7718, 140.3925),
            st("Keisei.NaritaSkyAccess", "NaritaAirport", "成田空港", "Narita Airport Terminal 1", "KS42", 35.7640, 140.3860),
        ],
        hopTimesMinutes: [8, 5, 9, 7, 7, 8, 2],
        directions: [
            direction("Keisei.NaritaSkyAccess", "NaritaAirport", "成田空港方面", "For Narita Airport", ascending: true,
                      weekday: skyAccessWeekday, holiday: skyAccessHoliday),
            direction("Keisei.NaritaSkyAccess", "KeiseiTakasago", "京成高砂方面", "For Keisei-Takasago", ascending: false,
                      weekday: skyAccessWeekday, holiday: skyAccessHoliday),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.NaritaSkyAccess", "KeiseiTakasago", .descending,
                    "京成本線", "Keisei Main Line",
                    "京成上野方面", "for Keisei-Ueno",
                    to: "odpt.Railway:Keisei.Main"),
            through("Keisei.NaritaSkyAccess", "KeiseiTakasago", .descending,
                    "京成押上線・都営浅草線・京急線", "Keisei Oshiage, Toei Asakusa & Keikyu Lines",
                    "羽田空港方面", "for Haneda Airport",
                    to: "odpt.Railway:Keisei.Oshiage"),
        ]
    )
}
