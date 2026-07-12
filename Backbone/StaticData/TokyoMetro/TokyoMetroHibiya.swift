import Foundation

extension TokyoMetroLineData {

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

}
