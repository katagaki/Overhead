import Foundation

extension TokyoMetroLineData {

    // MARK: - Marunouchi Line (M)

    static let marunouchi = StaticTrainLine(
        id: "Railway:TokyoMetro.Marunouchi",
        nameJa: "丸ノ内線",
        nameEn: "Marunouchi Line",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#E60012",
        stations: [
            st("Marunouchi", "Ogikubo", "荻窪", "Ogikubo", "M01", 35.7047, 139.6202),
            st("Marunouchi", "MinamiAsagaya", "南阿佐ケ谷", "Minami-Asagaya", "M02", 35.6998, 139.6356),
            st("Marunouchi", "ShinKoenji", "新高円寺", "Shin-Koenji", "M03", 35.6980, 139.6494),
            st("Marunouchi", "HigashiKoenji", "東高円寺", "Higashi-Koenji", "M04", 35.6976, 139.6605),
            st("Marunouchi", "ShinNakano", "新中野", "Shin-Nakano", "M05", 35.6972, 139.6707),
            st("Marunouchi", "NakanoSakaue", "中野坂上", "Nakano-sakaue", "M06", 35.6975, 139.6827),
            st("Marunouchi", "NishiShinjuku", "西新宿", "Nishi-shinjuku", "M07", 35.6945, 139.6926),
            st("Marunouchi", "Shinjuku", "新宿", "Shinjuku", "M08", 35.6907, 139.6996),
            st("Marunouchi", "ShinjukuSanchome", "新宿三丁目", "Shinjuku-sanchome", "M09", 35.6909, 139.7047),
            st("Marunouchi", "ShinjukuGyoemmae", "新宿御苑前", "Shinjuku-gyoemmae", "M10", 35.6887, 139.7109),
            st("Marunouchi", "YotsuyaSanchome", "四谷三丁目", "Yotsuya-sanchome", "M11", 35.6878, 139.7204),
            st("Marunouchi", "Yotsuya", "四ツ谷", "Yotsuya", "M12", 35.6858, 139.7290),
            st("Marunouchi", "AkasakaMitsuke", "赤坂見附", "Akasaka-mitsuke", "M13", 35.6770, 139.7370),
            st("Marunouchi", "KokkaiGijidomae", "国会議事堂前", "Kokkai-gijidomae", "M14", 35.6743, 139.7451),
            st("Marunouchi", "Kasumigaseki", "霞ケ関", "Kasumigaseki", "M15", 35.6750, 139.7518),
            st("Marunouchi", "Ginza", "銀座", "Ginza", "M16", 35.6717, 139.7640),
            st("Marunouchi", "Tokyo", "東京", "Tokyo", "M17", 35.6805, 139.7660),
            st("Marunouchi", "Otemachi", "大手町", "Otemachi", "M18", 35.6867, 139.7654),
            st("Marunouchi", "Awajicho", "淡路町", "Awajicho", "M19", 35.6950, 139.7677),
            st("Marunouchi", "Ochanomizu", "御茶ノ水", "Ochanomizu", "M20", 35.6998, 139.7649),
            st("Marunouchi", "HongoSanchome", "本郷三丁目", "Hongo-sanchome", "M21", 35.7068, 139.7597),
            st("Marunouchi", "Korakuen", "後楽園", "Korakuen", "M22", 35.7080, 139.7512),
            st("Marunouchi", "Myogadani", "茗荷谷", "Myogadani", "M23", 35.7175, 139.7371),
            st("Marunouchi", "ShinOtsuka", "新大塚", "Shin-otsuka", "M24", 35.7262, 139.7292),
            st("Marunouchi", "Ikebukuro", "池袋", "Ikebukuro", "M25", 35.7300, 139.7110),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 3,
        ],
        directions: [
            direction("Marunouchi", "Ikebukuro", "池袋方面", "For Ikebukuro", ascending: true,
                      weekday: metroWeekday("05:01", "24:11"), holiday: metroHoliday("05:01", "24:11"),
                      origins: [
                          origin("Station:TokyoMetro.Marunouchi.NakanoSakaue",
                                 ["05:04", "05:17", "05:31", "05:43", "05:55", "06:05", "06:13", "06:21", "06:29", "06:43", "06:50", "06:56", "07:02", "07:07", "07:13", "07:18", "07:27", "07:32", "07:37", "07:43", "07:48", "07:54", "08:05", "08:12", "08:18", "08:25", "08:32", "08:39", "08:45", "08:49", "08:54", "08:58", "09:03", "09:10", "09:17", "09:28", "09:38", "09:49", "10:21", "11:01", "11:21", "12:01", "12:26", "13:01", "13:26", "14:01", "14:26", "15:01", "15:20", "15:26", "15:33", "15:44", "15:54", "16:05", "16:12", "16:17", "16:24", "16:29", "16:34", "16:39", "16:46", "16:51", "17:01", "17:08", "17:21", "17:28", "17:41", "17:48", "18:01", "18:08", "18:21", "18:28", "18:41", "18:48", "19:01", "19:08", "19:21", "19:28", "19:41", "19:49"],
                                 ["05:04", "05:17", "06:01", "06:19", "06:55", "07:19", "08:26", "08:56", "09:26", "10:01", "10:26", "11:01", "11:26", "12:01", "12:26", "13:01", "13:26", "14:01", "14:26", "15:01", "15:26", "16:01", "16:26", "17:01", "17:26", "18:01", "18:26", "19:01", "19:26", "20:01", "20:26", "21:01", "21:26", "22:05"]),
                          origin("Station:TokyoMetro.Marunouchi.Shinjuku",
                                 ["05:00", "06:41"],
                                 ["05:00", "06:41"]),
                          origin("Station:TokyoMetro.Marunouchi.Korakuen",
                                 ["05:36"],
                                 ["05:51"]),
                          origin("Station:TokyoMetro.Marunouchi.Myogadani",
                                 ["05:00", "05:20", "05:51", "05:56", "06:15", "06:34", "06:44", "06:54", "07:06", "07:14", "07:22", "07:30", "07:44", "07:58", "08:14", "15:23", "15:38", "15:52", "16:04", "16:14", "16:24", "16:32", "16:42", "16:54"],
                                 ["05:00", "05:20", "06:08", "06:26", "07:22", "07:44"])
                      ]
            ),
            direction("Marunouchi", "Ogikubo", "荻窪方面", "For Ogikubo", ascending: false,
                      weekday: metroWeekday("05:00", "24:20"), holiday: metroHoliday("05:00", "24:20"),
                      origins: [
                          origin("Station:TokyoMetro.Marunouchi.NakanoSakaue",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:TokyoMetro.Marunouchi.ShinjukuSanchome",
                                 ["05:14", "05:26", "24:16"],
                                 ["05:14", "05:26", "24:16"]),
                          origin("Station:TokyoMetro.Marunouchi.Myogadani",
                                 ["05:13"],
                                 ["05:13"])
                      ]
            ),
        ],
        delayInfo: delayInfo
    )

}
