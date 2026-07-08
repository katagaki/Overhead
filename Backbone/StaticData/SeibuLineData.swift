import Foundation

// MARK: - Seibu Line Data

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

enum SeibuLineData {

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.seiburailway.jp/railways/unkou/",
        statusPageURLEn: "https://www.seiburailway.jp/global/en/",
        xAccount: nil,
        checkMethodJa: "西武鉄道「運行情報」ページまたは西武線アプリで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Seibu Railway operation information page or the Seibu Lines app. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        ikebukuro, seibuYurakucho, shinjuku,
    ]

    // MARK: - Seibu Ikebukuro Line (SI)

    static let ikebukuro = StaticTrainLine(
        id: "Railway:Seibu.Ikebukuro",
        nameJa: "西武池袋線",
        nameEn: "Seibu Ikebukuro Line",
        operatorId: "Operator:Seibu",
        colorHex: "#F08300",
        stations: [
            st("Seibu.Ikebukuro", "Ikebukuro", "池袋", "Ikebukuro", "SI01", 35.7295, 139.7109),
            st("Seibu.Ikebukuro", "Shiinamachi", "椎名町", "Shiinamachi", "SI02", 35.7237, 139.6987),
            st("Seibu.Ikebukuro", "HigashiNagasaki", "東長崎", "Higashi-nagasaki", "SI03", 35.7227, 139.6877),
            st("Seibu.Ikebukuro", "Ekoda", "江古田", "Ekoda", "SI04", 35.7367, 139.6737),
            st("Seibu.Ikebukuro", "Sakuradai", "桜台", "Sakuradai", "SI05", 35.7377, 139.6637),
            st("Seibu.Ikebukuro", "Nerima", "練馬", "Nerima", "SI06", 35.7377, 139.6537),
            st("Seibu.Ikebukuro", "Nakamurabashi", "中村橋", "Nakamurabashi", "SI07", 35.7397, 139.6387),
            st("Seibu.Ikebukuro", "Fujimidai", "富士見台", "Fujimidai", "SI08", 35.7407, 139.6287),
            st("Seibu.Ikebukuro", "NerimaTakanodai", "練馬高野台", "Nerima-takanodai", "SI09", 35.7457, 139.6187),
            st("Seibu.Ikebukuro", "ShakujiiKoen", "石神井公園", "Shakujii-koen", "SI10", 35.7437, 139.6067),
            st("Seibu.Ikebukuro", "OizumiGakuen", "大泉学園", "Oizumi-gakuen", "SI11", 35.7497, 139.5877),
            st("Seibu.Ikebukuro", "Hoya", "保谷", "Hoya", "SI12", 35.7517, 139.5687),
            st("Seibu.Ikebukuro", "Hibarigaoka", "ひばりヶ丘", "Hibarigaoka", "SI13", 35.7517, 139.5457),
            st("Seibu.Ikebukuro", "HigashiKurume", "東久留米", "Higashi-kurume", "SI14", 35.7577, 139.5297),
            st("Seibu.Ikebukuro", "Kiyose", "清瀬", "Kiyose", "SI15", 35.7697, 139.5187),
            st("Seibu.Ikebukuro", "Akitsu", "秋津", "Akitsu", "SI16", 35.7727, 139.4937),
            st("Seibu.Ikebukuro", "Tokorozawa", "所沢", "Tokorozawa", "SI17", 35.7867, 139.4733),
            st("Seibu.Ikebukuro", "NishiTokorozawa", "西所沢", "Nishi-tokorozawa", "SI18", 35.7897, 139.4487),
            st("Seibu.Ikebukuro", "Kotesashi", "小手指", "Kotesashi", "SI19", 35.7937, 139.4247),
            st("Seibu.Ikebukuro", "Sayamagaoka", "狭山ヶ丘", "Sayamagaoka", "SI20", 35.8027, 139.4087),
            st("Seibu.Ikebukuro", "MusashiFujisawa", "武蔵藤沢", "Musashi-fujisawa", "SI21", 35.8107, 139.3987),
            st("Seibu.Ikebukuro", "InariyamaKoen", "稲荷山公園", "Inariyama-koen", "SI22", 35.8317, 139.3887),
            st("Seibu.Ikebukuro", "Irumashi", "入間市", "Irumashi", "SI23", 35.8357, 139.3787),
            st("Seibu.Ikebukuro", "Bushi", "仏子", "Bushi", "SI24", 35.8407, 139.3487),
            st("Seibu.Ikebukuro", "Motokaji", "元加治", "Motokaji", "SI25", 35.8447, 139.3337),
            st("Seibu.Ikebukuro", "Hanno", "飯能", "Hanno", "SI26", 35.8557, 139.3277),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 1, 2, 2, 3, 2, 3, 2, 2,
            3, 3, 2, 3, 2, 2, 3, 2, 3, 2, 3,
        ],
        directions: [
            direction("Seibu.Ikebukuro", "Hanno", "所沢・飯能方面", "For Tokorozawa & Hanno",
                      ascending: true,
                      weekday: pattern("04:58", "23:52", [
                          ("04:58", 8), ("06:30", 4), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("04:58", "23:52", [
                          ("04:58", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ])),
            direction("Seibu.Ikebukuro", "Ikebukuro", "池袋方面", "For Ikebukuro",
                      ascending: false,
                      weekday: pattern("05:03", "23:08", [
                          ("05:03", 8), ("06:30", 4), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:03", "23:08", [
                          ("05:03", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Seibu.Ikebukuro.Nerima", .descending,
                    "西武有楽町線", "Seibu Yurakucho Line",
                    "小竹向原・有楽町線・副都心線方面", "for Kotake-Mukaihara & the Yurakucho and Fukutoshin Lines",
                    to: "Railway:Seibu.SeibuYurakucho"),
            through("Seibu.Ikebukuro.Hanno", .ascending,
                    "西武池袋線・秩父線", "Seibu Ikebukuro & Chichibu Lines",
                    "西武秩父方面", "for Seibu-Chichibu"),
        ]
    )

    // MARK: - Seibu Yurakucho Line (SI)

    static let seibuYurakucho = StaticTrainLine(
        id: "Railway:Seibu.SeibuYurakucho",
        nameJa: "西武有楽町線",
        nameEn: "Seibu Yurakucho Line",
        operatorId: "Operator:Seibu",
        colorHex: "#F08300",
        stations: [
            st("Seibu.SeibuYurakucho", "KotakeMukaihara", "小竹向原", "Kotake-Mukaihara", "SI37", 35.7437, 139.6787),
            st("Seibu.SeibuYurakucho", "Shinsakuradai", "新桜台", "Shin-sakuradai", "SI38", 35.7407, 139.6687),
            st("Seibu.SeibuYurakucho", "Nerima", "練馬", "Nerima", "SI06", 35.7377, 139.6537),
        ],
        hopTimesMinutes: [2, 2],
        directions: [
            // Feeder for metro through services; windows approximate the
            // through-running span
            direction("Seibu.SeibuYurakucho", "Nerima", "練馬・所沢方面", "For Nerima & Tokorozawa",
                      ascending: true,
                      weekday: pattern("05:02", "24:33", [
                          ("05:02", 10), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:02", "24:33", [
                          ("05:02", 10), ("07:00", 8), ("10:00", 8), ("20:00", 10),
                      ])),
            direction("Seibu.SeibuYurakucho", "KotakeMukaihara", "小竹向原方面", "For Kotake-Mukaihara",
                      ascending: false,
                      weekday: pattern("04:57", "24:16", [
                          ("04:57", 10), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:57", "24:16", [
                          ("04:57", 10), ("07:00", 8), ("10:00", 8), ("20:00", 10),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Seibu.SeibuYurakucho.KotakeMukaihara", .descending,
                    "東京メトロ有楽町線", "Tokyo Metro Yurakucho Line",
                    "有楽町・新木場方面", "for Yurakucho & Shin-Kiba",
                    to: "Railway:TokyoMetro.Yurakucho"),
            through("Seibu.SeibuYurakucho.KotakeMukaihara", .descending,
                    "東京メトロ副都心線", "Tokyo Metro Fukutoshin Line",
                    "渋谷・横浜方面", "for Shibuya & Yokohama",
                    to: "Railway:TokyoMetro.Fukutoshin"),
            through("Seibu.SeibuYurakucho.Nerima", .ascending,
                    "西武池袋線", "Seibu Ikebukuro Line",
                    "所沢・飯能方面", "for Tokorozawa & Hanno",
                    to: "Railway:Seibu.Ikebukuro"),
        ]
    )

    // MARK: - Seibu Shinjuku Line (SS)

    // First/last: ekitan + Yahoo, July 2026 (medium confidence).
    // Coordinates: ja.wikipedia per-station infoboxes, 2026-07-08.
    static let shinjuku = StaticTrainLine(
        id: "Railway:Seibu.Shinjuku",
        nameJa: "西武新宿線",
        nameEn: "Seibu Shinjuku Line",
        operatorId: "Operator:Seibu",
        colorHex: "#00A6BF",
        stations: [
            st("Seibu.Shinjuku", "SeibuShinjuku", "西武新宿", "Seibu-Shinjuku", "SS01", 35.6963, 139.7000),
            st("Seibu.Shinjuku", "Takadanobaba", "高田馬場", "Takadanobaba", "SS02", 35.7131, 139.7041),
            st("Seibu.Shinjuku", "ShimoOchiai", "下落合", "Shimo-ochiai", "SS03", 35.7158, 139.6951),
            st("Seibu.Shinjuku", "Nakai", "中井", "Nakai", "SS04", 35.7151, 139.6872),
            st("Seibu.Shinjuku", "Araiyakushimae", "新井薬師前", "Araiyakushi-mae", "SS05", 35.7158, 139.6719),
            st("Seibu.Shinjuku", "Numabukuro", "沼袋", "Numabukuro", "SS06", 35.7194, 139.6638),
            st("Seibu.Shinjuku", "Nogata", "野方", "Nogata", "SS07", 35.7197, 139.6528),
            st("Seibu.Shinjuku", "ToritsuKasei", "都立家政", "Toritsu-kasei", "SS08", 35.7223, 139.6446),
            st("Seibu.Shinjuku", "Saginomiya", "鷺ノ宮", "Saginomiya", "SS09", 35.7226, 139.6389),
            st("Seibu.Shinjuku", "ShimoIgusa", "下井草", "Shimo-igusa", "SS10", 35.7239, 139.6243),
            st("Seibu.Shinjuku", "Iogi", "井荻", "Iogi", "SS11", 35.7245, 139.6147),
            st("Seibu.Shinjuku", "KamiIgusa", "上井草", "Kami-igusa", "SS12", 35.7251, 139.6036),
            st("Seibu.Shinjuku", "KamiShakujii", "上石神井", "Kami-shakujii", "SS13", 35.7263, 139.5921),
            st("Seibu.Shinjuku", "MusashiSeki", "武蔵関", "Musashi-seki", "SS14", 35.7276, 139.5769),
            st("Seibu.Shinjuku", "HigashiFushimi", "東伏見", "Higashi-fushimi", "SS15", 35.7287, 139.5643),
            st("Seibu.Shinjuku", "SeibuYagisawa", "西武柳沢", "Seibu-yagisawa", "SS16", 35.7286, 139.5526),
            st("Seibu.Shinjuku", "Tanashi", "田無", "Tanashi", "SS17", 35.7274, 139.5393),
            st("Seibu.Shinjuku", "HanaKoganei", "花小金井", "Hana-koganei", "SS18", 35.7261, 139.5132),
            st("Seibu.Shinjuku", "Kodaira", "小平", "Kodaira", "SS19", 35.7370, 139.4883),
            st("Seibu.Shinjuku", "Kumegawa", "久米川", "Kumegawa", "SS20", 35.7500, 139.4720),
            st("Seibu.Shinjuku", "HigashiMurayama", "東村山", "Higashi-murayama", "SS21", 35.7606, 139.4658),
            st("Seibu.Shinjuku", "Tokorozawa", "所沢", "Tokorozawa", "SS22", 35.7867, 139.4733),
            st("Seibu.Shinjuku", "KokuKoen", "航空公園", "Koku-koen", "SS23", 35.7984, 139.4657),
            st("Seibu.Shinjuku", "ShinTokorozawa", "新所沢", "Shin-tokorozawa", "SS24", 35.8067, 139.4561),
            st("Seibu.Shinjuku", "Iriso", "入曽", "Iriso", "SS25", 35.8325, 139.4272),
            st("Seibu.Shinjuku", "Sayamashi", "狭山市", "Sayamashi", "SS26", 35.8569, 139.4131),
            st("Seibu.Shinjuku", "ShinSayama", "新狭山", "Shin-sayama", "SS27", 35.8741, 139.4333),
            st("Seibu.Shinjuku", "MinamiOtsuka", "南大塚", "Minami-otsuka", "SS28", 35.8898, 139.4543),
            st("Seibu.Shinjuku", "HonKawagoe", "本川越", "Hon-kawagoe", "SS29", 35.9142, 139.4814),
        ],
        hopTimesMinutes: [
            3, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 2, 2, 2,
            1, 2, 3, 3, 2, 2, 4, 2, 2, 4, 3, 3, 3, 4,
        ],
        directions: [
            direction("Seibu.Shinjuku", "HonKawagoe", "所沢・本川越方面", "For Tokorozawa & Hon-Kawagoe",
                      ascending: true,
                      weekday: pattern("05:01", "24:17", [
                          ("05:01", 8), ("06:30", 4), ("09:30", 5), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:01", "24:17", [
                          ("05:01", 8), ("07:00", 5), ("10:00", 5), ("20:00", 8),
                      ])),
            direction("Seibu.Shinjuku", "SeibuShinjuku", "高田馬場・西武新宿方面", "For Takadanobaba & Seibu-Shinjuku",
                      ascending: false,
                      weekday: pattern("04:54", "23:31", [
                          ("04:54", 10), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:54", "23:31", [
                          ("04:54", 10), ("07:00", 8), ("10:00", 8), ("20:00", 10),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Seibu.Shinjuku.Kodaira", .ascending,
                    "西武拝島線", "Seibu Haijima Line",
                    "拝島方面", "for Haijima"),
        ]
    )
}
