import Foundation

extension TokyoMetroLineData {

    // MARK: - Ginza Line (G)

    static let ginza = StaticTrainLine(
        id: "Railway:TokyoMetro.Ginza",
        nameJa: "銀座線",
        nameEn: "Ginza Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#F7931D",
        stations: [
            st("Ginza", "Shibuya", "渋谷", "Shibuya", "G01", 35.6580, 139.7016),
            st("Ginza", "Omotesando", "表参道", "Omote-sando", "G02", 35.6654, 139.7122),
            st("Ginza", "Gaiemmae", "外苑前", "Gaiemmae", "G03", 35.6706, 139.7178),
            st("Ginza", "AoyamaItchome", "青山一丁目", "Aoyama-itchome", "G04", 35.6726, 139.7244),
            st("Ginza", "AkasakaMitsuke", "赤坂見附", "Akasaka-mitsuke", "G05", 35.6770, 139.7370),
            st("Ginza", "TameikeSanno", "溜池山王", "Tameike-sanno", "G06", 35.6739, 139.7413),
            st("Ginza", "Toranomon", "虎ノ門", "Toranomon", "G07", 35.6700, 139.7496),
            st("Ginza", "Shimbashi", "新橋", "Shimbashi", "G08", 35.6660, 139.7583),
            st("Ginza", "Ginza", "銀座", "Ginza", "G09", 35.6717, 139.7640),
            st("Ginza", "Kyobashi", "京橋", "Kyobashi", "G10", 35.6767, 139.7701),
            st("Ginza", "Nihombashi", "日本橋", "Nihombashi", "G11", 35.6824, 139.7742),
            st("Ginza", "Mitsukoshimae", "三越前", "Mitsukoshimae", "G12", 35.6866, 139.7730),
            st("Ginza", "Kanda", "神田", "Kanda", "G13", 35.6910, 139.7708),
            st("Ginza", "Suehirocho", "末広町", "Suehirocho", "G14", 35.7023, 139.7715),
            st("Ginza", "UenoHirokoji", "上野広小路", "Ueno-hirokoji", "G15", 35.7076, 139.7727),
            st("Ginza", "Ueno", "上野", "Ueno", "G16", 35.7115, 139.7772),
            st("Ginza", "Inaricho", "稲荷町", "Inaricho", "G17", 35.7115, 139.7827),
            st("Ginza", "Tawaramachi", "田原町", "Tawaramachi", "G18", 35.7100, 139.7905),
            st("Ginza", "Asakusa", "浅草", "Asakusa", "G19", 35.7109, 139.7966),
        ],
        hopTimesMinutes: [
            2, 2, 1, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 1, 2, 2, 1, 2,
        ],
        directions: [
            direction("Ginza", "Asakusa", "浅草方面", "For Asakusa", ascending: true,
                      weekday: metroWeekday("05:01", "24:02"), holiday: metroHoliday("05:01", "24:02"),
                      origins: [
                          origin("Station:TokyoMetro.Ginza.Toranomon",
                                 ["06:10"],
                                 []),
                          origin("Station:TokyoMetro.Ginza.Shimbashi",
                                 [],
                                 ["06:09"]),
                          origin("Station:TokyoMetro.Ginza.Ueno",
                                 ["05:15", "06:04"],
                                 ["05:15", "06:04"])
                      ]
            ),
            direction("Ginza", "Shibuya", "渋谷方面", "For Shibuya", ascending: false,
                      weekday: metroWeekday("05:01", "24:10"), holiday: metroHoliday("05:01", "24:14"),
                      origins: [
                          origin("Station:TokyoMetro.Ginza.TameikeSanno",
                                 ["06:29"],
                                 ["07:41"]),
                          origin("Station:TokyoMetro.Ginza.Ueno",
                                 ["06:27", "06:36", "07:03", "07:12", "07:20", "07:27", "07:32", "07:36", "07:43", "07:50", "07:57", "08:09", "15:47", "15:59", "16:11", "16:23", "16:33", "16:40", "16:50", "16:59", "17:07"],
                                 ["07:51", "08:35", "09:14", "09:35"])
                      ]
            ),
        ],
        delayInfo: delayInfo
    )

}
