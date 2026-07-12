import Foundation

extension JREastLineData {

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
        // Hops measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [3, 2, 2, 2, 3, 3, 2, 3, 3, 3, 2, 2],
        // Real per-train timetable (652 grid) → 1:1 station timetables.
        timetableRuns: omeTimetable,
        directions: [
            direction("Ome", "Ome", "青梅方面", "For Ome", ascending: true,
                      weekday: pattern("04:46", "24:23", [
                          ("04:46", 10), ("06:30", 6), ("09:30", 11), ("16:30", 8), ("20:00", 7.5), ("22:00", 14),
                      ]),
                      holiday: pattern("04:46", "24:21", [
                          ("04:46", 10), ("07:00", 8), ("10:00", 10), ("20:00", 12),
                      ])),
            // 青梅 departures run ~5/h nearly all day (verified July-2026);
            // NOT a mirror of the 立川 volumes.
            direction("Ome", "Tachikawa", "立川方面", "For Tachikawa", ascending: false,
                      weekday: pattern("04:35", "23:58", [
                          ("04:35", 12), ("06:00", 9), ("09:30", 12), ("20:00", 12), ("22:00", 15),
                      ]),
                      holiday: pattern("04:35", "23:56", [
                          ("04:35", 12), ("07:00", 12), ("10:00", 13), ("20:00", 15),
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
}
