import Foundation

extension JREastLineData {

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
        // Hops measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [2, 3, 4, 2, 2, 4],
        // Real per-train timetable (652 grid) → 1:1 station timetables.
        timetableRuns: itsukaichiTimetable,
        directions: [
            direction("Itsukaichi", "MusashiItsukaichi", "武蔵五日市方面", "For Musashi-Itsukaichi", ascending: true,
                      weekday: pattern("05:48", "24:18", [
                          ("05:48", 20), ("06:30", 20), ("09:30", 25), ("16:30", 15), ("20:00", 20), ("22:00", 25),
                      ]),
                      holiday: pattern("05:57", "24:18", [
                          ("05:57", 20), ("07:00", 20), ("10:00", 22), ("20:00", 25),
                      ])),
            direction("Itsukaichi", "Haijima", "拝島・立川方面", "For Haijima & Tachikawa", ascending: false,
                      weekday: pattern("05:20", "23:53", [
                          ("05:20", 20), ("06:30", 15), ("09:30", 25), ("16:30", 15), ("20:00", 20), ("22:00", 25),
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
