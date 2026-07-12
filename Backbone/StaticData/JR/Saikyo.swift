import Foundation

extension JREastLineData {

    // MARK: - Saikyo Line (JA)

    static let saikyo = StaticTrainLine(
        id: "Railway:JR-East.SaikyoKawagoe",
        nameJa: "埼京線",
        nameEn: "Saikyo Line",
        operatorId: "Operator:JR-East",
        colorHex: "#00AC9A",
        stations: [
            st("SaikyoKawagoe", "Osaki", "大崎", "Osaki", "JA08", 35.6197, 139.7286),
            st("SaikyoKawagoe", "Ebisu", "恵比寿", "Ebisu", "JA09", 35.6467, 139.7101),
            st("SaikyoKawagoe", "Shibuya", "渋谷", "Shibuya", "JA10", 35.6580, 139.7016),
            st("SaikyoKawagoe", "Shinjuku", "新宿", "Shinjuku", "JA11", 35.6896, 139.7006),
            st("SaikyoKawagoe", "Ikebukuro", "池袋", "Ikebukuro", "JA12", 35.7295, 139.7109),
            st("SaikyoKawagoe", "Itabashi", "板橋", "Itabashi", "JA13", 35.7454, 139.7194),
            st("SaikyoKawagoe", "Jujo", "十条", "Jujo", "JA14", 35.7605, 139.7218),
            st("SaikyoKawagoe", "Akabane", "赤羽", "Akabane", "JA15", 35.7782, 139.7208),
            st("SaikyoKawagoe", "KitaAkabane", "北赤羽", "Kita-Akabane", "JA16", 35.7873, 139.7099),
            st("SaikyoKawagoe", "Ukimafunado", "浮間舟渡", "Ukima-Funado", "JA17", 35.7940, 139.6907),
            st("SaikyoKawagoe", "TodaKoen", "戸田公園", "Toda-Koen", "JA18", 35.8045, 139.6772),
            st("SaikyoKawagoe", "Toda", "戸田", "Toda", "JA19", 35.8140, 139.6680),
            st("SaikyoKawagoe", "KitaToda", "北戸田", "Kita-Toda", "JA20", 35.8258, 139.6598),
            st("SaikyoKawagoe", "MusashiUrawa", "武蔵浦和", "Musashi-Urawa", "JA21", 35.8456, 139.6484),
            st("SaikyoKawagoe", "NakaUrawa", "中浦和", "Naka-Urawa", "JA22", 35.8560, 139.6404),
            st("SaikyoKawagoe", "MinamiYono", "南与野", "Minami-Yono", "JA23", 35.8693, 139.6323),
            st("SaikyoKawagoe", "Yonohommachi", "与野本町", "Yonohommachi", "JA24", 35.8805, 139.6248),
            st("SaikyoKawagoe", "KitaYono", "北与野", "Kita-Yono", "JA25", 35.8930, 139.6260),
            st("SaikyoKawagoe", "Omiya", "大宮", "Omiya", "JA26", 35.9064, 139.6238),
        ],
        hopTimesMinutes: [
            5, 3, 5, 6, 3, 2, 3, 3, 2, 3, 2, 2, 3, 2, 2, 2, 2, 3,
        ],
        // Real per-train timetable (628 grid) → 1:1 station timetables.
        timetableRuns: saikyoTimetable,
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.SaikyoKawagoe.Omiya",
                nameJa: "大宮方面",
                nameEn: "For Omiya",
                isAscending: true,
                weekday: ServicePattern(
                    first: "06:13", last: "23:35",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "06:30", headwayMinutes: 5),
                        HeadwayBand(from: "09:30", headwayMinutes: 9),
                        HeadwayBand(from: "16:30", headwayMinutes: 6),
                        HeadwayBand(from: "20:00", headwayMinutes: 8),
                        HeadwayBand(from: "22:00", headwayMinutes: 10),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "06:13", last: "23:35",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "07:00", headwayMinutes: 7),
                        HeadwayBand(from: "10:00", headwayMinutes: 8),
                        HeadwayBand(from: "20:00", headwayMinutes: 9),
                    ]
                )
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.SaikyoKawagoe.Osaki",
                nameJa: "大崎方面",
                nameEn: "For Osaki",
                isAscending: false,
                weekday: ServicePattern(
                    first: "04:51", last: "23:46",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "06:30", headwayMinutes: 5),
                        HeadwayBand(from: "09:30", headwayMinutes: 9),
                        HeadwayBand(from: "16:30", headwayMinutes: 6),
                        HeadwayBand(from: "20:00", headwayMinutes: 8),
                        HeadwayBand(from: "22:00", headwayMinutes: 10),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:51", last: "23:46",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "07:00", headwayMinutes: 7),
                        HeadwayBand(from: "10:00", headwayMinutes: 8),
                        HeadwayBand(from: "20:00", headwayMinutes: 9),
                    ]
                )
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("SaikyoKawagoe.Osaki", .descending,
                    "りんかい線", "Rinkai Line", "新木場方面", "for Shin-Kiba",
                    to: "Railway:TWR.Rinkai"),
            through("SaikyoKawagoe.Osaki", .descending,
                    "相鉄線", "Sotetsu Line", "海老名方面", "for Ebina"),
            through("SaikyoKawagoe.Omiya", .ascending,
                    "川越線", "JR Kawagoe Line", "川越方面", "for Kawagoe"),
        ]
    )
}
