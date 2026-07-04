import Foundation

// MARK: - Tobu Line Data

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

enum TobuLineData {

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.tobu.co.jp/service_status/",
        statusPageURLEn: "https://www.tobu.co.jp/en/",
        xAccount: "@TobuRailway_JP",
        checkMethodJa: "東武鉄道「運行情報」ページ、東武線アプリ、またはX（@TobuRailway_JP）で確認できます。おおむね10分以上の遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Tobu Railway service status page, the Tobu app, or X (@TobuRailway_JP). Delays of roughly 10 minutes or more and suspensions are posted."
    )

    static let lines: [StaticTrainLine] = [
        skytree, tojo, kameido, daishi, urbanPark, nikko,
    ]

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
            through("Tobu.TobuSkytree.Oshiage", .descending,
                    "東京メトロ半蔵門線・東急田園都市線", "Tokyo Metro Hanzomon & Tokyu Den-en-toshi Lines",
                    "渋谷・中央林間方面", "for Shibuya & Chuo-Rinkan",
                    to: "odpt.Railway:TokyoMetro.Hanzomon"),
            through("Tobu.TobuSkytree.KitaSenju", .descending,
                    "東京メトロ日比谷線", "Tokyo Metro Hibiya Line",
                    "中目黒方面", "for Naka-meguro",
                    to: "odpt.Railway:TokyoMetro.Hibiya"),
            through("Tobu.TobuSkytree.TobuDobutsuKoen", .ascending,
                    "東武伊勢崎線", "Tobu Isesaki Line", "久喜方面", "for Kuki"),
            through("Tobu.TobuSkytree.TobuDobutsuKoen", .ascending,
                    "東武日光線", "Tobu Nikko Line", "南栗橋方面", "for Minami-Kurihashi",
                    to: "odpt.Railway:Tobu.Nikko"),
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
            through("Tobu.Tojo.Wakoshi", .descending,
                    "東京メトロ有楽町線", "Tokyo Metro Yurakucho Line",
                    "新木場方面", "for Shin-kiba",
                    to: "odpt.Railway:TokyoMetro.Yurakucho"),
            through("Tobu.Tojo.Wakoshi", .descending,
                    "東京メトロ副都心線", "Tokyo Metro Fukutoshin Line",
                    "渋谷・横浜方面", "for Shibuya & Yokohama",
                    to: "odpt.Railway:TokyoMetro.Fukutoshin"),
            through("Tobu.Tojo.ShinrinKoen", .ascending,
                    "東武東上線", "Tobu Tojo Line", "小川町方面", "for Ogawamachi"),
        ]
    )

    // MARK: Tobu Kameido Line (TS)

    private static let kameidoWeekday = pattern("05:05", "23:45", [
        ("05:05", 10), ("07:00", 8), ("09:30", 10), ("22:00", 12),
    ])
    private static let kameidoHoliday = pattern("05:05", "23:45", [
        ("05:05", 10), ("22:00", 12),
    ])

    static let kameido = StaticTrainLine(
        id: "odpt.Railway:Tobu.Kameido",
        nameJa: "東武亀戸線",
        nameEn: "Tobu Kameido Line",
        operatorId: "odpt.Operator:Tobu",
        colorHex: "#C7A367",
        stations: [
            st("Tobu.Kameido", "Hikifune", "曳舟", "Hikifune", "TS04", 35.7168, 139.8172),
            st("Tobu.Kameido", "Omurai", "小村井", "Omurai", "TS41", 35.7101, 139.8280),
            st("Tobu.Kameido", "HigashiAzuma", "東あずま", "Higashi-Azuma", "TS42", 35.7071, 139.8319),
            st("Tobu.Kameido", "KameidoSuijin", "亀戸水神", "Kameido-Suijin", "TS43", 35.7003, 139.8337),
            st("Tobu.Kameido", "Kameido", "亀戸", "Kameido", "TS44", 35.6976, 139.8261),
        ],
        hopTimesMinutes: [3, 1, 2, 2],
        directions: [
            direction("Tobu.Kameido", "Kameido", "亀戸方面", "For Kameido", ascending: true,
                      weekday: kameidoWeekday, holiday: kameidoHoliday),
            direction("Tobu.Kameido", "Hikifune", "曳舟方面", "For Hikifune", ascending: false,
                      weekday: kameidoWeekday, holiday: kameidoHoliday),
        ],
        delayInfo: delayInfo
    )

    // MARK: Tobu Daishi Line (TS)

    private static let daishiPattern = pattern("05:10", "23:40", [
        ("05:10", 10),
    ])

    static let daishi = StaticTrainLine(
        id: "odpt.Railway:Tobu.Daishi",
        nameJa: "東武大師線",
        nameEn: "Tobu Daishi Line",
        operatorId: "odpt.Operator:Tobu",
        colorHex: "#777195",
        stations: [
            st("Tobu.Daishi", "Nishiarai", "西新井", "Nishiarai", "TS13", 35.7775, 139.7925),
            st("Tobu.Daishi", "Daishimae", "大師前", "Daishimae", "TS51", 35.7789, 139.7815),
        ],
        hopTimesMinutes: [2],
        directions: [
            direction("Tobu.Daishi", "Daishimae", "大師前方面", "For Daishimae", ascending: true,
                      weekday: daishiPattern, holiday: daishiPattern),
            direction("Tobu.Daishi", "Nishiarai", "西新井方面", "For Nishiarai", ascending: false,
                      weekday: daishiPattern, holiday: daishiPattern),
        ],
        delayInfo: delayInfo
    )

    // MARK: Tobu Urban Park Line (TD)

    private static let urbanParkWeekday = pattern("05:00", "23:30", [
        ("05:00", 10), ("06:30", 6), ("09:30", 10), ("16:30", 8), ("20:00", 10), ("22:00", 12),
    ])
    private static let urbanParkHoliday = pattern("05:00", "23:30", [
        ("05:00", 10), ("20:00", 11),
    ])

    static let urbanPark = StaticTrainLine(
        id: "odpt.Railway:Tobu.TobuUrbanPark",
        nameJa: "東武アーバンパークライン",
        nameEn: "Tobu Urban Park Line",
        operatorId: "odpt.Operator:Tobu",
        colorHex: "#40B3E5",
        stations: [
            st("Tobu.TobuUrbanPark", "Omiya", "大宮", "Omiya", "TD01", 35.9076, 139.6244),
            st("Tobu.TobuUrbanPark", "KitaOmiya", "北大宮", "Kita-Omiya", "TD02", 35.9171, 139.6247),
            st("Tobu.TobuUrbanPark", "OmiyaKoen", "大宮公園", "Omiya-Koen", "TD03", 35.9236, 139.6324),
            st("Tobu.TobuUrbanPark", "Owada", "大和田", "Owada", "TD04", 35.9293, 139.6505),
            st("Tobu.TobuUrbanPark", "Nanasato", "七里", "Nanasato", "TD05", 35.9363, 139.6658),
            st("Tobu.TobuUrbanPark", "Iwatsuki", "岩槻", "Iwatsuki", "TD06", 35.9501, 139.6929),
            st("Tobu.TobuUrbanPark", "HigashiIwatsuki", "東岩槻", "Higashi-Iwatsuki", "TD07", 35.9634, 139.7124),
            st("Tobu.TobuUrbanPark", "Toyoharu", "豊春", "Toyoharu", "TD08", 35.9680, 139.7262),
            st("Tobu.TobuUrbanPark", "Yagisaki", "八木崎", "Yagisaki", "TD09", 35.9785, 139.7420),
            st("Tobu.TobuUrbanPark", "Kasukabe", "春日部", "Kasukabe", "TD10", 35.9778, 139.7522),
            st("Tobu.TobuUrbanPark", "Fujinoushijima", "藤の牛島", "Fujinoushijima", "TD11", 35.9802, 139.7778),
            st("Tobu.TobuUrbanPark", "MinamiSakurai", "南桜井", "Minami-Sakurai", "TD12", 35.9805, 139.8080),
            st("Tobu.TobuUrbanPark", "Kawama", "川間", "Kawama", "TD13", 35.9792, 139.8339),
            st("Tobu.TobuUrbanPark", "Nanakodai", "七光台", "Nanakodai", "TD14", 35.9709, 139.8528),
            st("Tobu.TobuUrbanPark", "ShimizuKoen", "清水公園", "Shimizu-Koen", "TD15", 35.9592, 139.8600),
            st("Tobu.TobuUrbanPark", "Atago", "愛宕", "Atago", "TD16", 35.9501, 139.8648),
            st("Tobu.TobuUrbanPark", "Nodashi", "野田市", "Nodashi", "TD17", 35.9434, 139.8708),
            st("Tobu.TobuUrbanPark", "Umesato", "梅郷", "Umesato", "TD18", 35.9313, 139.8912),
            st("Tobu.TobuUrbanPark", "Unga", "運河", "Unga", "TD19", 35.9146, 139.9058),
            st("Tobu.TobuUrbanPark", "Edogawadai", "江戸川台", "Edogawadai", "TD20", 35.8975, 139.9101),
            st("Tobu.TobuUrbanPark", "Hatsuishi", "初石", "Hatsuishi", "TD21", 35.8841, 139.9176),
            st("Tobu.TobuUrbanPark", "NagareyamaOtakanomori", "流山おおたかの森", "Nagareyama-Otakanomori", "TD22", 35.8721, 139.9259),
            st("Tobu.TobuUrbanPark", "Toyoshiki", "豊四季", "Toyoshiki", "TD23", 35.8665, 139.9395),
            st("Tobu.TobuUrbanPark", "Kashiwa", "柏", "Kashiwa", "TD24", 35.8622, 139.9706),
            st("Tobu.TobuUrbanPark", "ShinKashiwa", "新柏", "Shin-Kashiwa", "TD25", 35.8381, 139.9671),
            st("Tobu.TobuUrbanPark", "Masuo", "増尾", "Masuo", "TD26", 35.8296, 139.9767),
            st("Tobu.TobuUrbanPark", "Sakasai", "逆井", "Sakasai", "TD27", 35.8232, 139.9839),
            st("Tobu.TobuUrbanPark", "Takayanagi", "高柳", "Takayanagi", "TD28", 35.8085, 139.9990),
            st("Tobu.TobuUrbanPark", "Mutsumi", "六実", "Mutsumi", "TD29", 35.7937, 139.9992),
            st("Tobu.TobuUrbanPark", "ShinKamagaya", "新鎌ヶ谷", "Shin-Kamagaya", "TD30", 35.7803, 139.9994),
            st("Tobu.TobuUrbanPark", "Kamagaya", "鎌ヶ谷", "Kamagaya", "TD31", 35.7640, 139.9972),
            st("Tobu.TobuUrbanPark", "Magomezawa", "馬込沢", "Magomezawa", "TD32", 35.7417, 139.9923),
            st("Tobu.TobuUrbanPark", "Tsukada", "塚田", "Tsukada", "TD33", 35.7220, 139.9828),
            st("Tobu.TobuUrbanPark", "ShinFunabashi", "新船橋", "Shin-Funabashi", "TD34", 35.7109, 139.9798),
            st("Tobu.TobuUrbanPark", "Funabashi", "船橋", "Funabashi", "TD35", 35.7021, 139.9847),
        ],
        hopTimesMinutes: [
            2, 1, 2, 2, 4, 3, 2, 2, 2, 3, 3, 3, 3, 2, 2, 1, 3,
            3, 2, 2, 2, 2, 4, 3, 2, 1, 3, 2, 2, 2, 3, 3, 2, 2,
        ],
        directions: [
            direction("Tobu.TobuUrbanPark", "Funabashi", "柏・船橋方面", "For Kashiwa & Funabashi", ascending: true,
                      weekday: urbanParkWeekday, holiday: urbanParkHoliday),
            direction("Tobu.TobuUrbanPark", "Omiya", "大宮方面", "For Omiya", ascending: false,
                      weekday: urbanParkWeekday, holiday: urbanParkHoliday),
        ],
        delayInfo: delayInfo
    )

    // MARK: Tobu Nikko Line (TN)

    private static let nikkoWeekday = pattern("05:00", "22:40", [
        ("05:00", 30), ("06:30", 20), ("09:30", 30), ("17:00", 20), ("20:00", 30),
    ])
    private static let nikkoHoliday = pattern("05:00", "22:40", [
        ("05:00", 30),
    ])

    static let nikko = StaticTrainLine(
        id: "odpt.Railway:Tobu.Nikko",
        nameJa: "東武日光線",
        nameEn: "Tobu Nikko Line",
        operatorId: "odpt.Operator:Tobu",
        colorHex: "#FFA600",
        stations: [
            st("Tobu.Nikko", "TobuDobutsuKoen", "東武動物公園", "Tobu-Dobutsu-Koen", "TS30", 36.0208, 139.7292),
            st("Tobu.Nikko", "SugitoTakanodai", "杉戸高野台", "Sugito-Takanodai", "TN01", 36.0516, 139.7146),
            st("Tobu.Nikko", "Satte", "幸手", "Satte", "TN02", 36.0748, 139.7151),
            st("Tobu.Nikko", "MinamiKurihashi", "南栗橋", "Minami-Kurihashi", "TN03", 36.1132, 139.7129),
            st("Tobu.Nikko", "Kurihashi", "栗橋", "Kurihashi", "TN04", 36.1369, 139.6942),
            st("Tobu.Nikko", "ShinKoga", "新古河", "Shin-Koga", "TN05", 36.1927, 139.6869),
            st("Tobu.Nikko", "Yagyu", "柳生", "Yagyu", "TN06", 36.2066, 139.6596),
            st("Tobu.Nikko", "ItakuraToyodaimae", "板倉東洋大前", "Itakura-Toyodaimae", "TN07", 36.2221, 139.6485),
            st("Tobu.Nikko", "Fujioka", "藤岡", "Fujioka", "TN08", 36.2556, 139.6453),
            st("Tobu.Nikko", "Shizuwa", "静和", "Shizuwa", "TN09", 36.3170, 139.6851),
            st("Tobu.Nikko", "ShinOhirashita", "新大平下", "Shin-Ohirashita", "TN10", 36.3386, 139.7015),
            st("Tobu.Nikko", "Tochigi", "栃木", "Tochigi", "TN11", 36.3717, 139.7310),
            st("Tobu.Nikko", "ShinTochigi", "新栃木", "Shin-Tochigi", "TN12", 36.3897, 139.7423),
            st("Tobu.Nikko", "Kassemba", "合戦場", "Kassemba", "TN13", 36.4080, 139.7413),
            st("Tobu.Nikko", "Ienaka", "家中", "Ienaka", "TN14", 36.4293, 139.7474),
            st("Tobu.Nikko", "TobuKanasaki", "東武金崎", "Tobu-Kanasaki", "TN15", 36.4664, 139.7494),
            st("Tobu.Nikko", "Nireki", "楡木", "Nireki", "TN16", 36.5072, 139.7454),
            st("Tobu.Nikko", "Momiyama", "樅山", "Momiyama", "TN17", 36.5332, 139.7419),
            st("Tobu.Nikko", "ShinKanuma", "新鹿沼", "Shin-Kanuma", "TN18", 36.5572, 139.7450),
            st("Tobu.Nikko", "KitaKanuma", "北鹿沼", "Kita-Kanuma", "TN19", 36.5814, 139.7374),
            st("Tobu.Nikko", "Itaga", "板荷", "Itaga", "TN20", 36.6199, 139.7078),
            st("Tobu.Nikko", "ShimoGoshiro", "下小代", "Shimo-Goshiro", "TN21", 36.6510, 139.7137),
            st("Tobu.Nikko", "Myojin", "明神", "Myojin", "TN22", 36.6763, 139.7122),
            st("Tobu.Nikko", "ShimoImaichi", "下今市", "Shimo-Imaichi", "TN23", 36.7256, 139.6922),
            st("Tobu.Nikko", "KamiImaichi", "上今市", "Kami-Imaichi", "TN24", 36.7278, 139.6816),
            st("Tobu.Nikko", "TobuNikko", "東武日光", "Tobu-Nikko", "TN25", 36.7479, 139.6195),
        ],
        hopTimesMinutes: [
            4, 3, 6, 5, 9, 4, 3, 5, 10, 4, 6, 4, 3,
            3, 5, 6, 4, 3, 4, 7, 5, 4, 8, 2, 8,
        ],
        directions: [
            direction("Tobu.Nikko", "TobuNikko", "東武日光方面", "For Tobu-Nikko", ascending: true,
                      weekday: nikkoWeekday, holiday: nikkoHoliday),
            direction("Tobu.Nikko", "TobuDobutsuKoen", "東武動物公園方面", "For Tobu-Dobutsu-Koen", ascending: false,
                      weekday: nikkoWeekday, holiday: nikkoHoliday),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Tobu.Nikko.TobuDobutsuKoen", .descending,
                    "東武スカイツリーライン", "Tobu Skytree Line",
                    "北千住・浅草方面", "for Kita-Senju & Asakusa",
                    to: "odpt.Railway:Tobu.TobuSkytree"),
            through("Tobu.Nikko.ShimoImaichi", .ascending,
                    "東武鬼怒川線", "Tobu Kinugawa Line",
                    "鬼怒川温泉方面", "for Kinugawa-Onsen"),
        ]
    )
}
