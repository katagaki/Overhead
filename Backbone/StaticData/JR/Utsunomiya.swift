import Foundation

extension JREastLineData {

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
            6, 6, 5, 9, 4, 3, 4, 3, 4, 4, 3, 3, 3, 5, 7, 4, 4, 6, 7, 3, 4, 6, 7,
        ],
        // Real per-train timetable (station-page scrape) → 1:1 station timetables.
        timetableRuns: utsunomiyaTimetable,
        directions: [
            // First departure from Tokyo is 06:30 — earlier Ueno-Tokyo Line
            // departures on this corridor are Takasaki Line trains
            direction("Utsunomiya", "Utsunomiya", "宇都宮方面", "For Utsunomiya", ascending: true,
                      weekday: pattern("06:30", "23:32", [
                          ("06:30", 15), ("09:30", 20), ("16:30", 10), ("20:00", 20),
                      ]),
                      holiday: pattern("06:30", "23:32", [
                          ("06:30", 25), ("10:00", 20), ("20:00", 20),
                      ])),
            direction("Utsunomiya", "Tokyo", "上野・東京方面", "For Ueno & Tokyo", ascending: false,
                      weekday: pattern("04:37", "22:42", [
                          ("04:37", 15), ("06:00", 15), ("09:30", 20), ("16:30", 10), ("20:00", 20),
                      ]),
                      holiday: pattern("04:37", "22:42", [
                          ("04:37", 15), ("07:00", 12), ("10:00", 20), ("20:00", 20),
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
}
