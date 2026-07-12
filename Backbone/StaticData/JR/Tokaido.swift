import Foundation

extension JREastLineData {

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
        // Measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [
            3, 5, 9, 8, 10, 5, 5, 4, 4, 5, 4, 5, 4, 3, 4, 3, 4, 5, 4, 5,
        ],
        // Real per-train timetable (station-page scrape) → 1:1 station timetables.
        timetableRuns: tokaidoTimetable,
        directions: [
            direction("Tokaido", "Atami", "小田原・熱海方面", "For Odawara & Atami", ascending: true,
                      weekday: pattern("05:20", "23:54", [
                          ("05:20", 10), ("06:30", 5), ("09:30", 9), ("16:30", 7), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:20", "23:54", [
                          ("05:20", 10), ("07:00", 7), ("10:00", 9), ("20:00", 11),
                      ])),
            // 熱海 departures run ~3/h all day (verified July-2026); mid-line
            // 小田原/平塚 origins are not expressible in the band model.
            direction("Tokaido", "Tokyo", "東京方面", "For Tokyo", ascending: false,
                      weekday: pattern("04:35", "23:07", [
                          ("04:35", 20),
                      ]),
                      holiday: pattern("04:35", "23:07", [
                          ("04:35", 20),
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
}
