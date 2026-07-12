import Foundation

extension ToeiLineData {

    // MARK: - Mita Line (I)

    static let mita = StaticTrainLine(
        id: "Railway:Toei.Mita",
        nameJa: "都営三田線",
        nameEn: "Toei Mita Line",
        operatorId: "Operator:Toei",
        colorHex: "#0079C2",
        stations: [
            st("Mita", "Meguro", "目黒", "Meguro", "I01", 35.6340, 139.7157),
            st("Mita", "Shirokanedai", "白金台", "Shirokanedai", "I02", 35.6376, 139.7263),
            st("Mita", "ShirokaneTakanawa", "白金高輪", "Shirokane-takanawa", "I03", 35.6431, 139.7343),
            st("Mita", "Mita", "三田", "Mita", "I04", 35.6484, 139.7476),
            st("Mita", "Shibakoen", "芝公園", "Shibakoen", "I05", 35.6544, 139.7497),
            st("Mita", "Onarimon", "御成門", "Onarimon", "I06", 35.6618, 139.7506),
            st("Mita", "Uchisaiwaicho", "内幸町", "Uchisaiwaicho", "I07", 35.6698, 139.7548),
            st("Mita", "Hibiya", "日比谷", "Hibiya", "I08", 35.6748, 139.7595),
            st("Mita", "Otemachi", "大手町", "Otemachi", "I09", 35.6875, 139.7625),
            st("Mita", "Jimbocho", "神保町", "Jimbocho", "I10", 35.6958, 139.7578),
            st("Mita", "Suidobashi", "水道橋", "Suidobashi", "I11", 35.7020, 139.7530),
            st("Mita", "Kasuga", "春日", "Kasuga", "I12", 35.7125, 139.7525),
            st("Mita", "Hakusan", "白山", "Hakusan", "I13", 35.7222, 139.7518),
            st("Mita", "Sengoku", "千石", "Sengoku", "I14", 35.7282, 139.7448),
            st("Mita", "Sugamo", "巣鴨", "Sugamo", "I15", 35.7335, 139.7394),
            st("Mita", "NishiSugamo", "西巣鴨", "Nishi-sugamo", "I16", 35.7422, 139.7298),
            st("Mita", "ShinItabashi", "新板橋", "Shin-itabashi", "I17", 35.7478, 139.7192),
            st("Mita", "Itabashikuyakushomae", "板橋区役所前", "Itabashikuyakushomae", "I18", 35.7512, 139.7092),
            st("Mita", "Itabashihoncho", "板橋本町", "Itabashihoncho", "I19", 35.7578, 139.7002),
            st("Mita", "Motohasunuma", "本蓮沼", "Motohasunuma", "I20", 35.7652, 139.6942),
            st("Mita", "ShimuraSakaue", "志村坂上", "Shimura-sakaue", "I21", 35.7722, 139.6872),
            st("Mita", "ShimuraSanchome", "志村三丁目", "Shimura-sanchome", "I22", 35.7788, 139.6792),
            st("Mita", "Hasune", "蓮根", "Hasune", "I23", 35.7878, 139.6722),
            st("Mita", "Nishidai", "西台", "Nishidai", "I24", 35.7922, 139.6652),
            st("Mita", "Takashimadaira", "高島平", "Takashimadaira", "I25", 35.7948, 139.6562),
            st("Mita", "ShinTakashimadaira", "新高島平", "Shin-takashimadaira", "I26", 35.7962, 139.6472),
            st("Mita", "NishiTakashimadaira", "西高島平", "Nishi-takashimadaira", "I27", 35.7982, 139.6378),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 1, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2,
        ],
        directions: [
            direction("Mita", "NishiTakashimadaira", "西高島平方面", "For Nishi-takashimadaira", ascending: true,
                      weekday: toeiWeekday("05:12", "23:55"), holiday: toeiHoliday("05:12", "23:54"),
                      origins: [
                          origin("Station:Toei.Mita.ShirokaneTakanawa",
                                 ["05:00", "05:44", "06:18", "06:46", "07:59", "08:06", "08:22", "08:29", "08:34", "08:41", "08:46", "08:56", "09:03", "09:10", "09:19", "09:33", "09:47", "09:59", "10:07", "10:19", "10:47", "11:17", "11:23", "11:47", "11:53", "12:18", "12:23", "12:48", "12:54", "13:18", "13:24", "13:48", "13:54", "14:18", "14:24", "14:48", "14:54", "15:18", "15:24", "15:48", "15:54", "16:18", "16:25", "16:49", "16:55", "17:16", "17:21", "17:26", "17:41", "17:45", "17:59", "18:04", "18:09", "18:22", "18:26", "18:41", "18:51", "19:06", "19:17", "19:31", "19:45", "19:55", "20:04", "20:41", "21:07", "21:14", "21:34", "21:54", "22:08", "22:59", "23:22", "23:52"],
                                 ["05:00", "05:44", "06:16", "06:53", "07:07", "07:14", "07:42", "07:56", "08:15", "08:20", "08:25", "08:34", "08:50", "09:08", "09:19", "09:24", "09:47", "09:53", "10:17", "10:23", "10:48", "10:54", "11:18", "11:24", "11:48", "11:54", "12:18", "12:23", "12:48", "12:54", "13:18", "13:24", "13:48", "13:54", "14:18", "14:24", "14:48", "14:54", "15:18", "15:24", "15:48", "15:54", "16:18", "16:24", "16:48", "16:54", "17:18", "17:24", "17:48", "17:54", "18:18", "18:24", "18:48", "18:54", "19:19", "19:32", "20:00", "20:13", "20:21", "20:42", "21:21", "21:49", "21:55", "22:28", "22:59", "23:06", "23:31", "23:38", "23:45"]),
                          origin("Station:Toei.Mita.Takashimadaira",
                                 ["16:27", "20:50"],
                                 ["09:41", "18:57"])
                      ]
            ),
            direction("Mita", "Meguro", "目黒方面", "For Meguro", ascending: false,
                      weekday: toeiWeekday("05:10", "23:45"), holiday: toeiHoliday("05:10", "23:45"),
                      origins: [
                          origin("Station:Toei.Mita.Onarimon",
                                 ["05:13"],
                                 ["05:13"]),
                          origin("Station:Toei.Mita.ShinItabashi",
                                 ["05:00"],
                                 ["05:00"]),
                          origin("Station:Toei.Mita.Takashimadaira",
                                 ["05:00", "05:50", "06:13", "07:12", "07:28", "07:37", "07:47", "07:59", "08:06", "16:19", "16:43", "16:57", "17:10", "17:29"],
                                 ["05:00", "06:52", "07:31", "07:52", "08:19", "21:26"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Mita.Meguro", .descending,
                    "東急目黒線・新横浜線", "Tokyu Meguro & Shin-Yokohama Lines",
                    "日吉・新横浜方面", "for Hiyoshi & Shin-Yokohama",
                    to: "Railway:Tokyu.Meguro"),
        ]
    )

}
