import Foundation

extension ToeiLineData {

    // MARK: - Nippori-Toneri Liner (NT)

    static let nipporiToneri = StaticTrainLine(
        id: "Railway:Toei.NipporiToneri",
        nameJa: "日暮里・舎人ライナー",
        nameEn: "Nippori-Toneri Liner",
        operatorId: "Operator:Toei",
        colorHex: "#EF5BA1",
        stations: [
            st("NipporiToneri", "Nippori", "日暮里", "Nippori", "NT01", 35.7278, 139.7708),
            st("NipporiToneri", "NishiNippori", "西日暮里", "Nishi-nippori", "NT02", 35.7324, 139.7669),
            st("NipporiToneri", "AkadoShogakkomae", "赤土小学校前", "Akado-shogakkomae", "NT03", 35.7418, 139.7682),
            st("NipporiToneri", "Kumanomae", "熊野前", "Kumanomae", "NT04", 35.7485, 139.7699),
            st("NipporiToneri", "AdachiOdai", "足立小台", "Adachi-odai", "NT05", 35.7555, 139.7735),
            st("NipporiToneri", "OgiOhashi", "扇大橋", "Ogi-ohashi", "NT06", 35.7638, 139.7752),
            st("NipporiToneri", "Koya", "高野", "Koya", "NT07", 35.7688, 139.7745),
            st("NipporiToneri", "Kohoku", "江北", "Kohoku", "NT08", 35.7758, 139.7745),
            st("NipporiToneri", "NishiaraidaishiNishi", "西新井大師西", "Nishiaraidaishi-nishi", "NT09", 35.7828, 139.7692),
            st("NipporiToneri", "Yazaike", "谷在家", "Yazaike", "NT10", 35.7898, 139.7658),
            st("NipporiToneri", "ToneriKoen", "舎人公園", "Toneri-koen", "NT11", 35.7968, 139.7658),
            st("NipporiToneri", "Toneri", "舎人", "Toneri", "NT12", 35.8048, 139.7662),
            st("NipporiToneri", "MinumadaiShinsuikoen", "見沼代親水公園", "Minumadai-shinsuikoen", "NT13", 35.8125, 139.7660),
        ],
        hopTimesMinutes: [2, 2, 2, 2, 1, 1, 2, 2, 1, 2, 1, 2],
        directions: [
            direction("NipporiToneri", "MinumadaiShinsuikoen", "見沼代親水公園方面", "For Minumadai-shinsuikoen", ascending: true,
                      weekday: pattern("05:33", "24:30", [
                          ("05:33", 8), ("07:00", 3), ("09:30", 7), ("17:00", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:33", "24:03", [
                          ("05:33", 8), ("07:00", 7), ("10:00", 7.5), ("20:00", 8), ("22:00", 10),
                      ]),
                      origins: [
                          origin("Station:Toei.NipporiToneri.ToneriKoen",
                                 ["05:36"],
                                 ["05:36"])
                      ]
            ),
            direction("NipporiToneri", "Nippori", "日暮里方面", "For Nippori", ascending: false,
                      // Last departures are 舎人公園行 short turns (コ on the official
                      // timetable), which run well past the last full-line 日暮里行.
                      weekday: pattern("05:08", "24:54", [
                          ("05:08", 8), ("07:00", 3), ("09:30", 7), ("17:00", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:08", "24:27", [
                          ("05:08", 8), ("07:00", 7), ("10:00", 7.5), ("20:00", 8), ("22:00", 10),
                      ])),
        ],
        delayInfo: delayInfo
    )

}
