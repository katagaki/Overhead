import Foundation

// MARK: - Keikyu Line Data

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

enum KeikyuLineData {

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://unkou.keikyu.co.jp/",
        statusPageURLEn: "https://www.keikyu.co.jp/visit/",
        xAccount: nil,
        checkMethodJa: "京急電鉄「運行情報」ページまたは京急線アプリで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Keikyu train operation information page or the Keikyu app. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        main, airport,
    ]

    // MARK: - Keikyu Main Line (KK)

    static let main = StaticTrainLine(
        id: "Railway:Keikyu.Main",
        nameJa: "京急本線",
        nameEn: "Keikyu Main Line",
        operatorId: "Operator:Keikyu",
        colorHex: "#E60012",
        stations: [
            // Sengakuji is Toei-managed (A07); leave the code empty so the
            // line symbol derives from Shinagawa's KK01
            st("Keikyu.Main", "Sengakuji", "泉岳寺", "Sengakuji", "", 35.6385, 139.7401),
            st("Keikyu.Main", "Shinagawa", "品川", "Shinagawa", "KK01", 35.6285, 139.7388),
            st("Keikyu.Main", "Kitashinagawa", "北品川", "Kita-shinagawa", "KK02", 35.6222, 139.7392),
            st("Keikyu.Main", "Shimbamba", "新馬場", "Shimbamba", "KK03", 35.6172, 139.7407),
            st("Keikyu.Main", "AomonoYokocho", "青物横丁", "Aomono-yokocho", "KK04", 35.6093, 139.7428),
            st("Keikyu.Main", "Samezu", "鮫洲", "Samezu", "KK05", 35.6050, 139.7423),
            st("Keikyu.Main", "Tachiaigawa", "立会川", "Tachiaigawa", "KK06", 35.5985, 139.7387),
            st("Keikyu.Main", "OmoriKaigan", "大森海岸", "Omorikaigan", "KK07", 35.5875, 139.7357),
            st("Keikyu.Main", "Heiwajima", "平和島", "Heiwajima", "KK08", 35.5787, 139.7347),
            st("Keikyu.Main", "Omorimachi", "大森町", "Omorimachi", "KK09", 35.5722, 139.7317),
            st("Keikyu.Main", "Umeyashiki", "梅屋敷", "Umeyashiki", "KK10", 35.5665, 139.7287),
            st("Keikyu.Main", "KeikyuKamata", "京急蒲田", "Keikyu Kamata", "KK11", 35.5607, 139.7237),
            st("Keikyu.Main", "Zoshiki", "雑色", "Zoshiki", "KK18", 35.5497, 139.7147),
            st("Keikyu.Main", "Rokugodote", "六郷土手", "Rokugodote", "KK19", 35.5397, 139.7077),
            st("Keikyu.Main", "KeikyuKawasaki", "京急川崎", "Keikyu Kawasaki", "KK20", 35.5327, 139.7007),
            st("Keikyu.Main", "Hatchonawate", "八丁畷", "Hatchonawate", "KK27", 35.5257, 139.6907),
            st("Keikyu.Main", "Tsurumiichiba", "鶴見市場", "Tsurumi-ichiba", "KK28", 35.5197, 139.6837),
            st("Keikyu.Main", "KeikyuTsurumi", "京急鶴見", "Keikyu Tsurumi", "KK29", 35.5077, 139.6787),
            st("Keikyu.Main", "KagetsuSojiji", "花月総持寺", "Kagetsu-sojiji", "KK30", 35.4997, 139.6717),
            st("Keikyu.Main", "Namamugi", "生麦", "Namamugi", "KK31", 35.4917, 139.6647),
            st("Keikyu.Main", "KeikyuShinkoyasu", "京急新子安", "Keikyu Shin-koyasu", "KK32", 35.4847, 139.6577),
            st("Keikyu.Main", "Koyasu", "子安", "Koyasu", "KK33", 35.4807, 139.6507),
            st("Keikyu.Main", "KanagawaShimmachi", "神奈川新町", "Kanagawa-shimmachi", "KK34", 35.4777, 139.6457),
            st("Keikyu.Main", "KeikyuHigashiKanagawa", "京急東神奈川", "Keikyu Higashi-kanagawa", "KK35", 35.4757, 139.6407),
            st("Keikyu.Main", "Kanagawa", "神奈川", "Kanagawa", "KK36", 35.4707, 139.6317),
            st("Keikyu.Main", "Yokohama", "横浜", "Yokohama", "KK37", 35.4657, 139.6224),
            st("Keikyu.Main", "Tobe", "戸部", "Tobe", "KK38", 35.4577, 139.6187),
            st("Keikyu.Main", "Hinodecho", "日ノ出町", "Hinodecho", "KK39", 35.4467, 139.6247),
            st("Keikyu.Main", "Koganecho", "黄金町", "Koganecho", "KK40", 35.4407, 139.6257),
            st("Keikyu.Main", "MinamiOta", "南太田", "Minami-ota", "KK41", 35.4347, 139.6207),
            st("Keikyu.Main", "Idogaya", "井土ヶ谷", "Idogaya", "KK42", 35.4287, 139.6127),
            st("Keikyu.Main", "Gumyoji", "弘明寺", "Gumyoji", "KK43", 35.4197, 139.6047),
            st("Keikyu.Main", "Kamiooka", "上大岡", "Kamiooka", "KK44", 35.4087, 139.5967),
            st("Keikyu.Main", "Byobugaura", "屏風浦", "Byobugaura", "KK45", 35.3947, 139.6027),
            st("Keikyu.Main", "Sugita", "杉田", "Sugita", "KK46", 35.3857, 139.6117),
            st("Keikyu.Main", "KeikyuTomioka", "京急富岡", "Keikyu Tomioka", "KK47", 35.3737, 139.6197),
            st("Keikyu.Main", "Nokendai", "能見台", "Nokendai", "KK48", 35.3657, 139.6237),
            st("Keikyu.Main", "KanazawaBunko", "金沢文庫", "Kanazawa-bunko", "KK49", 35.3527, 139.6217),
            st("Keikyu.Main", "KanazawaHakkei", "金沢八景", "Kanazawa-hakkei", "KK50", 35.3377, 139.6207),
            st("Keikyu.Main", "Oppama", "追浜", "Oppama", "KK54", 35.3197, 139.6247),
            st("Keikyu.Main", "KeikyuTaura", "京急田浦", "Keikyu Taura", "KK55", 35.3077, 139.6337),
            st("Keikyu.Main", "Anjinzuka", "安針塚", "Anjinzuka", "KK56", 35.2937, 139.6467),
            st("Keikyu.Main", "Hemi", "逸見", "Hemi", "KK57", 35.2867, 139.6527),
            st("Keikyu.Main", "Shioiri", "汐入", "Shioiri", "KK58", 35.2827, 139.6607),
            st("Keikyu.Main", "YokosukaChuo", "横須賀中央", "Yokosuka-chuo", "KK59", 35.2787, 139.6707),
            st("Keikyu.Main", "KenritsuDaigaku", "県立大学", "Kenritsudaigaku", "KK60", 35.2697, 139.6787),
            st("Keikyu.Main", "Horinouchi", "堀ノ内", "Horinouchi", "KK61", 35.2597, 139.6867),
            st("Keikyu.Main", "KeikyuOtsu", "京急大津", "Keikyu Otsu", "KK62", 35.2557, 139.6947),
            st("Keikyu.Main", "MaboriKaigan", "馬堀海岸", "Maborikaigan", "KK63", 35.2527, 139.7067),
            st("Keikyu.Main", "Uraga", "浦賀", "Uraga", "KK64", 35.2427, 139.7137),
        ],
        hopTimesMinutes: [
            3, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 2, 2, 2,
            2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2,
            2, 2, 1, 1, 2, 2, 2, 3, 2, 2, 2, 2, 3,
            3, 3, 3, 2, 2, 1, 2, 2, 2, 2, 2,
        ],
        directions: [
            // First/last at Sengakuji estimated from verified Shinagawa data
            // (05:02/23:59, ekitan) minus the 2-3 min hop; Sengakuji page 404s.
            direction("Keikyu.Main", "Uraga", "横浜・浦賀方面", "For Yokohama & Uraga",
                      ascending: true,
                      weekday: pattern("05:10", "23:56", [
                          ("05:10", 8), ("06:30", 4), ("09:30", 5), ("16:30", 4), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:10", "23:56", [
                          ("05:10", 8), ("07:00", 5), ("10:00", 5), ("20:00", 7),
                      ])),
            // Uraga first/last estimated (ekitan page returned 500)
            direction("Keikyu.Main", "Sengakuji", "品川・泉岳寺方面", "For Shinagawa & Sengakuji",
                      ascending: false,
                      weekday: pattern("04:45", "23:35", [
                          ("04:45", 8), ("06:30", 4), ("09:30", 5), ("16:30", 4), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("04:45", "23:35", [
                          ("04:45", 8), ("07:00", 5), ("10:00", 5), ("20:00", 7),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keikyu.Main.Sengakuji", .descending,
                    "都営浅草線", "Toei Asakusa Line",
                    "押上・成田空港方面", "for Oshiage & Narita Airport",
                    to: "Railway:Toei.Asakusa"),
            through("Keikyu.Main.KeikyuKamata", .ascending,
                    "京急空港線", "Keikyu Airport Line",
                    "羽田空港方面", "for Haneda Airport",
                    to: "Railway:Keikyu.Airport"),
            through("Keikyu.Main.Horinouchi", .ascending,
                    "京急久里浜線", "Keikyu Kurihama Line",
                    "三崎口方面", "for Misakiguchi"),
        ]
    )

    // MARK: - Keikyu Airport Line (KK)

    static let airport = StaticTrainLine(
        id: "Railway:Keikyu.Airport",
        nameJa: "京急空港線",
        nameEn: "Keikyu Airport Line",
        operatorId: "Operator:Keikyu",
        colorHex: "#E60012",
        stations: [
            st("Keikyu.Airport", "KeikyuKamata", "京急蒲田", "Keikyu Kamata", "KK11", 35.5607, 139.7237),
            st("Keikyu.Airport", "Kojiya", "糀谷", "Kojiya", "KK12", 35.5537, 139.7317),
            st("Keikyu.Airport", "Otorii", "大鳥居", "Otorii", "KK13", 35.5487, 139.7417),
            st("Keikyu.Airport", "AnamoriInari", "穴守稲荷", "Anamori-inari", "KK14", 35.5477, 139.7517),
            st("Keikyu.Airport", "Tenkubashi", "天空橋", "Tenkubashi", "KK15", 35.5497, 139.7597),
            st("Keikyu.Airport", "HanedaAirportTerminal3", "羽田空港第3ターミナル", "Haneda Airport Terminal 3", "KK16", 35.5447, 139.7677),
            st("Keikyu.Airport", "HanedaAirportTerminal1and2", "羽田空港第1・第2ターミナル", "Haneda Airport Terminal 1 & 2", "KK17", 35.5487, 139.7847),
        ],
        hopTimesMinutes: [2, 2, 2, 2, 2, 3],
        directions: [
            // First/last estimated from Keikyu published patterns
            direction("Keikyu.Airport", "HanedaAirport", "羽田空港方面", "For Haneda Airport",
                      ascending: true,
                      weekday: pattern("05:14", "24:05", [
                          ("05:14", 8), ("06:30", 5), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:14", "24:05", [
                          ("05:14", 8), ("07:00", 6), ("10:00", 6), ("20:00", 7),
                      ])),
            direction("Keikyu.Airport", "KeikyuKamata", "京急蒲田・品川方面", "For Keikyu Kamata & Shinagawa",
                      ascending: false,
                      weekday: pattern("05:26", "24:01", [
                          ("05:26", 8), ("06:30", 5), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:26", "24:01", [
                          ("05:26", 8), ("07:00", 6), ("10:00", 6), ("20:00", 7),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keikyu.Airport.KeikyuKamata", .descending,
                    "京急本線", "Keikyu Main Line",
                    "品川・泉岳寺・都営浅草線方面", "for Shinagawa, Sengakuji & the Toei Asakusa Line",
                    to: "Railway:Keikyu.Main"),
        ]
    )
}
