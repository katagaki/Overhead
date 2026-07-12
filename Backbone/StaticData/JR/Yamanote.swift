import Foundation

extension JREastLineData {

    // MARK: - Yamanote Line (JY)

    static let yamanote = StaticTrainLine(
        id: "Railway:JR-East.Yamanote",
        nameJa: "山手線",
        nameEn: "Yamanote Line",
        operatorId: "Operator:JR-East",
        colorHex: "#9ACD32",
        stations: [
            st("Yamanote", "Tokyo", "東京", "Tokyo", "JY01", 35.6812, 139.7671),
            st("Yamanote", "Kanda", "神田", "Kanda", "JY02", 35.6918, 139.7709),
            st("Yamanote", "Akihabara", "秋葉原", "Akihabara", "JY03", 35.6984, 139.7731),
            st("Yamanote", "Okachimachi", "御徒町", "Okachimachi", "JY04", 35.7075, 139.7747),
            st("Yamanote", "Ueno", "上野", "Ueno", "JY05", 35.7141, 139.7774),
            st("Yamanote", "Uguisudani", "鶯谷", "Uguisudani", "JY06", 35.7206, 139.7785),
            st("Yamanote", "Nippori", "日暮里", "Nippori", "JY07", 35.7278, 139.7708),
            st("Yamanote", "NishiNippori", "西日暮里", "Nishi-Nippori", "JY08", 35.7324, 139.7669),
            st("Yamanote", "Tabata", "田端", "Tabata", "JY09", 35.7381, 139.7607),
            st("Yamanote", "Komagome", "駒込", "Komagome", "JY10", 35.7365, 139.7460),
            st("Yamanote", "Sugamo", "巣鴨", "Sugamo", "JY11", 35.7335, 139.7394),
            st("Yamanote", "Otsuka", "大塚", "Otsuka", "JY12", 35.7312, 139.7286),
            st("Yamanote", "Ikebukuro", "池袋", "Ikebukuro", "JY13", 35.7295, 139.7109),
            st("Yamanote", "Mejiro", "目白", "Mejiro", "JY14", 35.7210, 139.7068),
            st("Yamanote", "Takadanobaba", "高田馬場", "Takadanobaba", "JY15", 35.7126, 139.7038),
            st("Yamanote", "ShinOkubo", "新大久保", "Shin-Okubo", "JY16", 35.7011, 139.7001),
            st("Yamanote", "Shinjuku", "新宿", "Shinjuku", "JY17", 35.6896, 139.7006),
            st("Yamanote", "Yoyogi", "代々木", "Yoyogi", "JY18", 35.6832, 139.7020),
            st("Yamanote", "Harajuku", "原宿", "Harajuku", "JY19", 35.6702, 139.7027),
            st("Yamanote", "Shibuya", "渋谷", "Shibuya", "JY20", 35.6580, 139.7016),
            st("Yamanote", "Ebisu", "恵比寿", "Ebisu", "JY21", 35.6467, 139.7101),
            st("Yamanote", "Meguro", "目黒", "Meguro", "JY22", 35.6340, 139.7157),
            st("Yamanote", "Gotanda", "五反田", "Gotanda", "JY23", 35.6262, 139.7233),
            st("Yamanote", "Osaki", "大崎", "Osaki", "JY24", 35.6197, 139.7286),
            st("Yamanote", "Shinagawa", "品川", "Shinagawa", "JY25", 35.6285, 139.7388),
            st("Yamanote", "TakanawaGateway", "高輪ゲートウェイ", "Takanawa Gateway", "JY26", 35.6355, 139.7407),
            st("Yamanote", "Tamachi", "田町", "Tamachi", "JY27", 35.6457, 139.7476),
            st("Yamanote", "Hamamatsucho", "浜松町", "Hamamatsucho", "JY28", 35.6556, 139.7570),
            st("Yamanote", "Shimbashi", "新橋", "Shimbashi", "JY29", 35.6663, 139.7583),
            st("Yamanote", "Yurakucho", "有楽町", "Yurakucho", "JY30", 35.6749, 139.7628),
        ],
        // All 2 except 大塚→池袋 and 大崎→品川, measured 3 (July-2026 pairs).
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2,
        ],
        // Real per-train timetable (630 grid) → 1:1 station timetables. Loop line:
        // trains wrap the 有楽町→東京 seam (isLoop) so their runs stay contiguous.
        timetableRuns: yamanoteTimetable,
        isLoop: true,
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.Yamanote.InnerLoop",
                nameJa: "内回り（上野・池袋方面）",
                nameEn: "Inner Loop (for Ueno & Ikebukuro)",
                isAscending: true,
                weekday: ServicePattern(
                    first: "04:46", last: "24:38",
                    bands: [
                        HeadwayBand(from: "04:40", headwayMinutes: 6),
                        HeadwayBand(from: "06:30", headwayMinutes: 3.5),
                        HeadwayBand(from: "09:30", headwayMinutes: 4),
                        HeadwayBand(from: "17:00", headwayMinutes: 3.5),
                        HeadwayBand(from: "20:00", headwayMinutes: 5),
                        HeadwayBand(from: "22:00", headwayMinutes: 6),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:46", last: "24:39",
                    bands: [
                        HeadwayBand(from: "04:40", headwayMinutes: 6),
                        HeadwayBand(from: "07:00", headwayMinutes: 4.5),
                        HeadwayBand(from: "10:00", headwayMinutes: 4),
                        HeadwayBand(from: "19:00", headwayMinutes: 5),
                        HeadwayBand(from: "22:00", headwayMinutes: 6),
                    ]
                )
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.Yamanote.OuterLoop",
                nameJa: "外回り（品川・渋谷方面）",
                nameEn: "Outer Loop (for Shinagawa & Shibuya)",
                isAscending: false,
                weekday: ServicePattern(
                    first: "04:51", last: "24:48",
                    bands: [
                        HeadwayBand(from: "04:40", headwayMinutes: 6),
                        HeadwayBand(from: "06:30", headwayMinutes: 3.5),
                        HeadwayBand(from: "09:30", headwayMinutes: 4),
                        HeadwayBand(from: "17:00", headwayMinutes: 3.5),
                        HeadwayBand(from: "20:00", headwayMinutes: 5),
                        HeadwayBand(from: "22:00", headwayMinutes: 6),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:51", last: "24:48",
                    bands: [
                        HeadwayBand(from: "04:40", headwayMinutes: 6),
                        HeadwayBand(from: "07:00", headwayMinutes: 4.5),
                        HeadwayBand(from: "10:00", headwayMinutes: 4),
                        HeadwayBand(from: "19:00", headwayMinutes: 5),
                        HeadwayBand(from: "22:00", headwayMinutes: 6),
                    ]
                )
            ),
        ],
        delayInfo: delayInfo
    )
}
