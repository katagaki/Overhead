import Foundation

extension JREastLineData {

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
        // Hops measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [
            3, 3, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 3, 3, 2, 3,
        ],
        // Real per-train timetable (608 grid) → 1:1 station timetables.
        timetableRuns: yokohamaLineTimetable,
        directions: [
            direction("Yokohama", "Hachioji", "八王子方面", "For Hachioji", ascending: true,
                      weekday: pattern("04:53", "24:04", [
                          ("04:53", 8), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:53", "24:04", [
                          ("04:53", 8), ("07:00", 6), ("10:00", 8), ("20:00", 9),
                      ])),
            // 八王子 departures run a flat ~6/h through the day (verified
            // July-2026); the descending bands are NOT mirrors of ascending.
            direction("Yokohama", "HigashiKanagawa", "東神奈川方面", "For Higashi-Kanagawa", ascending: false,
                      weekday: pattern("04:53", "24:11", [
                          ("04:53", 10), ("06:30", 7), ("09:00", 10), ("21:00", 12),
                      ]),
                      holiday: pattern("04:53", "24:11", [
                          ("04:53", 10), ("07:00", 9), ("10:00", 10), ("20:00", 10),
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
}
