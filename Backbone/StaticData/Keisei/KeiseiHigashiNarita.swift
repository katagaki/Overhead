import Foundation

extension KeiseiLineData {

    static let higashiNarita = StaticTrainLine(
        id: "Railway:Keisei.HigashiNarita",
        nameJa: "京成東成田線",
        nameEn: "Keisei Higashi-Narita Line",
        operatorId: "Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.HigashiNarita", "KeiseiNarita", "京成成田", "Keisei-Narita", "KS40", 35.7718, 140.3178),
            st("Keisei.HigashiNarita", "HigashiNarita", "東成田", "Higashi-Narita", "KS44", 35.7701, 140.3872),
        ],
        hopTimesMinutes: [8],
        directions: [
            direction("Keisei.HigashiNarita", "HigashiNarita", "東成田方面", "For Higashi-Narita", ascending: true,
                      weekday: higashiNaritaPattern("05:51", "23:08"), holiday: higashiNaritaPattern("05:51", "23:08")),
            direction("Keisei.HigashiNarita", "KeiseiNarita", "京成成田方面", "For Keisei-Narita", ascending: false,
                      weekday: higashiNaritaPattern("06:11", "23:27"), holiday: higashiNaritaPattern("06:11", "23:27")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.HigashiNarita.HigashiNarita", .ascending,
                    "芝山鉄道線", "Shibayama Railway Line",
                    "芝山千代田方面", "for Shibayama-Chiyoda"),
        ]
    )

    // MARK: Keisei Higashi-Narita Line (KS)

    private static func higashiNaritaPattern(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 40),
        ])
    }

}
