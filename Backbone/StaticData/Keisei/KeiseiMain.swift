import Foundation

extension KeiseiLineData {

    // MARK: Keisei Main Line (KS)

    static let main = StaticTrainLine(
        id: "Railway:Keisei.Main",
        nameJa: "京成本線",
        nameEn: "Keisei Main Line",
        operatorId: "Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.Main", "KeiseiUeno", "京成上野", "Keisei-Ueno", "KS01", 35.7113, 139.7742),
            st("Keisei.Main", "Nippori", "日暮里", "Nippori", "KS02", 35.7280, 139.7710),
            st("Keisei.Main", "ShinMikawashima", "新三河島", "Shin-Mikawashima", "KS03", 35.7388, 139.7768),
            st("Keisei.Main", "Machiya", "町屋", "Machiya", "KS04", 35.7424, 139.7812),
            st("Keisei.Main", "SenjuOhashi", "千住大橋", "Senju-Ohashi", "KS05", 35.7418, 139.7935),
            st("Keisei.Main", "KeiseiSekiya", "京成関屋", "Keisei-Sekiya", "KS06", 35.7438, 139.8082),
            st("Keisei.Main", "HorikiriShobuen", "堀切菖蒲園", "Horikiri-Shobuen", "KS07", 35.7438, 139.8228),
            st("Keisei.Main", "Ohanajaya", "お花茶屋", "Ohanajaya", "KS08", 35.7478, 139.8338),
            st("Keisei.Main", "Aoto", "青砥", "Aoto", "KS09", 35.7448, 139.8552),
            st("Keisei.Main", "KeiseiTakasago", "京成高砂", "Keisei-Takasago", "KS10", 35.7498, 139.8658),
            st("Keisei.Main", "KeiseiKoiwa", "京成小岩", "Keisei-Koiwa", "KS11", 35.7438, 139.8808),
            st("Keisei.Main", "Edogawa", "江戸川", "Edogawa", "KS12", 35.7368, 139.8942),
            st("Keisei.Main", "Konodai", "国府台", "Konodai", "KS13", 35.7348, 139.9018),
            st("Keisei.Main", "Ichikawamama", "市川真間", "Ichikawamama", "KS14", 35.7328, 139.9108),
            st("Keisei.Main", "Sugano", "菅野", "Sugano", "KS15", 35.7288, 139.9208),
            st("Keisei.Main", "KeiseiYawata", "京成八幡", "Keisei-Yawata", "KS16", 35.7228, 139.9278),
            st("Keisei.Main", "Onigoe", "鬼越", "Onigoe", "KS17", 35.7218, 139.9368),
            st("Keisei.Main", "KeiseiNakayama", "京成中山", "Keisei-Nakayama", "KS18", 35.7178, 139.9438),
            st("Keisei.Main", "HigashiNakayama", "東中山", "Higashi-Nakayama", "KS19", 35.7148, 139.9498),
            st("Keisei.Main", "KeiseiNishifuna", "京成西船", "Keisei-Nishifuna", "KS20", 35.7118, 139.9548),
            st("Keisei.Main", "Kaijin", "海神", "Kaijin", "KS21", 35.7058, 139.9698),
            st("Keisei.Main", "KeiseiFunabashi", "京成船橋", "Keisei-Funabashi", "KS22", 35.7008, 139.9848),
            st("Keisei.Main", "Daijingushita", "大神宮下", "Daijingushita", "KS23", 35.6978, 139.9928),
            st("Keisei.Main", "Funabashikeibajo", "船橋競馬場", "Funabashikeibajo", "KS24", 35.6968, 140.0008),
            st("Keisei.Main", "Yatsu", "谷津", "Yatsu", "KS25", 35.6868, 140.0108),
            st("Keisei.Main", "KeiseiTsudanuma", "京成津田沼", "Keisei-Tsudanuma", "KS26", 35.6828, 140.0248),
            st("Keisei.Main", "KeiseiOkubo", "京成大久保", "Keisei-Okubo", "KS27", 35.6868, 140.0448),
            st("Keisei.Main", "Mimomi", "実籾", "Mimomi", "KS28", 35.6898, 140.0628),
            st("Keisei.Main", "Yachiyodai", "八千代台", "Yachiyodai", "KS29", 35.7058, 140.0808),
            st("Keisei.Main", "KeiseiOwada", "京成大和田", "Keisei-Owada", "KS30", 35.7128, 140.0958),
            st("Keisei.Main", "Katsutadai", "勝田台", "Katsutadai", "KS31", 35.7178, 140.1128),
            st("Keisei.Main", "Shizu", "志津", "Shizu", "KS32", 35.7158, 140.1308),
            st("Keisei.Main", "Yukarigaoka", "ユーカリが丘", "Yukarigaoka", "KS33", 35.7178, 140.1498),
            st("Keisei.Main", "KeiseiUsui", "京成臼井", "Keisei-Usui", "KS34", 35.7248, 140.1718),
            st("Keisei.Main", "KeiseiSakura", "京成佐倉", "Keisei-Sakura", "KS35", 35.7228, 140.2168),
            st("Keisei.Main", "Osakura", "大佐倉", "Osakura", "KS36", 35.7288, 140.2428),
            st("Keisei.Main", "KeiseiShisui", "京成酒々井", "Keisei-Shisui", "KS37", 35.7248, 140.2678),
            st("Keisei.Main", "Sogosando", "宗吾参道", "Sogosando", "KS38", 35.7348, 140.2868),
            st("Keisei.Main", "Kozunomori", "公津の杜", "Kozunomori", "KS39", 35.7568, 140.3038),
            st("Keisei.Main", "KeiseiNarita", "京成成田", "Keisei-Narita", "KS40", 35.7718, 140.3178),
            st("Keisei.Main", "AirportTerminal2", "空港第2ビル", "Narita Airport Terminal 2·3", "KS41", 35.7718, 140.3925),
            st("Keisei.Main", "NaritaAirport", "成田空港", "Narita Airport Terminal 1", "KS42", 35.7640, 140.3860),
        ],
        hopTimesMinutes: [
            4, 3, 1, 2, 2, 2, 2, 3, 2, 2, 2, 2, 1, 2, 2, 2, 1, 1, 2, 2,
            2, 2, 1, 2, 2, 3, 2, 3, 2, 2, 2, 2, 3, 4, 3, 3, 2, 2, 3, 8, 2,
        ],
        directions: [
            direction("Keisei.Main", "NaritaAirport", "成田空港方面", "For Narita Airport", ascending: true,
                      weekday: keiseiWeekday("05:03", "24:21"), holiday: keiseiHoliday("05:03", "24:21")),
            direction("Keisei.Main", "KeiseiUeno", "京成上野方面", "For Keisei-Ueno", ascending: false,
                      weekday: keiseiWeekday("05:17", "24:09"), holiday: keiseiHoliday("05:17", "24:09")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.Main.Aoto", .descending,
                    "京成押上線・都営浅草線", "Keisei Oshiage & Toei Asakusa Lines",
                    "押上・西馬込方面", "for Oshiage & Nishi-magome",
                    to: "Railway:Keisei.Oshiage"),
            through("Keisei.Main.KeiseiTakasago", .ascending,
                    "成田スカイアクセス線", "Narita Sky Access Line",
                    "成田空港方面", "for Narita Airport",
                    to: "Railway:Keisei.NaritaSkyAccess"),
            through("Keisei.Main.KeiseiTsudanuma", .ascending,
                    "京成千葉線", "Keisei Chiba Line",
                    "千葉中央方面", "for Chiba-Chuo",
                    to: "Railway:Keisei.Chiba"),
        ]
    )

    private static func keiseiWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 10), ("06:30", 6), ("09:30", 10), ("16:30", 8), ("20:00", 10), ("22:00", 12),
        ])
    }

    private static func keiseiHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 10), ("07:00", 8), ("10:00", 10), ("20:00", 11),
        ])
    }

}
