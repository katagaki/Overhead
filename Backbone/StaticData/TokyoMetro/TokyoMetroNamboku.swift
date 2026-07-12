import Foundation

extension TokyoMetroLineData {

    // MARK: - Namboku Line (N)

    static let namboku = StaticTrainLine(
        id: "Railway:TokyoMetro.Namboku",
        nameJa: "南北線",
        nameEn: "Namboku Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#00ADA9",
        stations: [
            st("Namboku", "Meguro", "目黒", "Meguro", "N01", 35.6340, 139.7157),
            st("Namboku", "Shirokanedai", "白金台", "Shirokanedai", "N02", 35.6376, 139.7263),
            st("Namboku", "ShirokaneTakanawa", "白金高輪", "Shirokane-takanawa", "N03", 35.6431, 139.7343),
            st("Namboku", "AzabuJuban", "麻布十番", "Azabu-juban", "N04", 35.6544, 139.7368),
            st("Namboku", "RoppongiItchome", "六本木一丁目", "Roppongi-itchome", "N05", 35.6635, 139.7392),
            st("Namboku", "TameikeSanno", "溜池山王", "Tameike-sanno", "N06", 35.6739, 139.7413),
            st("Namboku", "Nagatacho", "永田町", "Nagatacho", "N07", 35.6787, 139.7413),
            st("Namboku", "Yotsuya", "四ツ谷", "Yotsuya", "N08", 35.6857, 139.7292),
            st("Namboku", "Ichigaya", "市ケ谷", "Ichigaya", "N09", 35.6912, 139.7360),
            st("Namboku", "Iidabashi", "飯田橋", "Iidabashi", "N10", 35.7018, 139.7452),
            st("Namboku", "Korakuen", "後楽園", "Korakuen", "N11", 35.7080, 139.7512),
            st("Namboku", "Todaimae", "東大前", "Todaimae", "N12", 35.7175, 139.7578),
            st("Namboku", "HonKomagome", "本駒込", "Hon-komagome", "N13", 35.7245, 139.7540),
            st("Namboku", "Komagome", "駒込", "Komagome", "N14", 35.7365, 139.7460),
            st("Namboku", "Nishigahara", "西ケ原", "Nishigahara", "N15", 35.7419, 139.7393),
            st("Namboku", "Oji", "王子", "Oji", "N16", 35.7526, 139.7380),
            st("Namboku", "OjiKamiya", "王子神谷", "Oji-kamiya", "N17", 35.7645, 139.7420),
            st("Namboku", "Shimo", "志茂", "Shimo", "N18", 35.7736, 139.7305),
            st("Namboku", "AkabaneIwabuchi", "赤羽岩淵", "Akabane-iwabuchi", "N19", 35.7830, 139.7218),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        ],
        directions: [
            direction("Namboku", "AkabaneIwabuchi", "赤羽岩淵方面", "For Akabane-iwabuchi", ascending: true,
                      weekday: quietWeekday("05:16", "23:59"), holiday: quietHoliday("05:16", "23:59"),
                      origins: [
                          origin("Station:TokyoMetro.Namboku.ShirokaneTakanawa",
                                 ["05:07", "05:34", "08:18", "08:37", "08:53", "09:01", "09:13", "09:23", "09:31", "09:42", "09:53", "10:06", "10:11", "10:21", "10:33", "10:39", "10:51", "11:03", "11:09", "11:33", "11:39", "12:03", "12:09", "12:33", "12:39", "13:03", "13:09", "13:33", "13:39", "14:03", "14:09", "14:33", "14:39", "15:03", "15:09", "15:33", "15:39", "16:03", "16:09", "16:33", "16:39", "17:04", "17:10", "17:49", "18:14", "18:44", "18:58", "19:13", "19:28", "19:58", "20:27", "20:48", "20:56", "21:29", "21:49", "22:15", "22:30", "22:43", "22:50", "23:15", "23:29", "23:36", "24:00"],
                                 ["05:07", "05:34", "06:06", "06:37", "06:46", "07:21", "07:28", "07:34", "08:09", "08:30", "08:40", "08:45", "08:55", "09:05", "09:14", "09:33", "09:39", "10:03", "10:09", "10:33", "10:39", "11:03", "11:09", "11:33", "11:39", "12:03", "12:09", "12:33", "12:39", "13:03", "13:09", "13:33", "13:39", "14:03", "14:09", "14:33", "14:39", "15:03", "15:09", "15:33", "15:39", "16:03", "16:09", "16:33", "16:39", "17:03", "17:09", "17:33", "17:39", "18:03", "18:09", "18:33", "18:39", "19:03", "19:09", "19:23", "19:43", "19:56", "20:25", "20:47", "21:11", "21:40", "22:03", "22:19", "22:33", "22:48", "22:55", "23:13", "23:22", "23:46", "23:55"]),
                          origin("Station:TokyoMetro.Namboku.AzabuJuban",
                                 ["09:01", "09:18"],
                                 []),
                          origin("Station:TokyoMetro.Namboku.Ichigaya",
                                 ["05:03", "06:10", "07:05", "07:15"],
                                 ["05:03"]),
                          origin("Station:TokyoMetro.Namboku.OjiKamiya",
                                 ["05:09"],
                                 ["05:09"])
                      ]
            ),
            direction("Namboku", "Meguro", "目黒方面", "For Meguro", ascending: false,
                      weekday: quietWeekday("05:01", "24:26"), holiday: quietHoliday("05:01", "24:16"),
                      origins: [
                          origin("Station:TokyoMetro.Namboku.TameikeSanno",
                                 ["05:03"],
                                 ["05:03"]),
                          origin("Station:TokyoMetro.Namboku.Komagome",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:TokyoMetro.Namboku.OjiKamiya",
                                 ["06:34", "08:13", "16:48", "17:33", "18:31"],
                                 ["07:31", "07:47"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Namboku.AkabaneIwabuchi", .ascending,
                    "埼玉高速鉄道線", "Saitama Rapid Railway Line",
                    "浦和美園方面", "for Urawa-Misono",
                    to: "Railway:SaitamaRailway.SaitamaRailway"),
            through("Namboku.Meguro", .descending,
                    "東急目黒線・新横浜線", "Tokyu Meguro & Shin-Yokohama Lines",
                    "日吉・新横浜方面", "for Hiyoshi & Shin-Yokohama",
                    to: "Railway:Tokyu.Meguro"),
        ]
    )

}
