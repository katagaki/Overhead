import Foundation

extension JREastLineData {

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
            4, 3, 3, 5, 4, 5, 3, 9, 3, 5, 4, 4, 2, 5, 6, 10, 9, 6,
        ],
        // Real per-train timetable (station-page scrape) → 1:1 station timetables.
        timetableRuns: shonanShinjukuTimetable,
        directions: [
            // 逗子 has a real morning service GAP (07:47→09:34 weekday,
            // 06:57→09:28 holiday), then ~30-min clockface — verified July-2026.
            direction("ShonanShinjuku", "Omiya", "新宿・大宮方面", "For Shinjuku & Omiya", ascending: true,
                      weekday: pattern("06:54", "21:11", [
                          ("06:54", 25), ("07:47", 107), ("09:34", 30),
                      ], .rapid),
                      holiday: pattern("06:57", "21:34", [
                          ("06:57", 151), ("09:28", 30),
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
}
