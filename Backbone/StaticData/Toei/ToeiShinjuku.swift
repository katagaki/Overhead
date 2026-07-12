import Foundation

extension ToeiLineData {

    // MARK: - Shinjuku Line (S)

    static let shinjuku = StaticTrainLine(
        id: "Railway:Toei.Shinjuku",
        nameJa: "都営新宿線",
        nameEn: "Toei Shinjuku Line",
        operatorId: "Operator:Toei",
        colorHex: "#6CBB5A",
        stations: [
            st("Shinjuku", "Shinjuku", "新宿", "Shinjuku", "S01", 35.6895, 139.6988),
            st("Shinjuku", "ShinjukuSanchome", "新宿三丁目", "Shinjuku-sanchome", "S02", 35.6909, 139.7047),
            st("Shinjuku", "Akebonobashi", "曙橋", "Akebonobashi", "S03", 35.6922, 139.7232),
            st("Shinjuku", "Ichigaya", "市ケ谷", "Ichigaya", "S04", 35.6914, 139.7357),
            st("Shinjuku", "Kudanshita", "九段下", "Kudanshita", "S05", 35.6957, 139.7515),
            st("Shinjuku", "Jimbocho", "神保町", "Jimbocho", "S06", 35.6958, 139.7578),
            st("Shinjuku", "Ogawamachi", "小川町", "Ogawamachi", "S07", 35.6952, 139.7662),
            st("Shinjuku", "Iwamotocho", "岩本町", "Iwamotocho", "S08", 35.6942, 139.7752),
            st("Shinjuku", "BakuroYokoyama", "馬喰横山", "Bakuro-yokoyama", "S09", 35.6922, 139.7828),
            st("Shinjuku", "Hamacho", "浜町", "Hamacho", "S10", 35.6888, 139.7887),
            st("Shinjuku", "Morishita", "森下", "Morishita", "S11", 35.6877, 139.7970),
            st("Shinjuku", "Kikukawa", "菊川", "Kikukawa", "S12", 35.6868, 139.8072),
            st("Shinjuku", "Sumiyoshi", "住吉", "Sumiyoshi", "S13", 35.6890, 139.8143),
            st("Shinjuku", "NishiOjima", "西大島", "Nishi-ojima", "S14", 35.6902, 139.8330),
            st("Shinjuku", "Ojima", "大島", "Ojima", "S15", 35.6898, 139.8432),
            st("Shinjuku", "HigashiOjima", "東大島", "Higashi-ojima", "S16", 35.6902, 139.8528),
            st("Shinjuku", "Funabori", "船堀", "Funabori", "S17", 35.6842, 139.8642),
            st("Shinjuku", "Ichinoe", "一之江", "Ichinoe", "S18", 35.6788, 139.8762),
            st("Shinjuku", "Mizue", "瑞江", "Mizue", "S19", 35.6858, 139.8930),
            st("Shinjuku", "Shinozaki", "篠崎", "Shinozaki", "S20", 35.7042, 139.9012),
            st("Shinjuku", "Motoyawata", "本八幡", "Motoyawata", "S21", 35.7210, 139.9278),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3,
        ],
        directions: [
            direction("Shinjuku", "Motoyawata", "本八幡方面", "For Motoyawata", ascending: true,
                      weekday: toeiWeekday("05:00", "24:10"), holiday: toeiHoliday("05:00", "24:10"),
                      origins: [
                          origin("Station:Toei.Shinjuku.Ojima",
                                 ["05:01", "05:12", "07:09", "07:36", "08:03"],
                                 ["05:01", "05:12"])
                      ]
            ),
            direction("Shinjuku", "Shinjuku", "新宿方面", "For Shinjuku", ascending: false,
                      weekday: toeiWeekday("05:00", "24:09"), holiday: toeiHoliday("05:00", "24:09"),
                      origins: [
                          origin("Station:Toei.Shinjuku.Iwamotocho",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:Toei.Shinjuku.Ojima",
                                 ["05:00", "07:20", "07:28", "09:31", "16:23", "16:36", "17:05", "17:11", "17:18", "17:27"],
                                 ["05:00", "07:06", "07:25"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Shinjuku.Shinjuku", .descending,
                    "京王新線・京王線", "Keio New Line & Keio Line",
                    "笹塚・橋本方面", "for Sasazuka & Hashimoto",
                    to: "Railway:Keio.Keio"),
        ]
    )

}
