import Foundation

extension JREastLineData {

    // MARK: - Yokosuka / Sobu Rapid Line (JO)

    static let yokosukaSobu = StaticTrainLine(
        id: "Railway:JR-East.YokosukaSobu",
        nameJa: "横須賀・総武線快速",
        nameEn: "Yokosuka-Sobu Rapid Line",
        operatorId: "Operator:JR-East",
        colorHex: "#0072BC",
        stations: [
            st("YokosukaSobu", "Kurihama", "久里浜", "Kurihama", "JO01", 35.2333, 139.7057),
            st("YokosukaSobu", "Kinugasa", "衣笠", "Kinugasa", "JO02", 35.2512, 139.6688),
            st("YokosukaSobu", "Yokosuka", "横須賀", "Yokosuka", "JO03", 35.2872, 139.6598),
            st("YokosukaSobu", "Taura", "田浦", "Taura", "JO04", 35.3012, 139.6358),
            st("YokosukaSobu", "HigashiZushi", "東逗子", "Higashi-Zushi", "JO05", 35.3012, 139.6008),
            st("YokosukaSobu", "Zushi", "逗子", "Zushi", "JO06", 35.2953, 139.5798),
            st("YokosukaSobu", "Kamakura", "鎌倉", "Kamakura", "JO07", 35.3192, 139.5468),
            st("YokosukaSobu", "KitaKamakura", "北鎌倉", "Kita-Kamakura", "JO08", 35.3372, 139.5468),
            st("YokosukaSobu", "Ofuna", "大船", "Ofuna", "JO09", 35.3540, 139.5313),
            st("YokosukaSobu", "Totsuka", "戸塚", "Totsuka", "JO10", 35.4008, 139.5342),
            st("YokosukaSobu", "HigashiTotsuka", "東戸塚", "Higashi-Totsuka", "JO11", 35.4232, 139.5578),
            st("YokosukaSobu", "Hodogaya", "保土ケ谷", "Hodogaya", "JO12", 35.4442, 139.5968),
            st("YokosukaSobu", "Yokohama", "横浜", "Yokohama", "JO13", 35.4657, 139.6224),
            st("YokosukaSobu", "ShinKawasaki", "新川崎", "Shin-Kawasaki", "JO14", 35.5352, 139.6468),
            st("YokosukaSobu", "MusashiKosugi", "武蔵小杉", "Musashi-Kosugi", "JO15", 35.5766, 139.6597),
            st("YokosukaSobu", "NishiOi", "西大井", "Nishi-Oi", "JO16", 35.6012, 139.7218),
            st("YokosukaSobu", "Shinagawa", "品川", "Shinagawa", "JO17", 35.6285, 139.7388),
            st("YokosukaSobu", "Shimbashi", "新橋", "Shimbashi", "JO18", 35.6663, 139.7583),
            st("YokosukaSobu", "Tokyo", "東京", "Tokyo", "JO19", 35.6812, 139.7671),
            st("YokosukaSobu", "ShinNihombashi", "新日本橋", "Shin-Nihombashi", "JO20", 35.6892, 139.7738),
            st("YokosukaSobu", "Bakurocho", "馬喰町", "Bakurocho", "JO21", 35.6932, 139.7828),
            st("YokosukaSobu", "Kinshicho", "錦糸町", "Kinshicho", "JO22", 35.6967, 139.8140),
            st("YokosukaSobu", "ShinKoiwa", "新小岩", "Shin-Koiwa", "JO23", 35.7167, 139.8578),
            st("YokosukaSobu", "Ichikawa", "市川", "Ichikawa", "JO24", 35.7297, 139.9078),
            st("YokosukaSobu", "Funabashi", "船橋", "Funabashi", "JO25", 35.7019, 139.9853),
            st("YokosukaSobu", "Tsudanuma", "津田沼", "Tsudanuma", "JO26", 35.6913, 140.0200),
            st("YokosukaSobu", "Inage", "稲毛", "Inage", "JO27", 35.6333, 140.0900),
            st("YokosukaSobu", "Chiba", "千葉", "Chiba", "JO28", 35.6131, 140.1136),
        ],
        // Measured from real July-2026 train pairs (median, both directions);
        // 横浜→新川崎 is 9, 武蔵小杉→西大井 5 (was overstated).
        hopTimesMinutes: [
            6, 5, 3, 4, 3, 4, 3, 3, 5, 4, 5, 3, 9, 3,
            5, 5, 5, 3, 2, 2, 4, 5, 5, 6, 4, 7, 4,
        ],
        // Real per-train timetable (station-page scrape) → 1:1 station timetables.
        timetableRuns: yokosukaSobuTimetable,
        directions: [
            direction("YokosukaSobu", "Chiba", "東京・千葉方面", "For Tokyo & Chiba", ascending: true,
                      weekday: pattern("04:31", "23:11", [
                          ("04:31", 15), ("06:30", 15), ("09:30", 20), ("16:30", 15), ("20:00", 20), ("22:00", 30),
                      ], .rapid),
                      holiday: pattern("04:31", "23:11", [
                          ("04:31", 15), ("07:00", 15), ("10:00", 20), ("20:00", 25),
                      ], .rapid)),
            direction("YokosukaSobu", "Kurihama", "横浜・久里浜方面", "For Yokohama & Kurihama", ascending: false,
                      weekday: pattern("04:45", "24:15", [
                          ("04:45", 10), ("06:30", 8.5), ("09:30", 9), ("16:30", 7), ("20:00", 9), ("22:00", 12),
                      ], .rapid),
                      holiday: pattern("04:45", "24:15", [
                          ("04:45", 10), ("07:00", 7), ("10:00", 9), ("20:00", 10),
                      ], .rapid)),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("YokosukaSobu.Chiba", .ascending,
                    "総武本線・成田線", "JR Sobu Main & Narita Lines",
                    "成田空港・君津方面", "for Narita Airport & Kimitsu"),
        ]
    )
}
