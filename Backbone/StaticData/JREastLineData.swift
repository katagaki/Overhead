import Foundation

// MARK: - JR East Line Data

private func st(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "Station:JR-East.\(line).\(suffix)",
        name: ja, nameEn: en, stationCode: code,
        latitude: lat, longitude: lon
    )
}

private func through(_ junction: String, _ end: ThroughService.LineEnd,
                     _ lineJa: String, _ lineEn: String,
                     _ towardJa: String, _ towardEn: String,
                     to connectingLineId: String? = nil) -> ThroughService {
    ThroughService(
        junctionStationId: "Station:JR-East.\(junction)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

enum JREastLineData {

    // MARK: Delay Check

    // Delays of 15+ minutes are posted on the Train Operation Information page
    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://traininfo.jreast.co.jp/train_info/kanto.aspx",
        statusPageURLEn: "https://traininfo.jreast.co.jp/train_info/e/kanto.aspx",
        xAccount: nil,
        checkMethodJa: "JR東日本「列車運行情報」ページまたはJR東日本アプリで確認できます。首都圏エリアでは15分以上の遅れ・運休が発生または見込まれる場合に掲載されます。",
        checkMethodEn: "Check the JR East Train Operation Information page or the JR East app. In the Tokyo area, delays or suspensions of 15 minutes or more are posted."
    )

    static let lines: [StaticTrainLine] = [
        yamanote,
        chuoRapid,
        chuoSobuLocal,
        keihinTohoku,
        saikyo,
        keiyo,
    ] + extendedLines

    // MARK: - Yamanote Line (JY)

    static let yamanote = StaticTrainLine(
        id: "Railway:JR-East.Yamanote",
        nameJa: "山手線",
        nameEn: "Yamanote Line",
        operatorId: "Operator:JR-East",
        colorHex: "#9ACD32",
        stations: [
            st("Yamanote", "Tokyo", "東京", "Tokyo", "JY01", 35.6812, 139.7671),
            st("Yamanote", "Kanda", "神田", "Kanda", "JY02", 35.6918, 139.7709),
            st("Yamanote", "Akihabara", "秋葉原", "Akihabara", "JY03", 35.6984, 139.7731),
            st("Yamanote", "Okachimachi", "御徒町", "Okachimachi", "JY04", 35.7075, 139.7747),
            st("Yamanote", "Ueno", "上野", "Ueno", "JY05", 35.7141, 139.7774),
            st("Yamanote", "Uguisudani", "鶯谷", "Uguisudani", "JY06", 35.7206, 139.7785),
            st("Yamanote", "Nippori", "日暮里", "Nippori", "JY07", 35.7278, 139.7708),
            st("Yamanote", "NishiNippori", "西日暮里", "Nishi-Nippori", "JY08", 35.7324, 139.7669),
            st("Yamanote", "Tabata", "田端", "Tabata", "JY09", 35.7381, 139.7607),
            st("Yamanote", "Komagome", "駒込", "Komagome", "JY10", 35.7365, 139.7460),
            st("Yamanote", "Sugamo", "巣鴨", "Sugamo", "JY11", 35.7335, 139.7394),
            st("Yamanote", "Otsuka", "大塚", "Otsuka", "JY12", 35.7312, 139.7286),
            st("Yamanote", "Ikebukuro", "池袋", "Ikebukuro", "JY13", 35.7295, 139.7109),
            st("Yamanote", "Mejiro", "目白", "Mejiro", "JY14", 35.7210, 139.7068),
            st("Yamanote", "Takadanobaba", "高田馬場", "Takadanobaba", "JY15", 35.7126, 139.7038),
            st("Yamanote", "ShinOkubo", "新大久保", "Shin-Okubo", "JY16", 35.7011, 139.7001),
            st("Yamanote", "Shinjuku", "新宿", "Shinjuku", "JY17", 35.6896, 139.7006),
            st("Yamanote", "Yoyogi", "代々木", "Yoyogi", "JY18", 35.6832, 139.7020),
            st("Yamanote", "Harajuku", "原宿", "Harajuku", "JY19", 35.6702, 139.7027),
            st("Yamanote", "Shibuya", "渋谷", "Shibuya", "JY20", 35.6580, 139.7016),
            st("Yamanote", "Ebisu", "恵比寿", "Ebisu", "JY21", 35.6467, 139.7101),
            st("Yamanote", "Meguro", "目黒", "Meguro", "JY22", 35.6340, 139.7157),
            st("Yamanote", "Gotanda", "五反田", "Gotanda", "JY23", 35.6262, 139.7233),
            st("Yamanote", "Osaki", "大崎", "Osaki", "JY24", 35.6197, 139.7286),
            st("Yamanote", "Shinagawa", "品川", "Shinagawa", "JY25", 35.6285, 139.7388),
            st("Yamanote", "TakanawaGateway", "高輪ゲートウェイ", "Takanawa Gateway", "JY26", 35.6355, 139.7407),
            st("Yamanote", "Tamachi", "田町", "Tamachi", "JY27", 35.6457, 139.7476),
            st("Yamanote", "Hamamatsucho", "浜松町", "Hamamatsucho", "JY28", 35.6556, 139.7570),
            st("Yamanote", "Shimbashi", "新橋", "Shimbashi", "JY29", 35.6663, 139.7583),
            st("Yamanote", "Yurakucho", "有楽町", "Yurakucho", "JY30", 35.6749, 139.7628),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
        ],
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.Yamanote.InnerLoop",
                nameJa: "内回り（上野・池袋方面）",
                nameEn: "Inner Loop (for Ueno & Ikebukuro)",
                isAscending: true,
                weekday: ServicePattern(
                    first: "04:46", last: "24:30",
                    bands: [
                        HeadwayBand(from: "04:40", headwayMinutes: 6),
                        HeadwayBand(from: "06:30", headwayMinutes: 3.5),
                        HeadwayBand(from: "09:30", headwayMinutes: 4),
                        HeadwayBand(from: "17:00", headwayMinutes: 3.5),
                        HeadwayBand(from: "20:00", headwayMinutes: 5),
                        HeadwayBand(from: "22:00", headwayMinutes: 6),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:46", last: "24:20",
                    bands: [
                        HeadwayBand(from: "04:40", headwayMinutes: 6),
                        HeadwayBand(from: "07:00", headwayMinutes: 4.5),
                        HeadwayBand(from: "10:00", headwayMinutes: 4),
                        HeadwayBand(from: "19:00", headwayMinutes: 5),
                        HeadwayBand(from: "22:00", headwayMinutes: 6),
                    ]
                )
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.Yamanote.OuterLoop",
                nameJa: "外回り（品川・渋谷方面）",
                nameEn: "Outer Loop (for Shinagawa & Shibuya)",
                isAscending: false,
                weekday: ServicePattern(
                    first: "04:49", last: "24:46",
                    bands: [
                        HeadwayBand(from: "04:40", headwayMinutes: 6),
                        HeadwayBand(from: "06:30", headwayMinutes: 3.5),
                        HeadwayBand(from: "09:30", headwayMinutes: 4),
                        HeadwayBand(from: "17:00", headwayMinutes: 3.5),
                        HeadwayBand(from: "20:00", headwayMinutes: 5),
                        HeadwayBand(from: "22:00", headwayMinutes: 6),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:49", last: "24:46",
                    bands: [
                        HeadwayBand(from: "04:40", headwayMinutes: 6),
                        HeadwayBand(from: "07:00", headwayMinutes: 4.5),
                        HeadwayBand(from: "10:00", headwayMinutes: 4),
                        HeadwayBand(from: "19:00", headwayMinutes: 5),
                        HeadwayBand(from: "22:00", headwayMinutes: 6),
                    ]
                )
            ),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Chuo Rapid Line (JC)

    static let chuoRapid = StaticTrainLine(
        id: "Railway:JR-East.ChuoRapid",
        nameJa: "中央線快速",
        nameEn: "Chuo Rapid Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F15A22",
        stations: [
            st("ChuoRapid", "Tokyo", "東京", "Tokyo", "JC01", 35.6812, 139.7671),
            st("ChuoRapid", "Kanda", "神田", "Kanda", "JC02", 35.6918, 139.7709),
            st("ChuoRapid", "Ochanomizu", "御茶ノ水", "Ochanomizu", "JC03", 35.6994, 139.7649),
            st("ChuoRapid", "Yotsuya", "四ツ谷", "Yotsuya", "JC04", 35.6860, 139.7301),
            st("ChuoRapid", "Shinjuku", "新宿", "Shinjuku", "JC05", 35.6896, 139.7006),
            st("ChuoRapid", "Nakano", "中野", "Nakano", "JC06", 35.7056, 139.6659),
            st("ChuoRapid", "Koenji", "高円寺", "Koenji", "JC07", 35.7053, 139.6497),
            st("ChuoRapid", "Asagaya", "阿佐ケ谷", "Asagaya", "JC08", 35.7047, 139.6357),
            st("ChuoRapid", "Ogikubo", "荻窪", "Ogikubo", "JC09", 35.7047, 139.6202),
            st("ChuoRapid", "NishiOgikubo", "西荻窪", "Nishi-Ogikubo", "JC10", 35.7037, 139.5993),
            st("ChuoRapid", "Kichijoji", "吉祥寺", "Kichijoji", "JC11", 35.7030, 139.5796),
            st("ChuoRapid", "Mitaka", "三鷹", "Mitaka", "JC12", 35.7027, 139.5607),
            st("ChuoRapid", "MusashiSakai", "武蔵境", "Musashi-Sakai", "JC13", 35.7021, 139.5434),
            st("ChuoRapid", "HigashiKoganei", "東小金井", "Higashi-Koganei", "JC14", 35.7014, 139.5240),
            st("ChuoRapid", "MusashiKoganei", "武蔵小金井", "Musashi-Koganei", "JC15", 35.7010, 139.5063),
            st("ChuoRapid", "Kokubunji", "国分寺", "Kokubunji", "JC16", 35.7003, 139.4807),
            st("ChuoRapid", "NishiKokubunji", "西国分寺", "Nishi-Kokubunji", "JC17", 35.6997, 139.4665),
            st("ChuoRapid", "Kunitachi", "国立", "Kunitachi", "JC18", 35.6998, 139.4468),
            st("ChuoRapid", "Tachikawa", "立川", "Tachikawa", "JC19", 35.6980, 139.4139),
            st("ChuoRapid", "Hino", "日野", "Hino", "JC20", 35.6790, 139.3853),
            st("ChuoRapid", "Toyoda", "豊田", "Toyoda", "JC21", 35.6597, 139.3785),
            st("ChuoRapid", "Hachioji", "八王子", "Hachioji", "JC22", 35.6553, 139.3390),
            st("ChuoRapid", "NishiHachioji", "西八王子", "Nishi-Hachioji", "JC23", 35.6567, 139.3040),
            st("ChuoRapid", "Takao", "高尾", "Takao", "JC24", 35.6422, 139.2820),
        ],
        hopTimesMinutes: [
            2, 2, 4, 5, 5, 2, 2, 2, 2, 2, 2, 3,
            2, 2, 3, 2, 2, 3, 3, 3, 4, 4, 4,
        ],
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.ChuoRapid.Takao",
                nameJa: "高尾方面",
                nameEn: "For Takao",
                isAscending: true,
                weekday: ServicePattern(
                    first: "04:38", last: "24:06",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 7),
                        HeadwayBand(from: "06:30", headwayMinutes: 4),
                        HeadwayBand(from: "09:30", headwayMinutes: 5),
                        HeadwayBand(from: "16:30", headwayMinutes: 4),
                        HeadwayBand(from: "20:00", headwayMinutes: 6),
                        HeadwayBand(from: "22:30", headwayMinutes: 8),
                    ],
                    trainType: .rapid
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:38", last: "24:06",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 7),
                        HeadwayBand(from: "07:00", headwayMinutes: 5),
                        HeadwayBand(from: "10:00", headwayMinutes: 5.5),
                        HeadwayBand(from: "19:00", headwayMinutes: 6),
                        HeadwayBand(from: "22:00", headwayMinutes: 8),
                    ],
                    trainType: .rapid
                )
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.ChuoRapid.Tokyo",
                nameJa: "東京方面",
                nameEn: "For Tokyo",
                isAscending: false,
                weekday: ServicePattern(
                    first: "04:27", last: "24:13",
                    bands: [
                        HeadwayBand(from: "04:45", headwayMinutes: 7),
                        HeadwayBand(from: "06:00", headwayMinutes: 4),
                        HeadwayBand(from: "09:30", headwayMinutes: 5),
                        HeadwayBand(from: "16:30", headwayMinutes: 4),
                        HeadwayBand(from: "20:00", headwayMinutes: 6),
                        HeadwayBand(from: "22:30", headwayMinutes: 8),
                    ],
                    trainType: .rapid
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:27", last: "24:13",
                    bands: [
                        HeadwayBand(from: "04:45", headwayMinutes: 7),
                        HeadwayBand(from: "07:00", headwayMinutes: 5),
                        HeadwayBand(from: "10:00", headwayMinutes: 5.5),
                        HeadwayBand(from: "19:00", headwayMinutes: 6),
                        HeadwayBand(from: "22:00", headwayMinutes: 8),
                    ],
                    trainType: .rapid
                )
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("ChuoRapid.Tachikawa", .ascending,
                    "青梅線", "JR Ome Line", "青梅方面", "for Ome",
                    to: "Railway:JR-East.Ome"),
            through("ChuoRapid.Takao", .ascending,
                    "中央本線", "JR Chuo Main Line", "大月方面", "for Otsuki"),
        ]
    )

    // MARK: - Chuo-Sobu Line Local (JB)

    static let chuoSobuLocal = StaticTrainLine(
        id: "Railway:JR-East.ChuoSobuLocal",
        nameJa: "中央・総武線各駅停車",
        nameEn: "Chuo-Sobu Local Line",
        operatorId: "Operator:JR-East",
        colorHex: "#FFD400",
        stations: [
            st("ChuoSobuLocal", "Mitaka", "三鷹", "Mitaka", "JB01", 35.7027, 139.5607),
            st("ChuoSobuLocal", "Kichijoji", "吉祥寺", "Kichijoji", "JB02", 35.7030, 139.5796),
            st("ChuoSobuLocal", "NishiOgikubo", "西荻窪", "Nishi-Ogikubo", "JB03", 35.7037, 139.5993),
            st("ChuoSobuLocal", "Ogikubo", "荻窪", "Ogikubo", "JB04", 35.7047, 139.6202),
            st("ChuoSobuLocal", "Asagaya", "阿佐ケ谷", "Asagaya", "JB05", 35.7047, 139.6357),
            st("ChuoSobuLocal", "Koenji", "高円寺", "Koenji", "JB06", 35.7053, 139.6497),
            st("ChuoSobuLocal", "Nakano", "中野", "Nakano", "JB07", 35.7056, 139.6659),
            st("ChuoSobuLocal", "HigashiNakano", "東中野", "Higashi-Nakano", "JB08", 35.7062, 139.6835),
            st("ChuoSobuLocal", "Okubo", "大久保", "Okubo", "JB09", 35.7009, 139.6983),
            st("ChuoSobuLocal", "Shinjuku", "新宿", "Shinjuku", "JB10", 35.6896, 139.7006),
            st("ChuoSobuLocal", "Yoyogi", "代々木", "Yoyogi", "JB11", 35.6832, 139.7020),
            st("ChuoSobuLocal", "Sendagaya", "千駄ケ谷", "Sendagaya", "JB12", 35.6811, 139.7119),
            st("ChuoSobuLocal", "Shinanomachi", "信濃町", "Shinanomachi", "JB13", 35.6800, 139.7202),
            st("ChuoSobuLocal", "Yotsuya", "四ツ谷", "Yotsuya", "JB14", 35.6860, 139.7301),
            st("ChuoSobuLocal", "Ichigaya", "市ケ谷", "Ichigaya", "JB15", 35.6914, 139.7357),
            st("ChuoSobuLocal", "Iidabashi", "飯田橋", "Iidabashi", "JB16", 35.7020, 139.7448),
            st("ChuoSobuLocal", "Suidobashi", "水道橋", "Suidobashi", "JB17", 35.7020, 139.7530),
            st("ChuoSobuLocal", "Ochanomizu", "御茶ノ水", "Ochanomizu", "JB18", 35.6994, 139.7649),
            st("ChuoSobuLocal", "Akihabara", "秋葉原", "Akihabara", "JB19", 35.6984, 139.7731),
            st("ChuoSobuLocal", "Asakusabashi", "浅草橋", "Asakusabashi", "JB20", 35.6986, 139.7862),
            st("ChuoSobuLocal", "Ryogoku", "両国", "Ryogoku", "JB21", 35.6961, 139.7936),
            st("ChuoSobuLocal", "Kinshicho", "錦糸町", "Kinshicho", "JB22", 35.6967, 139.8140),
            st("ChuoSobuLocal", "Kameido", "亀戸", "Kameido", "JB23", 35.6973, 139.8265),
            st("ChuoSobuLocal", "Hirai", "平井", "Hirai", "JB24", 35.7057, 139.8419),
            st("ChuoSobuLocal", "ShinKoiwa", "新小岩", "Shin-Koiwa", "JB25", 35.7167, 139.8578),
            st("ChuoSobuLocal", "Koiwa", "小岩", "Koiwa", "JB26", 35.7331, 139.8817),
            st("ChuoSobuLocal", "Ichikawa", "市川", "Ichikawa", "JB27", 35.7297, 139.9078),
            st("ChuoSobuLocal", "Motoyawata", "本八幡", "Motoyawata", "JB28", 35.7203, 139.9276),
            st("ChuoSobuLocal", "ShimosaNakayama", "下総中山", "Shimosa-Nakayama", "JB29", 35.7143, 139.9399),
            st("ChuoSobuLocal", "NishiFunabashi", "西船橋", "Nishi-Funabashi", "JB30", 35.7075, 139.9594),
            st("ChuoSobuLocal", "Funabashi", "船橋", "Funabashi", "JB31", 35.7019, 139.9853),
            st("ChuoSobuLocal", "HigashiFunabashi", "東船橋", "Higashi-Funabashi", "JB32", 35.7027, 140.0040),
            st("ChuoSobuLocal", "Tsudanuma", "津田沼", "Tsudanuma", "JB33", 35.6913, 140.0200),
            st("ChuoSobuLocal", "MakuhariHongo", "幕張本郷", "Makuhari-Hongo", "JB34", 35.6725, 140.0421),
            st("ChuoSobuLocal", "Makuhari", "幕張", "Makuhari", "JB35", 35.6655, 140.0550),
            st("ChuoSobuLocal", "ShinKemigawa", "新検見川", "Shin-Kemigawa", "JB36", 35.6614, 140.0723),
            st("ChuoSobuLocal", "Inage", "稲毛", "Inage", "JB37", 35.6333, 140.0900),
            st("ChuoSobuLocal", "NishiChiba", "西千葉", "Nishi-Chiba", "JB38", 35.6213, 140.1015),
            st("ChuoSobuLocal", "Chiba", "千葉", "Chiba", "JB39", 35.6131, 140.1136),
        ],
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
            2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 3, 2, 2, 3, 2, 2, 3, 3, 2,
        ],
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.ChuoSobuLocal.Chiba",
                nameJa: "千葉方面",
                nameEn: "For Chiba",
                isAscending: true,
                weekday: ServicePattern(
                    first: "04:35", last: "24:34",
                    bands: [
                        HeadwayBand(from: "04:35", headwayMinutes: 8),
                        HeadwayBand(from: "06:30", headwayMinutes: 3.5),
                        HeadwayBand(from: "09:30", headwayMinutes: 6),
                        HeadwayBand(from: "16:30", headwayMinutes: 4.5),
                        HeadwayBand(from: "20:00", headwayMinutes: 6),
                        HeadwayBand(from: "22:00", headwayMinutes: 8),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:35", last: "24:34",
                    bands: [
                        HeadwayBand(from: "04:35", headwayMinutes: 8),
                        HeadwayBand(from: "07:00", headwayMinutes: 6),
                        HeadwayBand(from: "10:00", headwayMinutes: 6),
                        HeadwayBand(from: "20:00", headwayMinutes: 7),
                        HeadwayBand(from: "22:00", headwayMinutes: 8),
                    ]
                )
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.ChuoSobuLocal.Mitaka",
                nameJa: "三鷹方面",
                nameEn: "For Mitaka",
                isAscending: false,
                weekday: ServicePattern(
                    first: "04:28", last: "24:30",
                    bands: [
                        HeadwayBand(from: "04:35", headwayMinutes: 8),
                        HeadwayBand(from: "06:30", headwayMinutes: 3.5),
                        HeadwayBand(from: "09:30", headwayMinutes: 6),
                        HeadwayBand(from: "16:30", headwayMinutes: 4.5),
                        HeadwayBand(from: "20:00", headwayMinutes: 6),
                        HeadwayBand(from: "22:00", headwayMinutes: 8),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:28", last: "24:30",
                    bands: [
                        HeadwayBand(from: "04:35", headwayMinutes: 8),
                        HeadwayBand(from: "07:00", headwayMinutes: 6),
                        HeadwayBand(from: "10:00", headwayMinutes: 6),
                        HeadwayBand(from: "20:00", headwayMinutes: 7),
                        HeadwayBand(from: "22:00", headwayMinutes: 8),
                    ]
                )
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("ChuoSobuLocal.Nakano", .ascending,
                    "東京メトロ東西線", "Tokyo Metro Tozai Line",
                    "西船橋方面", "for Nishi-funabashi",
                    to: "Railway:TokyoMetro.Tozai"),
            through("ChuoSobuLocal.NishiFunabashi", .descending,
                    "東京メトロ東西線", "Tokyo Metro Tozai Line",
                    "中野方面", "for Nakano",
                    to: "Railway:TokyoMetro.Tozai"),
        ]
    )

    // MARK: - Keihin-Tohoku Line (JK, incl. Negishi Line)

    static let keihinTohoku = StaticTrainLine(
        id: "Railway:JR-East.KeihinTohoku",
        nameJa: "京浜東北線",
        nameEn: "Keihin-Tohoku Line",
        operatorId: "Operator:JR-East",
        colorHex: "#00B2E5",
        stations: [
            st("KeihinTohoku", "Ofuna", "大船", "Ofuna", "JK01", 35.3540, 139.5313),
            st("KeihinTohoku", "Hongodai", "本郷台", "Hongodai", "JK02", 35.3714, 139.5540),
            st("KeihinTohoku", "Konandai", "港南台", "Konandai", "JK03", 35.3753, 139.5787),
            st("KeihinTohoku", "Yokodai", "洋光台", "Yokodai", "JK04", 35.3852, 139.5943),
            st("KeihinTohoku", "ShinSugita", "新杉田", "Shin-Sugita", "JK05", 35.3880, 139.6187),
            st("KeihinTohoku", "Isogo", "磯子", "Isogo", "JK06", 35.4009, 139.6187),
            st("KeihinTohoku", "Negishi", "根岸", "Negishi", "JK07", 35.4147, 139.6320),
            st("KeihinTohoku", "Yamate", "山手", "Yamate", "JK08", 35.4310, 139.6448),
            st("KeihinTohoku", "Ishikawacho", "石川町", "Ishikawacho", "JK09", 35.4395, 139.6424),
            st("KeihinTohoku", "Kannai", "関内", "Kannai", "JK10", 35.4437, 139.6367),
            st("KeihinTohoku", "Sakuragicho", "桜木町", "Sakuragicho", "JK11", 35.4507, 139.6317),
            st("KeihinTohoku", "Yokohama", "横浜", "Yokohama", "JK12", 35.4657, 139.6224),
            st("KeihinTohoku", "HigashiKanagawa", "東神奈川", "Higashi-Kanagawa", "JK13", 35.4772, 139.6343),
            st("KeihinTohoku", "ShinKoyasu", "新子安", "Shin-Koyasu", "JK14", 35.4890, 139.6592),
            st("KeihinTohoku", "Tsurumi", "鶴見", "Tsurumi", "JK15", 35.5086, 139.6796),
            st("KeihinTohoku", "Kawasaki", "川崎", "Kawasaki", "JK16", 35.5308, 139.6970),
            st("KeihinTohoku", "Kamata", "蒲田", "Kamata", "JK17", 35.5626, 139.7160),
            st("KeihinTohoku", "Omori", "大森", "Omori", "JK18", 35.5884, 139.7278),
            st("KeihinTohoku", "Oimachi", "大井町", "Oimachi", "JK19", 35.6062, 139.7340),
            st("KeihinTohoku", "Shinagawa", "品川", "Shinagawa", "JK20", 35.6285, 139.7388),
            st("KeihinTohoku", "TakanawaGateway", "高輪ゲートウェイ", "Takanawa Gateway", "JK21", 35.6355, 139.7407),
            st("KeihinTohoku", "Tamachi", "田町", "Tamachi", "JK22", 35.6457, 139.7476),
            st("KeihinTohoku", "Hamamatsucho", "浜松町", "Hamamatsucho", "JK23", 35.6556, 139.7570),
            st("KeihinTohoku", "Shimbashi", "新橋", "Shimbashi", "JK24", 35.6663, 139.7583),
            st("KeihinTohoku", "Yurakucho", "有楽町", "Yurakucho", "JK25", 35.6749, 139.7628),
            st("KeihinTohoku", "Tokyo", "東京", "Tokyo", "JK26", 35.6812, 139.7671),
            st("KeihinTohoku", "Kanda", "神田", "Kanda", "JK27", 35.6918, 139.7709),
            st("KeihinTohoku", "Akihabara", "秋葉原", "Akihabara", "JK28", 35.6984, 139.7731),
            st("KeihinTohoku", "Okachimachi", "御徒町", "Okachimachi", "JK29", 35.7075, 139.7747),
            st("KeihinTohoku", "Ueno", "上野", "Ueno", "JK30", 35.7141, 139.7774),
            st("KeihinTohoku", "Uguisudani", "鶯谷", "Uguisudani", "JK31", 35.7206, 139.7785),
            st("KeihinTohoku", "Nippori", "日暮里", "Nippori", "JK32", 35.7278, 139.7708),
            st("KeihinTohoku", "NishiNippori", "西日暮里", "Nishi-Nippori", "JK33", 35.7324, 139.7669),
            st("KeihinTohoku", "Tabata", "田端", "Tabata", "JK34", 35.7381, 139.7607),
            st("KeihinTohoku", "Kaminakazato", "上中里", "Kaminakazato", "JK35", 35.7472, 139.7472),
            st("KeihinTohoku", "Oji", "王子", "Oji", "JK36", 35.7526, 139.7380),
            st("KeihinTohoku", "HigashiJujo", "東十条", "Higashi-Jujo", "JK37", 35.7645, 139.7284),
            st("KeihinTohoku", "Akabane", "赤羽", "Akabane", "JK38", 35.7782, 139.7208),
            st("KeihinTohoku", "Kawaguchi", "川口", "Kawaguchi", "JK39", 35.8020, 139.7103),
            st("KeihinTohoku", "NishiKawaguchi", "西川口", "Nishi-Kawaguchi", "JK40", 35.8158, 139.7040),
            st("KeihinTohoku", "Warabi", "蕨", "Warabi", "JK41", 35.8262, 139.6969),
            st("KeihinTohoku", "MinamiUrawa", "南浦和", "Minami-Urawa", "JK42", 35.8446, 139.6656),
            st("KeihinTohoku", "Urawa", "浦和", "Urawa", "JK43", 35.8593, 139.6570),
            st("KeihinTohoku", "KitaUrawa", "北浦和", "Kita-Urawa", "JK44", 35.8726, 139.6510),
            st("KeihinTohoku", "Yono", "与野", "Yono", "JK45", 35.8845, 139.6466),
            st("KeihinTohoku", "SaitamaShintoshin", "さいたま新都心", "Saitama-Shintoshin", "JK46", 35.8940, 139.6339),
            st("KeihinTohoku", "Omiya", "大宮", "Omiya", "JK47", 35.9064, 139.6238),
        ],
        hopTimesMinutes: [
            3, 3, 2, 3, 2, 3, 3, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 2, 2, 3, 3, 2, 2, 2, 3,
        ],
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.KeihinTohoku.Omiya",
                nameJa: "大宮方面",
                nameEn: "For Omiya",
                isAscending: true,
                weekday: ServicePattern(
                    first: "04:43", last: "24:09",
                    bands: [
                        HeadwayBand(from: "04:30", headwayMinutes: 8),
                        HeadwayBand(from: "06:30", headwayMinutes: 4),
                        HeadwayBand(from: "09:30", headwayMinutes: 5),
                        HeadwayBand(from: "16:30", headwayMinutes: 4.5),
                        HeadwayBand(from: "20:00", headwayMinutes: 6),
                        HeadwayBand(from: "22:00", headwayMinutes: 8),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:43", last: "24:09",
                    bands: [
                        HeadwayBand(from: "04:30", headwayMinutes: 8),
                        HeadwayBand(from: "07:00", headwayMinutes: 5),
                        HeadwayBand(from: "10:00", headwayMinutes: 5.5),
                        HeadwayBand(from: "20:00", headwayMinutes: 6.5),
                        HeadwayBand(from: "22:00", headwayMinutes: 8),
                    ]
                )
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.KeihinTohoku.Ofuna",
                nameJa: "大船方面",
                nameEn: "For Ofuna",
                isAscending: false,
                weekday: ServicePattern(
                    first: "04:28", last: "24:15",
                    bands: [
                        HeadwayBand(from: "04:30", headwayMinutes: 8),
                        HeadwayBand(from: "06:30", headwayMinutes: 4),
                        HeadwayBand(from: "09:30", headwayMinutes: 5),
                        HeadwayBand(from: "16:30", headwayMinutes: 4.5),
                        HeadwayBand(from: "20:00", headwayMinutes: 6),
                        HeadwayBand(from: "22:00", headwayMinutes: 8),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:28", last: "24:15",
                    bands: [
                        HeadwayBand(from: "04:30", headwayMinutes: 8),
                        HeadwayBand(from: "07:00", headwayMinutes: 5),
                        HeadwayBand(from: "10:00", headwayMinutes: 5.5),
                        HeadwayBand(from: "20:00", headwayMinutes: 6.5),
                        HeadwayBand(from: "22:00", headwayMinutes: 8),
                    ]
                )
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("KeihinTohoku.HigashiKanagawa", .ascending,
                    "横浜線", "JR Yokohama Line",
                    "町田・八王子方面", "for Machida & Hachioji",
                    to: "Railway:JR-East.Yokohama"),
        ]
    )

    // MARK: - Saikyo Line (JA)

    static let saikyo = StaticTrainLine(
        id: "Railway:JR-East.SaikyoKawagoe",
        nameJa: "埼京線",
        nameEn: "Saikyo Line",
        operatorId: "Operator:JR-East",
        colorHex: "#00AC9A",
        stations: [
            st("SaikyoKawagoe", "Osaki", "大崎", "Osaki", "JA08", 35.6197, 139.7286),
            st("SaikyoKawagoe", "Ebisu", "恵比寿", "Ebisu", "JA09", 35.6467, 139.7101),
            st("SaikyoKawagoe", "Shibuya", "渋谷", "Shibuya", "JA10", 35.6580, 139.7016),
            st("SaikyoKawagoe", "Shinjuku", "新宿", "Shinjuku", "JA11", 35.6896, 139.7006),
            st("SaikyoKawagoe", "Ikebukuro", "池袋", "Ikebukuro", "JA12", 35.7295, 139.7109),
            st("SaikyoKawagoe", "Itabashi", "板橋", "Itabashi", "JA13", 35.7454, 139.7194),
            st("SaikyoKawagoe", "Jujo", "十条", "Jujo", "JA14", 35.7605, 139.7218),
            st("SaikyoKawagoe", "Akabane", "赤羽", "Akabane", "JA15", 35.7782, 139.7208),
            st("SaikyoKawagoe", "KitaAkabane", "北赤羽", "Kita-Akabane", "JA16", 35.7873, 139.7099),
            st("SaikyoKawagoe", "Ukimafunado", "浮間舟渡", "Ukima-Funado", "JA17", 35.7940, 139.6907),
            st("SaikyoKawagoe", "TodaKoen", "戸田公園", "Toda-Koen", "JA18", 35.8045, 139.6772),
            st("SaikyoKawagoe", "Toda", "戸田", "Toda", "JA19", 35.8140, 139.6680),
            st("SaikyoKawagoe", "KitaToda", "北戸田", "Kita-Toda", "JA20", 35.8258, 139.6598),
            st("SaikyoKawagoe", "MusashiUrawa", "武蔵浦和", "Musashi-Urawa", "JA21", 35.8456, 139.6484),
            st("SaikyoKawagoe", "NakaUrawa", "中浦和", "Naka-Urawa", "JA22", 35.8560, 139.6404),
            st("SaikyoKawagoe", "MinamiYono", "南与野", "Minami-Yono", "JA23", 35.8693, 139.6323),
            st("SaikyoKawagoe", "Yonohommachi", "与野本町", "Yonohommachi", "JA24", 35.8805, 139.6248),
            st("SaikyoKawagoe", "KitaYono", "北与野", "Kita-Yono", "JA25", 35.8930, 139.6260),
            st("SaikyoKawagoe", "Omiya", "大宮", "Omiya", "JA26", 35.9064, 139.6238),
        ],
        hopTimesMinutes: [
            5, 3, 5, 6, 3, 2, 3, 3, 2, 3, 2, 2, 3, 2, 2, 2, 2, 3,
        ],
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.SaikyoKawagoe.Omiya",
                nameJa: "大宮方面",
                nameEn: "For Omiya",
                isAscending: true,
                weekday: ServicePattern(
                    first: "06:13", last: "23:35",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "06:30", headwayMinutes: 5),
                        HeadwayBand(from: "09:30", headwayMinutes: 9),
                        HeadwayBand(from: "16:30", headwayMinutes: 6),
                        HeadwayBand(from: "20:00", headwayMinutes: 8),
                        HeadwayBand(from: "22:00", headwayMinutes: 10),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "06:13", last: "23:35",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "07:00", headwayMinutes: 7),
                        HeadwayBand(from: "10:00", headwayMinutes: 8),
                        HeadwayBand(from: "20:00", headwayMinutes: 9),
                    ]
                )
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.SaikyoKawagoe.Osaki",
                nameJa: "大崎方面",
                nameEn: "For Osaki",
                isAscending: false,
                weekday: ServicePattern(
                    first: "04:51", last: "24:00",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "06:30", headwayMinutes: 5),
                        HeadwayBand(from: "09:30", headwayMinutes: 9),
                        HeadwayBand(from: "16:30", headwayMinutes: 6),
                        HeadwayBand(from: "20:00", headwayMinutes: 8),
                        HeadwayBand(from: "22:00", headwayMinutes: 10),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:51", last: "23:46",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "07:00", headwayMinutes: 7),
                        HeadwayBand(from: "10:00", headwayMinutes: 8),
                        HeadwayBand(from: "20:00", headwayMinutes: 9),
                    ]
                )
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("SaikyoKawagoe.Osaki", .descending,
                    "りんかい線", "Rinkai Line", "新木場方面", "for Shin-Kiba"),
            through("SaikyoKawagoe.Osaki", .descending,
                    "相鉄線", "Sotetsu Line", "海老名方面", "for Ebina"),
            through("SaikyoKawagoe.Omiya", .ascending,
                    "川越線", "JR Kawagoe Line", "川越方面", "for Kawagoe"),
        ]
    )

    // MARK: - Keiyo Line (JE)

    static let keiyo = StaticTrainLine(
        id: "Railway:JR-East.Keiyo",
        nameJa: "京葉線",
        nameEn: "Keiyo Line",
        operatorId: "Operator:JR-East",
        colorHex: "#C9242F",
        stations: [
            st("Keiyo", "Tokyo", "東京", "Tokyo", "JE01", 35.6770, 139.7650),
            st("Keiyo", "Hatchobori", "八丁堀", "Hatchobori", "JE02", 35.6748, 139.7777),
            st("Keiyo", "Etchujima", "越中島", "Etchujima", "JE03", 35.6680, 139.7925),
            st("Keiyo", "Shiomi", "潮見", "Shiomi", "JE04", 35.6553, 139.8156),
            st("Keiyo", "ShinKiba", "新木場", "Shin-Kiba", "JE05", 35.6460, 139.8268),
            st("Keiyo", "KasaiRinkaiKoen", "葛西臨海公園", "Kasai-Rinkai-Koen", "JE06", 35.6437, 139.8637),
            st("Keiyo", "Maihama", "舞浜", "Maihama", "JE07", 35.6361, 139.8831),
            st("Keiyo", "ShinUrayasu", "新浦安", "Shin-Urayasu", "JE08", 35.6528, 139.9090),
            st("Keiyo", "IchikawaShiohama", "市川塩浜", "Ichikawa-Shiohama", "JE09", 35.6569, 139.9343),
            st("Keiyo", "FutamataShimmachi", "二俣新町", "Futamata-Shimmachi", "JE10", 35.6685, 139.9605),
            st("Keiyo", "MinamiFunabashi", "南船橋", "Minami-Funabashi", "JE11", 35.6842, 139.9903),
            st("Keiyo", "ShinNarashino", "新習志野", "Shin-Narashino", "JE12", 35.6716, 140.0257),
            st("Keiyo", "MakuhariToyosuna", "幕張豊砂", "Makuhari-Toyosuna", "JE13", 35.6555, 140.0339),
            st("Keiyo", "KaihimMakuhari", "海浜幕張", "Kaihimmakuhari", "JE14", 35.6482, 140.0416),
            st("Keiyo", "Kemigawahama", "検見川浜", "Kemigawahama", "JE15", 35.6391, 140.0687),
            st("Keiyo", "InageKaigan", "稲毛海岸", "Inage-Kaigan", "JE16", 35.6300, 140.0868),
            st("Keiyo", "Chibaminato", "千葉みなと", "Chibaminato", "JE17", 35.6072, 140.1052),
            st("Keiyo", "Soga", "蘇我", "Soga", "JE18", 35.5812, 140.1315),
        ],
        hopTimesMinutes: [
            2, 2, 3, 2, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 2, 4, 4,
        ],
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.Keiyo.Soga",
                nameJa: "蘇我方面",
                nameEn: "For Soga",
                isAscending: true,
                weekday: ServicePattern(
                    first: "04:55", last: "24:24",
                    bands: [
                        HeadwayBand(from: "05:10", headwayMinutes: 9),
                        HeadwayBand(from: "06:30", headwayMinutes: 6),
                        HeadwayBand(from: "09:30", headwayMinutes: 9),
                        HeadwayBand(from: "16:30", headwayMinutes: 6),
                        HeadwayBand(from: "20:00", headwayMinutes: 8),
                        HeadwayBand(from: "22:00", headwayMinutes: 10),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:55", last: "24:24",
                    bands: [
                        HeadwayBand(from: "05:10", headwayMinutes: 9),
                        HeadwayBand(from: "07:00", headwayMinutes: 7),
                        HeadwayBand(from: "10:00", headwayMinutes: 8),
                        HeadwayBand(from: "20:00", headwayMinutes: 9),
                    ]
                )
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.Keiyo.Tokyo",
                nameJa: "東京方面",
                nameEn: "For Tokyo",
                isAscending: false,
                weekday: ServicePattern(
                    first: "04:50", last: "24:20",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "06:00", headwayMinutes: 6),
                        HeadwayBand(from: "09:30", headwayMinutes: 9),
                        HeadwayBand(from: "16:30", headwayMinutes: 6),
                        HeadwayBand(from: "20:00", headwayMinutes: 8),
                        HeadwayBand(from: "22:00", headwayMinutes: 10),
                    ]
                ),
                saturdayHoliday: ServicePattern(
                    first: "04:50", last: "24:20",
                    bands: [
                        HeadwayBand(from: "05:00", headwayMinutes: 9),
                        HeadwayBand(from: "07:00", headwayMinutes: 7),
                        HeadwayBand(from: "10:00", headwayMinutes: 8),
                        HeadwayBand(from: "20:00", headwayMinutes: 9),
                    ]
                )
            ),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keiyo.Soga", .ascending,
                    "内房線・外房線", "JR Uchibo & Sotobo Lines",
                    "君津・上総一ノ宮方面", "for Kimitsu & Kazusa-Ichinomiya"),
        ]
    )
}
