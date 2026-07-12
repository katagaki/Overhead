import Foundation

extension JREastLineData {

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
        // Hops measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [
            3, 2, 2, 2, 2, 2, 3, 2, 3, 2, 2, 2, 2, 3, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2,
        ],
        // Real per-train timetable (703 grid) → 1:1 station timetables.
        timetableRuns: nambuTimetable,
        directions: [
            // 川崎 morning peak is ~20 trains/h (verified July-2026) — far
            // denser than the reverse direction.
            direction("Nambu", "Tachikawa", "立川方面", "For Tachikawa", ascending: true,
                      weekday: pattern("04:48", "24:26", [
                          ("04:48", 8), ("06:30", 4), ("09:30", 7), ("16:30", 5.5), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:48", "24:26", [
                          ("04:48", 8), ("07:00", 6), ("10:00", 7.5), ("20:00", 9),
                      ])),
            direction("Nambu", "Kawasaki", "川崎方面", "For Kawasaki", ascending: false,
                      weekday: pattern("04:46", "24:02", [
                          ("04:46", 8), ("06:30", 6), ("09:30", 7), ("16:30", 9), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:46", "24:02", [
                          ("04:46", 8), ("07:00", 6), ("10:00", 7.5), ("20:00", 9),
                      ])),
        ],
        delayInfo: delayInfo
    )
}
