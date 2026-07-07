import Foundation

// MARK: - Keio Line Data

private func st(_ path: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "odpt.Station:\(path).\(suffix)",
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
                       weekday: ServicePattern, holiday: ServicePattern) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:\(path).\(suffix)",
        nameJa: ja, nameEn: en,
        isAscending: ascending,
        weekday: weekday, saturdayHoliday: holiday
    )
}

private func through(_ junction: String, _ end: ThroughService.LineEnd,
                     _ lineJa: String, _ lineEn: String,
                     _ towardJa: String, _ towardEn: String,
                     to connectingLineId: String? = nil) -> ThroughService {
    ThroughService(
        junctionStationId: "odpt.Station:\(junction)",
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
        keio, sagamihara,
    ]

    // MARK: - Keio Line (KO)

    // 初台・幡ヶ谷 are Keio New Line platforms and are not stops on Keio Line
    // locals from Shinjuku, so they are omitted.
    static let keio = StaticTrainLine(
        id: "odpt.Railway:Keio.Keio",
        nameJa: "京王線",
        nameEn: "Keio Line",
        operatorId: "odpt.Operator:Keio",
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
                      ])),
            direction("Keio.Keio", "Shinjuku", "新宿方面", "For Shinjuku",
                      ascending: false,
                      weekday: pattern("04:42", "24:26", [
                          ("04:42", 8), ("06:30", 4), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("04:42", "24:26", [
                          ("04:42", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keio.Keio.Shinjuku", .descending,
                    "京王新線・都営新宿線", "Keio New Line & Toei Shinjuku Line",
                    "本八幡方面", "for Motoyawata",
                    to: "odpt.Railway:Toei.Shinjuku"),
            through("Keio.Keio.Chofu", .ascending,
                    "京王相模原線", "Keio Sagamihara Line",
                    "橋本方面", "for Hashimoto",
                    to: "odpt.Railway:Keio.Sagamihara"),
            through("Keio.Keio.Kitano", .ascending,
                    "京王高尾線", "Keio Takao Line",
                    "高尾山口方面", "for Takaosanguchi"),
        ]
    )

    // MARK: - Keio Sagamihara Line (KO)

    static let sagamihara = StaticTrainLine(
        id: "odpt.Railway:Keio.Sagamihara",
        nameJa: "京王相模原線",
        nameEn: "Keio Sagamihara Line",
        operatorId: "odpt.Operator:Keio",
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
                      ])),
            direction("Keio.Sagamihara", "Chofu", "調布・新宿方面", "For Chofu & Shinjuku",
                      ascending: false,
                      weekday: pattern("04:50", "23:55", [
                          ("04:50", 8), ("06:30", 5), ("09:30", 6), ("16:30", 5), ("20:00", 6), ("22:00", 8),
                      ]),
                      holiday: pattern("04:50", "23:55", [
                          ("04:50", 8), ("07:00", 6), ("10:00", 6), ("20:00", 8),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keio.Sagamihara.Chofu", .descending,
                    "京王線", "Keio Line",
                    "明大前・新宿方面", "for Meidaimae & Shinjuku",
                    to: "odpt.Railway:Keio.Keio"),
        ]
    )
}
