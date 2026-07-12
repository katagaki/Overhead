import Foundation

extension JREastLineData {

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
            6, 6, 5, 9, 4, 3, 5, 4, 3, 3, 4, 4, 4, 4, 3, 5, 6, 5, 4, 5, 4, 4, 5, 5,
        ],
        // Real per-train timetable (station-page scrape) → 1:1 station timetables.
        timetableRuns: takasakiTimetable,
        directions: [
            // Last departure from Tokyo is 23:19 — later Ueno-Tokyo Line
            // departures on this corridor are Utsunomiya Line trains
            direction("Takasaki", "Takasaki", "高崎方面", "For Takasaki", ascending: true,
                      weekday: pattern("05:53", "23:19", [
                          ("05:53", 15), ("06:30", 15), ("09:30", 18), ("16:30", 10), ("20:00", 25),
                      ]),
                      holiday: pattern("05:53", "23:19", [
                          ("05:53", 15), ("07:00", 15), ("10:00", 18), ("20:00", 20),
                      ])),
            // 高崎-origin mornings run only ~2-4/h (verified July-2026); the
            // dense 06:00 headway was a down-corridor figure, not the origin's.
            direction("Takasaki", "Tokyo", "上野・東京方面", "For Ueno & Tokyo", ascending: false,
                      weekday: pattern("05:10", "23:06", [
                          ("05:10", 20), ("06:00", 20), ("09:30", 30), ("16:30", 12), ("20:00", 20),
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
}
