import Foundation

extension TokyoMetroLineData {

    // MARK: - Yurakucho Line (Y)

    static let yurakucho = StaticTrainLine(
        id: "Railway:TokyoMetro.Yurakucho",
        nameJa: "有楽町線",
        nameEn: "Yurakucho Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#C1A470",
        stations: [
            st("Yurakucho", "Wakoshi", "和光市", "Wakoshi", "Y01", 35.7887, 139.6122),
            st("Yurakucho", "ChikatetsuNarimasu", "地下鉄成増", "Chikatetsu-narimasu", "Y02", 35.7775, 139.6317),
            st("Yurakucho", "ChikatetsuAkatsuka", "地下鉄赤塚", "Chikatetsu-akatsuka", "Y03", 35.7709, 139.6447),
            st("Yurakucho", "Heiwadai", "平和台", "Heiwadai", "Y04", 35.7578, 139.6530),
            st("Yurakucho", "Hikawadai", "氷川台", "Hikawadai", "Y05", 35.7483, 139.6633),
            st("Yurakucho", "KotakeMukaihara", "小竹向原", "Kotake-mukaihara", "Y06", 35.7433, 139.6788),
            st("Yurakucho", "Senkawa", "千川", "Senkawa", "Y07", 35.7382, 139.6898),
            st("Yurakucho", "Kanamecho", "要町", "Kanamecho", "Y08", 35.7323, 139.6992),
            st("Yurakucho", "Ikebukuro", "池袋", "Ikebukuro", "Y09", 35.7292, 139.7125),
            st("Yurakucho", "HigashiIkebukuro", "東池袋", "Higashi-ikebukuro", "Y10", 35.7204, 139.7193),
            st("Yurakucho", "Gokokuji", "護国寺", "Gokokuji", "Y11", 35.7180, 139.7287),
            st("Yurakucho", "Edogawabashi", "江戸川橋", "Edogawabashi", "Y12", 35.7074, 139.7355),
            st("Yurakucho", "Iidabashi", "飯田橋", "Iidabashi", "Y13", 35.7018, 139.7452),
            st("Yurakucho", "Ichigaya", "市ケ谷", "Ichigaya", "Y14", 35.6912, 139.7360),
            st("Yurakucho", "Kojimachi", "麹町", "Kojimachi", "Y15", 35.6840, 139.7392),
            st("Yurakucho", "Nagatacho", "永田町", "Nagatacho", "Y16", 35.6787, 139.7413),
            st("Yurakucho", "Sakuradamon", "桜田門", "Sakuradamon", "Y17", 35.6770, 139.7517),
            st("Yurakucho", "Yurakucho", "有楽町", "Yurakucho", "Y18", 35.6746, 139.7630),
            st("Yurakucho", "GinzaItchome", "銀座一丁目", "Ginza-itchome", "Y19", 35.6741, 139.7668),
            st("Yurakucho", "Shintomicho", "新富町", "Shintomicho", "Y20", 35.6708, 139.7723),
            st("Yurakucho", "Tsukishima", "月島", "Tsukishima", "Y21", 35.6640, 139.7838),
            st("Yurakucho", "Toyosu", "豊洲", "Toyosu", "Y22", 35.6549, 139.7964),
            st("Yurakucho", "Tatsumi", "辰巳", "Tatsumi", "Y23", 35.6454, 139.8104),
            st("Yurakucho", "ShinKiba", "新木場", "Shin-kiba", "Y24", 35.6460, 139.8268),
        ],
        hopTimesMinutes: [
            3, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 3, 2, 1, 2, 2, 1, 2, 2, 2, 3, 3,
        ],
        directions: [
            // Last departure 23:46 is an Ikebukuro-bound through train from
            // the Tobu Tojo Line, on all calendars
            direction("Yurakucho", "ShinKiba", "新木場方面", "For Shin-kiba", ascending: true,
                      weekday: quietWeekday("05:00", "23:46"), holiday: quietHoliday("05:00", "23:46"),
                      origins: [
                          origin("Station:TokyoMetro.Yurakucho.KotakeMukaihara",
                                 ["05:03", "06:02", "06:32", "07:00", "07:19", "07:26", "07:37", "07:41", "07:53", "08:02", "08:08", "08:11", "08:22", "08:32", "08:38", "08:46", "08:56", "09:02", "09:29", "09:47", "10:13", "11:12", "11:18", "11:31", "11:48", "12:01", "12:18", "12:31", "12:48", "13:01", "13:18", "13:31", "13:48", "14:01", "14:18", "14:31", "14:48", "15:01", "15:18", "15:31", "15:48", "16:01", "16:11", "16:31", "16:50", "17:02", "17:12", "17:32", "17:41", "17:56", "18:05", "18:16", "18:31", "18:46", "19:04", "19:14", "19:25", "19:36", "19:43", "19:57", "20:07", "20:33", "20:47", "21:10", "21:15", "21:38", "21:44", "22:02", "22:07", "22:33", "22:47", "23:26"],
                                 ["05:03", "06:01", "06:17", "06:37", "06:49", "07:26", "07:41", "07:52", "08:08", "08:34", "08:57", "09:08", "09:37", "10:05", "10:26", "10:31", "10:47", "11:01", "11:18", "11:31", "11:42", "11:48", "12:01", "12:18", "12:31", "12:48", "13:01", "13:18", "13:31", "13:48", "14:01", "14:18", "14:31", "14:48", "15:01", "15:18", "15:31", "15:48", "16:01", "16:18", "16:31", "16:47", "17:01", "17:18", "17:31", "17:41", "17:56", "18:31", "18:43", "18:55", "19:47", "20:49", "21:17", "21:46", "22:11", "22:49", "23:15", "23:30", "23:44"]),
                          origin("Station:TokyoMetro.Yurakucho.Ikebukuro",
                                 ["05:00", "07:01", "07:47", "08:09", "08:45", "09:59"],
                                 ["05:00"]),
                          origin("Station:TokyoMetro.Yurakucho.Yurakucho",
                                 ["05:01"],
                                 ["05:01"])
                      ]
            ),
            direction("Yurakucho", "Wakoshi", "和光市方面", "For Wakoshi", ascending: false,
                      weekday: quietWeekday("05:00", "24:01"), holiday: quietHoliday("05:00", "24:01"),
                      origins: [
                          origin("Station:TokyoMetro.Yurakucho.Ichigaya",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:TokyoMetro.Yurakucho.Toyosu",
                                 ["17:29", "18:29", "19:29", "20:30", "21:30"],
                                 [])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Yurakucho.Wakoshi", .descending,
                    "東武東上線", "Tobu Tojo Line",
                    "川越市・森林公園方面", "for Kawagoeshi & Shinrin-Koen",
                    to: "Railway:Tobu.Tojo"),
            through("Yurakucho.KotakeMukaihara", .descending,
                    "西武有楽町線・池袋線", "Seibu Yurakucho & Ikebukuro Lines",
                    "所沢・飯能方面", "for Tokorozawa & Hanno",
                    to: "Railway:Seibu.SeibuYurakucho"),
        ]
    )

}
