import Foundation

extension KeiseiLineData {

    // MARK: Keisei Oshiage Line (KS)

    static let oshiage = StaticTrainLine(
        id: "Railway:Keisei.Oshiage",
        nameJa: "京成押上線",
        nameEn: "Keisei Oshiage Line",
        operatorId: "Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.Oshiage", "Oshiage", "押上", "Oshiage 'SKYTREE'", "KS45", 35.7103, 139.8129),
            st("Keisei.Oshiage", "KeiseiHikifune", "京成曳舟", "Keisei-Hikifune", "KS46", 35.7168, 139.8178),
            st("Keisei.Oshiage", "Yahiro", "八広", "Yahiro", "KS47", 35.7228, 139.8268),
            st("Keisei.Oshiage", "Yotsugi", "四ツ木", "Yotsugi", "KS48", 35.7315, 139.8370),
            st("Keisei.Oshiage", "KeiseiTateishi", "京成立石", "Keisei-Tateishi", "KS49", 35.7378, 139.8478),
            st("Keisei.Oshiage", "Aoto", "青砥", "Aoto", "KS09", 35.7448, 139.8552),
        ],
        hopTimesMinutes: [2, 2, 2, 2, 3],
        directions: [
            direction("Keisei.Oshiage", "Aoto", "青砥方面", "For Aoto", ascending: true,
                      weekday: pattern("05:00", "24:27", [
                          ("05:00", 8), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:00", "24:27", [
                          ("05:00", 8), ("07:00", 7), ("10:00", 8), ("20:00", 9),
                      ])),
            direction("Keisei.Oshiage", "Oshiage", "押上方面", "For Oshiage", ascending: false,
                      weekday: pattern("04:50", "23:56", [
                          ("04:50", 8), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:50", "23:56", [
                          ("04:50", 8), ("07:00", 7), ("10:00", 8), ("20:00", 9),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.Oshiage.Aoto", .ascending,
                    "京成本線", "Keisei Main Line",
                    "京成船橋・成田空港方面", "for Keisei-Funabashi & Narita Airport",
                    to: "Railway:Keisei.Main"),
            through("Keisei.Oshiage.Oshiage", .descending,
                    "都営浅草線・京急線", "Toei Asakusa & Keikyu Lines",
                    "羽田空港・西馬込方面", "for Haneda Airport & Nishi-magome",
                    to: "Railway:Toei.Asakusa"),
        ]
    )

}
