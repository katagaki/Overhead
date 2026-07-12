import Foundation

extension TokyoMetroLineData {

    // MARK: - Hanzomon Line (Z)

    static let hanzomon = StaticTrainLine(
        id: "Railway:TokyoMetro.Hanzomon",
        nameJa: "半蔵門線",
        nameEn: "Hanzomon Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#8B76D0",
        stations: [
            st("Hanzomon", "Shibuya", "渋谷", "Shibuya", "Z01", 35.6580, 139.7016),
            st("Hanzomon", "Omotesando", "表参道", "Omote-sando", "Z02", 35.6654, 139.7122),
            st("Hanzomon", "AoyamaItchome", "青山一丁目", "Aoyama-itchome", "Z03", 35.6726, 139.7244),
            st("Hanzomon", "Nagatacho", "永田町", "Nagatacho", "Z04", 35.6787, 139.7413),
            st("Hanzomon", "Hanzomon", "半蔵門", "Hanzomon", "Z05", 35.6852, 139.7413),
            st("Hanzomon", "Kudanshita", "九段下", "Kudanshita", "Z06", 35.6957, 139.7515),
            st("Hanzomon", "Jimbocho", "神保町", "Jimbocho", "Z07", 35.6958, 139.7578),
            st("Hanzomon", "Otemachi", "大手町", "Otemachi", "Z08", 35.6868, 139.7647),
            st("Hanzomon", "Mitsukoshimae", "三越前", "Mitsukoshimae", "Z09", 35.6866, 139.7730),
            st("Hanzomon", "Suitengumae", "水天宮前", "Suitengumae", "Z10", 35.6830, 139.7853),
            st("Hanzomon", "KiyosumiShirakawa", "清澄白河", "Kiyosumi-shirakawa", "Z11", 35.6816, 139.7994),
            st("Hanzomon", "Sumiyoshi", "住吉", "Sumiyoshi", "Z12", 35.6890, 139.8143),
            st("Hanzomon", "Kinshicho", "錦糸町", "Kinshicho", "Z13", 35.6967, 139.8140),
            st("Hanzomon", "Oshiage", "押上", "Oshiage 'SKYTREE'", "Z14", 35.7103, 139.8129),
        ],
        hopTimesMinutes: [
            2, 2, 3, 1, 2, 1, 2, 2, 2, 2, 3, 2, 3,
        ],
        directions: [
            direction("Hanzomon", "Oshiage", "押上方面", "For Oshiage", ascending: true,
                      weekday: quietWeekday("05:15", "24:12"), holiday: quietHoliday("05:15", "24:15"),
                      origins: [
                          origin("Station:TokyoMetro.Hanzomon.Hanzomon",
                                 ["05:08"],
                                 ["05:07"]),
                          origin("Station:TokyoMetro.Hanzomon.KiyosumiShirakawa",
                                 ["05:06"],
                                 ["05:06"])
                      ]
            ),
            direction("Hanzomon", "Shibuya", "渋谷方面", "For Shibuya", ascending: false,
                      weekday: quietWeekday("05:06", "24:18"), holiday: quietHoliday("05:06", "23:53"),
                      origins: [
                          origin("Station:TokyoMetro.Hanzomon.Hanzomon",
                                 ["07:38"],
                                 []),
                          origin("Station:TokyoMetro.Hanzomon.Suitengumae",
                                 ["05:02"],
                                 ["05:02"]),
                          origin("Station:TokyoMetro.Hanzomon.KiyosumiShirakawa",
                                 ["07:05", "07:30", "07:39", "07:45", "07:57", "08:06", "08:17", "08:27", "08:36"],
                                 []),
                          origin("Station:TokyoMetro.Hanzomon.Sumiyoshi",
                                 ["05:57", "17:52"],
                                 ["06:13"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Hanzomon.Shibuya", .descending,
                    "東急田園都市線", "Tokyu Den-en-toshi Line",
                    "中央林間方面", "for Chuo-Rinkan",
                    to: "Railway:Tokyu.DenEnToshi"),
            through("Hanzomon.Oshiage", .ascending,
                    "東武スカイツリーライン", "Tobu Skytree Line",
                    "久喜・南栗橋方面", "for Kuki & Minami-Kurihashi",
                    to: "Railway:Tobu.TobuSkytree"),
        ]
    )

}
