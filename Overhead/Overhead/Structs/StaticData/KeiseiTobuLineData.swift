import Foundation

// MARK: - Keisei & Tobu Line Data
//
// Station lists, run times and service patterns for Keisei and Tobu
// commuter lines, compiled from publicly available route maps and
// published timetables. Branch lines (Kanamachi, Chiba, Chihara,
// Higashi-Narita, Sky Access; Tobu Kameido, Daishi, Urban Park, Nikko)
// are not included.

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
                     _ towardJa: String, _ towardEn: String) -> ThroughService {
    ThroughService(
        junctionStationId: "odpt.Station:\(path).\(junctionSuffix)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn
    )
}

// MARK: - Keisei

enum KeiseiLineData {

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.keisei.co.jp/traininfo/index.php",
        statusPageURLEn: "https://www.keisei.co.jp/keisei/tetudou/skyliner/us/traffic/",
        xAccount: "@keiseirailway",
        checkMethodJa: "京成電鉄「運行情報」ページ、京成アプリ、またはX（@keiseirailway）で確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Keisei train information page, the Keisei app, or X (@keiseirailway). Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [main, oshiage]

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
            through("Keisei.Main", "KeiseiTakasago", .ascending,
                    "成田スカイアクセス線", "Narita Sky Access Line",
                    "成田空港方面", "for Narita Airport"),
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
                    "京成船橋・成田空港方面", "for Keisei-Funabashi & Narita Airport"),
            through("Keisei.Oshiage", "Oshiage", .descending,
                    "都営浅草線・京急線", "Toei Asakusa & Keikyu Lines",
                    "羽田空港・西馬込方面", "for Haneda Airport & Nishi-magome"),
        ]
    )
}

// MARK: - Tobu

enum TobuLineData {

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.tobu.co.jp/service_status/",
        statusPageURLEn: "https://www.tobu.co.jp/en/",
        xAccount: "@TobuRailway_JP",
        checkMethodJa: "東武鉄道「運行情報」ページ、東武線アプリ、またはX（@TobuRailway_JP）で確認できます。おおむね10分以上の遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Tobu Railway service status page, the Tobu app, or X (@TobuRailway_JP). Delays of roughly 10 minutes or more and suspensions are posted."
    )

    static let lines: [StaticTrainLine] = [skytree, tojo]

    // MARK: Tobu Skytree Line (TS)

    static let skytree = StaticTrainLine(
        id: "odpt.Railway:Tobu.TobuSkytree",
        nameJa: "東武スカイツリーライン",
        nameEn: "Tobu Skytree Line",
        operatorId: "odpt.Operator:Tobu",
        colorHex: "#0067C0",
        stations: [
            st("Tobu.TobuSkytree", "Asakusa", "浅草", "Asakusa", "TS01", 35.7106, 139.7973),
            st("Tobu.TobuSkytree", "TokyoSkytree", "とうきょうスカイツリー", "Tokyo Skytree", "TS02", 35.7098, 139.8092),
            st("Tobu.TobuSkytree", "Oshiage", "押上", "Oshiage 'SKYTREE'", "TS03", 35.7103, 139.8129),
            st("Tobu.TobuSkytree", "Hikifune", "曳舟", "Hikifune", "TS04", 35.7168, 139.8172),
            st("Tobu.TobuSkytree", "HigashiMukojima", "東向島", "Higashi-Mukojima", "TS05", 35.7248, 139.8178),
            st("Tobu.TobuSkytree", "Kanegafuchi", "鐘ヶ淵", "Kanegafuchi", "TS06", 35.7328, 139.8208),
            st("Tobu.TobuSkytree", "Horikiri", "堀切", "Horikiri", "TS07", 35.7398, 139.8182),
            st("Tobu.TobuSkytree", "Ushida", "牛田", "Ushida", "TS08", 35.7438, 139.8112),
            st("Tobu.TobuSkytree", "KitaSenju", "北千住", "Kita-Senju", "TS09", 35.7497, 139.8047),
            st("Tobu.TobuSkytree", "Kosuge", "小菅", "Kosuge", "TS10", 35.7578, 139.8102),
            st("Tobu.TobuSkytree", "Gotanno", "五反野", "Gotanno", "TS11", 35.7658, 139.8138),
            st("Tobu.TobuSkytree", "Umejima", "梅島", "Umejima", "TS12", 35.7738, 139.8112),
            st("Tobu.TobuSkytree", "Nishiarai", "西新井", "Nishiarai", "TS13", 35.7775, 139.7925),
            st("Tobu.TobuSkytree", "Takenotsuka", "竹ノ塚", "Takenotsuka", "TS14", 35.7938, 139.7922),
            st("Tobu.TobuSkytree", "Yatsuka", "谷塚", "Yatsuka", "TS15", 35.8098, 139.7962),
            st("Tobu.TobuSkytree", "Soka", "草加", "Soka", "TS16", 35.8248, 139.8038),
            st("Tobu.TobuSkytree", "Dokkyodaigakumae", "獨協大学前", "Dokkyodaigakumae", "TS17", 35.8358, 139.8062),
            st("Tobu.TobuSkytree", "Shinden", "新田", "Shinden", "TS18", 35.8468, 139.8092),
            st("Tobu.TobuSkytree", "Gamo", "蒲生", "Gamo", "TS19", 35.8620, 139.7955),
            st("Tobu.TobuSkytree", "ShinKoshigaya", "新越谷", "Shin-Koshigaya", "TS20", 35.8758, 139.7920),
            st("Tobu.TobuSkytree", "Koshigaya", "越谷", "Koshigaya", "TS21", 35.8878, 139.7902),
            st("Tobu.TobuSkytree", "KitaKoshigaya", "北越谷", "Kita-Koshigaya", "TS22", 35.9008, 139.7852),
            st("Tobu.TobuSkytree", "Obukuro", "大袋", "Obukuro", "TS23", 35.9168, 139.7792),
            st("Tobu.TobuSkytree", "Sengendai", "せんげん台", "Sengendai", "TS24", 35.9278, 139.7772),
            st("Tobu.TobuSkytree", "Takesato", "武里", "Takesato", "TS25", 35.9368, 139.7742),
            st("Tobu.TobuSkytree", "Ichinowari", "一ノ割", "Ichinowari", "TS26", 35.9545, 139.7615),
            st("Tobu.TobuSkytree", "Kasukabe", "春日部", "Kasukabe", "TS27", 35.9778, 139.7522),
            st("Tobu.TobuSkytree", "KitaKasukabe", "北春日部", "Kita-Kasukabe", "TS28", 35.9908, 139.7582),
            st("Tobu.TobuSkytree", "Himemiya", "姫宮", "Himemiya", "TS29", 36.0068, 139.7482),
            st("Tobu.TobuSkytree", "TobuDobutsuKoen", "東武動物公園", "Tobu-Dobutsu-Koen", "TS30", 36.0208, 139.7292),
        ],
        hopTimesMinutes: [
            2, 1, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 3, 3,
            2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 3, 3, 2, 3, 3,
        ],
        directions: [
            direction("Tobu.TobuSkytree", "TobuDobutsuKoen", "東武動物公園方面", "For Tobu-Dobutsu-Koen", ascending: true,
                      weekday: pattern("05:00", "23:40", [
                          ("05:00", 10), ("06:30", 5), ("09:30", 10), ("16:30", 7), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:00", "23:40", [
                          ("05:00", 10), ("07:00", 8), ("10:00", 10), ("20:00", 11),
                      ])),
            direction("Tobu.TobuSkytree", "Asakusa", "浅草方面", "For Asakusa", ascending: false,
                      weekday: pattern("05:00", "23:40", [
                          ("05:00", 10), ("06:30", 5), ("09:30", 10), ("16:30", 7), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:00", "23:40", [
                          ("05:00", 10), ("07:00", 8), ("10:00", 10), ("20:00", 11),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Tobu.TobuSkytree", "Oshiage", .descending,
                    "東京メトロ半蔵門線・東急田園都市線", "Tokyo Metro Hanzomon & Tokyu Den-en-toshi Lines",
                    "渋谷・中央林間方面", "for Shibuya & Chuo-Rinkan"),
            through("Tobu.TobuSkytree", "KitaSenju", .descending,
                    "東京メトロ日比谷線", "Tokyo Metro Hibiya Line",
                    "中目黒方面", "for Naka-meguro"),
            through("Tobu.TobuSkytree", "TobuDobutsuKoen", .ascending,
                    "東武伊勢崎線", "Tobu Isesaki Line", "久喜方面", "for Kuki"),
            through("Tobu.TobuSkytree", "TobuDobutsuKoen", .ascending,
                    "東武日光線", "Tobu Nikko Line", "南栗橋方面", "for Minami-Kurihashi"),
        ]
    )

    // MARK: Tobu Tojo Line (TJ)

    static let tojo = StaticTrainLine(
        id: "odpt.Railway:Tobu.Tojo",
        nameJa: "東武東上線",
        nameEn: "Tobu Tojo Line",
        operatorId: "odpt.Operator:Tobu",
        colorHex: "#00479D",
        stations: [
            st("Tobu.Tojo", "Ikebukuro", "池袋", "Ikebukuro", "TJ01", 35.7298, 139.7100),
            st("Tobu.Tojo", "KitaIkebukuro", "北池袋", "Kita-Ikebukuro", "TJ02", 35.7398, 139.7152),
            st("Tobu.Tojo", "ShimoItabashi", "下板橋", "Shimo-Itabashi", "TJ03", 35.7458, 139.7142),
            st("Tobu.Tojo", "Oyama", "大山", "Oyama", "TJ04", 35.7528, 139.7052),
            st("Tobu.Tojo", "Nakaitabashi", "中板橋", "Nakaitabashi", "TJ05", 35.7578, 139.6952),
            st("Tobu.Tojo", "Tokiwadai", "ときわ台", "Tokiwadai", "TJ06", 35.7618, 139.6872),
            st("Tobu.Tojo", "KamiItabashi", "上板橋", "Kami-Itabashi", "TJ07", 35.7658, 139.6772),
            st("Tobu.Tojo", "TobuNerima", "東武練馬", "Tobu-Nerima", "TJ08", 35.7688, 139.6652),
            st("Tobu.Tojo", "ShimoAkatsuka", "下赤塚", "Shimo-Akatsuka", "TJ09", 35.7728, 139.6482),
            st("Tobu.Tojo", "Narimasu", "成増", "Narimasu", "TJ10", 35.7768, 139.6332),
            st("Tobu.Tojo", "Wakoshi", "和光市", "Wakoshi", "TJ11", 35.7887, 139.6122),
            st("Tobu.Tojo", "Asaka", "朝霞", "Asaka", "TJ12", 35.7968, 139.5932),
            st("Tobu.Tojo", "Asakadai", "朝霞台", "Asakadai", "TJ13", 35.8088, 139.5918),
            st("Tobu.Tojo", "Shiki", "志木", "Shiki", "TJ14", 35.8188, 139.5822),
            st("Tobu.Tojo", "Yanasegawa", "柳瀬川", "Yanasegawa", "TJ15", 35.8278, 139.5722),
            st("Tobu.Tojo", "Mizuhodai", "みずほ台", "Mizuhodai", "TJ16", 35.8378, 139.5652),
            st("Tobu.Tojo", "Tsuruse", "鶴瀬", "Tsuruse", "TJ17", 35.8478, 139.5562),
            st("Tobu.Tojo", "Fujimino", "ふじみ野", "Fujimino", "TJ18", 35.8588, 139.5482),
            st("Tobu.Tojo", "KamiFukuoka", "上福岡", "Kami-Fukuoka", "TJ19", 35.8708, 139.5372),
            st("Tobu.Tojo", "Shingashi", "新河岸", "Shingashi", "TJ20", 35.8868, 139.5172),
            st("Tobu.Tojo", "Kawagoe", "川越", "Kawagoe", "TJ21", 35.9078, 139.4822),
            st("Tobu.Tojo", "Kawagoeshi", "川越市", "Kawagoeshi", "TJ22", 35.9148, 139.4772),
            st("Tobu.Tojo", "Kasumigaseki", "霞ヶ関", "Kasumigaseki", "TJ23", 35.9208, 139.4402),
            st("Tobu.Tojo", "Tsurugashima", "鶴ヶ島", "Tsurugashima", "TJ24", 35.9338, 139.4162),
            st("Tobu.Tojo", "Wakaba", "若葉", "Wakaba", "TJ25", 35.9448, 139.4062),
            st("Tobu.Tojo", "Sakado", "坂戸", "Sakado", "TJ26", 35.9568, 139.3882),
            st("Tobu.Tojo", "KitaSakado", "北坂戸", "Kita-Sakado", "TJ27", 35.9718, 139.3802),
            st("Tobu.Tojo", "Takasaka", "高坂", "Takasaka", "TJ28", 35.9978, 139.3782),
            st("Tobu.Tojo", "HigashiMatsuyama", "東松山", "Higashi-Matsuyama", "TJ29", 36.0335, 139.3990),
            st("Tobu.Tojo", "ShinrinKoen", "森林公園", "Shinrin-Koen", "TJ30", 36.0458, 139.3802),
        ],
        hopTimesMinutes: [
            2, 1, 2, 2, 1, 2, 2, 2, 2, 3, 2, 3, 2, 2,
            2, 2, 2, 2, 3, 3, 2, 4, 2, 2, 2, 2, 3, 4, 3,
        ],
        directions: [
            direction("Tobu.Tojo", "ShinrinKoen", "川越・森林公園方面", "For Kawagoe & Shinrin-Koen", ascending: true,
                      weekday: pattern("05:00", "23:45", [
                          ("05:00", 10), ("06:30", 4.5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:00", "23:45", [
                          ("05:00", 10), ("07:00", 7), ("10:00", 8), ("20:00", 9),
                      ])),
            direction("Tobu.Tojo", "Ikebukuro", "池袋方面", "For Ikebukuro", ascending: false,
                      weekday: pattern("05:00", "23:45", [
                          ("05:00", 10), ("06:30", 4.5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:00", "23:45", [
                          ("05:00", 10), ("07:00", 7), ("10:00", 8), ("20:00", 9),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Tobu.Tojo", "Wakoshi", .descending,
                    "東京メトロ有楽町線・副都心線", "Tokyo Metro Yurakucho & Fukutoshin Lines",
                    "新木場・横浜方面", "for Shin-kiba & Yokohama"),
            through("Tobu.Tojo", "ShinrinKoen", .ascending,
                    "東武東上線", "Tobu Tojo Line", "小川町方面", "for Ogawamachi"),
        ]
    )
}
