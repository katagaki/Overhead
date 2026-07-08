import Foundation

// MARK: - Keio Line Data

private func st(_ path: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "Station:\(path).\(suffix)",
        name: ja, nameEn: en, stationCode: code,
        latitude: lat, longitude: lon
    )
}

private func pattern(_ first: String, _ last: String, _ bands: [(String, Double)]) -> ServicePattern {
    ServicePattern(
        first: first, last: last,
        bands: bands.map { HeadwayBand(from: $0.0, headwayMinutes: $0.1) }
    )
}

private func direction(_ path: String, _ suffix: String, _ ja: String, _ en: String,
                       ascending: Bool,
                       weekday: ServicePattern, holiday: ServicePattern,
                       origins: [IntermediateOrigin] = []) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:\(path).\(suffix)",
        nameJa: ja, nameEn: en,
        isAscending: ascending,
        weekday: weekday, saturdayHoliday: holiday,
        intermediateOrigins: origins
    )
}

// 当駅始発 origin with EXACT departure times from ODPT (odpt:originStation).
private func origin(_ stationId: String, _ weekday: [String], _ holiday: [String]) -> IntermediateOrigin {
    IntermediateOrigin(stationId: stationId, weekday: weekday, saturdayHoliday: holiday)
}

private func through(_ junction: String, _ end: ThroughService.LineEnd,
                     _ lineJa: String, _ lineEn: String,
                     _ towardJa: String, _ towardEn: String,
                     to connectingLineId: String? = nil) -> ThroughService {
    ThroughService(
        junctionStationId: "Station:\(junction)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

enum KeioLineData {

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.keio.co.jp/unkou/unkou_pc.html",
        statusPageURLEn: "https://www.keio.co.jp/global/",
        xAccount: nil,
        checkMethodJa: "京王電鉄「運行情報」ページまたは京王アプリで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Keio train operation information page or the Keio app. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        keio, sagamihara, takao,
    ]

    // MARK: - Keio Line (KO)

    // 初台・幡ヶ谷 are Keio New Line platforms and are not stops on Keio Line
    // locals from Shinjuku, so they are omitted.
    static let keio = StaticTrainLine(
        id: "Railway:Keio.Keio",
        nameJa: "京王線",
        nameEn: "Keio Line",
        operatorId: "Operator:Keio",
        colorHex: "#DD0077",
        stations: [
            st("Keio.Keio", "Shinjuku", "新宿", "Shinjuku", "KO01", 35.6896, 139.7006),
            st("Keio.Keio", "Sasazuka", "笹塚", "Sasazuka", "KO04", 35.6737, 139.6667),
            st("Keio.Keio", "Daitabashi", "代田橋", "Daitabashi", "KO05", 35.6717, 139.6577),
            st("Keio.Keio", "Meidaimae", "明大前", "Meidaimae", "KO06", 35.6687, 139.6497),
            st("Keio.Keio", "Shimotakaido", "下高井戸", "Shimo-takaido", "KO07", 35.6667, 139.6437),
            st("Keio.Keio", "Sakurajosui", "桜上水", "Sakurajosui", "KO08", 35.6667, 139.6357),
            st("Keio.Keio", "Kamikitazawa", "上北沢", "Kami-kitazawa", "KO09", 35.6657, 139.6277),
            st("Keio.Keio", "Hachimanyama", "八幡山", "Hachimanyama", "KO10", 35.6657, 139.6197),
            st("Keio.Keio", "Rokakoen", "芦花公園", "Roka-koen", "KO11", 35.6647, 139.6117),
            st("Keio.Keio", "ChitoseKarasuyama", "千歳烏山", "Chitose-karasuyama", "KO12", 35.6637, 139.6027),
            st("Keio.Keio", "Sengawa", "仙川", "Sengawa", "KO13", 35.6627, 139.5867),
            st("Keio.Keio", "Tsutsujigaoka", "つつじヶ丘", "Tsutsujigaoka", "KO14", 35.6577, 139.5757),
            st("Keio.Keio", "Shibasaki", "柴崎", "Shibasaki", "KO15", 35.6527, 139.5667),
            st("Keio.Keio", "Kokuryo", "国領", "Kokuryo", "KO16", 35.6497, 139.5587),
            st("Keio.Keio", "Fuda", "布田", "Fuda", "KO17", 35.6497, 139.5497),
            st("Keio.Keio", "Chofu", "調布", "Chofu", "KO18", 35.6517, 139.5407),
            st("Keio.Keio", "NishiChofu", "西調布", "Nishi-chofu", "KO19", 35.6577, 139.5287),
            st("Keio.Keio", "Tobitakyu", "飛田給", "Tobitakyu", "KO20", 35.6607, 139.5227),
            st("Keio.Keio", "Musashinodai", "武蔵野台", "Musashinodai", "KO21", 35.6637, 139.5107),
            st("Keio.Keio", "Tamareien", "多磨霊園", "Tama-reien", "KO22", 35.6667, 139.5017),
            st("Keio.Keio", "HigashiFuchu", "東府中", "Higashi-fuchu", "KO23", 35.6687, 139.4927),
            st("Keio.Keio", "Fuchu", "府中", "Fuchu", "KO24", 35.6717, 139.4797),
            st("Keio.Keio", "Bubaigawara", "分倍河原", "Bubaigawara", "KO25", 35.6683, 139.4667),
            st("Keio.Keio", "Nakagawara", "中河原", "Nakagawara", "KO26", 35.6647, 139.4567),
            st("Keio.Keio", "SeisekiSakuragaoka", "聖蹟桜ヶ丘", "Seiseki-sakuragaoka", "KO27", 35.6507, 139.4467),
            st("Keio.Keio", "Mogusaen", "百草園", "Mogusaen", "KO28", 35.6497, 139.4327),
            st("Keio.Keio", "TakahataFudo", "高幡不動", "Takahatafudo", "KO29", 35.6597, 139.4127),
            st("Keio.Keio", "Minamidaira", "南平", "Minamidaira", "KO30", 35.6607, 139.3977),
            st("Keio.Keio", "HirayamaJoshiKoen", "平山城址公園", "Hirayamajoshi-koen", "KO31", 35.6577, 139.3847),
            st("Keio.Keio", "Naganuma", "長沼", "Naganuma", "KO32", 35.6567, 139.3697),
            st("Keio.Keio", "Kitano", "北野", "Kitano", "KO33", 35.6567, 139.3567),
            st("Keio.Keio", "KeioHachioji", "京王八王子", "Keio-hachioji", "KO34", 35.6597, 139.3437),
        ],
        hopTimesMinutes: [
            4, 1, 2, 1, 2, 1, 2, 1, 2, 2, 2, 1, 2, 1, 2,
            3, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 3,
        ],
        directions: [
            direction("Keio.Keio", "KeioHachioji", "調布・京王八王子方面", "For Chofu & Keio-hachioji",
                      ascending: true,
                      weekday: pattern("05:29", "24:18", [
                          ("05:29", 7), ("06:30", 4), ("09:30", 5), ("16:30", 4), ("20:00", 5), ("22:00", 7),
                      ]),
                      holiday: pattern("05:29", "24:18", [
                          ("05:29", 7), ("07:00", 5), ("10:00", 5), ("20:00", 7),
                      ]),
                      origins: [
                          origin("Station:Keio.Keio.Sasazuka",
                                 ["05:01", "05:25", "06:37", "07:02", "07:17", "07:44", "07:56", "08:01", "08:14", "08:17", "08:34", "08:42", "08:49", "08:58", "09:08", "09:14", "09:21", "09:32", "09:36", "09:46", "09:56", "10:07", "10:17", "10:26", "10:37", "10:46", "10:57", "11:06", "11:17", "11:26", "11:36", "11:46", "11:56", "12:06", "12:17", "12:26", "12:37", "12:46", "12:56", "13:06", "13:16", "13:26", "13:37", "13:46", "13:56", "14:06", "14:16", "14:26", "14:36", "14:46", "14:56", "15:06", "15:16", "15:26", "15:36", "15:46", "15:57", "16:06", "16:16", "16:26", "16:37", "16:47", "16:57", "17:07", "17:10", "17:18", "17:27", "17:38", "17:47", "17:58", "18:07", "18:18", "18:27", "18:38", "18:47", "18:58", "19:07", "19:18", "19:27", "19:38", "19:47", "19:58", "20:07", "20:17", "20:27", "20:37", "20:47", "20:57", "21:07", "21:16", "21:27", "21:45", "21:56", "22:07", "23:25", "24:25", "24:33", "24:47"],
                                 ["05:01", "05:25", "07:01", "07:37", "07:47", "08:08", "08:20", "08:29", "08:45", "08:51", "08:56", "09:10", "09:16", "09:38", "09:44", "09:50", "09:57", "10:11", "10:16", "10:26", "10:37", "10:39", "10:48", "10:56", "11:07", "11:11", "11:17", "11:26", "11:36", "11:46", "11:57", "12:06", "12:17", "12:26", "12:37", "12:46", "12:56", "13:06", "13:17", "13:26", "13:37", "13:46", "13:57", "14:06", "14:16", "14:26", "14:36", "14:44", "14:54", "15:04", "15:11", "15:26", "15:36", "15:44", "15:50", "16:05", "16:10", "16:25", "16:31", "16:44", "16:49", "17:05", "17:10", "17:25", "17:31", "17:40", "17:53", "18:05", "18:10", "18:25", "18:31", "18:39", "18:49", "19:05", "19:10", "19:25", "19:31", "19:44", "19:49", "20:05", "20:10", "20:25", "20:31", "20:44", "20:50", "21:05", "21:10", "21:25", "21:37", "21:59", "22:38", "23:25", "24:25", "24:33", "24:47"]),
                          origin("Station:Keio.Keio.Sakurajosui",
                                 ["04:37", "06:00"],
                                 ["04:37", "06:00", "06:50"]),
                          origin("Station:Keio.Keio.Chofu",
                                 ["19:13", "19:34", "20:12"],
                                 ["06:53"]),
                          origin("Station:Keio.Keio.Fuchu",
                                 ["06:30"],
                                 ["06:30"]),
                          origin("Station:Keio.Keio.TakahataFudo",
                                 ["04:41", "05:02", "05:26", "06:02", "06:23", "06:39", "10:01", "21:39", "21:49", "22:00", "22:11", "22:26", "22:39", "22:52", "23:08", "23:21", "23:36", "23:51", "24:05", "24:20", "24:35", "24:51"],
                                 ["04:41", "05:02", "05:26", "05:57", "21:34", "21:42", "21:52", "22:03", "22:14", "22:31", "22:39", "22:50", "23:08", "23:22", "23:36", "23:51", "24:05", "24:20", "24:35", "24:51"]),
                          origin("Station:Keio.Keio.Kitano",
                                 ["06:11"],
                                 [])
                      ]
            ),
            direction("Keio.Keio", "Shinjuku", "新宿方面", "For Shinjuku",
                      ascending: false,
                      weekday: pattern("04:42", "24:26", [
                          ("04:42", 8), ("06:30", 4), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("04:42", "24:26", [
                          ("04:42", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ]),
                      origins: [
                          origin("Station:Keio.Keio.Sasazuka",
                                 [],
                                 ["06:40"]),
                          origin("Station:Keio.Keio.Sakurajosui",
                                 ["04:38", "06:40", "07:02", "07:32", "15:24"],
                                 ["04:38"]),
                          origin("Station:Keio.Keio.Tsutsujigaoka",
                                 ["04:52", "06:23", "06:58", "07:47", "08:33"],
                                 ["04:52"]),
                          origin("Station:Keio.Keio.Chofu",
                                 ["05:08", "05:27", "05:35", "05:48", "05:51", "06:09", "06:12", "06:17", "06:26", "06:31", "06:37", "06:41", "06:48", "06:50", "07:00", "07:04", "07:13", "07:14", "07:17", "07:23", "07:25", "07:30", "07:39", "07:43", "07:47", "07:52", "07:59", "08:03", "08:08", "08:11", "08:18", "08:23", "08:28", "08:35", "08:41", "08:51", "09:00", "09:07", "09:18", "09:27", "09:29", "09:37", "09:47", "09:48", "09:56", "09:59", "10:07", "10:16", "10:19", "10:26", "10:36", "10:39", "10:46", "10:56", "10:59", "11:06", "11:16", "11:19", "11:26", "11:36", "11:39", "11:46", "11:56", "11:59", "12:06", "12:16", "12:19", "12:26", "12:36", "12:39", "12:46", "12:56", "12:59", "13:06", "13:16", "13:19", "13:26", "13:36", "13:39", "13:46", "13:56", "13:59", "14:06", "14:16", "14:19", "14:26", "14:36", "14:39", "14:46", "14:56", "14:59", "15:06", "15:16", "15:19", "15:26", "15:36", "15:39", "15:46", "15:56", "15:59", "16:06", "16:16", "16:27", "16:28", "16:37", "16:39", "16:47", "16:56", "16:58", "17:07", "17:16", "17:19", "17:27", "17:30", "17:37", "17:41", "17:49", "17:58", "18:00", "18:07", "18:11", "18:18", "18:20", "18:27", "18:32", "18:38", "18:40", "18:47", "18:50", "18:58", "19:01", "19:07", "19:11", "19:18", "19:20", "19:27", "19:30", "19:38", "19:40", "19:46", "19:52", "19:59", "20:00", "20:07", "20:12", "20:19", "20:27", "20:32", "20:39", "20:46", "20:51", "20:59", "21:07", "21:11", "21:19", "21:30", "21:41", "21:57", "22:08", "22:21", "22:35", "22:47", "23:00", "23:15", "23:32", "23:42", "23:58", "24:11"],
                                 ["05:08", "05:27", "05:35", "05:48", "05:53", "06:08", "06:13", "06:24", "06:38", "06:41", "06:46", "06:54", "06:57", "07:04", "07:13", "07:23", "07:33", "07:36", "07:45", "07:53", "07:56", "08:03", "08:14", "08:16", "08:26", "08:33", "08:36", "08:46", "08:54", "08:56", "09:04", "09:14", "09:17", "09:25", "09:33", "09:36", "09:46", "09:54", "09:55", "10:04", "10:14", "10:17", "10:26", "10:34", "10:36", "10:47", "10:57", "10:59", "11:07", "11:16", "11:18", "11:28", "11:36", "11:39", "11:46", "11:56", "11:59", "12:06", "12:16", "12:19", "12:26", "12:36", "12:39", "12:46", "12:56", "12:59", "13:06", "13:16", "13:19", "13:26", "13:36", "13:39", "13:46", "13:56", "13:59", "14:06", "14:15", "14:17", "14:25", "14:35", "14:37", "14:46", "14:56", "14:58", "15:05", "15:15", "15:17", "15:25", "15:34", "15:37", "15:48", "15:56", "15:58", "16:06", "16:15", "16:18", "16:26", "16:31", "16:37", "16:45", "16:50", "16:57", "17:07", "17:15", "17:18", "17:27", "17:36", "17:38", "17:48", "17:55", "17:58", "18:05", "18:15", "18:18", "18:27", "18:35", "18:38", "18:47", "18:55", "18:57", "19:05", "19:15", "19:18", "19:27", "19:35", "19:38", "19:47", "19:55", "19:58", "20:05", "20:15", "20:18", "20:28", "20:35", "20:38", "20:47", "20:56", "20:59", "21:10", "21:21", "21:24", "21:37", "21:47", "22:00", "22:10", "22:35", "22:45", "23:00", "23:15", "23:29", "23:45", "23:58", "24:11"]),
                          origin("Station:Keio.Keio.Fuchu",
                                 ["07:06"],
                                 []),
                          origin("Station:Keio.Keio.TakahataFudo",
                                 ["04:39", "05:10", "05:18", "05:31", "05:38", "06:02", "06:06", "06:46", "08:22", "10:45", "14:45", "15:35", "17:00", "17:05", "17:15", "19:07", "22:03", "22:10", "22:16", "22:23", "22:29", "22:36", "22:42", "22:51", "22:57", "23:06", "23:13", "23:21", "23:25"],
                                 ["04:39", "05:10", "05:18", "05:31", "05:39", "22:05", "22:14", "22:19", "22:24", "22:27", "22:36", "22:41", "22:52", "22:56", "23:08", "23:12", "23:22", "23:26"]),
                          origin("Station:Keio.Keio.Kitano",
                                 ["04:40", "05:46", "06:03", "06:13", "06:24", "06:36", "06:47", "06:57", "07:08", "07:26", "07:33", "07:39", "07:43", "07:54", "08:01", "08:12", "08:22", "08:35", "08:45", "08:55", "09:05", "09:23", "09:34", "09:37", "09:43", "09:55", "10:03", "10:15", "10:23", "10:35", "10:43", "10:55", "11:03", "11:15", "11:23", "11:35", "11:43", "11:55", "12:03", "12:15", "12:23", "12:35", "12:43", "12:55", "13:03", "13:15", "13:23", "13:35", "13:43", "13:55", "14:03", "14:15", "14:23", "14:35", "14:43", "14:55", "15:03", "15:15", "15:23", "15:35", "15:43", "15:55", "16:03", "16:15", "16:23", "16:43", "17:28", "17:36", "17:46", "17:56", "18:07", "18:16", "18:27", "18:37", "18:47", "18:57", "19:07", "19:17", "19:27", "19:37", "19:46", "19:56", "20:07", "20:16", "20:27", "20:37", "20:46", "20:58", "21:09", "21:21", "21:34", "21:44", "23:25", "23:36"],
                                 ["04:40", "05:46", "06:07", "06:16", "06:32", "06:42", "06:57", "07:12", "07:22", "07:30", "07:42", "07:52", "08:00", "08:11", "08:18", "08:31", "08:43", "08:53", "09:01", "09:11", "09:19", "09:30", "09:43", "09:53", "10:04", "10:14", "10:25", "10:35", "10:42", "10:55", "11:04", "11:15", "11:23", "11:35", "11:45", "11:55", "12:03", "12:15", "12:23", "12:35", "12:42", "12:55", "13:03", "13:15", "13:23", "13:35", "13:42", "13:54", "14:01", "14:14", "14:21", "14:26", "14:34", "14:41", "14:55", "15:02", "15:15", "15:21", "15:26", "15:34", "15:42", "15:55", "16:03", "16:14", "16:26", "16:27", "16:34", "16:44", "16:53", "17:01", "17:14", "17:22", "17:26", "17:34", "17:42", "17:54", "18:02", "18:14", "18:22", "18:34", "18:42", "18:54", "19:02", "19:14", "19:22", "19:34", "19:42", "19:54", "20:01", "20:14", "20:22", "20:37", "20:46", "21:04", "21:10", "21:27", "21:38", "21:49", "23:26", "23:36"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keio.Keio.Shinjuku", .descending,
                    "京王新線・都営新宿線", "Keio New Line & Toei Shinjuku Line",
                    "本八幡方面", "for Motoyawata",
                    to: "Railway:Toei.Shinjuku"),
            through("Keio.Keio.Chofu", .ascending,
                    "京王相模原線", "Keio Sagamihara Line",
                    "橋本方面", "for Hashimoto",
                    to: "Railway:Keio.Sagamihara"),
            through("Keio.Keio.Kitano", .ascending,
                    "京王高尾線", "Keio Takao Line",
                    "高尾山口方面", "for Takaosanguchi",
                    to: "Railway:Keio.Takao"),
        ]
    )

    // MARK: - Keio Sagamihara Line (KO)

    static let sagamihara = StaticTrainLine(
        id: "Railway:Keio.Sagamihara",
        nameJa: "京王相模原線",
        nameEn: "Keio Sagamihara Line",
        operatorId: "Operator:Keio",
        colorHex: "#DD0077",
        stations: [
            st("Keio.Sagamihara", "Chofu", "調布", "Chofu", "KO18", 35.6517, 139.5407),
            st("Keio.Sagamihara", "KeioTamagawa", "京王多摩川", "Keio-tamagawa", "KO35", 35.6437, 139.5397),
            st("Keio.Sagamihara", "KeioInadazutsumi", "京王稲田堤", "Keio-inadazutsumi", "KO36", 35.6337, 139.5297),
            st("Keio.Sagamihara", "KeioYomiuriLand", "京王よみうりランド", "Keio-yomiuri-land", "KO37", 35.6257, 139.5187),
            st("Keio.Sagamihara", "Inagi", "稲城", "Inagi", "KO38", 35.6297, 139.5047),
            st("Keio.Sagamihara", "Wakabadai", "若葉台", "Wakabadai", "KO39", 35.6177, 139.4867),
            st("Keio.Sagamihara", "KeioNagayama", "京王永山", "Keio-nagayama", "KO40", 35.6187, 139.4467),
            st("Keio.Sagamihara", "KeioTamaCenter", "京王多摩センター", "Keio-tama-center", "KO41", 35.6247, 139.4247),
            st("Keio.Sagamihara", "KeioHorinouchi", "京王堀之内", "Keio-horinouchi", "KO42", 35.6217, 139.4047),
            st("Keio.Sagamihara", "MinamiOsawa", "南大沢", "Minami-osawa", "KO43", 35.6147, 139.3807),
            st("Keio.Sagamihara", "Tamasakai", "多摩境", "Tamasakai", "KO44", 35.6027, 139.3667),
            st("Keio.Sagamihara", "Hashimoto", "橋本", "Hashimoto", "KO45", 35.5948, 139.3449),
        ],
        hopTimesMinutes: [3, 2, 2, 2, 3, 4, 3, 3, 3, 3, 4],
        directions: [
            // First/last estimated from Keio published patterns
            direction("Keio.Sagamihara", "Hashimoto", "橋本方面", "For Hashimoto",
                      ascending: true,
                      weekday: pattern("05:20", "24:30", [
                          ("05:20", 8), ("06:30", 5), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("05:20", "24:30", [
                          ("05:20", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ]),
                      origins: [
                          origin("Station:Keio.Sagamihara.Wakabadai",
                                 ["04:39", "04:58", "05:18", "05:55", "06:15", "06:34", "16:44", "17:27"],
                                 ["04:39", "04:58", "05:18", "05:58", "06:13", "06:32", "08:42"]),
                          origin("Station:Keio.Sagamihara.KeioTamaCenter",
                                 ["08:37", "09:17", "09:35", "10:40", "10:58", "11:18", "11:37", "11:58", "12:17", "12:37", "12:57", "13:17", "13:37", "13:57", "14:17", "14:37", "14:57", "15:17", "15:37", "17:21", "17:52", "18:13", "18:53", "19:14", "19:41", "19:53", "20:03", "20:13", "20:33", "20:51", "21:11", "21:52", "22:28"],
                                 ["10:28", "10:58", "11:39", "11:58", "12:17", "12:38", "12:57", "13:17", "13:37", "13:57", "14:17", "14:37", "14:57", "15:17", "15:38", "15:59", "16:38", "17:00", "17:38", "18:00", "18:38", "19:00", "19:38", "19:59", "20:17", "20:38", "20:59", "21:16", "21:37"])
                      ]
            ),
            direction("Keio.Sagamihara", "Chofu", "調布・新宿方面", "For Chofu & Shinjuku",
                      ascending: false,
                      weekday: pattern("04:50", "23:55", [
                          ("04:50", 8), ("06:30", 5), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("04:50", "23:55", [
                          ("04:50", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ]),
                      origins: [
                          origin("Station:Keio.Sagamihara.Wakabadai",
                                 ["05:23", "05:39", "06:00", "06:27", "18:28", "23:18"],
                                 ["05:23", "05:42", "06:01", "06:29", "18:52"]),
                          origin("Station:Keio.Sagamihara.KeioTamaCenter",
                                 ["06:04", "07:01", "07:45", "08:08", "09:44", "09:47", "09:54", "10:05", "10:07", "10:25", "10:45", "11:05", "11:07", "11:25", "11:27", "11:45", "11:47", "12:05", "12:07", "12:25", "12:27", "12:45", "12:47", "13:05", "13:07", "13:25", "13:27", "13:45", "13:47", "14:05", "14:07", "14:25", "14:27", "14:45", "14:47", "15:05", "15:07", "15:25", "15:27", "15:45", "15:47", "18:11", "18:14", "18:20", "19:01", "19:22", "20:01", "20:11", "20:14", "20:31", "20:34", "20:52", "20:54", "21:12"],
                                 ["06:44", "08:02", "08:22", "08:42", "08:45", "09:02", "09:22", "10:04", "10:23", "10:45", "10:46", "11:05", "11:07", "11:25", "11:27", "11:45", "11:47", "12:05", "12:07", "12:25", "12:27", "12:45", "12:47", "13:05", "13:07", "13:25", "13:27", "13:45", "13:47", "14:04", "14:06", "14:24", "14:27", "14:45", "14:46", "15:04", "15:06", "15:24", "15:26", "15:45", "15:47", "16:04", "16:07", "20:05", "20:07", "20:25", "20:27", "20:46", "20:49", "21:09", "21:40"])
                      ]
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keio.Sagamihara.Chofu", .descending,
                    "京王線", "Keio Line",
                    "明大前・新宿方面", "for Meidaimae & Shinjuku",
                    to: "Railway:Keio.Keio"),
        ]
    )

    // MARK: - Keio Takao Line (KO)

    // Branches off the Keio Line at 北野; most trains through-run to/from
    // 新宿 on the Keio Line. Station numbers verified against keio.co.jp
    // (高尾山口 = KO53); coordinates from ja.wikipedia per-station infoboxes.
    // First/last from ekitan (weekday, July 2026); holiday first/last mirror
    // weekday and are approximate. Base 各駅停車 pattern; 特急/急行/快速 run
    // the same corridor but are approximated by headway bands.
    static let takao = StaticTrainLine(
        id: "Railway:Keio.Takao",
        nameJa: "京王高尾線",
        nameEn: "Keio Takao Line",
        operatorId: "Operator:Keio",
        colorHex: "#DD0077",
        stations: [
            st("Keio.Takao", "Kitano", "北野", "Kitano", "KO33", 35.6567, 139.3567),
            st("Keio.Takao", "KeioKatakura", "京王片倉", "Keio-katakura", "KO48", 35.6444, 139.3373),
            st("Keio.Takao", "Yamada", "山田", "Yamada", "KO49", 35.6444, 139.3213),
            st("Keio.Takao", "Mejirodai", "めじろ台", "Mejirodai", "KO50", 35.6433, 139.3077),
            st("Keio.Takao", "Hazama", "狭間", "Hazama", "KO51", 35.6406, 139.2933),
            st("Keio.Takao", "Takao", "高尾", "Takao", "KO52", 35.6422, 139.2819),
            st("Keio.Takao", "Takaosanguchi", "高尾山口", "Takaosanguchi", "KO53", 35.6322, 139.2699),
        ],
        hopTimesMinutes: [2, 2, 2, 2, 3, 3],
        directions: [
            direction("Keio.Takao", "Takaosanguchi", "高尾山口方面", "For Takaosanguchi",
                      ascending: true,
                      weekday: pattern("05:12", "24:14", [
                          ("05:12", 8), ("06:30", 6), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:12", "24:14", [
                          ("05:12", 8), ("07:00", 7), ("10:00", 7), ("20:00", 9),
                      ])),
            direction("Keio.Takao", "Kitano", "北野・新宿方面", "For Kitano & Shinjuku",
                      ascending: false,
                      weekday: pattern("05:07", "24:13", [
                          ("05:07", 8), ("06:30", 5), ("09:30", 7), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:07", "24:13", [
                          ("05:07", 8), ("07:00", 7), ("10:00", 7), ("20:00", 9),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keio.Takao.Kitano", .descending,
                    "京王線", "Keio Line",
                    "明大前・新宿方面", "for Meidaimae & Shinjuku",
                    to: "Railway:Keio.Keio"),
        ]
    )
}
