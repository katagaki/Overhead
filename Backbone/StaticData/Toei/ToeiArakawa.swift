import Foundation

extension ToeiLineData {

    // MARK: - Arakawa Line / Tokyo Sakura Tram (SA)

    static let arakawa = StaticTrainLine(
        id: "Railway:Toei.Arakawa",
        nameJa: "都電荒川線",
        nameEn: "Toden Arakawa Line",
        operatorId: "Operator:Toei",
        colorHex: "#EE86A7",
        stations: [
            st("Arakawa", "Minowabashi", "三ノ輪橋", "Minowabashi", "SA01", 35.7321, 139.7915),
            st("Arakawa", "ArakawaItchumae", "荒川一中前", "Arakawa-itchumae", "SA02", 35.7337, 139.7889),
            st("Arakawa", "ArakawaKuyakushomae", "荒川区役所前", "Arakawa-kuyakushomae", "SA03", 35.7350, 139.7864),
            st("Arakawa", "ArakawaNichome", "荒川二丁目", "Arakawa-nichome", "SA04", 35.7386, 139.7847),
            st("Arakawa", "ArakawaNanachome", "荒川七丁目", "Arakawa-nanachome", "SA05", 35.7419, 139.7842),
            st("Arakawa", "MachiyaEkimae", "町屋駅前", "Machiya-ekimae", "SA06", 35.7428, 139.7808),
            st("Arakawa", "MachiyaNichome", "町屋二丁目", "Machiya-nichome", "SA07", 35.7437, 139.7769),
            st("Arakawa", "HigashiOguSanchome", "東尾久三丁目", "Higashi-ogu-sanchome", "SA08", 35.7454, 139.7744),
            st("Arakawa", "Kumanomae", "熊野前", "Kumanomae", "SA09", 35.7492, 139.7692),
            st("Arakawa", "Miyanomae", "宮ノ前", "Miyanomae", "SA10", 35.7501, 139.7650),
            st("Arakawa", "Odai", "小台", "Odai", "SA11", 35.7505, 139.7616),
            st("Arakawa", "ArakawaYuenchimae", "荒川遊園地前", "Arakawa-yuenchimae", "SA12", 35.7507, 139.7577),
            st("Arakawa", "ArakawaShakomae", "荒川車庫前", "Arakawa-shakomae", "SA13", 35.7509, 139.7528),
            st("Arakawa", "Kajiwara", "梶原", "Kajiwara", "SA14", 35.7511, 139.7475),
            st("Arakawa", "Sakaecho", "栄町", "Sakaecho", "SA15", 35.7509, 139.7422),
            st("Arakawa", "OjiEkimae", "王子駅前", "Oji-ekimae", "SA16", 35.7527, 139.7383),
            st("Arakawa", "Asukayama", "飛鳥山", "Asukayama", "SA17", 35.7502, 139.7374),
            st("Arakawa", "TakinogawaItchome", "滝野川一丁目", "Takinogawa-itchome", "SA18", 35.7474, 139.7354),
            st("Arakawa", "NishigaharaYonchome", "西ヶ原四丁目", "Nishigahara-yonchome", "SA19", 35.7444, 139.7328),
            st("Arakawa", "ShinKoshinzuka", "新庚申塚", "Shin-koshinzuka", "SA20", 35.7413, 139.7304),
            st("Arakawa", "Koshinzuka", "庚申塚", "Koshinzuka", "SA21", 35.7395, 139.7296),
            st("Arakawa", "Sugamoshinden", "巣鴨新田", "Sugamoshinden", "SA22", 35.7354, 139.7278),
            st("Arakawa", "OtsukaEkimae", "大塚駅前", "Otsuka-ekimae", "SA23", 35.7316, 139.7293),
            st("Arakawa", "Mukohara", "向原", "Mukohara", "SA24", 35.7289, 139.7249),
            st("Arakawa", "HigashiIkebukuroYonchome", "東池袋四丁目", "Higashi-ikebukuro-yonchome", "SA25", 35.7254, 139.7204),
            st("Arakawa", "TodenZoshigaya", "都電雑司ヶ谷", "Toden-zoshigaya", "SA26", 35.7243, 139.7180),
            st("Arakawa", "Kishibojimmae", "鬼子母神前", "Kishibojimmae", "SA27", 35.7203, 139.7150),
            st("Arakawa", "Gakushuinshita", "学習院下", "Gakushuinshita", "SA28", 35.7162, 139.7125),
            st("Arakawa", "Omokagebashi", "面影橋", "Omokagebashi", "SA29", 35.7129, 139.7145),
            st("Arakawa", "Waseda", "早稲田", "Waseda", "SA30", 35.7118, 139.7189),
        ],
        hopTimesMinutes: [
            1, 1, 2, 2, 2, 2, 1, 2, 2, 1, 1, 2, 2, 2, 2,
            2, 2, 2, 2, 1, 2, 2, 2, 2, 1, 2, 2, 2, 2,
        ],
        directions: [
            direction("Arakawa", "Waseda", "早稲田方面", "For Waseda", ascending: true,
                      // Last trams are 荒川車庫前行 (車) / 王子駅前行 (王) short turns.
                      weekday: pattern("05:48", "23:14", [
                          ("05:48", 6), ("07:00", 4), ("10:00", 6.5), ("16:00", 5), ("19:00", 7),
                      ]),
                      holiday: pattern("05:48", "23:14", [
                          ("05:48", 7), ("10:00", 6.5), ("19:00", 8),
                      ]),
                      origins: [
                          origin("Station:Toei.Arakawa.MachiyaEkimae",
                                 ["05:47", "06:23", "06:43", "06:58", "07:32", "07:52", "15:34", "19:37", "19:56", "20:18", "20:55", "21:07", "21:34"],
                                 []),
                          origin("Station:Toei.Arakawa.ArakawaShakomae",
                                 ["05:25", "05:27", "05:29", "05:39", "05:43", "05:52", "06:05", "06:18", "06:29", "06:34", "06:44", "07:01", "07:20", "07:36", "07:57", "14:43", "15:15"],
                                 [])
                      ]
            ),
            direction("Arakawa", "Minowabashi", "三ノ輪橋方面", "For Minowabashi", ascending: false,
                      weekday: pattern("06:00", "23:04", [
                          ("06:00", 6), ("07:00", 4), ("10:00", 6.5), ("16:00", 5), ("19:00", 7),
                      ]),
                      holiday: pattern("06:00", "23:04", [
                          ("06:00", 7), ("10:00", 6.5), ("19:00", 8),
                      ]),
                      origins: [
                          origin("Station:Toei.Arakawa.ArakawaShakomae",
                                 ["05:26", "05:31", "06:05", "06:16", "06:26", "06:31", "06:39", "06:42", "06:52", "06:57", "07:06", "07:14", "07:25", "07:32", "15:13", "15:26", "15:51"],
                                 []),
                          origin("Station:Toei.Arakawa.OjiEkimae",
                                 ["05:35", "05:54", "06:16", "07:11", "07:29", "22:15", "23:16", "23:28"],
                                 []),
                          origin("Station:Toei.Arakawa.OtsukaEkimae",
                                 ["05:49", "08:00", "08:24", "08:45", "18:59", "19:23", "19:40", "20:08", "20:36", "22:44", "23:11"],
                                 [])
                      ]
            ),
        ],
        delayInfo: delayInfo
    )

}
