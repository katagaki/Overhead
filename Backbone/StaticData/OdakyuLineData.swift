import Foundation

// MARK: - Odakyu Line Data

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

enum OdakyuLineData {

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.odakyu.jp/train/unkou/",
        statusPageURLEn: "https://www.odakyu.jp/english/",
        xAccount: "@odakyuline_info",
        checkMethodJa: "小田急電鉄「運行情報」ページ、小田急アプリ、またはX（@odakyuline_info）で確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Odakyu train information page, the Odakyu app, or X (@odakyuline_info). Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        odawara, enoshima, tama,
    ]

    private static let odawaraWeekday = pattern("05:00", "24:00", [
        ("05:00", 8), ("06:30", 4), ("09:30", 7), ("16:30", 5), ("20:00", 7), ("22:00", 9),
    ])
    private static let odawaraHoliday = pattern("05:00", "24:00", [
        ("05:00", 8), ("07:00", 6), ("10:00", 7), ("20:00", 8),
    ])

    // MARK: Odakyu Odawara Line (OH)

    static let odawara = StaticTrainLine(
        id: "odpt.Railway:Odakyu.Odawara",
        nameJa: "小田急小田原線",
        nameEn: "Odakyu Odawara Line",
        operatorId: "odpt.Operator:Odakyu",
        colorHex: "#005BAC",
        stations: [
            st("Odakyu.Odawara", "Shinjuku", "新宿", "Shinjuku", "OH01", 35.6905, 139.6994),
            st("Odakyu.Odawara", "MinamiShinjuku", "南新宿", "Minami-Shinjuku", "OH02", 35.6842, 139.6980),
            st("Odakyu.Odawara", "Sangubashi", "参宮橋", "Sangubashi", "OH03", 35.6784, 139.6935),
            st("Odakyu.Odawara", "YoyogiHachiman", "代々木八幡", "Yoyogi-Hachiman", "OH04", 35.6690, 139.6890),
            st("Odakyu.Odawara", "YoyogiUehara", "代々木上原", "Yoyogi-Uehara", "OH05", 35.6690, 139.6799),
            st("Odakyu.Odawara", "HigashiKitazawa", "東北沢", "Higashi-Kitazawa", "OH06", 35.6663, 139.6740),
            st("Odakyu.Odawara", "ShimoKitazawa", "下北沢", "Shimo-Kitazawa", "OH07", 35.6614, 139.6667),
            st("Odakyu.Odawara", "SetagayaDaita", "世田谷代田", "Setagaya-Daita", "OH08", 35.6591, 139.6600),
            st("Odakyu.Odawara", "Umegaoka", "梅ヶ丘", "Umegaoka", "OH09", 35.6567, 139.6533),
            st("Odakyu.Odawara", "Gotokuji", "豪徳寺", "Gotokuji", "OH10", 35.6538, 139.6469),
            st("Odakyu.Odawara", "Kyodo", "経堂", "Kyodo", "OH11", 35.6510, 139.6363),
            st("Odakyu.Odawara", "ChitoseFunabashi", "千歳船橋", "Chitose-Funabashi", "OH12", 35.6484, 139.6252),
            st("Odakyu.Odawara", "SoshigayaOkura", "祖師ヶ谷大蔵", "Soshigaya-Okura", "OH13", 35.6459, 139.6127),
            st("Odakyu.Odawara", "SeijogakuenMae", "成城学園前", "Seijogakuen-mae", "OH14", 35.6404, 139.6004),
            st("Odakyu.Odawara", "Kitami", "喜多見", "Kitami", "OH15", 35.6350, 139.5891),
            st("Odakyu.Odawara", "Komae", "狛江", "Komae", "OH16", 35.6317, 139.5786),
            st("Odakyu.Odawara", "IzumiTamagawa", "和泉多摩川", "Izumi-Tamagawa", "OH17", 35.6280, 139.5716),
            st("Odakyu.Odawara", "Noborito", "登戸", "Noborito", "OH18", 35.6205, 139.5702),
            st("Odakyu.Odawara", "MukogaokaYuen", "向ヶ丘遊園", "Mukogaoka-Yuen", "OH19", 35.6172, 139.5648),
            st("Odakyu.Odawara", "Ikuta", "生田", "Ikuta", "OH20", 35.6146, 139.5427),
            st("Odakyu.Odawara", "YomiurilandMae", "読売ランド前", "Yomiuriland-mae", "OH21", 35.6130, 139.5278),
            st("Odakyu.Odawara", "Yurigaoka", "百合ヶ丘", "Yurigaoka", "OH22", 35.6083, 139.5175),
            st("Odakyu.Odawara", "ShinYurigaoka", "新百合ヶ丘", "Shin-Yurigaoka", "OH23", 35.6039, 139.5083),
            st("Odakyu.Odawara", "Kakio", "柿生", "Kakio", "OH24", 35.5947, 139.5023),
            st("Odakyu.Odawara", "Tsurukawa", "鶴川", "Tsurukawa", "OH25", 35.5893, 139.4820),
            st("Odakyu.Odawara", "TamagawagakuenMae", "玉川学園前", "Tamagawagakuen-mae", "OH26", 35.5666, 139.4644),
            st("Odakyu.Odawara", "Machida", "町田", "Machida", "OH27", 35.5424, 139.4467),
            st("Odakyu.Odawara", "SagamiOno", "相模大野", "Sagami-Ono", "OH28", 35.5318, 139.4383),
            st("Odakyu.Odawara", "OdakyuSagamihara", "小田急相模原", "Odakyu-Sagamihara", "OH29", 35.5262, 139.4262),
            st("Odakyu.Odawara", "SobudaiMae", "相武台前", "Sobudai-mae", "OH30", 35.5165, 139.4083),
            st("Odakyu.Odawara", "Zama", "座間", "Zama", "OH31", 35.5085, 139.4009),
            st("Odakyu.Odawara", "Ebina", "海老名", "Ebina", "OH32", 35.4529, 139.3906),
            st("Odakyu.Odawara", "Atsugi", "厚木", "Atsugi", "OH33", 35.4406, 139.3719),
            st("Odakyu.Odawara", "HonAtsugi", "本厚木", "Hon-Atsugi", "OH34", 35.4394, 139.3648),
            st("Odakyu.Odawara", "AikoIshida", "愛甲石田", "Aiko-Ishida", "OH35", 35.4260, 139.3350),
            st("Odakyu.Odawara", "Isehara", "伊勢原", "Isehara", "OH36", 35.4030, 139.3149),
            st("Odakyu.Odawara", "TsurumakiOnsen", "鶴巻温泉", "Tsurumaki-Onsen", "OH37", 35.3877, 139.2760),
            st("Odakyu.Odawara", "Tokaidaigakumae", "東海大学前", "Tokaidaigaku-mae", "OH38", 35.3844, 139.2673),
            st("Odakyu.Odawara", "Hadano", "秦野", "Hadano", "OH39", 35.3714, 139.2245),
            st("Odakyu.Odawara", "Shibusawa", "渋沢", "Shibusawa", "OH40", 35.3617, 139.1830),
            st("Odakyu.Odawara", "ShinMatsuda", "新松田", "Shin-Matsuda", "OH41", 35.3437, 139.1408),
            st("Odakyu.Odawara", "Kaisei", "開成", "Kaisei", "OH42", 35.3299, 139.1332),
            st("Odakyu.Odawara", "Kayama", "栢山", "Kayama", "OH43", 35.3125, 139.1408),
            st("Odakyu.Odawara", "Tomizu", "富水", "Tomizu", "OH44", 35.3003, 139.1444),
            st("Odakyu.Odawara", "Hotaruda", "螢田", "Hotaruda", "OH45", 35.2894, 139.1477),
            st("Odakyu.Odawara", "Ashigara", "足柄", "Ashigara", "OH46", 35.2726, 139.1518),
            st("Odakyu.Odawara", "Odawara", "小田原", "Odawara", "OH47", 35.2563, 139.1552),
        ],
        hopTimesMinutes: [
            2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 3, 2, 2, 2, 2,
            2, 3, 3, 3, 3, 2, 2, 4, 2, 2, 3, 4, 4, 2, 4, 4, 5, 2, 2, 2, 2, 2, 3,
        ],
        directions: [
            direction("Odakyu.Odawara", "Odawara", "小田原方面", "For Odawara", ascending: true,
                      weekday: odawaraWeekday, holiday: odawaraHoliday),
            direction("Odakyu.Odawara", "Shinjuku", "新宿方面", "For Shinjuku", ascending: false,
                      weekday: odawaraWeekday, holiday: odawaraHoliday),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Odakyu.Odawara.YoyogiUehara", .descending,
                    "東京メトロ千代田線", "Tokyo Metro Chiyoda Line",
                    "大手町・綾瀬方面", "for Otemachi & Ayase",
                    to: "odpt.Railway:TokyoMetro.Chiyoda"),
            through("Odakyu.Odawara.ShinYurigaoka", .ascending,
                    "小田急多摩線", "Odakyu Tama Line",
                    "唐木田方面", "for Karakida",
                    to: "odpt.Railway:Odakyu.Tama"),
            through("Odakyu.Odawara.SagamiOno", .ascending,
                    "小田急江ノ島線", "Odakyu Enoshima Line",
                    "藤沢・片瀬江ノ島方面", "for Fujisawa & Katase-Enoshima",
                    to: "odpt.Railway:Odakyu.Enoshima"),
            through("Odakyu.Odawara.Odawara", .ascending,
                    "箱根登山線", "Hakone Tozan Line",
                    "箱根湯本方面", "for Hakone-Yumoto"),
        ]
    )

    // MARK: Odakyu Enoshima Line (OE)

    private static let enoshimaWeekday = pattern("05:00", "24:00", [
        ("05:00", 8), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
    ])
    private static let enoshimaHoliday = pattern("05:00", "24:00", [
        ("05:00", 8), ("07:00", 7), ("10:00", 8), ("20:00", 9),
    ])

    static let enoshima = StaticTrainLine(
        id: "odpt.Railway:Odakyu.Enoshima",
        nameJa: "小田急江ノ島線",
        nameEn: "Odakyu Enoshima Line",
        operatorId: "odpt.Operator:Odakyu",
        colorHex: "#009250",
        stations: [
            st("Odakyu.Enoshima", "SagamiOno", "相模大野", "Sagami-Ono", "OH28", 35.5318, 139.4383),
            st("Odakyu.Enoshima", "HigashiRinkan", "東林間", "Higashi-Rinkan", "OE01", 35.5203, 139.4365),
            st("Odakyu.Enoshima", "ChuoRinkan", "中央林間", "Chuo-Rinkan", "OE02", 35.5079, 139.4443),
            st("Odakyu.Enoshima", "MinamiRinkan", "南林間", "Minami-Rinkan", "OE03", 35.4974, 139.4483),
            st("Odakyu.Enoshima", "Tsuruma", "鶴間", "Tsuruma", "OE04", 35.4879, 139.4514),
            st("Odakyu.Enoshima", "Yamato", "大和", "Yamato", "OE05", 35.4691, 139.4599),
            st("Odakyu.Enoshima", "Sakuragaoka", "桜ヶ丘", "Sakuragaoka", "OE06", 35.4520, 139.4635),
            st("Odakyu.Enoshima", "KozaShibuya", "高座渋谷", "Koza-Shibuya", "OE07", 35.4319, 139.4620),
            st("Odakyu.Enoshima", "Chogo", "長後", "Chogo", "OE08", 35.4177, 139.4661),
            st("Odakyu.Enoshima", "Shonandai", "湘南台", "Shonandai", "OE09", 35.3953, 139.4668),
            st("Odakyu.Enoshima", "MutsuaiNichidaimae", "六会日大前", "Mutsuai-Nichidai-mae", "OE10", 35.3820, 139.4665),
            st("Odakyu.Enoshima", "Zengyo", "善行", "Zengyo", "OE11", 35.3652, 139.4699),
            st("Odakyu.Enoshima", "FujisawaHommachi", "藤沢本町", "Fujisawa-Hommachi", "OE12", 35.3502, 139.4770),
            st("Odakyu.Enoshima", "Fujisawa", "藤沢", "Fujisawa", "OE13", 35.3387, 139.4872),
            st("Odakyu.Enoshima", "HonKugenuma", "本鵠沼", "Hon-Kugenuma", "OE14", 35.3269, 139.4816),
            st("Odakyu.Enoshima", "KugenumaKaigan", "鵠沼海岸", "Kugenuma-Kaigan", "OE15", 35.3162, 139.4788),
            st("Odakyu.Enoshima", "KataseEnoshima", "片瀬江ノ島", "Katase-Enoshima", "OE16", 35.3096, 139.4791),
        ],
        hopTimesMinutes: [3, 2, 2, 1, 3, 2, 3, 2, 3, 2, 2, 2, 3, 2, 2, 2],
        directions: [
            direction("Odakyu.Enoshima", "KataseEnoshima", "藤沢・片瀬江ノ島方面", "For Fujisawa & Katase-Enoshima", ascending: true,
                      weekday: enoshimaWeekday, holiday: enoshimaHoliday),
            direction("Odakyu.Enoshima", "SagamiOno", "相模大野方面", "For Sagami-Ono", ascending: false,
                      weekday: enoshimaWeekday, holiday: enoshimaHoliday),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Odakyu.Enoshima.SagamiOno", .descending,
                    "小田急小田原線", "Odakyu Odawara Line",
                    "町田・新宿方面", "for Machida & Shinjuku",
                    to: "odpt.Railway:Odakyu.Odawara"),
        ]
    )

    // MARK: Odakyu Tama Line (OT)

    private static let tamaWeekday = pattern("05:00", "24:00", [
        ("05:00", 10), ("06:30", 6), ("09:30", 10), ("16:30", 8), ("20:00", 10), ("22:00", 12),
    ])
    private static let tamaHoliday = pattern("05:00", "24:00", [
        ("05:00", 10), ("07:00", 8), ("10:00", 10), ("20:00", 11),
    ])

    static let tama = StaticTrainLine(
        id: "odpt.Railway:Odakyu.Tama",
        nameJa: "小田急多摩線",
        nameEn: "Odakyu Tama Line",
        operatorId: "odpt.Operator:Odakyu",
        colorHex: "#00A5E3",
        stations: [
            st("Odakyu.Tama", "ShinYurigaoka", "新百合ヶ丘", "Shin-Yurigaoka", "OH23", 35.6039, 139.5083),
            st("Odakyu.Tama", "Satsukidai", "五月台", "Satsukidai", "OT01", 35.6008, 139.4979),
            st("Odakyu.Tama", "Kurihira", "栗平", "Kurihira", "OT02", 35.5983, 139.4855),
            st("Odakyu.Tama", "Kurokawa", "黒川", "Kurokawa", "OT03", 35.5985, 139.4732),
            st("Odakyu.Tama", "Haruhino", "はるひ野", "Haruhino", "OT04", 35.5990, 139.4635),
            st("Odakyu.Tama", "OdakyuNagayama", "小田急永山", "Odakyu-Nagayama", "OT05", 35.6187, 139.4462),
            st("Odakyu.Tama", "OdakyuTamaCenter", "小田急多摩センター", "Odakyu-Tama-Center", "OT06", 35.6244, 139.4243),
            st("Odakyu.Tama", "Karakida", "唐木田", "Karakida", "OT07", 35.6146, 139.4110),
        ],
        hopTimesMinutes: [3, 2, 2, 2, 3, 3, 3],
        directions: [
            direction("Odakyu.Tama", "Karakida", "唐木田方面", "For Karakida", ascending: true,
                      weekday: tamaWeekday, holiday: tamaHoliday),
            direction("Odakyu.Tama", "ShinYurigaoka", "新百合ヶ丘方面", "For Shin-Yurigaoka", ascending: false,
                      weekday: tamaWeekday, holiday: tamaHoliday),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Odakyu.Tama.ShinYurigaoka", .descending,
                    "小田急小田原線", "Odakyu Odawara Line",
                    "新宿・千代田線方面", "for Shinjuku & the Chiyoda Line",
                    to: "odpt.Railway:Odakyu.Odawara"),
        ]
    )
}
