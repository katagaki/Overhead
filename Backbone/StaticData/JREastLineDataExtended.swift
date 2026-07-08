import Foundation

// MARK: - JR East Line Data (Extended)

private func st(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "Station:JR-East.\(line).\(suffix)",
        name: ja, nameEn: en, stationCode: code,
        latitude: lat, longitude: lon
    )
}

private func pattern(_ first: String, _ last: String, _ bands: [(String, Double)],
                     _ trainType: TrainService.TrainType = .local) -> ServicePattern {
    ServicePattern(
        first: first, last: last,
        bands: bands.map { HeadwayBand(from: $0.0, headwayMinutes: $0.1) },
        trainType: trainType
    )
}

private func direction(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                       ascending: Bool,
                       weekday: ServicePattern, holiday: ServicePattern) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:JR-East.\(line).\(suffix)",
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
        junctionStationId: "Station:JR-East.\(junction)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

extension JREastLineData {

    static var extendedLines: [StaticTrainLine] {
        [
            jobanRapid, jobanLocal, yokosukaSobu, tokaido, shonanShinjuku,
            utsunomiya, takasaki, yokohamaLine, nambu, musashino, keiyoBranch,
            ome, itsukaichi,
        ]
    }

    // MARK: - Joban Rapid Line (JJ)

    static let jobanRapid = StaticTrainLine(
        id: "Railway:JR-East.JobanRapid",
        nameJa: "常磐線快速",
        nameEn: "Joban Rapid Line",
        operatorId: "Operator:JR-East",
        colorHex: "#00B261",
        // The 品川–東京–上野 corridor (上野東京ライン) is part of the official
        // JJ line: through trains all continue to 品川, so it is modeled as
        // line stations rather than a through service.
        stations: [
            st("JobanRapid", "Shinagawa", "品川", "Shinagawa", "JJ01", 35.6285, 139.7388),
            st("JobanRapid", "Shimbashi", "新橋", "Shimbashi", "JJ02", 35.6663, 139.7583),
            st("JobanRapid", "Tokyo", "東京", "Tokyo", "JJ03", 35.6812, 139.7671),
            st("JobanRapid", "Ueno", "上野", "Ueno", "JJ04", 35.7141, 139.7774),
            st("JobanRapid", "Nippori", "日暮里", "Nippori", "JJ05", 35.7278, 139.7708),
            st("JobanRapid", "Mikawashima", "三河島", "Mikawashima", "JJ06", 35.7325, 139.7794),
            st("JobanRapid", "MinamiSenju", "南千住", "Minami-Senju", "JJ07", 35.7333, 139.7995),
            st("JobanRapid", "KitaSenju", "北千住", "Kita-Senju", "JJ08", 35.7497, 139.8047),
            st("JobanRapid", "Matsudo", "松戸", "Matsudo", "JJ09", 35.7841, 139.9010),
            st("JobanRapid", "Kashiwa", "柏", "Kashiwa", "JJ10", 35.8622, 139.9707),
            st("JobanRapid", "Abiko", "我孫子", "Abiko", "JJ11", 35.8687, 140.0277),
            st("JobanRapid", "Tennodai", "天王台", "Tennodai", "JJ12", 35.8700, 140.0672),
            st("JobanRapid", "Toride", "取手", "Toride", "JJ13", 35.8973, 140.0629),
        ],
        hopTimesMinutes: [5, 3, 5, 4, 3, 3, 3, 7, 6, 6, 3, 4],
        directions: [
            // NOTE: the down direction's origin moved 上野 → 品川 when the
            // corridor was added. The verified 上野 times (first 04:33 /
            // last 24:33, March-2026 revision) are preserved by shifting the
            // origin pattern back by the 13-minute 品川→上野 run; early
            // trains that really originate at 上野 appear as phantom 品川
            // departures (full-line-only generator).
            direction("JobanRapid", "Toride", "取手方面", "For Toride", ascending: true,
                      weekday: pattern("04:20", "24:20", [
                          ("04:20", 8), ("06:17", 5), ("09:17", 12), ("16:17", 6), ("19:47", 8), ("21:47", 10),
                      ], .rapid),
                      holiday: pattern("04:20", "24:20", [
                          ("04:20", 8), ("06:47", 6), ("09:47", 12), ("19:47", 8), ("21:47", 10),
                      ], .rapid)),
            direction("JobanRapid", "Ueno", "上野・品川方面", "For Ueno & Shinagawa", ascending: false,
                      weekday: pattern("04:44", "24:18", [
                          ("04:44", 8), ("06:00", 5), ("09:30", 7), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ], .rapid),
                      holiday: pattern("04:44", "24:18", [
                          ("04:44", 8), ("07:00", 6), ("10:00", 7), ("20:00", 8), ("22:00", 10),
                      ], .rapid)),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("JobanRapid.Toride", .ascending,
                    "常磐線", "JR Joban Line", "土浦・水戸方面", "for Tsuchiura & Mito"),
        ]
    )

    // MARK: - Joban Local Line (JL)

    static let jobanLocal = StaticTrainLine(
        id: "Railway:JR-East.JobanLocal",
        nameJa: "常磐線各駅停車",
        nameEn: "Joban Local Line",
        operatorId: "Operator:JR-East",
        // JR East signage renders the Joban Local (JL) line in gray
        colorHex: "#999999",
        stations: [
            st("JobanLocal", "Ayase", "綾瀬", "Ayase", "JL19", 35.7620, 139.8247),
            st("JobanLocal", "Kameari", "亀有", "Kameari", "JL20", 35.7669, 139.8488),
            st("JobanLocal", "Kanamachi", "金町", "Kanamachi", "JL21", 35.7692, 139.8709),
            st("JobanLocal", "Matsudo", "松戸", "Matsudo", "JL22", 35.7841, 139.9010),
            st("JobanLocal", "KitaMatsudo", "北松戸", "Kita-Matsudo", "JL23", 35.7988, 139.9130),
            st("JobanLocal", "Mabashi", "馬橋", "Mabashi", "JL24", 35.8093, 139.9200),
            st("JobanLocal", "ShimMatsudo", "新松戸", "Shim-Matsudo", "JL25", 35.8260, 139.9336),
            st("JobanLocal", "KitaKogane", "北小金", "Kita-Kogane", "JL26", 35.8332, 139.9442),
            st("JobanLocal", "MinamiKashiwa", "南柏", "Minami-Kashiwa", "JL27", 35.8460, 139.9600),
            st("JobanLocal", "Kashiwa", "柏", "Kashiwa", "JL28", 35.8622, 139.9707),
            st("JobanLocal", "KitaKashiwa", "北柏", "Kita-Kashiwa", "JL29", 35.8722, 139.9932),
            st("JobanLocal", "Abiko", "我孫子", "Abiko", "JL30", 35.8687, 140.0277),
            st("JobanLocal", "Tennodai", "天王台", "Tennodai", "JL31", 35.8700, 140.0672),
            st("JobanLocal", "Toride", "取手", "Toride", "JL32", 35.8973, 140.0629),
        ],
        hopTimesMinutes: [3, 2, 4, 3, 2, 2, 2, 3, 3, 3, 3, 3, 4],
        directions: [
            direction("JobanLocal", "Toride", "取手方面", "For Toride", ascending: true,
                      weekday: pattern("04:58", "24:52", [
                          ("04:58", 8), ("07:00", 6.5), ("09:30", 8), ("16:30", 5), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:58", "24:52", [
                          ("04:58", 8), ("07:00", 7), ("10:00", 8), ("20:00", 9),
                      ])),
            // NOTE: only the Toride end is rush-hours-only (midday locals
            // originate at Abiko); the direction as a whole runs all day and
            // feeds the 千代田線/小田急線 through service, so model all-day.
            direction("JobanLocal", "Ayase", "綾瀬方面", "For Ayase", ascending: false,
                      weekday: pattern("04:40", "24:00", [
                          ("04:40", 8), ("07:00", 6.5), ("09:30", 8), ("16:30", 5), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:40", "24:00", [
                          ("04:40", 8), ("07:00", 7), ("10:00", 8), ("20:00", 9),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("JobanLocal.Ayase", .descending,
                    "東京メトロ千代田線", "Tokyo Metro Chiyoda Line",
                    "代々木上原・小田急線方面", "for Yoyogi-Uehara & the Odakyu Line",
                    to: "Railway:TokyoMetro.Chiyoda"),
        ]
    )

    // MARK: - Yokosuka / Sobu Rapid Line (JO)

    static let yokosukaSobu = StaticTrainLine(
        id: "Railway:JR-East.YokosukaSobu",
        nameJa: "横須賀・総武線快速",
        nameEn: "Yokosuka-Sobu Rapid Line",
        operatorId: "Operator:JR-East",
        colorHex: "#0072BC",
        stations: [
            st("YokosukaSobu", "Kurihama", "久里浜", "Kurihama", "JO01", 35.2333, 139.7057),
            st("YokosukaSobu", "Kinugasa", "衣笠", "Kinugasa", "JO02", 35.2512, 139.6688),
            st("YokosukaSobu", "Yokosuka", "横須賀", "Yokosuka", "JO03", 35.2872, 139.6598),
            st("YokosukaSobu", "Taura", "田浦", "Taura", "JO04", 35.3012, 139.6358),
            st("YokosukaSobu", "HigashiZushi", "東逗子", "Higashi-Zushi", "JO05", 35.3012, 139.6008),
            st("YokosukaSobu", "Zushi", "逗子", "Zushi", "JO06", 35.2953, 139.5798),
            st("YokosukaSobu", "Kamakura", "鎌倉", "Kamakura", "JO07", 35.3192, 139.5468),
            st("YokosukaSobu", "KitaKamakura", "北鎌倉", "Kita-Kamakura", "JO08", 35.3372, 139.5468),
            st("YokosukaSobu", "Ofuna", "大船", "Ofuna", "JO09", 35.3540, 139.5313),
            st("YokosukaSobu", "Totsuka", "戸塚", "Totsuka", "JO10", 35.4008, 139.5342),
            st("YokosukaSobu", "HigashiTotsuka", "東戸塚", "Higashi-Totsuka", "JO11", 35.4232, 139.5578),
            st("YokosukaSobu", "Hodogaya", "保土ケ谷", "Hodogaya", "JO12", 35.4442, 139.5968),
            st("YokosukaSobu", "Yokohama", "横浜", "Yokohama", "JO13", 35.4657, 139.6224),
            st("YokosukaSobu", "ShinKawasaki", "新川崎", "Shin-Kawasaki", "JO14", 35.5352, 139.6468),
            st("YokosukaSobu", "MusashiKosugi", "武蔵小杉", "Musashi-Kosugi", "JO15", 35.5766, 139.6597),
            st("YokosukaSobu", "NishiOi", "西大井", "Nishi-Oi", "JO16", 35.6012, 139.7218),
            st("YokosukaSobu", "Shinagawa", "品川", "Shinagawa", "JO17", 35.6285, 139.7388),
            st("YokosukaSobu", "Shimbashi", "新橋", "Shimbashi", "JO18", 35.6663, 139.7583),
            st("YokosukaSobu", "Tokyo", "東京", "Tokyo", "JO19", 35.6812, 139.7671),
            st("YokosukaSobu", "ShinNihombashi", "新日本橋", "Shin-Nihombashi", "JO20", 35.6892, 139.7738),
            st("YokosukaSobu", "Bakurocho", "馬喰町", "Bakurocho", "JO21", 35.6932, 139.7828),
            st("YokosukaSobu", "Kinshicho", "錦糸町", "Kinshicho", "JO22", 35.6967, 139.8140),
            st("YokosukaSobu", "ShinKoiwa", "新小岩", "Shin-Koiwa", "JO23", 35.7167, 139.8578),
            st("YokosukaSobu", "Ichikawa", "市川", "Ichikawa", "JO24", 35.7297, 139.9078),
            st("YokosukaSobu", "Funabashi", "船橋", "Funabashi", "JO25", 35.7019, 139.9853),
            st("YokosukaSobu", "Tsudanuma", "津田沼", "Tsudanuma", "JO26", 35.6913, 140.0200),
            st("YokosukaSobu", "Inage", "稲毛", "Inage", "JO27", 35.6333, 140.0900),
            st("YokosukaSobu", "Chiba", "千葉", "Chiba", "JO28", 35.6131, 140.1136),
        ],
        hopTimesMinutes: [
            4, 4, 3, 3, 3, 5, 3, 3, 5, 4, 4, 4, 7, 3,
            7, 5, 4, 3, 2, 2, 4, 5, 5, 6, 4, 6, 5,
        ],
        directions: [
            direction("YokosukaSobu", "Chiba", "東京・千葉方面", "For Tokyo & Chiba", ascending: true,
                      weekday: pattern("04:31", "23:11", [
                          ("04:31", 15), ("06:30", 15), ("09:30", 20), ("16:30", 15), ("20:00", 20), ("22:00", 30),
                      ], .rapid),
                      holiday: pattern("04:31", "23:11", [
                          ("04:31", 15), ("07:00", 15), ("10:00", 20), ("20:00", 25),
                      ], .rapid)),
            direction("YokosukaSobu", "Kurihama", "横浜・久里浜方面", "For Yokohama & Kurihama", ascending: false,
                      weekday: pattern("04:45", "24:15", [
                          ("04:45", 10), ("06:30", 5), ("09:30", 9), ("16:30", 7), ("20:00", 9), ("22:00", 12),
                      ], .rapid),
                      holiday: pattern("04:45", "24:15", [
                          ("04:45", 10), ("07:00", 7), ("10:00", 9), ("20:00", 10),
                      ], .rapid)),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("YokosukaSobu.Chiba", .ascending,
                    "総武本線・成田線", "JR Sobu Main & Narita Lines",
                    "成田空港・君津方面", "for Narita Airport & Kimitsu"),
        ]
    )

    // MARK: - Tokaido Line (JT)

    static let tokaido = StaticTrainLine(
        id: "Railway:JR-East.Tokaido",
        nameJa: "東海道線",
        nameEn: "Tokaido Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F68B1E",
        stations: [
            st("Tokaido", "Tokyo", "東京", "Tokyo", "JT01", 35.6812, 139.7671),
            st("Tokaido", "Shimbashi", "新橋", "Shimbashi", "JT02", 35.6663, 139.7583),
            st("Tokaido", "Shinagawa", "品川", "Shinagawa", "JT03", 35.6285, 139.7388),
            st("Tokaido", "Kawasaki", "川崎", "Kawasaki", "JT04", 35.5308, 139.6970),
            st("Tokaido", "Yokohama", "横浜", "Yokohama", "JT05", 35.4657, 139.6224),
            st("Tokaido", "Totsuka", "戸塚", "Totsuka", "JT06", 35.4008, 139.5342),
            st("Tokaido", "Ofuna", "大船", "Ofuna", "JT07", 35.3540, 139.5313),
            st("Tokaido", "Fujisawa", "藤沢", "Fujisawa", "JT08", 35.3387, 139.4872),
            st("Tokaido", "Tsujido", "辻堂", "Tsujido", "JT09", 35.3362, 139.4468),
            st("Tokaido", "Chigasaki", "茅ケ崎", "Chigasaki", "JT10", 35.3302, 139.4068),
            st("Tokaido", "Hiratsuka", "平塚", "Hiratsuka", "JT11", 35.3272, 139.3498),
            st("Tokaido", "Oiso", "大磯", "Oiso", "JT12", 35.3112, 139.3128),
            st("Tokaido", "Ninomiya", "二宮", "Ninomiya", "JT13", 35.2992, 139.2558),
            st("Tokaido", "Kozu", "国府津", "Kozu", "JT14", 35.2812, 139.2128),
            st("Tokaido", "Kamonomiya", "鴨宮", "Kamonomiya", "JT15", 35.2682, 139.1828),
            st("Tokaido", "Odawara", "小田原", "Odawara", "JT16", 35.2563, 139.1552),
            st("Tokaido", "Hayakawa", "早川", "Hayakawa", "JT17", 35.2382, 139.1498),
            st("Tokaido", "Nebukawa", "根府川", "Nebukawa", "JT18", 35.2082, 139.1358),
            st("Tokaido", "Manazuru", "真鶴", "Manazuru", "JT19", 35.1622, 139.1218),
            st("Tokaido", "Yugawara", "湯河原", "Yugawara", "JT20", 35.1472, 139.1078),
            st("Tokaido", "Atami", "熱海", "Atami", "JT21", 35.1038, 139.0778),
        ],
        hopTimesMinutes: [
            3, 5, 8, 8, 10, 5, 4, 3, 3, 5, 4, 4, 4, 3, 4, 3, 4, 5, 3, 5,
        ],
        directions: [
            direction("Tokaido", "Atami", "小田原・熱海方面", "For Odawara & Atami", ascending: true,
                      weekday: pattern("05:20", "23:54", [
                          ("05:20", 10), ("06:30", 5), ("09:30", 9), ("16:30", 7), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:20", "23:54", [
                          ("05:20", 10), ("07:00", 7), ("10:00", 9), ("20:00", 11),
                      ])),
            direction("Tokaido", "Tokyo", "東京方面", "For Tokyo", ascending: false,
                      weekday: pattern("04:35", "23:07", [
                          ("04:35", 10), ("06:00", 5), ("09:30", 20), ("16:30", 7), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("04:35", "23:07", [
                          ("04:35", 10), ("07:00", 7), ("10:00", 20), ("20:00", 11),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Tokaido.Tokyo", .descending,
                    "宇都宮線（上野東京ライン）", "JR Utsunomiya Line (via Ueno-Tokyo Line)",
                    "宇都宮方面", "for Utsunomiya",
                    to: "Railway:JR-East.Utsunomiya"),
            through("Tokaido.Tokyo", .descending,
                    "高崎線（上野東京ライン）", "JR Takasaki Line (via Ueno-Tokyo Line)",
                    "高崎方面", "for Takasaki",
                    to: "Railway:JR-East.Takasaki"),
            through("Tokaido.Ofuna", .descending,
                    "湘南新宿ライン", "Shonan-Shinjuku Line",
                    "渋谷・新宿方面", "for Shibuya & Shinjuku",
                    to: "Railway:JR-East.ShonanShinjuku"),
            through("Tokaido.Atami", .ascending,
                    "伊東線", "JR Ito Line", "伊東方面", "for Ito"),
        ]
    )

    // MARK: - Shonan-Shinjuku Line (JS)

    static let shonanShinjuku = StaticTrainLine(
        id: "Railway:JR-East.ShonanShinjuku",
        nameJa: "湘南新宿ライン",
        nameEn: "Shonan-Shinjuku Line",
        operatorId: "Operator:JR-East",
        colorHex: "#E21F26",
        stations: [
            st("ShonanShinjuku", "Zushi", "逗子", "Zushi", "JS06", 35.2953, 139.5798),
            st("ShonanShinjuku", "Kamakura", "鎌倉", "Kamakura", "JS07", 35.3192, 139.5468),
            st("ShonanShinjuku", "KitaKamakura", "北鎌倉", "Kita-Kamakura", "JS08", 35.3372, 139.5468),
            st("ShonanShinjuku", "Ofuna", "大船", "Ofuna", "JS09", 35.3540, 139.5313),
            st("ShonanShinjuku", "Totsuka", "戸塚", "Totsuka", "JS10", 35.4008, 139.5342),
            st("ShonanShinjuku", "HigashiTotsuka", "東戸塚", "Higashi-Totsuka", "JS11", 35.4232, 139.5578),
            st("ShonanShinjuku", "Hodogaya", "保土ケ谷", "Hodogaya", "JS12", 35.4442, 139.5968),
            st("ShonanShinjuku", "Yokohama", "横浜", "Yokohama", "JS13", 35.4657, 139.6224),
            st("ShonanShinjuku", "ShinKawasaki", "新川崎", "Shin-Kawasaki", "JS14", 35.5352, 139.6468),
            st("ShonanShinjuku", "MusashiKosugi", "武蔵小杉", "Musashi-Kosugi", "JS15", 35.5766, 139.6597),
            st("ShonanShinjuku", "NishiOi", "西大井", "Nishi-Oi", "JS16", 35.6012, 139.7218),
            st("ShonanShinjuku", "Osaki", "大崎", "Osaki", "JS17", 35.6197, 139.7286),
            st("ShonanShinjuku", "Ebisu", "恵比寿", "Ebisu", "JS18", 35.6467, 139.7101),
            st("ShonanShinjuku", "Shibuya", "渋谷", "Shibuya", "JS19", 35.6580, 139.7016),
            st("ShonanShinjuku", "Shinjuku", "新宿", "Shinjuku", "JS20", 35.6896, 139.7006),
            st("ShonanShinjuku", "Ikebukuro", "池袋", "Ikebukuro", "JS21", 35.7295, 139.7109),
            st("ShonanShinjuku", "Akabane", "赤羽", "Akabane", "JS22", 35.7782, 139.7208),
            st("ShonanShinjuku", "Urawa", "浦和", "Urawa", "JS23", 35.8593, 139.6570),
            st("ShonanShinjuku", "Omiya", "大宮", "Omiya", "JS24", 35.9064, 139.6238),
        ],
        hopTimesMinutes: [
            6, 3, 3, 5, 4, 4, 4, 6, 3, 7, 3, 5, 3, 5, 5, 10, 8, 8,
        ],
        directions: [
            direction("ShonanShinjuku", "Omiya", "新宿・大宮方面", "For Shinjuku & Omiya", ascending: true,
                      weekday: pattern("06:54", "21:11", [
                          ("06:54", 30), ("09:30", 60), ("16:30", 30), ("20:00", 60),
                      ], .rapid),
                      holiday: pattern("06:57", "21:34", [
                          ("06:57", 40), ("10:00", 60), ("16:30", 40),
                      ], .rapid)),
            direction("ShonanShinjuku", "Zushi", "横浜・逗子方面", "For Yokohama & Zushi", ascending: false,
                      weekday: pattern("06:07", "22:26", [
                          ("06:07", 15), ("07:00", 12), ("09:30", 25), ("16:30", 15), ("20:00", 25),
                      ], .rapid),
                      holiday: pattern("06:07", "22:25", [
                          ("06:07", 15), ("08:00", 15), ("10:00", 25), ("20:00", 25),
                      ], .rapid)),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("ShonanShinjuku.Omiya", .ascending,
                    "宇都宮線", "JR Utsunomiya Line",
                    "宇都宮方面", "for Utsunomiya",
                    to: "Railway:JR-East.Utsunomiya"),
            through("ShonanShinjuku.Omiya", .ascending,
                    "高崎線", "JR Takasaki Line",
                    "高崎方面", "for Takasaki",
                    to: "Railway:JR-East.Takasaki"),
            through("ShonanShinjuku.Ofuna", .descending,
                    "東海道線", "JR Tokaido Line",
                    "藤沢・小田原方面", "for Fujisawa & Odawara",
                    to: "Railway:JR-East.Tokaido"),
        ]
    )

    // MARK: - Utsunomiya Line (JU)

    static let utsunomiya = StaticTrainLine(
        id: "Railway:JR-East.Utsunomiya",
        nameJa: "宇都宮線",
        nameEn: "Utsunomiya Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F68B1E",
        stations: [
            st("Utsunomiya", "Tokyo", "東京", "Tokyo", "JU01", 35.6812, 139.7671),
            st("Utsunomiya", "Ueno", "上野", "Ueno", "JU02", 35.7141, 139.7774),
            st("Utsunomiya", "Oku", "尾久", "Oku", "JU03", 35.7423, 139.7568),
            st("Utsunomiya", "Akabane", "赤羽", "Akabane", "JU04", 35.7782, 139.7208),
            st("Utsunomiya", "Urawa", "浦和", "Urawa", "JU05", 35.8593, 139.6570),
            st("Utsunomiya", "SaitamaShintoshin", "さいたま新都心", "Saitama-Shintoshin", "JU06", 35.8940, 139.6339),
            st("Utsunomiya", "Omiya", "大宮", "Omiya", "JU07", 35.9064, 139.6238),
            st("Utsunomiya", "Toro", "土呂", "Toro", "", 35.9288, 139.6318),
            st("Utsunomiya", "HigashiOmiya", "東大宮", "Higashi-Omiya", "", 35.9500, 139.6480),
            st("Utsunomiya", "Hasuda", "蓮田", "Hasuda", "", 35.9900, 139.6600),
            st("Utsunomiya", "Shiraoka", "白岡", "Shiraoka", "", 36.0182, 139.6718),
            st("Utsunomiya", "ShinShiraoka", "新白岡", "Shin-Shiraoka", "", 36.0378, 139.6798),
            st("Utsunomiya", "Kuki", "久喜", "Kuki", "", 36.0638, 139.6688),
            st("Utsunomiya", "HigashiWashinomiya", "東鷲宮", "Higashi-Washinomiya", "", 36.0872, 139.6718),
            st("Utsunomiya", "Kurihashi", "栗橋", "Kurihashi", "", 36.1369, 139.6942),
            st("Utsunomiya", "Koga", "古河", "Koga", "", 36.1832, 139.7078),
            st("Utsunomiya", "Nogi", "野木", "Nogi", "", 36.2158, 139.7148),
            st("Utsunomiya", "Mamada", "間々田", "Mamada", "", 36.2558, 139.7358),
            st("Utsunomiya", "Oyama", "小山", "Oyama", "", 36.3135, 139.8080),
            st("Utsunomiya", "Koganei", "小金井", "Koganei", "", 36.3550, 139.8570),
            st("Utsunomiya", "Jichiidai", "自治医大", "Jichiidai", "", 36.3912, 139.8668),
            st("Utsunomiya", "Ishibashi", "石橋", "Ishibashi", "", 36.4258, 139.8658),
            st("Utsunomiya", "Suzumenomiya", "雀宮", "Suzumenomiya", "", 36.4978, 139.8718),
            st("Utsunomiya", "Utsunomiya", "宇都宮", "Utsunomiya", "", 36.5591, 139.8988),
        ],
        hopTimesMinutes: [
            4, 5, 5, 8, 4, 3, 4, 3, 4, 4, 3, 4, 3, 5, 5, 4, 4, 5, 6, 4, 3, 5, 7,
        ],
        directions: [
            // First departure from Tokyo is 06:30 — earlier Ueno-Tokyo Line
            // departures on this corridor are Takasaki Line trains
            direction("Utsunomiya", "Utsunomiya", "宇都宮方面", "For Utsunomiya", ascending: true,
                      weekday: pattern("06:30", "23:32", [
                          ("06:30", 15), ("09:30", 14), ("16:30", 10), ("20:00", 14), ("22:00", 18),
                      ]),
                      holiday: pattern("06:30", "23:32", [
                          ("06:30", 15), ("10:00", 13), ("20:00", 15),
                      ])),
            direction("Utsunomiya", "Tokyo", "上野・東京方面", "For Ueno & Tokyo", ascending: false,
                      weekday: pattern("04:37", "22:42", [
                          ("04:37", 15), ("06:00", 15), ("09:30", 14), ("16:30", 10), ("20:00", 14), ("22:00", 18),
                      ]),
                      holiday: pattern("04:37", "22:42", [
                          ("04:37", 15), ("07:00", 10), ("10:00", 13), ("20:00", 15),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Utsunomiya.Tokyo", .descending,
                    "東海道線（上野東京ライン）", "JR Tokaido Line (via Ueno-Tokyo Line)",
                    "横浜・熱海方面", "for Yokohama & Atami",
                    to: "Railway:JR-East.Tokaido"),
            through("Utsunomiya.Omiya", .descending,
                    "湘南新宿ライン", "Shonan-Shinjuku Line",
                    "新宿・横浜方面", "for Shinjuku & Yokohama",
                    to: "Railway:JR-East.ShonanShinjuku"),
        ]
    )

    // MARK: - Takasaki Line (JU)

    static let takasaki = StaticTrainLine(
        id: "Railway:JR-East.Takasaki",
        nameJa: "高崎線",
        nameEn: "Takasaki Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F68B1E",
        stations: [
            st("Takasaki", "Tokyo", "東京", "Tokyo", "JU01", 35.6812, 139.7671),
            st("Takasaki", "Ueno", "上野", "Ueno", "JU02", 35.7141, 139.7774),
            st("Takasaki", "Oku", "尾久", "Oku", "JU03", 35.7423, 139.7568),
            st("Takasaki", "Akabane", "赤羽", "Akabane", "JU04", 35.7782, 139.7208),
            st("Takasaki", "Urawa", "浦和", "Urawa", "JU05", 35.8593, 139.6570),
            st("Takasaki", "SaitamaShintoshin", "さいたま新都心", "Saitama-Shintoshin", "JU06", 35.8940, 139.6339),
            st("Takasaki", "Omiya", "大宮", "Omiya", "JU07", 35.9064, 139.6238),
            st("Takasaki", "Miyahara", "宮原", "Miyahara", "", 35.9438, 139.6098),
            st("Takasaki", "Ageo", "上尾", "Ageo", "", 35.9698, 139.5898),
            st("Takasaki", "KitaAgeo", "北上尾", "Kita-Ageo", "", 35.9878, 139.5848),
            st("Takasaki", "Okegawa", "桶川", "Okegawa", "", 36.0060, 139.5580),
            st("Takasaki", "Kitamoto", "北本", "Kitamoto", "", 36.0268, 139.5318),
            st("Takasaki", "Konosu", "鴻巣", "Konosu", "", 36.0658, 139.5218),
            st("Takasaki", "KitaKonosu", "北鴻巣", "Kita-Konosu", "", 36.0928, 139.4958),
            st("Takasaki", "Fukiage", "吹上", "Fukiage", "", 36.1088, 139.4588),
            st("Takasaki", "Gyoda", "行田", "Gyoda", "", 36.1248, 139.4338),
            st("Takasaki", "Kumagaya", "熊谷", "Kumagaya", "", 36.1398, 139.3898),
            st("Takasaki", "Kagohara", "籠原", "Kagohara", "", 36.1658, 139.3258),
            st("Takasaki", "Fukaya", "深谷", "Fukaya", "", 36.1928, 139.2808),
            st("Takasaki", "Okabe", "岡部", "Okabe", "", 36.2108, 139.2398),
            st("Takasaki", "Honjo", "本庄", "Honjo", "", 36.2428, 139.1858),
            st("Takasaki", "Jimbohara", "神保原", "Jimbohara", "", 36.2568, 139.1418),
            st("Takasaki", "Shinmachi", "新町", "Shinmachi", "", 36.2698, 139.1128),
            st("Takasaki", "Kuragano", "倉賀野", "Kuragano", "", 36.3038, 139.0488),
            st("Takasaki", "Takasaki", "高崎", "Takasaki", "", 36.3222, 139.0128),
        ],
        hopTimesMinutes: [
            4, 5, 5, 8, 4, 3, 4, 4, 2, 3, 4, 4, 4, 3, 3, 5, 5, 5, 4, 5, 4, 4, 6, 5,
        ],
        directions: [
            // Last departure from Tokyo is 23:19 — later Ueno-Tokyo Line
            // departures on this corridor are Utsunomiya Line trains
            direction("Takasaki", "Takasaki", "高崎方面", "For Takasaki", ascending: true,
                      weekday: pattern("05:53", "23:19", [
                          ("05:53", 15), ("06:30", 15), ("09:30", 14), ("16:30", 10), ("20:00", 14), ("22:00", 18),
                      ]),
                      holiday: pattern("05:53", "23:19", [
                          ("05:53", 15), ("07:00", 15), ("10:00", 13), ("20:00", 15),
                      ])),
            direction("Takasaki", "Tokyo", "上野・東京方面", "For Ueno & Tokyo", ascending: false,
                      weekday: pattern("05:10", "23:06", [
                          ("05:10", 15), ("06:00", 15), ("09:30", 30), ("16:30", 10), ("20:00", 14), ("22:00", 18),
                      ]),
                      holiday: pattern("05:10", "23:06", [
                          ("05:10", 15), ("07:00", 15), ("10:00", 30), ("20:00", 15),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Takasaki.Tokyo", .descending,
                    "東海道線（上野東京ライン）", "JR Tokaido Line (via Ueno-Tokyo Line)",
                    "横浜・熱海方面", "for Yokohama & Atami",
                    to: "Railway:JR-East.Tokaido"),
            through("Takasaki.Omiya", .descending,
                    "湘南新宿ライン", "Shonan-Shinjuku Line",
                    "新宿・横浜方面", "for Shinjuku & Yokohama",
                    to: "Railway:JR-East.ShonanShinjuku"),
            through("Takasaki.Takasaki", .ascending,
                    "両毛線", "JR Ryomo Line", "前橋方面", "for Maebashi"),
        ]
    )

    // MARK: - Yokohama Line (JH)

    static let yokohamaLine = StaticTrainLine(
        id: "Railway:JR-East.Yokohama",
        nameJa: "横浜線",
        nameEn: "Yokohama Line",
        operatorId: "Operator:JR-East",
        colorHex: "#7FC342",
        stations: [
            st("Yokohama", "HigashiKanagawa", "東神奈川", "Higashi-Kanagawa", "JH13", 35.4772, 139.6343),
            st("Yokohama", "Oguchi", "大口", "Oguchi", "JH14", 35.4870, 139.6296),
            st("Yokohama", "Kikuna", "菊名", "Kikuna", "JH15", 35.5093, 139.6303),
            st("Yokohama", "ShinYokohama", "新横浜", "Shin-Yokohama", "JH16", 35.5070, 139.6170),
            st("Yokohama", "Kozukue", "小机", "Kozukue", "JH17", 35.5095, 139.6010),
            st("Yokohama", "Kamoi", "鴨居", "Kamoi", "JH18", 35.5098, 139.5678),
            st("Yokohama", "Nakayama", "中山", "Nakayama", "JH19", 35.5149, 139.5387),
            st("Yokohama", "Tokaichiba", "十日市場", "Tokaichiba", "JH20", 35.5184, 139.5168),
            st("Yokohama", "Nagatsuta", "長津田", "Nagatsuta", "JH21", 35.5318, 139.4944),
            st("Yokohama", "Naruse", "成瀬", "Naruse", "JH22", 35.5315, 139.4682),
            st("Yokohama", "Machida", "町田", "Machida", "JH23", 35.5421, 139.4451),
            st("Yokohama", "Kobuchi", "古淵", "Kobuchi", "JH24", 35.5547, 139.4212),
            st("Yokohama", "Fuchinobe", "淵野辺", "Fuchinobe", "JH25", 35.5683, 139.3968),
            st("Yokohama", "Yabe", "矢部", "Yabe", "JH26", 35.5737, 139.3882),
            st("Yokohama", "Sagamihara", "相模原", "Sagamihara", "JH27", 35.5796, 139.3733),
            st("Yokohama", "Hashimoto", "橋本", "Hashimoto", "JH28", 35.5948, 139.3449),
            st("Yokohama", "Aihara", "相原", "Aihara", "JH29", 35.6058, 139.3347),
            st("Yokohama", "HachiojiMinamino", "八王子みなみ野", "Hachioji-Minamino", "JH30", 35.6282, 139.3323),
            st("Yokohama", "Katakura", "片倉", "Katakura", "JH31", 35.6421, 139.3352),
            st("Yokohama", "Hachioji", "八王子", "Hachioji", "JH32", 35.6553, 139.3390),
        ],
        hopTimesMinutes: [
            3, 3, 2, 2, 3, 3, 2, 3, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3,
        ],
        directions: [
            direction("Yokohama", "Hachioji", "八王子方面", "For Hachioji", ascending: true,
                      weekday: pattern("04:53", "24:04", [
                          ("04:53", 8), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:53", "24:04", [
                          ("04:53", 8), ("07:00", 6), ("10:00", 8), ("20:00", 9),
                      ])),
            direction("Yokohama", "HigashiKanagawa", "東神奈川方面", "For Higashi-Kanagawa", ascending: false,
                      weekday: pattern("04:53", "24:11", [
                          ("04:53", 8), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:53", "24:11", [
                          ("04:53", 8), ("07:00", 6), ("10:00", 8), ("20:00", 9),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Yokohama.HigashiKanagawa", .descending,
                    "根岸線", "JR Negishi Line",
                    "桜木町・大船方面", "for Sakuragicho & Ofuna",
                    to: "Railway:JR-East.KeihinTohoku"),
        ]
    )

    // MARK: - Nambu Line (JN)

    static let nambu = StaticTrainLine(
        id: "Railway:JR-East.Nambu",
        nameJa: "南武線",
        nameEn: "Nambu Line",
        operatorId: "Operator:JR-East",
        colorHex: "#FFE100",
        stations: [
            st("Nambu", "Kawasaki", "川崎", "Kawasaki", "JN01", 35.5308, 139.6970),
            st("Nambu", "Shitte", "尻手", "Shitte", "JN02", 35.5288, 139.6818),
            st("Nambu", "Yako", "矢向", "Yako", "JN03", 35.5322, 139.6718),
            st("Nambu", "Kashimada", "鹿島田", "Kashimada", "JN04", 35.5452, 139.6648),
            st("Nambu", "Hirama", "平間", "Hirama", "JN05", 35.5542, 139.6577),
            st("Nambu", "Mukaigawara", "向河原", "Mukaigawara", "JN06", 35.5632, 139.6542),
            st("Nambu", "MusashiKosugi", "武蔵小杉", "Musashi-Kosugi", "JN07", 35.5766, 139.6597),
            st("Nambu", "MusashiNakahara", "武蔵中原", "Musashi-Nakahara", "JN08", 35.5832, 139.6443),
            st("Nambu", "MusashiShinjo", "武蔵新城", "Musashi-Shinjo", "JN09", 35.5872, 139.6277),
            st("Nambu", "MusashiMizonokuchi", "武蔵溝ノ口", "Musashi-Mizonokuchi", "JN10", 35.5998, 139.6103),
            st("Nambu", "Tsudayama", "津田山", "Tsudayama", "JN11", 35.6062, 139.6008),
            st("Nambu", "Kuji", "久地", "Kuji", "JN12", 35.6122, 139.5918),
            st("Nambu", "Shukugawara", "宿河原", "Shukugawara", "JN13", 35.6182, 139.5808),
            st("Nambu", "Noborito", "登戸", "Noborito", "JN14", 35.6205, 139.5702),
            st("Nambu", "Nakanoshima", "中野島", "Nakanoshima", "JN15", 35.6282, 139.5538),
            st("Nambu", "Inadazutsumi", "稲田堤", "Inadazutsumi", "JN16", 35.6332, 139.5448),
            st("Nambu", "Yanokuchi", "矢野口", "Yanokuchi", "JN17", 35.6382, 139.5278),
            st("Nambu", "InagiNaganuma", "稲城長沼", "Inagi-Naganuma", "JN18", 35.6412, 139.5098),
            st("Nambu", "MinamiTama", "南多摩", "Minami-Tama", "JN19", 35.6432, 139.4928),
            st("Nambu", "FuchuHommachi", "府中本町", "Fuchu-Hommachi", "JN20", 35.6618, 139.4788),
            st("Nambu", "Bubaigawara", "分倍河原", "Bubaigawara", "JN21", 35.6683, 139.4667),
            st("Nambu", "Nishifu", "西府", "Nishifu", "JN22", 35.6722, 139.4578),
            st("Nambu", "Yaho", "谷保", "Yaho", "JN23", 35.6782, 139.4468),
            st("Nambu", "Yagawa", "矢川", "Yagawa", "JN24", 35.6842, 139.4378),
            st("Nambu", "NishiKunitachi", "西国立", "Nishi-Kunitachi", "JN25", 35.6932, 139.4228),
            st("Nambu", "Tachikawa", "立川", "Tachikawa", "JN26", 35.6980, 139.4139),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 3, 2, 2, 2, 3, 2,
        ],
        directions: [
            direction("Nambu", "Tachikawa", "立川方面", "For Tachikawa", ascending: true,
                      weekday: pattern("04:48", "24:26", [
                          ("04:48", 8), ("06:30", 7.5), ("09:30", 7), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:48", "24:26", [
                          ("04:48", 8), ("07:00", 6), ("10:00", 7.5), ("20:00", 9),
                      ])),
            direction("Nambu", "Kawasaki", "川崎方面", "For Kawasaki", ascending: false,
                      weekday: pattern("04:46", "24:02", [
                          ("04:46", 8), ("06:30", 4.5), ("09:30", 7), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:46", "24:02", [
                          ("04:46", 8), ("07:00", 6), ("10:00", 7.5), ("20:00", 9),
                      ])),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Musashino Line (JM)

    static let musashino = StaticTrainLine(
        id: "Railway:JR-East.Musashino",
        nameJa: "武蔵野線",
        nameEn: "Musashino Line",
        operatorId: "Operator:JR-East",
        colorHex: "#EB6100",
        stations: [
            st("Musashino", "NishiFunabashi", "西船橋", "Nishi-Funabashi", "JM10", 35.7075, 139.9594),
            st("Musashino", "FunabashiHoten", "船橋法典", "Funabashi-Hoten", "JM11", 35.7182, 139.9448),
            st("Musashino", "IchikawaOno", "市川大野", "Ichikawa-Ono", "JM12", 35.7420, 139.9277),
            st("Musashino", "HigashiMatsudo", "東松戸", "Higashi-Matsudo", "JM13", 35.7706, 139.9438),
            st("Musashino", "ShinYahashira", "新八柱", "Shin-Yahashira", "JM14", 35.7772, 139.9368),
            st("Musashino", "ShimMatsudo", "新松戸", "Shim-Matsudo", "JM15", 35.8260, 139.9336),
            st("Musashino", "MinamiNagareyama", "南流山", "Minami-Nagareyama", "JM16", 35.8378, 139.9028),
            st("Musashino", "Misato", "三郷", "Misato", "JM17", 35.8283, 139.8790),
            st("Musashino", "ShinMisato", "新三郷", "Shin-Misato", "JM18", 35.8383, 139.8727),
            st("Musashino", "Yoshikawaminami", "吉川美南", "Yoshikawaminami", "JM19", 35.8502, 139.8558),
            st("Musashino", "Yoshikawa", "吉川", "Yoshikawa", "JM20", 35.8628, 139.8418),
            st("Musashino", "KoshigayaLaketown", "越谷レイクタウン", "Koshigaya-Laketown", "JM21", 35.8758, 139.8247),
            st("Musashino", "MinamiKoshigaya", "南越谷", "Minami-Koshigaya", "JM22", 35.8758, 139.7918),
            st("Musashino", "HigashiKawaguchi", "東川口", "Higashi-Kawaguchi", "JM23", 35.8712, 139.7478),
            st("Musashino", "HigashiUrawa", "東浦和", "Higashi-Urawa", "JM24", 35.8618, 139.7062),
            st("Musashino", "MinamiUrawa", "南浦和", "Minami-Urawa", "JM25", 35.8446, 139.6656),
            st("Musashino", "MusashiUrawa", "武蔵浦和", "Musashi-Urawa", "JM26", 35.8456, 139.6484),
            st("Musashino", "NishiUrawa", "西浦和", "Nishi-Urawa", "JM27", 35.8478, 139.6218),
            st("Musashino", "KitaAsaka", "北朝霞", "Kita-Asaka", "JM28", 35.8088, 139.5918),
            st("Musashino", "Niiza", "新座", "Niiza", "JM29", 35.7928, 139.5618),
            st("Musashino", "HigashiTokorozawa", "東所沢", "Higashi-Tokorozawa", "JM30", 35.7828, 139.5218),
            st("Musashino", "ShinAkitsu", "新秋津", "Shin-Akitsu", "JM31", 35.7722, 139.4878),
            st("Musashino", "ShinKodaira", "新小平", "Shin-Kodaira", "JM32", 35.7282, 139.4738),
            st("Musashino", "NishiKokubunji", "西国分寺", "Nishi-Kokubunji", "JM33", 35.6997, 139.4665),
            st("Musashino", "KitaFuchu", "北府中", "Kita-Fuchu", "JM34", 35.6788, 139.4738),
            st("Musashino", "FuchuHommachi", "府中本町", "Fuchu-Hommachi", "JM35", 35.6618, 139.4788),
        ],
        hopTimesMinutes: [
            3, 3, 2, 3, 4, 2, 3, 2, 2, 2, 2, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 4, 3, 2, 2,
        ],
        directions: [
            direction("Musashino", "FuchuHommachi", "府中本町方面", "For Fuchu-Hommachi", ascending: true,
                      weekday: pattern("04:59", "24:02", [
                          ("04:59", 10), ("06:30", 5), ("09:30", 10), ("16:30", 8), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("04:59", "24:02", [
                          ("04:59", 10), ("07:00", 8), ("10:00", 10), ("20:00", 12),
                      ])),
            direction("Musashino", "NishiFunabashi", "西船橋方面", "For Nishi-Funabashi", ascending: false,
                      weekday: pattern("05:02", "24:01", [
                          ("05:02", 10), ("06:30", 6), ("09:30", 10), ("16:30", 8), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:01", "24:01", [
                          ("05:01", 10), ("07:00", 8), ("10:00", 10), ("20:00", 12),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Musashino.NishiFunabashi", .descending,
                    "京葉線", "JR Keiyo Line",
                    "東京方面", "for Tokyo",
                    to: "Railway:JR-East.KeiyoBranch"),
        ]
    )

    // MARK: - Keiyo Line Nishi-Funabashi Branch

    /// Bridge line for the 武蔵野線⇄京葉線 through service: the 西船橋–市川塩浜
    /// connecting track is on neither line's station list, so through
    /// resolution needs it as its own line (same pattern as 西武有楽町線).
    /// Patterns approximate the through-train window (estimated).
    static let keiyoBranch = StaticTrainLine(
        id: "Railway:JR-East.KeiyoBranch",
        nameJa: "京葉線（西船橋支線）",
        nameEn: "Keiyo Line Nishi-Funabashi Branch",
        operatorId: "Operator:JR-East",
        colorHex: "#C9242F",
        stations: [
            // No station codes: 西船橋 carries JM/JE codes on its own lines,
            // and the first station's code letters would set the line symbol.
            st("KeiyoBranch", "NishiFunabashi", "西船橋", "Nishi-Funabashi", "", 35.7075, 139.9594),
            st("KeiyoBranch", "IchikawaShiohama", "市川塩浜", "Ichikawa-Shiohama", "", 35.6569, 139.9343),
        ],
        hopTimesMinutes: [6],
        directions: [
            direction("KeiyoBranch", "IchikawaShiohama", "市川塩浜・東京方面", "For Ichikawa-Shiohama & Tokyo",
                      ascending: true,
                      weekday: pattern("05:10", "23:30", [
                          ("05:10", 12), ("07:00", 8), ("10:00", 15), ("17:00", 10), ("20:00", 15),
                      ]),
                      holiday: pattern("05:10", "23:30", [
                          ("05:10", 12), ("07:00", 10), ("10:00", 15), ("20:00", 15),
                      ])),
            direction("KeiyoBranch", "NishiFunabashi", "西船橋方面", "For Nishi-Funabashi",
                      ascending: false,
                      weekday: pattern("05:30", "24:05", [
                          ("05:30", 12), ("07:00", 8), ("10:00", 15), ("17:00", 10), ("20:00", 15),
                      ]),
                      holiday: pattern("05:30", "24:05", [
                          ("05:30", 12), ("07:00", 10), ("10:00", 15), ("20:00", 15),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("KeiyoBranch.NishiFunabashi", .descending,
                    "武蔵野線", "JR Musashino Line",
                    "南流山・府中本町方面", "for Minami-Nagareyama & Fuchu-Hommachi",
                    to: "Railway:JR-East.Musashino"),
            through("KeiyoBranch.IchikawaShiohama", .ascending,
                    "京葉線", "JR Keiyo Line",
                    "東京方面", "for Tokyo",
                    to: "Railway:JR-East.Keiyo"),
        ]
    )

    // MARK: - Ome Line (JC)

    static let ome = StaticTrainLine(
        id: "Railway:JR-East.Ome",
        nameJa: "青梅線",
        nameEn: "Ome Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F15A22",
        stations: [
            st("Ome", "Tachikawa", "立川", "Tachikawa", "JC19", 35.6980, 139.4139),
            st("Ome", "NishiTachikawa", "西立川", "Nishi-Tachikawa", "JC51", 35.7012, 139.4028),
            st("Ome", "HigashiNakagami", "東中神", "Higashi-Nakagami", "JC52", 35.7022, 139.3918),
            st("Ome", "Nakagami", "中神", "Nakagami", "JC53", 35.7032, 139.3828),
            st("Ome", "Akishima", "昭島", "Akishima", "JC54", 35.7058, 139.3698),
            st("Ome", "Haijima", "拝島", "Haijima", "JC55", 35.7088, 139.3532),
            st("Ome", "Ushihama", "牛浜", "Ushihama", "JC56", 35.7290, 139.3350),
            st("Ome", "Fussa", "福生", "Fussa", "JC57", 35.7380, 139.3270),
            st("Ome", "Hamura", "羽村", "Hamura", "JC58", 35.7620, 139.3110),
            st("Ome", "Ozaku", "小作", "Ozaku", "JC59", 35.7758, 139.2958),
            st("Ome", "Kabe", "河辺", "Kabe", "JC60", 35.7878, 139.2828),
            st("Ome", "HigashiOme", "東青梅", "Higashi-Ome", "JC61", 35.7898, 139.2648),
            st("Ome", "Ome", "青梅", "Ome", "JC62", 35.7878, 139.2438),
        ],
        hopTimesMinutes: [3, 2, 2, 2, 4, 2, 2, 3, 3, 3, 3, 3],
        directions: [
            direction("Ome", "Ome", "青梅方面", "For Ome", ascending: true,
                      weekday: pattern("04:46", "24:23", [
                          ("04:46", 10), ("06:30", 6), ("09:30", 11), ("16:30", 8), ("20:00", 10), ("22:00", 14),
                      ]),
                      holiday: pattern("04:46", "24:21", [
                          ("04:46", 10), ("07:00", 8), ("10:00", 10), ("20:00", 12),
                      ])),
            direction("Ome", "Tachikawa", "立川方面", "For Tachikawa", ascending: false,
                      weekday: pattern("04:35", "23:58", [
                          ("04:35", 10), ("06:00", 6), ("09:30", 11), ("16:30", 8), ("20:00", 10), ("22:00", 14),
                      ]),
                      holiday: pattern("04:35", "23:56", [
                          ("04:35", 10), ("07:00", 8), ("10:00", 10), ("20:00", 12),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Ome.Tachikawa", .descending,
                    "中央線快速", "JR Chuo Rapid Line", "東京方面", "for Tokyo",
                    to: "Railway:JR-East.ChuoRapid"),
            through("Ome.Haijima", .ascending,
                    "五日市線", "JR Itsukaichi Line",
                    "武蔵五日市方面", "for Musashi-Itsukaichi",
                    to: "Railway:JR-East.Itsukaichi"),
            through("Ome.Ome", .ascending,
                    "青梅線（東京アドベンチャーライン）", "JR Ome Line (Tokyo Adventure Line)",
                    "奥多摩方面", "for Okutama"),
        ]
    )

    // MARK: - Itsukaichi Line (JC)

    static let itsukaichi = StaticTrainLine(
        id: "Railway:JR-East.Itsukaichi",
        nameJa: "五日市線",
        nameEn: "Itsukaichi Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F15A22",
        stations: [
            st("Itsukaichi", "Haijima", "拝島", "Haijima", "JC55", 35.7088, 139.3532),
            st("Itsukaichi", "Kumagawa", "熊川", "Kumagawa", "JC81", 35.7095, 139.3405),
            st("Itsukaichi", "HigashiAkiru", "東秋留", "Higashi-Akiru", "JC82", 35.7140, 139.3110),
            st("Itsukaichi", "Akigawa", "秋川", "Akigawa", "JC83", 35.7180, 139.2920),
            st("Itsukaichi", "MusashiHikida", "武蔵引田", "Musashi-Hikida", "JC84", 35.7210, 139.2740),
            st("Itsukaichi", "MusashiMasuko", "武蔵増戸", "Musashi-Masuko", "JC85", 35.7240, 139.2560),
            st("Itsukaichi", "MusashiItsukaichi", "武蔵五日市", "Musashi-Itsukaichi", "JC86", 35.7253, 139.2177),
        ],
        hopTimesMinutes: [3, 2, 3, 2, 2, 3],
        directions: [
            direction("Itsukaichi", "MusashiItsukaichi", "武蔵五日市方面", "For Musashi-Itsukaichi", ascending: true,
                      weekday: pattern("05:48", "24:18", [
                          ("05:48", 20), ("06:30", 20), ("09:30", 25), ("16:30", 15), ("20:00", 20), ("22:00", 25),
                      ]),
                      holiday: pattern("05:57", "24:18", [
                          ("05:57", 20), ("07:00", 17), ("10:00", 22), ("20:00", 25),
                      ])),
            direction("Itsukaichi", "Haijima", "拝島・立川方面", "For Haijima & Tachikawa", ascending: false,
                      weekday: pattern("05:20", "23:53", [
                          ("05:20", 20), ("06:30", 12), ("09:30", 25), ("16:30", 15), ("20:00", 20), ("22:00", 25),
                      ]),
                      holiday: pattern("05:22", "23:49", [
                          ("05:22", 20), ("07:00", 17), ("10:00", 22), ("20:00", 25),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Itsukaichi.Haijima", .descending,
                    "青梅線・中央線", "JR Ome & Chuo Lines", "立川方面", "for Tachikawa",
                    to: "Railway:JR-East.Ome"),
        ]
    )
}
