import Foundation

extension KeiseiLineData {

    static let chiba = StaticTrainLine(
        id: "Railway:Keisei.Chiba",
        nameJa: "京成千葉線",
        nameEn: "Keisei Chiba Line",
        operatorId: "Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.Chiba", "KeiseiTsudanuma", "京成津田沼", "Keisei-Tsudanuma", "KS26", 35.6828, 140.0248),
            st("Keisei.Chiba", "KeiseiMakuharihongo", "京成幕張本郷", "Keisei-Makuharihongo", "KS52", 35.6726, 140.0421),
            st("Keisei.Chiba", "KeiseiMakuhari", "京成幕張", "Keisei-Makuhari", "KS53", 35.6610, 140.0557),
            st("Keisei.Chiba", "Kemigawa", "検見川", "Kemigawa", "KS54", 35.6526, 140.0663),
            st("Keisei.Chiba", "KeiseiInage", "京成稲毛", "Keisei-Inage", "KS55", 35.6378, 140.0855),
            st("Keisei.Chiba", "Midoridai", "みどり台", "Midoridai", "KS56", 35.6248, 140.0977),
            st("Keisei.Chiba", "NishiNobuto", "西登戸", "Nishi-Nobuto", "KS57", 35.6176, 140.1028),
            st("Keisei.Chiba", "ShinChiba", "新千葉", "Shin-Chiba", "KS58", 35.6124, 140.1083),
            st("Keisei.Chiba", "KeiseiChiba", "京成千葉", "Keisei-Chiba", "KS59", 35.6117, 140.1144),
            st("Keisei.Chiba", "Chibachuo", "千葉中央", "Chiba-Chuo", "KS60", 35.6073, 140.1178),
        ],
        hopTimesMinutes: [3, 2, 2, 3, 2, 2, 1, 2, 2],
        directions: [
            direction("Keisei.Chiba", "Chibachuo", "千葉中央方面", "For Chiba-Chuo", ascending: true,
                      weekday: chibaWeekday, holiday: chibaHoliday),
            direction("Keisei.Chiba", "KeiseiTsudanuma", "京成津田沼方面", "For Keisei-Tsudanuma", ascending: false,
                      weekday: chibaWeekday, holiday: chibaHoliday),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.Chiba.Chibachuo", .ascending,
                    "京成千原線", "Keisei Chihara Line",
                    "ちはら台方面", "for Chiharadai",
                    to: "Railway:Keisei.Chihara"),
            through("Keisei.Chiba.KeiseiTsudanuma", .descending,
                    "京成本線", "Keisei Main Line",
                    "京成上野方面", "for Keisei-Ueno",
                    to: "Railway:Keisei.Main"),
            through("Keisei.Chiba.KeiseiTsudanuma", .descending,
                    "京成松戸線", "Keisei Matsudo Line",
                    "松戸方面", "for Matsudo"),
        ]
    )

    // MARK: Keisei Chiba Line (KS)

    private static let chibaWeekday = pattern("05:00", "23:45", [
        ("05:00", 10), ("06:30", 7), ("09:30", 10), ("17:00", 8), ("20:00", 10), ("22:00", 12),
    ])

    private static let chibaHoliday = pattern("05:00", "23:45", [
        ("05:00", 10), ("20:00", 12),
    ])

}
