import Foundation

extension SeibuLineData {

    // MARK: - Seibu Yurakucho Line (SI)

    static let seibuYurakucho = StaticTrainLine(
        id: "Railway:Seibu.SeibuYurakucho",
        nameJa: "西武有楽町線",
        nameEn: "Seibu Yurakucho Line",
        operatorId: "Operator:Seibu",
        colorHex: "#F08300",
        stations: [
            st("Seibu.SeibuYurakucho", "KotakeMukaihara", "小竹向原", "Kotake-Mukaihara", "SI37", 35.7437, 139.6787),
            st("Seibu.SeibuYurakucho", "Shinsakuradai", "新桜台", "Shin-sakuradai", "SI38", 35.7407, 139.6687),
            st("Seibu.SeibuYurakucho", "Nerima", "練馬", "Nerima", "SI06", 35.7377, 139.6537),
        ],
        hopTimesMinutes: [2, 2],
        directions: [
            // Feeder for metro through services; windows approximate the
            // through-running span
            direction("Seibu.SeibuYurakucho", "Nerima", "練馬・所沢方面", "For Nerima & Tokorozawa",
                      ascending: true,
                      weekday: pattern("05:02", "24:33", [
                          ("05:02", 10), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:02", "24:33", [
                          ("05:02", 10), ("07:00", 8), ("10:00", 8), ("20:00", 10),
                      ])),
            direction("Seibu.SeibuYurakucho", "KotakeMukaihara", "小竹向原方面", "For Kotake-Mukaihara",
                      ascending: false,
                      weekday: pattern("04:57", "24:16", [
                          ("04:57", 10), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:57", "24:16", [
                          ("04:57", 10), ("07:00", 8), ("10:00", 8), ("20:00", 10),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Seibu.SeibuYurakucho.KotakeMukaihara", .descending,
                    "東京メトロ有楽町線", "Tokyo Metro Yurakucho Line",
                    "有楽町・新木場方面", "for Yurakucho & Shin-Kiba",
                    to: "Railway:TokyoMetro.Yurakucho"),
            through("Seibu.SeibuYurakucho.KotakeMukaihara", .descending,
                    "東京メトロ副都心線", "Tokyo Metro Fukutoshin Line",
                    "渋谷・横浜方面", "for Shibuya & Yokohama",
                    to: "Railway:TokyoMetro.Fukutoshin"),
            through("Seibu.SeibuYurakucho.Nerima", .ascending,
                    "西武池袋線", "Seibu Ikebukuro Line",
                    "所沢・飯能方面", "for Tokorozawa & Hanno",
                    to: "Railway:Seibu.Ikebukuro"),
        ]
    )

}
