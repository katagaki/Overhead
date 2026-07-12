import Foundation

extension JREastLineData {

    // MARK: - Keiyo Line (JE)

    static let keiyo = StaticTrainLine(
        id: "Railway:JR-East.Keiyo",
        nameJa: "京葉線",
        nameEn: "Keiyo Line",
        operatorId: "Operator:JR-East",
        colorHex: "#C9242F",
        stations: [
            st("Keiyo", "Tokyo", "東京", "Tokyo", "JE01", 35.6770, 139.7650),
            st("Keiyo", "Hatchobori", "八丁堀", "Hatchobori", "JE02", 35.6748, 139.7777),
            st("Keiyo", "Etchujima", "越中島", "Etchujima", "JE03", 35.6680, 139.7925),
            st("Keiyo", "Shiomi", "潮見", "Shiomi", "JE04", 35.6553, 139.8156),
            st("Keiyo", "ShinKiba", "新木場", "Shin-Kiba", "JE05", 35.6460, 139.8268),
            st("Keiyo", "KasaiRinkaiKoen", "葛西臨海公園", "Kasai-Rinkai-Koen", "JE06", 35.6437, 139.8637),
            st("Keiyo", "Maihama", "舞浜", "Maihama", "JE07", 35.6361, 139.8831),
            st("Keiyo", "ShinUrayasu", "新浦安", "Shin-Urayasu", "JE08", 35.6528, 139.9090),
            st("Keiyo", "IchikawaShiohama", "市川塩浜", "Ichikawa-Shiohama", "JE09", 35.6569, 139.9343),
            st("Keiyo", "FutamataShimmachi", "二俣新町", "Futamata-Shimmachi", "JE10", 35.6685, 139.9605),
            st("Keiyo", "MinamiFunabashi", "南船橋", "Minami-Funabashi", "JE11", 35.6842, 139.9903),
            st("Keiyo", "ShinNarashino", "新習志野", "Shin-Narashino", "JE12", 35.6716, 140.0257),
            st("Keiyo", "MakuhariToyosuna", "幕張豊砂", "Makuhari-Toyosuna", "JE13", 35.6555, 140.0339),
            st("Keiyo", "KaihimMakuhari", "海浜幕張", "Kaihimmakuhari", "JE14", 35.6482, 140.0416),
            st("Keiyo", "Kemigawahama", "検見川浜", "Kemigawahama", "JE15", 35.6391, 140.0687),
            st("Keiyo", "InageKaigan", "稲毛海岸", "Inage-Kaigan", "JE16", 35.6300, 140.0868),
            st("Keiyo", "Chibaminato", "千葉みなと", "Chibaminato", "JE17", 35.6072, 140.1052),
            st("Keiyo", "Soga", "蘇我", "Soga", "JE18", 35.5812, 140.1315),
        ],
        hopTimesMinutes: [
            2, 2, 3, 2, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 2, 4, 4,
        ],
        // Real per-train timetable (624 grid) → 1:1 station timetables.
        timetableRuns: keiyoTimetable,
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.Keiyo.Soga",
                nameJa: "蘇我方面",
                nameEn: "For Soga",
                isAscending: true,
                weekday: ServicePattern(
                    first: "04:55", last: "24:24",
                    bands: [
                        HeadwayBand(from: "05:10", headwayMinutes: 9),
                        HeadwayBand(from: "06:30", headwayMinutes: 6),
                        HeadwayBand(from: "09:30", headwayMinutes: 9),
                        HeadwayBand(from: "16:30", headwayMinutes: 6),
                        HeadwayBand(from: "20:00", headwayMinutes: 8),
                        HeadwayBand(from: "22:00", headwayMinutes: 10),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:55", last: "24:24",
                    bands: [
                        HeadwayBand(from: "05:10", headwayMinutes: 9),
                        HeadwayBand(from: "07:00", headwayMinutes: 7),
                        HeadwayBand(from: "10:00", headwayMinutes: 8),
                        HeadwayBand(from: "20:00", headwayMinutes: 9),
                    ]
                )
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.Keiyo.Tokyo",
                nameJa: "東京方面",
                nameEn: "For Tokyo",
                isAscending: false,
                weekday: ServicePattern(
                    first: "04:50", last: "24:20",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "06:00", headwayMinutes: 6),
                        HeadwayBand(from: "09:30", headwayMinutes: 9),
                        HeadwayBand(from: "16:30", headwayMinutes: 6),
                        HeadwayBand(from: "20:00", headwayMinutes: 8),
                        HeadwayBand(from: "22:00", headwayMinutes: 10),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:50", last: "24:20",
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
            through("Keiyo.Soga", .ascending,
                    "内房線・外房線", "JR Uchibo & Sotobo Lines",
                    "君津・上総一ノ宮方面", "for Kimitsu & Kazusa-Ichinomiya"),
            through("Keiyo.IchikawaShiohama", .ascending,
                    "武蔵野線", "JR Musashino Line",
                    "西船橋・南流山方面", "for Nishi-Funabashi & Minami-Nagareyama",
                    to: "Railway:JR-East.KeiyoBranch"),
        ]
    )
}
