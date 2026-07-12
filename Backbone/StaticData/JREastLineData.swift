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

/// Chuo Rapid exact run: terminus suffix resolves to a ChuoRapid station id;
/// `thru: true` marks a run entering the line mid-way (中央本線から at 高尾,
/// 青梅線から at 立川) rather than originating there (当駅始発); `cont: true`
/// marks a run continuing beyond its last in-line station onto another line
/// (青梅行き leaving at 立川, or 大月方面 continuing past 高尾).
private func jc(_ dep: String, to: String? = nil, thru: Bool = false, cont: Bool = false) -> ExactRun {
    ExactRun(dep, terminusStationId: to.map { "Station:JR-East.ChuoRapid.\($0)" },
             startsHere: !thru, continuesBeyond: cont)
}

/// Chuo-Sobu Local exact run: terminus suffix resolves to a ChuoSobuLocal
/// station id; `thru: true` marks a run entering the line mid-way (東西線から
/// at 中野/西船橋); `cont: true` marks a run leaving onto the 東西線 mid-line.
private func jb(_ dep: String, to: String? = nil, thru: Bool = false, cont: Bool = false) -> ExactRun {
    ExactRun(dep, terminusStationId: to.map { "Station:JR-East.ChuoSobuLocal.\($0)" },
             startsHere: !thru, continuesBeyond: cont)
}

/// Keihin-Tohoku exact run: terminus suffix resolves to a KeihinTohoku
/// station id; `thru: true` marks a run entering from the 横浜線 at 東神奈川;
/// `cont: true` marks a run leaving onto the 横浜線 there.
private func jk(_ dep: String, to: String? = nil, thru: Bool = false, cont: Bool = false) -> ExactRun {
    ExactRun(dep, terminusStationId: to.map { "Station:JR-East.KeihinTohoku.\($0)" },
             startsHere: !thru, continuesBeyond: cont)
}

/// Pattern backed by real exact runs; first/last are informative only.
private func exact(_ runs: [ExactRun], first: String, last: String,
                   _ type: TrainService.TrainType = .local) -> ServicePattern {
    ServicePattern(first: first, last: last, bands: [], trainType: type, exactRuns: runs)
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
        // All 2 except 大塚→池袋 and 大崎→品川, measured 3 (July-2026 pairs).
        hopTimesMinutes: [
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2,
        ],
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.Yamanote.InnerLoop",
                nameJa: "内回り（上野・池袋方面）",
                nameEn: "Inner Loop (for Ueno & Ikebukuro)",
                isAscending: true,
                weekday: ServicePattern(
                    first: "04:46", last: "24:38",
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
                    first: "04:46", last: "24:39",
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
                    first: "04:51", last: "24:48",
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
                    first: "04:51", last: "24:48",
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
        // Measured from real July-2026 train pairs (median dep-to-dep, both
        // directions): 御茶ノ水→四ツ谷 5, 吉祥寺→三鷹 3, 豊田→八王子 5,
        // 八王子→西八王子 3, 西八王子→高尾 3; the 新宿 hops take the lower
        // directional median (dwell inflates the other side).
        hopTimesMinutes: [
            2, 2, 5, 4, 4, 2, 2, 2, 2, 2, 3, 2,
            2, 2, 3, 2, 2, 3, 3, 3, 5, 3, 3,
        ],
        // Real per-station times per run (658 grid), incl. holiday 快速 skips
        // of 高円寺/阿佐ケ谷/西荻窪 (negative sentinel) → 1:1 station timetables.
        exactStationTimes: chuoRapidExactTimes,
        // Real exact runs, July-2026 revision (timetables.jreast.co.jp).
        // 快速 only: 中央特快・青梅特快・通勤快速・特急・むさしの号 are
        // excluded (their stop patterns skip stations the all-stops line
        // model cannot express). Per-train termini are honored: down trains
        // run to 高尾/八王子/豊田/立川/国分寺/武蔵小金井, with 青梅線直通
        // (青梅行き) modeled as terminating at the 立川 junction; up trains
        // mostly reach 東京 but late-night runs end at 三鷹/武蔵小金井.
        // Runs entering mid-line (中央本線から at 高尾, 青梅線から at 立川)
        // carry thru: true (not 当駅始発).
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.ChuoRapid.Takao",
                nameJa: "高尾方面",
                nameEn: "For Takao",
                isAscending: true,
                weekday: exact(chuoRapidDownTokyoWd, first: "04:38", last: "24:06", .rapid),
                saturdayHoliday: exact(chuoRapidDownTokyoHol, first: "04:38", last: "24:06", .rapid),
                intermediateOrigins: [
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoRapid.Mitaka",
                                       weekdayRuns: chuoRapidDownMitakaWd,
                                       saturdayHolidayRuns: chuoRapidDownMitakaHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoRapid.MusashiKoganei",
                                       weekdayRuns: chuoRapidDownMusashiKoganeiWd,
                                       saturdayHolidayRuns: chuoRapidDownMusashiKoganeiHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoRapid.Tachikawa",
                                       weekdayRuns: chuoRapidDownTachikawaWd,
                                       saturdayHolidayRuns: chuoRapidDownTachikawaHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoRapid.Toyoda",
                                       weekdayRuns: chuoRapidDownToyodaWd,
                                       saturdayHolidayRuns: chuoRapidDownToyodaHol),
                ]
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.ChuoRapid.Tokyo",
                nameJa: "東京方面",
                nameEn: "For Tokyo",
                isAscending: false,
                weekday: exact(chuoRapidUpTakaoWd, first: "04:27", last: "24:13", .rapid),
                saturdayHoliday: exact(chuoRapidUpTakaoHol, first: "04:27", last: "24:13", .rapid),
                intermediateOrigins: [
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoRapid.Hachioji",
                                       weekdayRuns: chuoRapidUpHachiojiWd,
                                       saturdayHolidayRuns: chuoRapidUpHachiojiHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoRapid.Toyoda",
                                       weekdayRuns: chuoRapidUpToyodaWd,
                                       saturdayHolidayRuns: chuoRapidUpToyodaHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoRapid.Tachikawa",
                                       weekdayRuns: chuoRapidUpTachikawaWd,
                                       saturdayHolidayRuns: chuoRapidUpTachikawaHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoRapid.Kokubunji",
                                       weekdayRuns: chuoRapidUpKokubunjiWd,
                                       saturdayHolidayRuns: chuoRapidUpKokubunjiHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoRapid.MusashiKoganei",
                                       weekdayRuns: chuoRapidUpMusashiKoganeiWd,
                                       saturdayHolidayRuns: chuoRapidUpMusashiKoganeiHol),
                ]
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


    // MARK: - Chuo Rapid Real Runs (July-2026 revision)

    private static let chuoRapidDownTokyoWd: [ExactRun] = [
        jc("04:38"), jc("04:59"), jc("05:18"), jc("05:29"),
        jc("05:42"), jc("05:53"), jc("06:05"), jc("06:17"),
        jc("06:22", to: "Tachikawa", cont: true), jc("06:31"), jc("06:37"), jc("06:45"),
        jc("06:51", to: "Tachikawa", cont: true), jc("06:56"), jc("07:01"), jc("07:04", to: "Hachioji"),
        jc("07:08"), jc("07:14"), jc("07:20"), jc("07:23", to: "MusashiKoganei"),
        jc("07:26"), jc("07:29", to: "Tachikawa", cont: true), jc("07:34"), jc("07:36", to: "MusashiKoganei"),
        jc("07:40"), jc("07:43", to: "Tachikawa", cont: true), jc("07:46"), jc("07:50", to: "MusashiKoganei"),
        jc("07:55"), jc("07:57", to: "Tachikawa", cont: true), jc("08:00"), jc("08:02", to: "Toyoda"),
        jc("08:04", to: "Tachikawa", cont: true), jc("08:07"), jc("08:09", to: "MusashiKoganei"), jc("08:12"),
        jc("08:15", to: "Toyoda"), jc("08:17"), jc("08:20", to: "Tachikawa"), jc("08:22", to: "MusashiKoganei"),
        jc("08:24", to: "Toyoda"), jc("08:26"), jc("08:28", to: "Tachikawa", cont: true), jc("08:30", to: "Toyoda"),
        jc("08:33", to: "MusashiKoganei"), jc("08:35", to: "Toyoda"), jc("08:37"), jc("08:39", to: "Toyoda"),
        jc("08:41", to: "MusashiKoganei"), jc("08:43", to: "Tachikawa", cont: true), jc("08:46"), jc("08:48", to: "MusashiKoganei"),
        jc("08:50", to: "Toyoda"), jc("08:52", to: "Hachioji"), jc("08:54", cont: true), jc("08:57", to: "MusashiKoganei"),
        jc("08:59", to: "Toyoda"), jc("09:03"), jc("09:08", to: "Tachikawa", cont: true), jc("09:10", to: "MusashiKoganei"),
        jc("09:12"), jc("09:14", to: "MusashiKoganei"), jc("09:16", to: "Toyoda"), jc("09:20"),
        jc("09:22", to: "Tachikawa", cont: true), jc("09:25", to: "Toyoda"), jc("09:27", to: "MusashiKoganei"), jc("09:30"),
        jc("09:38", to: "MusashiKoganei"), jc("09:41", to: "Tachikawa", cont: true), jc("09:43"), jc("09:45", to: "Toyoda"),
        jc("09:50", to: "Tachikawa", cont: true), jc("09:56", to: "Toyoda"), jc("09:58", to: "MusashiKoganei"), jc("10:00"),
        jc("10:10"), jc("10:14", to: "Tachikawa", cont: true), jc("10:23", to: "Tachikawa"), jc("10:27"),
        jc("10:34", to: "Tachikawa"), jc("10:37", to: "Tachikawa", cont: true), jc("10:43"), jc("10:49", to: "Toyoda"),
        jc("10:57"), jc("11:01", to: "Toyoda"), jc("11:09", to: "Tachikawa", cont: true), jc("11:13"),
        jc("11:19"), jc("11:29", to: "Tachikawa", cont: true), jc("11:38", to: "Hachioji"), jc("11:43", to: "Tachikawa", cont: true),
        jc("11:50", to: "Toyoda"), jc("11:57"), jc("12:05", to: "Tachikawa", cont: true), jc("12:09"),
        jc("12:17", to: "Toyoda"), jc("12:25"), jc("12:29", to: "Toyoda"), jc("12:38"),
        jc("12:43", to: "Tachikawa", cont: true), jc("12:55", to: "Tachikawa", cont: true), jc("12:59"), jc("13:03", to: "Tachikawa"),
        jc("13:10", to: "Tachikawa", cont: true), jc("13:17"), jc("13:25", to: "Toyoda"), jc("13:30"),
        jc("13:40", to: "Tachikawa", cont: true), jc("13:45", to: "Toyoda"), jc("13:55"), jc("13:59", to: "Tachikawa", cont: true),
        jc("14:09"), jc("14:15"), jc("14:23", to: "Tachikawa", cont: true), jc("14:28", to: "Tachikawa"),
        jc("14:37"), jc("14:42", to: "Tachikawa", cont: true), jc("14:47", to: "Toyoda"), jc("14:55", to: "Hachioji"),
        jc("14:59"), jc("15:07", to: "Tachikawa", cont: true), jc("15:12"), jc("15:17", cont: true),
        jc("15:24"), jc("15:32", to: "Tachikawa", cont: true), jc("15:38"), jc("15:45", to: "Tachikawa", cont: true),
        jc("15:55"), jc("16:06", to: "Tachikawa", cont: true), jc("16:09"), jc("16:17", to: "Tachikawa", cont: true),
        jc("16:20"), jc("16:24"), jc("16:32", to: "Hachioji"), jc("16:35", to: "Tachikawa", cont: true),
        jc("16:40"), jc("16:47"), jc("16:51"), jc("16:57", to: "Tachikawa", cont: true),
        jc("17:00", to: "MusashiKoganei"), jc("17:03"), jc("17:05", to: "Hachioji"), jc("17:07"),
        jc("17:12"), jc("17:17", to: "Toyoda"), jc("17:22", to: "MusashiKoganei"), jc("17:25"),
        jc("17:27", to: "MusashiKoganei"), jc("17:32", cont: true), jc("17:34", to: "Tachikawa", cont: true), jc("17:37"),
        jc("17:41"), jc("17:47", to: "Tachikawa", cont: true), jc("17:49"), jc("17:52", to: "MusashiKoganei"),
        jc("17:58", to: "Tachikawa", cont: true), jc("18:00"), jc("18:03", to: "Toyoda"), jc("18:08", to: "MusashiKoganei"),
        jc("18:13", to: "Tachikawa", cont: true), jc("18:17", to: "Toyoda"), jc("18:23"), jc("18:26"),
        jc("18:28", to: "Tachikawa"), jc("18:34"), jc("18:36", to: "MusashiKoganei"), jc("18:41", to: "Tachikawa", cont: true),
        jc("18:47"), jc("18:50", to: "Tachikawa", cont: true), jc("18:55"), jc("18:58", to: "Tachikawa", cont: true),
        jc("19:01"), jc("19:08", to: "Tachikawa", cont: true), jc("19:12"), jc("19:17", to: "Tachikawa"),
        jc("19:20", to: "Tachikawa", cont: true), jc("19:27", to: "Toyoda"), jc("19:30"), jc("19:36", to: "Tachikawa", cont: true),
        jc("19:39"), jc("19:43", to: "Tachikawa", cont: true), jc("19:48"), jc("19:54", to: "Tachikawa"),
        jc("19:57"), jc("20:00", to: "Tachikawa", cont: true), jc("20:09"), jc("20:15"),
        jc("20:19", to: "Tachikawa", cont: true), jc("20:25", to: "Toyoda"), jc("20:30"), jc("20:35", to: "Tachikawa"),
        jc("20:39"), jc("20:47", to: "Tachikawa", cont: true), jc("20:54", to: "Tachikawa"), jc("20:58"),
        jc("21:06", to: "Tachikawa", cont: true), jc("21:11"), jc("21:14"), jc("21:18", to: "Toyoda"),
        jc("21:25"), jc("21:31"), jc("21:38", to: "Toyoda"), jc("21:43"),
        jc("21:49", to: "Toyoda"), jc("21:55", to: "Toyoda"), jc("22:00"), jc("22:10"),
        jc("22:14", to: "Tachikawa", cont: true), jc("22:21"), jc("22:26", to: "Tachikawa", cont: true), jc("22:31"),
        jc("22:38", to: "Toyoda"), jc("22:43", to: "Tachikawa"), jc("22:47"), jc("22:55", to: "Toyoda"),
        jc("23:01", to: "Toyoda"), jc("23:08"), jc("23:18", to: "Toyoda"), jc("23:24", to: "Toyoda"),
        jc("23:27", to: "Tachikawa", cont: true), jc("23:36"), jc("23:40", to: "Toyoda"), jc("23:45"),
        jc("23:50", to: "Toyoda"), jc("23:56", to: "Toyoda"), jc("24:06", to: "MusashiKoganei"),
    ]

    private static let chuoRapidDownTokyoHol: [ExactRun] = [
        jc("04:38"), jc("04:59"), jc("05:18"), jc("05:29"),
        jc("05:43"), jc("05:55"), jc("06:10"), jc("06:20"),
        jc("06:25"), jc("06:34", to: "Tachikawa", cont: true), jc("06:39"), jc("06:50", to: "Tachikawa"),
        jc("06:56"), jc("07:01"), jc("07:09"), jc("07:15"),
        jc("07:20", to: "Toyoda"), jc("07:25", to: "Tachikawa", cont: true), jc("07:32", to: "MusashiKoganei"), jc("07:40"),
        jc("07:45"), jc("07:51", to: "Tachikawa", cont: true), jc("07:59"), jc("08:03", to: "Tachikawa", cont: true),
        jc("08:11"), jc("08:14"), jc("08:18", to: "Toyoda"), jc("08:26", to: "Tachikawa"),
        jc("08:30"), jc("08:39"), jc("08:45"), jc("08:53", to: "Tachikawa", cont: true),
        jc("08:56", to: "MusashiKoganei"), jc("08:58", to: "Toyoda"), jc("09:03", to: "Tachikawa", cont: true), jc("09:12"),
        jc("09:16", to: "Hachioji"), jc("09:19"), jc("09:22", to: "Tachikawa", cont: true), jc("09:26", to: "Tachikawa", cont: true),
        jc("09:31"), jc("09:40", to: "Hachioji"), jc("09:45"), jc("09:51", to: "Tachikawa"),
        jc("09:58", to: "Hachioji"), jc("10:07"), jc("10:12"), jc("10:16", to: "MusashiKoganei"),
        jc("10:23", to: "Tachikawa", cont: true), jc("10:28", to: "Toyoda"), jc("10:36"), jc("10:41", to: "Tachikawa", cont: true),
        jc("10:47"), jc("10:55"), jc("11:02", to: "Tachikawa", cont: true), jc("11:09"),
        jc("11:17", to: "Tachikawa"), jc("11:24"), jc("11:33", to: "Toyoda"), jc("11:41", to: "Tachikawa", cont: true),
        jc("11:48", to: "Toyoda"), jc("11:55", to: "Tachikawa"), jc("12:01"), jc("12:09"),
        jc("12:15", to: "Hachioji"), jc("12:24", to: "Toyoda"), jc("12:32", to: "Tachikawa", cont: true), jc("12:40", to: "Tachikawa"),
        jc("12:46"), jc("12:54"), jc("13:02", to: "Tachikawa"), jc("13:11", to: "Toyoda"),
        jc("13:17"), jc("13:27"), jc("13:33", to: "Tachikawa"), jc("13:40", to: "Tachikawa", cont: true),
        jc("13:46"), jc("13:54", to: "Hachioji"), jc("14:03", to: "Tachikawa", cont: true), jc("14:12"),
        jc("14:17", to: "Tachikawa", cont: true), jc("14:27"), jc("14:31", to: "Tachikawa", cont: true), jc("14:38", to: "Tachikawa"),
        jc("14:43", to: "Toyoda"), jc("14:47"), jc("14:54", to: "Toyoda"), jc("15:02", to: "Tachikawa", cont: true),
        jc("15:11"), jc("15:17"), jc("15:26", cont: true), jc("15:33"),
        jc("15:40", to: "Tachikawa", cont: true), jc("15:46"), jc("15:54", to: "MusashiKoganei"), jc("16:04"),
        jc("16:09", to: "Tachikawa", cont: true), jc("16:13", to: "Tachikawa"), jc("16:18", to: "Tachikawa", cont: true), jc("16:27"),
        jc("16:35"), jc("16:38", to: "Tachikawa", cont: true), jc("16:42"), jc("16:48"),
        jc("16:52"), jc("17:00"), jc("17:03", to: "MusashiKoganei"), jc("17:09", to: "Tachikawa", cont: true),
        jc("17:13", to: "Hachioji"), jc("17:20", to: "Tachikawa", cont: true), jc("17:25"), jc("17:33"),
        jc("17:37", to: "Toyoda"), jc("17:42"), jc("17:47", to: "Tachikawa", cont: true), jc("17:55"),
        jc("18:02", to: "Tachikawa", cont: true), jc("18:07"), jc("18:11", to: "Tachikawa", cont: true), jc("18:17"),
        jc("18:25", to: "Tachikawa", cont: true), jc("18:29"), jc("18:34", to: "Tachikawa", cont: true), jc("18:40", to: "MusashiKoganei"),
        jc("18:47", cont: true), jc("18:50", to: "Toyoda"), jc("18:57"), jc("19:01", to: "Hachioji"),
        jc("19:06"), jc("19:13", to: "Tachikawa", cont: true), jc("19:18"), jc("19:21", to: "Tachikawa", cont: true),
        jc("19:26"), jc("19:32"), jc("19:36", to: "Tachikawa", cont: true), jc("19:40"),
        jc("19:48", to: "Tachikawa", cont: true), jc("19:52", to: "Toyoda"), jc("20:01", to: "Hachioji"), jc("20:05"),
        jc("20:13", to: "Tachikawa"), jc("20:17", to: "Tachikawa", cont: true), jc("20:22", to: "Hachioji"), jc("20:29"),
        jc("20:37"), jc("20:42"), jc("20:48", to: "Tachikawa", cont: true), jc("20:54"),
        jc("21:01", to: "Tachikawa"), jc("21:04", to: "Toyoda"), jc("21:07", to: "Tachikawa", cont: true), jc("21:11"),
        jc("21:19", to: "Tachikawa", cont: true), jc("21:24"), jc("21:29", to: "Toyoda"), jc("21:40"),
        jc("21:47", to: "Toyoda"), jc("21:56"), jc("22:03", to: "Toyoda"), jc("22:13"),
        jc("22:16", to: "MusashiKoganei"), jc("22:19", to: "Tachikawa", cont: true), jc("22:23"), jc("22:28", to: "Tachikawa", cont: true),
        jc("22:38"), jc("22:42", to: "MusashiKoganei"), jc("22:51", to: "Tachikawa"), jc("22:55", to: "Kokubunji"),
        jc("23:04"), jc("23:10", cont: true), jc("23:17", to: "Toyoda"), jc("23:24"),
        jc("23:30", to: "Tachikawa", cont: true), jc("23:35"), jc("23:41", to: "Toyoda"), jc("23:47"),
        jc("23:53", to: "Toyoda"), jc("24:00", to: "Toyoda"), jc("24:06", to: "MusashiKoganei"),
    ]

    private static let chuoRapidDownMitakaWd: [ExactRun] = [
        jc("04:39", cont: true), jc("04:58"),
    ]

    private static let chuoRapidDownMitakaHol: [ExactRun] = [
        jc("04:39", cont: true), jc("04:58"),
    ]

    private static let chuoRapidDownMusashiKoganeiWd: [ExactRun] = [
        jc("04:29"), jc("05:30"), jc("05:54", to: "Tachikawa", cont: true), jc("06:12", to: "Tachikawa", cont: true),
        jc("06:25", to: "Tachikawa", cont: true), jc("06:41", to: "Tachikawa", cont: true), jc("06:54"), jc("07:17", to: "Tachikawa", cont: true),
    ]

    private static let chuoRapidDownMusashiKoganeiHol: [ExactRun] = [
        jc("04:29"), jc("05:12", cont: true), jc("05:27"), jc("07:24", to: "Tachikawa", cont: true),
    ]

    private static let chuoRapidDownTachikawaWd: [ExactRun] = [
        jc("05:25", cont: true),
    ]

    private static let chuoRapidDownTachikawaHol: [ExactRun] = [
        jc("06:10", cont: true),
    ]

    private static let chuoRapidDownToyodaWd: [ExactRun] = [
        jc("06:07"),
    ]

    private static let chuoRapidDownToyodaHol: [ExactRun] = [
    ]

    private static let chuoRapidUpTakaoWd: [ExactRun] = [
        jc("04:27"), jc("04:57"), jc("05:08"), jc("05:22"),
        jc("05:38"), jc("05:48"), jc("06:06"), jc("06:18"),
        jc("06:26"), jc("06:31"), jc("06:37", thru: true), jc("06:46"),
        jc("06:50"), jc("06:59"), jc("07:06"), jc("07:12"),
        jc("07:18"), jc("07:24"), jc("07:31", thru: true), jc("07:34"),
        jc("07:39"), jc("07:46"), jc("07:50"), jc("07:52", thru: true),
        jc("08:01"), jc("08:04", thru: true), jc("08:08"), jc("08:15"),
        jc("08:21"), jc("08:31"), jc("08:41"), jc("08:44"),
        jc("08:54"), jc("08:59"), jc("09:08"), jc("09:26"),
        jc("09:37"), jc("09:50"), jc("09:59"), jc("10:10"),
        jc("10:39"), jc("10:48"), jc("10:59"), jc("11:05"),
        jc("11:35"), jc("12:02"), jc("12:24"), jc("13:01"),
        jc("13:09"), jc("14:00"), jc("14:08"), jc("14:21"),
        jc("15:07"), jc("15:20"), jc("15:38"), jc("15:54"),
        jc("16:06"), jc("16:13"), jc("16:23"), jc("16:38"),
        jc("16:46"), jc("16:53"), jc("16:57", thru: true), jc("17:11"),
        jc("17:16"), jc("17:31"), jc("17:37"), jc("17:41"),
        jc("17:59"), jc("18:12"), jc("18:17"), jc("18:27"),
        jc("18:36"), jc("18:39"), jc("18:43"), jc("18:49"),
        jc("19:00"), jc("19:06"), jc("19:24", thru: true), jc("19:31"),
        jc("19:41"), jc("19:51"), jc("20:01"), jc("20:18", thru: true),
        jc("20:25"), jc("20:32", thru: true), jc("20:51"), jc("20:55"),
        jc("21:03"), jc("21:16"), jc("21:22"), jc("21:33", thru: true),
        jc("21:39"), jc("21:46"), jc("21:55"), jc("22:04"),
        jc("22:16"), jc("22:29", thru: true), jc("22:35"), jc("22:41"),
        jc("22:51"), jc("23:02"), jc("23:19"), jc("23:34", to: "Mitaka"),
        jc("23:50", to: "Mitaka"), jc("24:13", to: "MusashiKoganei"),
    ]

    private static let chuoRapidUpTakaoHol: [ExactRun] = [
        jc("04:27"), jc("04:57"), jc("05:09"), jc("05:23"),
        jc("05:41"), jc("06:00"), jc("06:08"), jc("06:18"),
        jc("06:36", thru: true), jc("06:42"), jc("06:50"), jc("06:58"),
        jc("07:09"), jc("07:27"), jc("07:41"), jc("07:45"),
        jc("07:51"), jc("07:56", thru: true), jc("08:08"), jc("08:12"),
        jc("08:18"), jc("08:23"), jc("08:38"), jc("08:42"),
        jc("08:53"), jc("09:01"), jc("09:17"), jc("09:31"),
        jc("09:37"), jc("09:48"), jc("10:44"), jc("10:57"),
        jc("11:17"), jc("11:34"), jc("11:58"), jc("12:14"),
        jc("12:21"), jc("13:13"), jc("13:19"), jc("13:59"),
        jc("14:12"), jc("14:19"), jc("14:35"), jc("15:00"),
        jc("15:20"), jc("15:33"), jc("15:39"), jc("15:50"),
        jc("16:10"), jc("16:14"), jc("16:35"), jc("16:38"),
        jc("17:03"), jc("17:07"), jc("17:16"), jc("17:33"),
        jc("17:37"), jc("17:43"), jc("17:58"), jc("18:08"),
        jc("18:17", thru: true), jc("18:23"), jc("18:39"), jc("18:53"),
        jc("19:01"), jc("19:23"), jc("19:34", thru: true), jc("19:39"),
        jc("19:52"), jc("20:01"), jc("20:27"), jc("20:31", thru: true),
        jc("20:39"), jc("20:45"), jc("20:55"), jc("21:16"),
        jc("21:23"), jc("21:38"), jc("21:50"), jc("21:55"),
        jc("22:01"), jc("22:09"), jc("22:22"), jc("22:28", thru: true),
        jc("22:35"), jc("22:40"), jc("22:53"), jc("23:03"),
        jc("23:20"), jc("23:33", to: "Mitaka"), jc("23:50", to: "Mitaka"), jc("24:13", to: "MusashiKoganei"),
    ]

    private static let chuoRapidUpHachiojiWd: [ExactRun] = [
        jc("07:02"), jc("07:17"), jc("07:35"), jc("08:19"),
        jc("10:24"), jc("12:53"), jc("16:18"), jc("17:59"),
        jc("18:26"),
    ]

    private static let chuoRapidUpHachiojiHol: [ExactRun] = [
        jc("10:30"), jc("11:00"), jc("11:16"), jc("13:42"),
        jc("15:19"), jc("18:26"), jc("20:21"), jc("21:17"),
        jc("21:49"),
    ]

    private static let chuoRapidUpToyodaWd: [ExactRun] = [
        jc("04:26"), jc("04:48"), jc("05:13"), jc("05:24"),
        jc("05:28"), jc("05:44"), jc("06:03"), jc("06:25"),
        jc("06:54"), jc("07:16"), jc("07:34"), jc("09:42"),
        jc("11:02"), jc("12:02"), jc("12:19"), jc("12:32"),
        jc("13:01"), jc("13:28"), jc("13:43"), jc("14:39"),
        jc("14:59"), jc("15:39"), jc("16:02"), jc("16:40"),
        jc("16:55"), jc("17:21"), jc("17:36"), jc("18:44"),
        jc("19:32"), jc("20:40"),
    ]

    private static let chuoRapidUpToyodaHol: [ExactRun] = [
        jc("04:28"), jc("04:49"), jc("05:24"), jc("05:39"),
        jc("06:02"), jc("06:18"), jc("06:50"), jc("07:17"),
        jc("07:32"), jc("09:30"), jc("10:17"), jc("11:43"),
        jc("11:59"), jc("12:44"), jc("13:09"), jc("13:51"),
        jc("15:11"), jc("18:03"), jc("19:32"), jc("19:58"),
    ]

    private static let chuoRapidUpTachikawaWd: [ExactRun] = [
        jc("05:04", thru: true), jc("06:04", thru: true), jc("06:22", thru: true), jc("06:43", thru: true),
        jc("06:54", thru: true), jc("07:03", thru: true), jc("07:16", thru: true), jc("07:28", thru: true),
        jc("07:35", thru: true), jc("07:39", thru: true), jc("07:46", thru: true), jc("07:55", thru: true),
        jc("08:01", thru: true), jc("08:17", thru: true), jc("08:38", thru: true), jc("08:50", thru: true),
        jc("09:06", thru: true), jc("09:30"), jc("09:37", thru: true), jc("09:54", thru: true),
        jc("10:15", thru: true), jc("10:39", thru: true), jc("10:49", thru: true), jc("11:26", thru: true),
        jc("11:32"), jc("11:41"), jc("11:55", thru: true), jc("12:05", thru: true),
        jc("12:18", thru: true), jc("12:55", thru: true), jc("13:17", thru: true), jc("13:42", thru: true),
        jc("13:56", thru: true), jc("14:06"), jc("14:17", thru: true), jc("14:56", thru: true),
        jc("15:13", thru: true), jc("15:18", thru: true), jc("15:39"), jc("15:54", thru: true),
        jc("16:16", thru: true), jc("16:28", thru: true), jc("16:43", thru: true), jc("16:53", thru: true),
        jc("17:24", thru: true), jc("17:46", thru: true), jc("18:04", thru: true), jc("18:15", thru: true),
        jc("18:29", thru: true), jc("19:12", thru: true), jc("19:27", thru: true), jc("19:33"),
        jc("19:36", thru: true), jc("19:48", thru: true), jc("20:05", thru: true), jc("20:16", thru: true),
        jc("20:23"), jc("20:30", thru: true), jc("20:35", thru: true), jc("20:54"),
        jc("21:04", thru: true), jc("21:19", thru: true), jc("21:27", thru: true), jc("21:41"),
        jc("21:48", thru: true), jc("21:57", thru: true), jc("22:16", thru: true), jc("22:37", thru: true),
        jc("23:04", to: "MusashiKoganei", thru: true), jc("23:13", to: "Mitaka", thru: true),
    ]

    private static let chuoRapidUpTachikawaHol: [ExactRun] = [
        jc("05:04", thru: true), jc("05:57", thru: true), jc("06:36", thru: true), jc("06:48", thru: true),
        jc("07:19", thru: true), jc("07:30", thru: true), jc("07:53"), jc("08:13", thru: true),
        jc("08:48", thru: true), jc("09:25", thru: true), jc("09:31"), jc("09:47", thru: true),
        jc("10:13", thru: true), jc("10:17", thru: true), jc("10:33", thru: true), jc("10:51", thru: true),
        jc("10:57"), jc("11:01", thru: true), jc("11:43", thru: true), jc("12:22", thru: true),
        jc("12:28"), jc("12:57"), jc("13:07", thru: true), jc("13:23", thru: true),
        jc("13:46"), jc("14:07", thru: true), jc("14:13"), jc("14:43"),
        jc("14:50", thru: true), jc("15:07", thru: true), jc("15:44"), jc("15:54", thru: true),
        jc("16:05", thru: true), jc("16:18", thru: true), jc("16:39", thru: true), jc("16:45", thru: true),
        jc("17:01", thru: true), jc("17:10", thru: true), jc("17:15"), jc("17:46", thru: true),
        jc("18:24", thru: true), jc("18:52", thru: true), jc("19:08", thru: true), jc("19:25", thru: true),
        jc("19:32", thru: true), jc("20:12", thru: true), jc("20:23", thru: true), jc("20:37", thru: true),
        jc("20:57", thru: true), jc("21:09", thru: true), jc("21:16"), jc("21:25", thru: true),
        jc("21:31", thru: true), jc("21:47", thru: true),
        jc("22:04"), jc("23:05", thru: true),
    ]

    private static let chuoRapidUpKokubunjiWd: [ExactRun] = [
    ]

    private static let chuoRapidUpKokubunjiHol: [ExactRun] = [
        jc("05:44"),
    ]

    private static let chuoRapidUpMusashiKoganeiWd: [ExactRun] = [
        jc("04:32"), jc("06:47"), jc("06:54"), jc("07:31"),
        jc("08:12"), jc("08:28"), jc("08:42"), jc("08:59"),
        jc("16:14"), jc("16:25"), jc("16:36"), jc("16:44"),
        jc("17:06"), jc("17:16"), jc("17:23"), jc("17:37"),
        jc("17:51"), jc("18:20"), jc("18:47"), jc("19:08"),
    ]

    private static let chuoRapidUpMusashiKoganeiHol: [ExactRun] = [
        jc("04:33"), jc("09:07"), jc("16:36"), jc("17:49"),
        jc("18:28"), jc("19:03"), jc("19:52"),
    ]

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
        // Measured from real July-2026 train pairs (median dep-to-dep, both
        // directions): 三鷹〜西荻窪 3/hop, 両国→錦糸町 3, 東船橋→津田沼 3,
        // 幕張本郷→幕張 3, 稲毛→西千葉 2.
        hopTimesMinutes: [
            3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
            2, 3, 2, 3, 3, 3, 3, 3, 2, 2, 3, 2, 3, 3, 3, 2, 3, 2, 2,
        ],
        // Real per-station times per run (659 grid) → 1:1 station timetables.
        exactStationTimes: chuoSobuLocalExactTimes,
        // Real exact runs, July-2026 revision (timetables.jreast.co.jp).
        // Per-train termini are honored: 千葉/三鷹 full runs plus 中野・津田沼
        // turnbacks, late-night 御茶ノ水行き, and 東西線直通 runs leaving at
        // 西船橋 (下り) or 中野 (上り), both marked cont. Runs entering from
        // the 東西線 at 中野/西船橋 carry thru: true (not 当駅始発). 東西線内
        // running segments (中野〜西船橋 via 大手町) are not part of this line.
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.ChuoSobuLocal.Chiba",
                nameJa: "千葉方面",
                nameEn: "For Chiba",
                isAscending: true,
                weekday: exact(sobuLocalUpMitakaWd, first: "04:35", last: "24:34"),
                saturdayHoliday: exact(sobuLocalUpMitakaHol, first: "04:35", last: "24:34"),
                intermediateOrigins: [
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoSobuLocal.Nakano",
                                       weekdayRuns: sobuLocalUpNakanoWd,
                                       saturdayHolidayRuns: sobuLocalUpNakanoHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoSobuLocal.Ochanomizu",
                                       weekdayRuns: sobuLocalUpOchanomizuWd,
                                       saturdayHolidayRuns: sobuLocalUpOchanomizuHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoSobuLocal.NishiFunabashi",
                                       weekdayRuns: sobuLocalUpNishiFunabashiWd,
                                       saturdayHolidayRuns: sobuLocalUpNishiFunabashiHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoSobuLocal.Tsudanuma",
                                       weekdayRuns: sobuLocalUpTsudanumaWd,
                                       saturdayHolidayRuns: sobuLocalUpTsudanumaHol),
                ]
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.ChuoSobuLocal.Mitaka",
                nameJa: "三鷹方面",
                nameEn: "For Mitaka",
                isAscending: false,
                weekday: exact(sobuLocalDownChibaWd, first: "04:28", last: "24:30"),
                saturdayHoliday: exact(sobuLocalDownChibaHol, first: "04:28", last: "24:30"),
                intermediateOrigins: [
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoSobuLocal.Makuhari",
                                       weekdayRuns: sobuLocalDownMakuhariWd,
                                       saturdayHolidayRuns: sobuLocalDownMakuhariHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoSobuLocal.Tsudanuma",
                                       weekdayRuns: sobuLocalDownTsudanumaWd,
                                       saturdayHolidayRuns: sobuLocalDownTsudanumaHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoSobuLocal.NishiFunabashi",
                                       weekdayRuns: sobuLocalDownNishiFunabashiWd,
                                       saturdayHolidayRuns: sobuLocalDownNishiFunabashiHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoSobuLocal.Ochanomizu",
                                       weekdayRuns: sobuLocalDownOchanomizuWd,
                                       saturdayHolidayRuns: sobuLocalDownOchanomizuHol),
                    IntermediateOrigin(stationId: "Station:JR-East.ChuoSobuLocal.Nakano",
                                       weekdayRuns: sobuLocalDownNakanoWd,
                                       saturdayHolidayRuns: sobuLocalDownNakanoHol),
                ]
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

    // MARK: - Chuo-Sobu Local Real Runs (July-2026 revision)

    private static let sobuLocalDownChibaWd: [ExactRun] = [
        jb("04:28"), jb("04:44"), jb("05:05"),
        jb("05:23"), jb("05:33"), jb("05:43"),
        jb("05:56", to: "Nakano"), jb("06:06"), jb("06:15"),
        jb("06:22", to: "Nakano"), jb("06:29"), jb("06:34"),
        jb("06:39", to: "Nakano"), jb("06:43"), jb("06:48"),
        jb("06:55", to: "Nakano"), jb("07:00"), jb("07:04"),
        jb("07:07"), jb("07:13"), jb("07:18"),
        jb("07:22", to: "Nakano"), jb("07:27", to: "Nakano"), jb("07:31", to: "Nakano"),
        jb("07:35", to: "Nakano"), jb("07:39"), jb("07:44"),
        jb("07:51"), jb("07:58"), jb("08:04"),
        jb("08:10"), jb("08:15"), jb("08:22"),
        jb("08:31", to: "Nakano"), jb("08:42"), jb("08:51", to: "Nakano"),
        jb("09:00", to: "Nakano"), jb("09:11", to: "Nakano"), jb("09:21", to: "Nakano"),
        jb("09:28", to: "Nakano"), jb("09:35"), jb("09:42", to: "Nakano"),
        jb("09:48"), jb("09:57", to: "Nakano"), jb("10:06", to: "Nakano"),
        jb("10:15"), jb("10:24", to: "Nakano"), jb("10:30", to: "Nakano"),
        jb("10:36"), jb("10:42", to: "Nakano"), jb("10:48"),
        jb("10:59", to: "Nakano"), jb("11:10", to: "Nakano"), jb("11:21"),
        jb("11:32", to: "Nakano"), jb("11:43", to: "Nakano"), jb("11:54", to: "Nakano"),
        jb("12:05"), jb("12:16"), jb("12:27", to: "Nakano"),
        jb("12:37"), jb("12:48"), jb("12:59", to: "Nakano"),
        jb("13:10", to: "Nakano"), jb("13:21"), jb("13:32", to: "Nakano"),
        jb("13:43", to: "Nakano"), jb("13:54", to: "Nakano"), jb("14:05"),
        jb("14:16", to: "Nakano"), jb("14:27", to: "Nakano"), jb("14:37"),
        jb("14:48"), jb("14:59", to: "Nakano"), jb("15:10", to: "Nakano"),
        jb("15:21", to: "Nakano"), jb("15:32", to: "Nakano"), jb("15:43"),
        jb("15:55"), jb("16:06"), jb("16:17", to: "Nakano"),
        jb("16:27"), jb("16:37"), jb("16:46", to: "Nakano"),
        jb("16:55"), jb("17:04"), jb("17:12"),
        jb("17:20", to: "Nakano"), jb("17:30", to: "Nakano"), jb("17:41", to: "Nakano"),
        jb("17:51", to: "Nakano"), jb("18:01"), jb("18:07"),
        jb("18:13", to: "Nakano"), jb("18:18", to: "Nakano"), jb("18:24"),
        jb("18:32"), jb("18:40"), jb("18:47", to: "Nakano"),
        jb("18:55", to: "Nakano"), jb("19:04"), jb("19:10", to: "Nakano"),
        jb("19:19", to: "Nakano"), jb("19:25"), jb("19:30", to: "Nakano"),
        jb("19:38"), jb("19:44", to: "Nakano"), jb("19:49"),
        jb("19:55", to: "Nakano"), jb("20:04", to: "Nakano"), jb("20:10"),
        jb("20:16", to: "Nakano"), jb("20:25"), jb("20:33"),
        jb("20:42"), jb("20:50", to: "Nakano"), jb("20:57"),
        jb("21:03"), jb("21:09", to: "Nakano"), jb("21:19", to: "Nakano"),
        jb("21:28"), jb("21:35", to: "Nakano"), jb("21:41"),
        jb("21:48"), jb("21:55"), jb("22:06"),
        jb("22:15", to: "Nakano"), jb("22:23"), jb("22:30", to: "Nakano"),
        jb("22:37"), jb("22:44"), jb("22:52"),
        jb("23:05", to: "Nakano"), jb("23:14"), jb("23:22"),
        jb("23:31", to: "Nakano"), jb("23:41", to: "Nakano"), jb("24:00", to: "Tsudanuma"),
        jb("24:14", to: "Tsudanuma"), jb("24:30", to: "Tsudanuma"),
    ]

    private static let sobuLocalDownChibaHol: [ExactRun] = [
        jb("04:28"), jb("04:44"), jb("05:05"),
        jb("05:18"), jb("05:33"), jb("05:52", to: "Nakano"),
        jb("06:05", to: "Nakano"), jb("06:20", to: "Nakano"), jb("06:33", to: "Nakano"),
        jb("06:41", to: "Nakano"), jb("06:50"), jb("06:58"),
        jb("07:04", to: "Nakano"), jb("07:09"), jb("07:19"),
        jb("07:29"), jb("07:39", to: "Nakano"), jb("07:44", to: "Nakano"),
        jb("07:53"), jb("08:00"), jb("08:07"),
        jb("08:17"), jb("08:27", to: "Nakano"), jb("08:37"),
        jb("08:47"), jb("08:57", to: "Nakano"), jb("09:07"),
        jb("09:17"), jb("09:27", to: "Nakano"), jb("09:37"),
        jb("09:47"), jb("09:57", to: "Nakano"), jb("10:07"),
        jb("10:17"), jb("10:27", to: "Nakano"), jb("10:37"),
        jb("10:47"), jb("10:57", to: "Nakano"), jb("11:07"),
        jb("11:17"), jb("11:27", to: "Nakano"), jb("11:37"),
        jb("11:47"), jb("11:57", to: "Nakano"), jb("12:07"),
        jb("12:17"), jb("12:27", to: "Nakano"), jb("12:37"),
        jb("12:47"), jb("12:57", to: "Nakano"), jb("13:07"),
        jb("13:17"), jb("13:27", to: "Nakano"), jb("13:37"),
        jb("13:47"), jb("13:57", to: "Nakano"), jb("14:07"),
        jb("14:17"), jb("14:27", to: "Nakano"), jb("14:37"),
        jb("14:47"), jb("14:57", to: "Nakano"), jb("15:07"),
        jb("15:17"), jb("15:27", to: "Nakano"), jb("15:37"),
        jb("15:47"), jb("15:57"), jb("16:07"),
        jb("16:17"), jb("16:27"), jb("16:37"),
        jb("16:47"), jb("16:57"), jb("17:07", to: "Nakano"),
        jb("17:17"), jb("17:27", to: "Nakano"), jb("17:37"),
        jb("17:47"), jb("17:57"), jb("18:07"),
        jb("18:17"), jb("18:27"), jb("18:37"),
        jb("18:47"), jb("18:57"), jb("19:07"),
        jb("19:17"), jb("19:27"), jb("19:37", to: "Nakano"),
        jb("19:48"), jb("19:59", to: "Nakano"), jb("20:11"),
        jb("20:23"), jb("20:34"), jb("20:42"),
        jb("20:50", to: "Nakano"), jb("21:02"), jb("21:15"),
        jb("21:24"), jb("21:33"), jb("21:47"),
        jb("21:57"), jb("22:06"), jb("22:15"),
        jb("22:24"), jb("22:33"), jb("22:43"),
        jb("22:53"), jb("23:03"), jb("23:13"),
        jb("23:22"), jb("23:31", to: "Nakano"), jb("23:41", to: "Nakano"),
        jb("24:00", to: "Tsudanuma"), jb("24:14", to: "Tsudanuma"), jb("24:30", to: "Tsudanuma"),
    ]

    private static let sobuLocalDownMakuhariWd: [ExactRun] = [
        jb("06:29"),
    ]

    private static let sobuLocalDownMakuhariHol: [ExactRun] = [
        jb("07:34"),
    ]

    private static let sobuLocalDownTsudanumaWd: [ExactRun] = [
        jb("04:25"), jb("05:12"), jb("05:30"),
        jb("05:46", to: "Nakano"), jb("05:56", to: "Nakano"), jb("06:05", to: "Nakano"),
        jb("06:10"), jb("06:19"), jb("06:29"),
        jb("06:43"), jb("06:50"), jb("07:00"),
        jb("07:08", to: "Nakano"), jb("07:16"), jb("07:24", to: "Nakano"),
        jb("07:33", to: "NishiFunabashi", cont: true), jb("07:43", to: "NishiFunabashi", cont: true), jb("07:51", to: "NishiFunabashi", cont: true),
        jb("07:59", to: "NishiFunabashi", cont: true), jb("08:07", to: "NishiFunabashi", cont: true), jb("08:14", to: "NishiFunabashi", cont: true),
        jb("08:25", to: "NishiFunabashi", cont: true), jb("08:35", to: "NishiFunabashi", cont: true), jb("08:54"),
        jb("09:24"), jb("09:34"), jb("10:10", to: "Nakano"),
        jb("10:21"), jb("10:37"), jb("11:10", to: "Nakano"),
        jb("11:21"), jb("11:32"), jb("11:43", to: "Nakano"),
        jb("11:54"), jb("12:05"), jb("12:16", to: "Nakano"),
        jb("12:27", to: "Nakano"), jb("12:38"), jb("12:49", to: "Nakano"),
        jb("13:00", to: "Nakano"), jb("13:11", to: "Nakano"), jb("13:22"),
        jb("13:33"), jb("13:43", to: "Nakano"), jb("13:54"),
        jb("14:05"), jb("14:17", to: "Nakano"), jb("14:27"),
        jb("14:38"), jb("14:49", to: "Nakano"), jb("15:00", to: "Nakano"),
        jb("15:11"), jb("15:22"), jb("15:33"),
        jb("15:43"), jb("15:54"), jb("16:05"),
        jb("16:09", to: "Nakano"), jb("16:19", to: "Nakano"), jb("16:29"),
        jb("16:39"), jb("16:49", to: "Nakano"), jb("16:59"),
        jb("17:08", to: "Nakano"), jb("17:16"), jb("17:25", to: "Nakano"),
        jb("17:42"), jb("17:50", to: "NishiFunabashi", cont: true), jb("17:55"),
        jb("18:04", to: "NishiFunabashi", cont: true), jb("18:13", to: "NishiFunabashi", cont: true), jb("18:16", to: "Nakano"),
        jb("18:23", to: "NishiFunabashi", cont: true), jb("18:33", to: "NishiFunabashi", cont: true), jb("18:54", to: "NishiFunabashi", cont: true),
        jb("19:01", to: "NishiFunabashi", cont: true), jb("19:20", to: "NishiFunabashi", cont: true), jb("19:32"),
        jb("19:35", to: "NishiFunabashi", cont: true), jb("19:52"), jb("20:17"),
        jb("20:38"), jb("20:55", to: "Nakano"), jb("21:32"),
        jb("22:18", to: "Nakano"), jb("23:16"),
    ]

    private static let sobuLocalDownTsudanumaHol: [ExactRun] = [
        jb("04:25"), jb("06:00"), jb("06:15"),
        jb("06:28"), jb("06:33", to: "Nakano"), jb("06:44"),
        jb("07:03"), jb("07:12"), jb("07:31"),
        jb("07:51"), jb("08:06"), jb("08:15", to: "Nakano"),
        jb("08:29", to: "Nakano"), jb("08:39"), jb("08:49"),
        jb("08:59", to: "Nakano"), jb("09:09"), jb("09:19"),
        jb("09:29", to: "Nakano"), jb("09:39"), jb("09:49"),
        jb("09:59", to: "Nakano"), jb("10:09"), jb("10:19"),
        jb("10:29"), jb("10:39"), jb("10:49"),
        jb("10:59", to: "Nakano"), jb("11:09"), jb("11:19"),
        jb("11:29"), jb("11:39"), jb("11:49"),
        jb("11:59", to: "Nakano"), jb("12:09"), jb("12:19"),
        jb("12:29"), jb("12:39"), jb("12:49"),
        jb("12:59", to: "Nakano"), jb("13:09"), jb("13:19"),
        jb("13:29"), jb("13:39"), jb("13:49"),
        jb("13:59", to: "Nakano"), jb("14:09"), jb("14:19"),
        jb("14:29"), jb("14:39"), jb("14:49"),
        jb("14:59", to: "Nakano"), jb("15:09"), jb("15:19"),
        jb("15:29", to: "Nakano"), jb("15:39"), jb("15:49"),
        jb("15:59", to: "Nakano"), jb("16:09"), jb("16:19"),
        jb("16:29", to: "Nakano"), jb("16:39"), jb("16:49"),
        jb("16:59", to: "Nakano"), jb("17:09"), jb("17:19"),
        jb("17:29"), jb("17:39"), jb("17:49"),
        jb("17:59"), jb("18:09"), jb("18:19"),
        jb("18:29"), jb("18:39"), jb("18:49"),
        jb("18:59"), jb("19:09"), jb("19:19"),
        jb("19:29"), jb("19:39"), jb("19:49"),
        jb("19:59"), jb("20:10"), jb("20:22"),
        jb("20:34"), jb("20:47"), jb("21:14"),
        jb("21:27", to: "Nakano"), jb("21:58"),
    ]

    private static let sobuLocalDownNishiFunabashiWd: [ExactRun] = [
        jb("07:20"), jb("07:38", to: "Nakano"), jb("07:44", to: "Nakano"),
        jb("07:52"), jb("08:01"), jb("08:09", to: "Nakano"),
        jb("08:16", to: "Nakano"), jb("08:24", to: "Nakano"), jb("08:35", to: "Nakano"),
        jb("08:46"), jb("08:54"), jb("09:01"),
        jb("09:14"), jb("09:23"), jb("17:43", to: "Nakano"),
        jb("18:00"), jb("18:13"), jb("18:22"),
        jb("18:42"), jb("18:54", to: "Nakano"), jb("19:03", to: "Nakano"),
        jb("19:17"), jb("19:26"),
    ]

    private static let sobuLocalDownNishiFunabashiHol: [ExactRun] = [
        jb("07:03"),
    ]

    private static let sobuLocalDownOchanomizuWd: [ExactRun] = [
        jb("04:44"),
    ]

    private static let sobuLocalDownOchanomizuHol: [ExactRun] = [
        jb("04:44"),
    ]

    private static let sobuLocalDownNakanoWd: [ExactRun] = [
        jb("04:40"), jb("06:08", thru: true), jb("06:24", thru: true),
        jb("06:32", thru: true), jb("06:42", thru: true), jb("06:50", thru: true),
        jb("06:56", thru: true), jb("07:06", thru: true), jb("07:12", thru: true),
        jb("07:26", thru: true), jb("07:37", thru: true), jb("07:47", thru: true),
        jb("07:52", thru: true), jb("08:06", thru: true), jb("08:18", thru: true),
        jb("08:24", thru: true), jb("08:39", thru: true), jb("08:46", thru: true),
        jb("08:54", thru: true), jb("08:57", thru: true), jb("09:04", thru: true),
        jb("09:09", thru: true), jb("09:11", thru: true), jb("09:17", thru: true),
        jb("09:25", thru: true), jb("09:35", thru: true), jb("09:37", thru: true),
        jb("09:45", thru: true), jb("10:05", thru: true), jb("10:21", thru: true),
        jb("10:26", thru: true), jb("10:36", thru: true), jb("10:49", thru: true),
        jb("11:19", thru: true), jb("11:49", thru: true), jb("12:19", thru: true),
        jb("12:49", thru: true), jb("13:19", thru: true), jb("13:49", thru: true),
        jb("14:19", thru: true), jb("14:49", thru: true), jb("15:19", thru: true),
        jb("15:49", thru: true), jb("16:04", thru: true), jb("16:12", thru: true),
        jb("16:24", thru: true), jb("16:32", thru: true), jb("16:36", thru: true),
        jb("16:44", thru: true), jb("16:50", thru: true), jb("16:54", thru: true),
        jb("17:01", thru: true), jb("17:08", thru: true), jb("17:15", thru: true),
        jb("17:24", thru: true), jb("17:31", thru: true), jb("17:38", thru: true),
        jb("17:44", thru: true), jb("17:56", thru: true), jb("18:02", thru: true),
        jb("18:09", thru: true), jb("18:14", thru: true), jb("18:20", thru: true),
        jb("18:26", thru: true), jb("18:32", thru: true), jb("18:38", thru: true),
        jb("18:44", thru: true), jb("18:51", thru: true), jb("18:59", thru: true),
        jb("19:15", thru: true), jb("19:23", thru: true), jb("19:37", thru: true),
        jb("19:45", thru: true), jb("20:08", thru: true), jb("20:17", thru: true),
        jb("20:31", thru: true), jb("20:45", thru: true), jb("20:55", thru: true),
        jb("21:07", thru: true), jb("21:28", thru: true), jb("21:39", thru: true),
        jb("22:00", thru: true),
    ]

    private static let sobuLocalDownNakanoHol: [ExactRun] = [
        jb("04:40"), jb("05:42"), jb("06:16"),
        jb("07:13", thru: true), jb("07:25", thru: true), jb("07:38", thru: true),
        jb("07:42"), jb("07:49", thru: true), jb("08:02", thru: true),
        jb("08:15", thru: true), jb("08:25", thru: true), jb("08:38", thru: true),
        jb("08:50", thru: true), jb("09:05", thru: true), jb("09:08", thru: true),
        jb("09:21", thru: true), jb("09:34", thru: true), jb("09:48", thru: true),
        jb("10:04", thru: true), jb("10:19", thru: true), jb("10:34", thru: true),
        jb("10:49", thru: true), jb("11:19", thru: true), jb("11:49", thru: true),
        jb("12:19", thru: true), jb("12:49", thru: true), jb("13:19", thru: true),
        jb("13:49", thru: true), jb("14:19", thru: true), jb("14:49", thru: true),
        jb("15:19", thru: true), jb("15:49", thru: true), jb("16:04", thru: true),
        jb("16:19", thru: true), jb("16:34", thru: true), jb("16:49", thru: true),
        jb("17:04", thru: true), jb("17:19", thru: true), jb("17:35", thru: true),
        jb("17:50", thru: true), jb("18:04", thru: true), jb("18:19", thru: true),
        jb("18:31", thru: true), jb("18:49", thru: true), jb("19:00", thru: true),
        jb("19:21", thru: true),
    ]

    private static let sobuLocalUpMitakaWd: [ExactRun] = [
        jb("04:35"), jb("04:49"), jb("05:05"),
        jb("05:14"), jb("05:25"), jb("05:36"),
        jb("05:50", to: "Nakano", cont: true), jb("05:52"), jb("06:01", to: "Nakano", cont: true),
        jb("06:05", to: "NishiFunabashi"), jb("06:11", to: "Nakano", cont: true), jb("06:16"),
        jb("06:20", to: "Nakano", cont: true), jb("06:26"), jb("06:31", to: "Nakano", cont: true),
        jb("06:36"), jb("06:41", to: "Nakano", cont: true), jb("06:44"),
        jb("06:48", to: "Nakano", cont: true), jb("06:51"), jb("06:54", to: "Nakano", cont: true),
        jb("06:59", to: "Nakano", cont: true), jb("07:01", to: "NishiFunabashi"), jb("07:06", to: "Nakano", cont: true),
        jb("07:09", to: "NishiFunabashi"), jb("07:13", to: "Nakano", cont: true), jb("07:15"),
        jb("07:18", to: "NishiFunabashi"), jb("07:23", to: "Nakano", cont: true), jb("07:26", to: "Tsudanuma"),
        jb("07:29", to: "Nakano", cont: true), jb("07:32", to: "NishiFunabashi"), jb("07:35"),
        jb("07:38", to: "NishiFunabashi"), jb("07:42", to: "Nakano", cont: true), jb("07:45", to: "NishiFunabashi"),
        jb("07:51"), jb("07:53", to: "Nakano", cont: true), jb("07:58"),
        jb("08:01", to: "Tsudanuma"), jb("08:04", to: "Nakano", cont: true), jb("08:07", to: "NishiFunabashi"),
        jb("08:09", to: "Nakano", cont: true), jb("08:12", to: "Tsudanuma"), jb("08:15"),
        jb("08:18", to: "Tsudanuma"), jb("08:21"), jb("08:24", to: "Nakano", cont: true),
        jb("08:26"), jb("08:31", to: "Tsudanuma"), jb("08:35", to: "Nakano", cont: true),
        jb("08:38", to: "Tsudanuma"), jb("08:41", to: "Nakano", cont: true), jb("08:46", to: "Tsudanuma"),
        jb("08:51"), jb("08:56", to: "Nakano", cont: true), jb("09:00"),
        jb("09:03", to: "Nakano", cont: true), jb("09:06"), jb("09:12", to: "Nakano", cont: true),
        jb("09:14", to: "Nakano", cont: true), jb("09:18"), jb("09:21", to: "Nakano", cont: true),
        jb("09:24", to: "Tsudanuma"), jb("09:26", to: "Nakano", cont: true), jb("09:30", to: "Nakano", cont: true),
        jb("09:34", to: "Tsudanuma"), jb("09:39"), jb("09:43", to: "Nakano", cont: true),
        jb("09:46", to: "Tsudanuma"), jb("09:52", to: "Nakano", cont: true), jb("09:57", to: "Tsudanuma"),
        jb("10:00"), jb("10:04", to: "Nakano", cont: true), jb("10:12"),
        jb("10:22", to: "Nakano", cont: true), jb("10:29", to: "Tsudanuma"), jb("10:38", to: "Nakano", cont: true),
        jb("10:46"), jb("10:57"), jb("11:07", to: "Nakano", cont: true),
        jb("11:14", to: "Tsudanuma"), jb("11:24", to: "Tsudanuma"), jb("11:30"),
        jb("11:37", to: "Nakano", cont: true), jb("11:47", to: "Tsudanuma"), jb("11:57", to: "Tsudanuma"),
        jb("12:07", to: "Nakano", cont: true), jb("12:14"), jb("12:24"),
        jb("12:30", to: "Tsudanuma"), jb("12:37", to: "Nakano", cont: true), jb("12:47"),
        jb("12:57"), jb("13:07", to: "Nakano", cont: true), jb("13:14", to: "Tsudanuma"),
        jb("13:24", to: "Tsudanuma"), jb("13:30"), jb("13:37", to: "Nakano", cont: true),
        jb("13:47", to: "Tsudanuma"), jb("13:57", to: "Tsudanuma"), jb("14:07", to: "Nakano", cont: true),
        jb("14:14"), jb("14:24"), jb("14:30", to: "Tsudanuma"),
        jb("14:37", to: "Nakano", cont: true), jb("14:47"), jb("14:57", to: "Tsudanuma"),
        jb("15:07", to: "Nakano", cont: true), jb("15:14"), jb("15:20", to: "Tsudanuma"),
        jb("15:29"), jb("15:37", to: "Nakano", cont: true), jb("15:43", to: "Tsudanuma"),
        jb("15:49"), jb("15:53", to: "Nakano", cont: true), jb("15:59"),
        jb("16:03"), jb("16:08", to: "Nakano", cont: true), jb("16:13", to: "Nakano", cont: true),
        jb("16:16", to: "Tsudanuma"), jb("16:21", to: "Nakano", cont: true), jb("16:24", to: "Nakano", cont: true),
        jb("16:26", to: "NishiFunabashi"), jb("16:30", to: "Nakano", cont: true), jb("16:33"),
        jb("16:36", to: "Nakano", cont: true), jb("16:38"), jb("16:41", to: "Nakano", cont: true),
        jb("16:46"), jb("16:49", to: "Nakano", cont: true), jb("16:52"),
        jb("16:55", to: "Nakano", cont: true), jb("16:58"), jb("17:01", to: "Nakano", cont: true),
        jb("17:04", to: "NishiFunabashi"), jb("17:07", to: "Nakano", cont: true), jb("17:09"),
        jb("17:13", to: "Nakano", cont: true), jb("17:16", to: "Tsudanuma"), jb("17:19", to: "Nakano", cont: true),
        jb("17:22", to: "NishiFunabashi"), jb("17:25", to: "Nakano", cont: true), jb("17:28"),
        jb("17:31", to: "Nakano", cont: true), jb("17:34", to: "NishiFunabashi"), jb("17:36"),
        jb("17:40", to: "Tsudanuma"), jb("17:43", to: "Nakano", cont: true), jb("17:45", to: "NishiFunabashi"),
        jb("17:49", to: "Nakano", cont: true), jb("17:52"), jb("17:55", to: "Nakano", cont: true),
        jb("17:58", to: "NishiFunabashi"), jb("18:01", to: "Nakano", cont: true), jb("18:04"),
        jb("18:08", to: "NishiFunabashi"), jb("18:12", to: "Nakano", cont: true), jb("18:16", to: "Tsudanuma"),
        jb("18:19", to: "Nakano", cont: true), jb("18:21"), jb("18:26", to: "Nakano", cont: true),
        jb("18:32", to: "Nakano", cont: true), jb("18:35"), jb("18:38", to: "Nakano", cont: true),
        jb("18:41", to: "Tsudanuma"), jb("18:44", to: "Nakano", cont: true), jb("18:48", to: "Tsudanuma"),
        jb("18:51", to: "Nakano", cont: true), jb("18:56", to: "Nakano", cont: true), jb("18:59", to: "Tsudanuma"),
        jb("19:03", to: "Nakano", cont: true), jb("19:06", to: "Tsudanuma"), jb("19:09", to: "Nakano", cont: true),
        jb("19:16"), jb("19:21", to: "Nakano", cont: true), jb("19:25"),
        jb("19:32", to: "Nakano", cont: true), jb("19:35"), jb("19:40", to: "Nakano", cont: true),
        jb("19:44", to: "Tsudanuma"), jb("19:48"), jb("19:52"),
        jb("19:54", to: "Nakano", cont: true), jb("20:00"), jb("20:03", to: "Nakano", cont: true),
        jb("20:06", to: "Tsudanuma"), jb("20:14"), jb("20:23"),
        jb("20:26", to: "Nakano", cont: true), jb("20:33"), jb("20:42"),
        jb("20:49"), jb("20:58"), jb("21:04", to: "Nakano", cont: true),
        jb("21:09", to: "Tsudanuma"), jb("21:15", to: "Nakano", cont: true), jb("21:19"),
        jb("21:24", to: "Tsudanuma"), jb("21:28", to: "Nakano", cont: true), jb("21:33"),
        jb("21:41"), jb("21:53"), jb("22:06"),
        jb("22:13", to: "Tsudanuma"), jb("22:27"), jb("22:42"),
        jb("22:51", to: "Tsudanuma"), jb("23:04"), jb("23:12", to: "Tsudanuma"),
        jb("23:25"), jb("23:34", to: "Tsudanuma"), jb("23:44", to: "Tsudanuma"),
        jb("23:50", to: "Ochanomizu"), jb("24:15", to: "Nakano"), jb("24:34", to: "Nakano"),
    ]

    private static let sobuLocalUpMitakaHol: [ExactRun] = [
        jb("04:35"), jb("04:54"), jb("05:08"),
        jb("05:24"), jb("05:36"), jb("05:47"),
        jb("05:55"), jb("06:04"), jb("06:14"),
        jb("06:24"), jb("06:35"), jb("06:41"),
        jb("06:47"), jb("06:53", to: "Tsudanuma"), jb("06:58", to: "Nakano", cont: true),
        jb("07:02", to: "Tsudanuma"), jb("07:05", to: "Nakano", cont: true), jb("07:12", to: "Tsudanuma"),
        jb("07:16", to: "Nakano", cont: true), jb("07:23", to: "Tsudanuma"), jb("07:29", to: "Nakano", cont: true),
        jb("07:37"), jb("07:42", to: "Nakano", cont: true), jb("07:48"),
        jb("07:54", to: "Nakano", cont: true), jb("07:59"), jb("08:06", to: "Nakano", cont: true),
        jb("08:09"), jb("08:14", to: "Tsudanuma"), jb("08:19", to: "Nakano", cont: true),
        jb("08:23", to: "Tsudanuma"), jb("08:27"), jb("08:32", to: "Nakano", cont: true),
        jb("08:35", to: "Tsudanuma"), jb("08:41", to: "Nakano", cont: true), jb("08:45", to: "Tsudanuma"),
        jb("08:51"), jb("08:54", to: "Nakano", cont: true), jb("09:01"),
        jb("09:07", to: "Nakano", cont: true), jb("09:11"), jb("09:17", to: "Tsudanuma"),
        jb("09:22", to: "Nakano", cont: true), jb("09:28", to: "Tsudanuma"), jb("09:33"),
        jb("09:38", to: "Nakano", cont: true), jb("09:42"), jb("09:47", to: "Tsudanuma"),
        jb("09:52", to: "Nakano", cont: true), jb("09:57", to: "Tsudanuma"), jb("10:03"),
        jb("10:08", to: "Nakano", cont: true), jb("10:13"), jb("10:18", to: "Tsudanuma"),
        jb("10:23", to: "Nakano", cont: true), jb("10:28", to: "Tsudanuma"), jb("10:33"),
        jb("10:38", to: "Nakano", cont: true), jb("10:43"), jb("10:48", to: "Tsudanuma"),
        jb("10:55", to: "Tsudanuma"), jb("11:02"), jb("11:07", to: "Nakano", cont: true),
        jb("11:12"), jb("11:18", to: "Tsudanuma"), jb("11:23"),
        jb("11:28", to: "Tsudanuma"), jb("11:33"), jb("11:38", to: "Nakano", cont: true),
        jb("11:43"), jb("11:48", to: "Tsudanuma"), jb("11:55", to: "Tsudanuma"),
        jb("12:02"), jb("12:07", to: "Nakano", cont: true), jb("12:12"),
        jb("12:18", to: "Tsudanuma"), jb("12:23"), jb("12:28", to: "Tsudanuma"),
        jb("12:33"), jb("12:38", to: "Nakano", cont: true), jb("12:43"),
        jb("12:48", to: "Tsudanuma"), jb("12:55", to: "Tsudanuma"), jb("13:02"),
        jb("13:07", to: "Nakano", cont: true), jb("13:12"), jb("13:17", to: "Tsudanuma"),
        jb("13:23"), jb("13:28", to: "Tsudanuma"), jb("13:33"),
        jb("13:38", to: "Nakano", cont: true), jb("13:43"), jb("13:48", to: "Tsudanuma"),
        jb("13:55", to: "Tsudanuma"), jb("14:02"), jb("14:07", to: "Nakano", cont: true),
        jb("14:12"), jb("14:18", to: "Tsudanuma"), jb("14:23"),
        jb("14:28", to: "Tsudanuma"), jb("14:33"), jb("14:38", to: "Nakano", cont: true),
        jb("14:43"), jb("14:48", to: "Tsudanuma"), jb("14:55", to: "Tsudanuma"),
        jb("15:02"), jb("15:07", to: "Nakano", cont: true), jb("15:12"),
        jb("15:17", to: "Tsudanuma"), jb("15:23"), jb("15:28", to: "Tsudanuma"),
        jb("15:33"), jb("15:38", to: "Nakano", cont: true), jb("15:43"),
        jb("15:47", to: "Tsudanuma"), jb("15:52", to: "Nakano", cont: true), jb("15:57", to: "Tsudanuma"),
        jb("16:03"), jb("16:08", to: "Nakano", cont: true), jb("16:11"),
        jb("16:15", to: "Tsudanuma"), jb("16:18", to: "Nakano", cont: true), jb("16:23", to: "Nakano", cont: true),
        jb("16:27", to: "Tsudanuma"), jb("16:33"), jb("16:38", to: "Nakano", cont: true),
        jb("16:43"), jb("16:47", to: "Tsudanuma"), jb("16:53", to: "Nakano", cont: true),
        jb("16:56", to: "Tsudanuma"), jb("17:01"), jb("17:05", to: "Nakano", cont: true),
        jb("17:11"), jb("17:16", to: "Tsudanuma"), jb("17:21", to: "Nakano", cont: true),
        jb("17:26", to: "Tsudanuma"), jb("17:30"), jb("17:34", to: "Tsudanuma"),
        jb("17:38", to: "Nakano", cont: true), jb("17:41"), jb("17:44", to: "Tsudanuma"),
        jb("17:49"), jb("17:53", to: "Nakano", cont: true), jb("17:56", to: "Tsudanuma"),
        jb("18:00"), jb("18:04", to: "Tsudanuma"), jb("18:07", to: "Nakano", cont: true),
        jb("18:10"), jb("18:15", to: "Tsudanuma"), jb("18:21", to: "Nakano", cont: true),
        jb("18:26", to: "Tsudanuma"), jb("18:31"), jb("18:36", to: "Nakano", cont: true),
        jb("18:41"), jb("18:47", to: "Tsudanuma"), jb("18:52"),
        jb("18:58", to: "Tsudanuma"), jb("19:03"), jb("19:07", to: "Nakano", cont: true),
        jb("19:10", to: "Tsudanuma"), jb("19:15"), jb("19:20", to: "Tsudanuma"),
        jb("19:25"), jb("19:30", to: "Tsudanuma"), jb("19:35"),
        jb("19:40", to: "Tsudanuma"), jb("19:45"), jb("19:51", to: "Tsudanuma"),
        jb("19:56"), jb("20:02", to: "Tsudanuma"), jb("20:08"),
        jb("20:13", to: "Tsudanuma"), jb("20:18"), jb("20:23", to: "Tsudanuma"),
        jb("20:29"), jb("20:34", to: "Tsudanuma"), jb("20:39"),
        jb("20:45", to: "Tsudanuma"), jb("20:50"), jb("20:55", to: "Tsudanuma"),
        jb("21:01"), jb("21:06"), jb("21:16"),
        jb("21:23"), jb("21:29", to: "Tsudanuma"), jb("21:35"),
        jb("21:41"), jb("21:47", to: "Tsudanuma"), jb("21:55"),
        jb("22:02", to: "Tsudanuma"), jb("22:09"), jb("22:16", to: "Tsudanuma"),
        jb("22:23", to: "Tsudanuma"), jb("22:31"), jb("22:40", to: "Tsudanuma"),
        jb("22:49"), jb("22:59", to: "Tsudanuma"), jb("23:08"),
        jb("23:18", to: "Tsudanuma"), jb("23:27"), jb("23:37", to: "Tsudanuma"),
        jb("23:44", to: "Tsudanuma"), jb("23:50", to: "Ochanomizu"), jb("24:15", to: "Nakano"),
        jb("24:34", to: "Nakano"),
    ]

    private static let sobuLocalUpNakanoWd: [ExactRun] = [
        jb("04:24"), jb("05:11"), jb("06:00"),
        jb("06:14"), jb("06:25"), jb("06:38", to: "NishiFunabashi"),
        jb("06:47", to: "NishiFunabashi"), jb("06:56", to: "NishiFunabashi"), jb("07:03", to: "NishiFunabashi"),
        jb("07:10", to: "NishiFunabashi"), jb("07:14"), jb("07:21"),
        jb("07:39"), jb("08:00"), jb("08:11", to: "NishiFunabashi"),
        jb("08:20"), jb("08:41", to: "Tsudanuma"), jb("08:51"),
        jb("08:59"), jb("09:12", to: "Tsudanuma"), jb("09:28", to: "Tsudanuma"),
        jb("09:45"), jb("10:07"), jb("10:22", to: "Tsudanuma"),
        jb("10:34", to: "Tsudanuma"), jb("10:40"), jb("10:50"),
        jb("10:56", to: "Tsudanuma"), jb("11:07", to: "Tsudanuma"), jb("11:18", to: "Tsudanuma"),
        jb("11:23"), jb("11:34"), jb("11:50", to: "Tsudanuma"),
        jb("11:56"), jb("12:07"), jb("12:18"),
        jb("12:24", to: "Tsudanuma"), jb("12:35", to: "Tsudanuma"), jb("12:50"),
        jb("12:56", to: "Tsudanuma"), jb("13:07", to: "Tsudanuma"), jb("13:18", to: "Tsudanuma"),
        jb("13:24"), jb("13:35"), jb("13:51", to: "Tsudanuma"),
        jb("13:57"), jb("14:07"), jb("14:18"),
        jb("14:24", to: "Tsudanuma"), jb("14:35", to: "Tsudanuma"), jb("14:51"),
        jb("14:57", to: "Tsudanuma"), jb("15:07"), jb("15:18"),
        jb("15:24", to: "Tsudanuma"), jb("15:40"), jb("15:50", to: "Tsudanuma"),
        jb("15:55"), jb("16:10", to: "Tsudanuma"), jb("16:23", to: "Tsudanuma"),
        jb("16:28"), jb("16:37"), jb("16:45"),
        jb("16:58", to: "NishiFunabashi"), jb("17:11", to: "NishiFunabashi"), jb("17:17", to: "Tsudanuma"),
        jb("17:28", to: "Tsudanuma"), jb("17:34"), jb("17:41"),
        jb("17:47", to: "Tsudanuma"), jb("18:04"), jb("18:10", to: "Tsudanuma"),
        jb("18:17"), jb("18:27"), jb("18:35"),
        jb("18:41", to: "Tsudanuma"), jb("18:46"), jb("19:00"),
        jb("19:09"), jb("19:19"), jb("19:28"),
        jb("19:45", to: "Tsudanuma"), jb("19:55"), jb("20:12", to: "Tsudanuma"),
        jb("20:26"), jb("20:35", to: "Tsudanuma"), jb("20:44", to: "Tsudanuma"),
        jb("20:54", to: "Tsudanuma"), jb("21:09", to: "Tsudanuma"), jb("21:20"),
        jb("21:31"), jb("22:03", to: "Tsudanuma"), jb("22:16", to: "Tsudanuma"),
        jb("22:36", to: "Tsudanuma"), jb("22:51", to: "Tsudanuma"), jb("23:14", to: "Tsudanuma"),
        jb("23:35", to: "Tsudanuma"), jb("23:55", to: "Tsudanuma"),
    ]

    private static let sobuLocalUpNakanoHol: [ExactRun] = [
        jb("04:24"), jb("06:45", to: "Tsudanuma"), jb("07:14"),
        jb("07:23"), jb("07:33"), jb("07:43"),
        jb("07:49", to: "Tsudanuma"), jb("07:59", to: "Tsudanuma"), jb("08:10", to: "Tsudanuma"),
        jb("08:20", to: "Tsudanuma"), jb("08:35"), jb("08:56"),
        jb("09:12", to: "Tsudanuma"), jb("09:23", to: "Tsudanuma"), jb("09:39"),
        jb("09:54", to: "Tsudanuma"), jb("10:09"), jb("10:24", to: "Tsudanuma"),
        jb("10:39"), jb("10:53", to: "Tsudanuma"), jb("11:08"),
        jb("11:23", to: "Tsudanuma"), jb("11:54", to: "Tsudanuma"), jb("12:08"),
        jb("12:23", to: "Tsudanuma"), jb("12:54", to: "Tsudanuma"), jb("13:08"),
        jb("13:23", to: "Tsudanuma"), jb("13:54", to: "Tsudanuma"), jb("14:08"),
        jb("14:23", to: "Tsudanuma"), jb("14:54", to: "Tsudanuma"), jb("15:08"),
        jb("15:23", to: "Tsudanuma"), jb("15:54", to: "Tsudanuma"), jb("16:09"),
        jb("16:23", to: "Tsudanuma"), jb("16:37"), jb("16:54", to: "Tsudanuma"),
        jb("17:06"), jb("17:21", to: "Tsudanuma"), jb("17:36"),
        jb("18:36"), jb("18:52", to: "Tsudanuma"), jb("21:27", to: "Tsudanuma"),
    ]

    private static let sobuLocalUpOchanomizuWd: [ExactRun] = [
        jb("04:29"),
    ]

    private static let sobuLocalUpOchanomizuHol: [ExactRun] = [
        jb("04:29"),
    ]

    private static let sobuLocalUpNishiFunabashiWd: [ExactRun] = [
        jb("07:20", to: "Tsudanuma", thru: true), jb("07:30", to: "Tsudanuma", thru: true), jb("07:39", to: "Tsudanuma", thru: true),
        jb("07:47", to: "Tsudanuma", thru: true), jb("07:55", to: "Tsudanuma", thru: true), jb("08:02", to: "Tsudanuma", thru: true),
        jb("08:11", to: "Tsudanuma", thru: true), jb("08:21", to: "Tsudanuma", thru: true), jb("17:36", to: "Tsudanuma", thru: true),
        jb("17:49", to: "Tsudanuma", thru: true), jb("17:59", to: "Tsudanuma", thru: true), jb("18:09", to: "Tsudanuma", thru: true),
        jb("18:19", to: "Tsudanuma", thru: true), jb("18:40", to: "Tsudanuma", thru: true), jb("18:49", to: "Tsudanuma", thru: true),
        jb("19:08", to: "Tsudanuma", thru: true), jb("19:21", to: "Tsudanuma", thru: true),
    ]

    private static let sobuLocalUpNishiFunabashiHol: [ExactRun] = [
    ]

    private static let sobuLocalUpTsudanumaWd: [ExactRun] = [
        jb("04:43"), jb("04:54"), jb("05:17"),
        jb("05:40"), jb("05:50"), jb("06:12"),
        jb("06:26"), jb("06:38"), jb("06:48"),
        jb("06:58"), jb("07:07"), jb("07:15"),
        jb("07:23"), jb("07:33"),
    ]

    private static let sobuLocalUpTsudanumaHol: [ExactRun] = [
        jb("04:43"), jb("04:54"), jb("05:41"),
        jb("06:17"), jb("06:34"), jb("06:47"),
        jb("07:37"),
    ]

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
        // Measured from real July-2026 train pairs (median dep-to-dep, both
        // directions): 大船→本郷台 4, 新子安〜大森 4/hop, 田町→浜松町 3,
        // 川口→西川口 3. Remaining hops match the lower directional median.
        hopTimesMinutes: [
            4, 3, 2, 3, 2, 3, 3, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 3, 3, 2, 2, 3, 2,
            2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 2, 3, 3, 2, 2, 2, 3,
        ],
        // Real per-station times per run (623 grid), incl. midday 快速 skips
        // (negative sentinel) → 1:1 station timetables.
        exactStationTimes: keihinTohokuExactTimes,
        // Real exact runs, July-2026 revision (timetables.jreast.co.jp).
        // Per-train termini are honored: 南浦和・赤羽・東十条 turnbacks on the
        // north end, 蒲田・鶴見・桜木町・磯子 on the south, plus 横浜線直通
        // runs entering (南行, thru) or leaving (北行, cont) at 東神奈川.
        // Midday 快速 trains are included as all-stops — the linear model
        // cannot express their skipped 田端〜浜松町 stations, and excluding
        // them would leave the core section with no midday service (the
        // previous headway-band model made the same approximation).
        directions: [
            StaticLineDirection(
                id: "static.RailDirection:JR-East.KeihinTohoku.Omiya",
                nameJa: "大宮方面",
                nameEn: "For Omiya",
                isAscending: true,
                weekday: exact(keihinTohokuUpOfunaWd, first: "04:43", last: "24:09"),
                saturdayHoliday: exact(keihinTohokuUpOfunaHol, first: "04:43", last: "24:09"),
                intermediateOrigins: [
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.Isogo",
                                       weekdayRuns: keihinTohokuUpIsogoWd,
                                       saturdayHolidayRuns: keihinTohokuUpIsogoHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.Sakuragicho",
                                       weekdayRuns: keihinTohokuUpSakuragichoWd,
                                       saturdayHolidayRuns: keihinTohokuUpSakuragichoHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.HigashiKanagawa",
                                       weekdayRuns: keihinTohokuUpHigashiKanagawaWd,
                                       saturdayHolidayRuns: keihinTohokuUpHigashiKanagawaHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.Tsurumi",
                                       weekdayRuns: keihinTohokuUpTsurumiWd,
                                       saturdayHolidayRuns: keihinTohokuUpTsurumiHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.Kamata",
                                       weekdayRuns: keihinTohokuUpKamataWd,
                                       saturdayHolidayRuns: keihinTohokuUpKamataHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.Ueno",
                                       weekdayRuns: keihinTohokuUpUenoWd,
                                       saturdayHolidayRuns: keihinTohokuUpUenoHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.MinamiUrawa",
                                       weekdayRuns: keihinTohokuUpMinamiUrawaWd,
                                       saturdayHolidayRuns: keihinTohokuUpMinamiUrawaHol),
                ]
            ),
            StaticLineDirection(
                id: "static.RailDirection:JR-East.KeihinTohoku.Ofuna",
                nameJa: "大船方面",
                nameEn: "For Ofuna",
                isAscending: false,
                weekday: exact(keihinTohokuDownOmiyaWd, first: "04:28", last: "24:15"),
                saturdayHoliday: exact(keihinTohokuDownOmiyaHol, first: "04:28", last: "24:15"),
                intermediateOrigins: [
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.MinamiUrawa",
                                       weekdayRuns: keihinTohokuDownMinamiUrawaWd,
                                       saturdayHolidayRuns: keihinTohokuDownMinamiUrawaHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.Akabane",
                                       weekdayRuns: keihinTohokuDownAkabaneWd,
                                       saturdayHolidayRuns: keihinTohokuDownAkabaneHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.HigashiJujo",
                                       weekdayRuns: keihinTohokuDownHigashiJujoWd,
                                       saturdayHolidayRuns: keihinTohokuDownHigashiJujoHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.Tabata",
                                       weekdayRuns: keihinTohokuDownTabataWd,
                                       saturdayHolidayRuns: keihinTohokuDownTabataHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.Kamata",
                                       weekdayRuns: keihinTohokuDownKamataWd,
                                       saturdayHolidayRuns: keihinTohokuDownKamataHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.HigashiKanagawa",
                                       weekdayRuns: keihinTohokuDownHigashiKanagawaWd,
                                       saturdayHolidayRuns: keihinTohokuDownHigashiKanagawaHol),
                    IntermediateOrigin(stationId: "Station:JR-East.KeihinTohoku.Isogo",
                                       weekdayRuns: keihinTohokuDownIsogoWd,
                                       saturdayHolidayRuns: keihinTohokuDownIsogoHol),
                ]
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

    // MARK: - Keihin-Tohoku Real Runs (July-2026 revision)

    private static let keihinTohokuDownOmiyaWd: [ExactRun] = [
        jk("04:28"), jk("04:48", to: "Isogo"), jk("05:16"),
        jk("05:29"), jk("05:40", to: "Isogo"), jk("05:48", to: "Sakuragicho"),
        jk("05:59"), jk("06:05"), jk("06:13"),
        jk("06:19", to: "Sakuragicho"), jk("06:24"), jk("06:32"),
        jk("06:38", to: "Kamata"), jk("06:44"), jk("06:48", to: "Kamata"),
        jk("06:52"), jk("06:56", to: "Sakuragicho"), jk("07:00"),
        jk("07:04"), jk("07:07", to: "Tsurumi"), jk("07:11"),
        jk("07:14", to: "Sakuragicho"), jk("07:18", to: "Tsurumi"), jk("07:21"),
        jk("07:24", to: "Isogo"), jk("07:28", to: "Kamata"), jk("07:32"),
        jk("07:35", to: "Tsurumi"), jk("07:38", to: "Isogo"), jk("07:42", to: "Kamata"),
        jk("07:46", to: "Isogo"), jk("07:49"), jk("07:53"),
        jk("07:57", to: "Isogo"), jk("08:03"), jk("08:07", to: "Tsurumi"),
        jk("08:14", to: "Kamata"), jk("08:19", to: "HigashiKanagawa"), jk("08:25"),
        jk("08:32", to: "Isogo"), jk("08:35", to: "Kamata"), jk("08:44", to: "Isogo"),
        jk("08:47", to: "Kamata"), jk("08:52"), jk("08:56", to: "Isogo"),
        jk("09:01", to: "Kamata"), jk("09:06", to: "Isogo"), jk("09:10", to: "Kamata"),
        jk("09:14"), jk("09:17", to: "Isogo"), jk("09:24"),
        jk("09:29", to: "Kamata"), jk("09:36", to: "Isogo"), jk("09:43", to: "Kamata"),
        jk("09:49"), jk("09:54", to: "Kamata"), jk("09:59"),
        jk("10:07"), jk("10:16"), jk("10:23", to: "Kamata"),
        jk("10:33", to: "Isogo"), jk("10:39"), jk("10:47"),
        jk("10:54", to: "Isogo"), jk("10:59"), jk("11:09"),
        jk("11:18"), jk("11:29"), jk("11:39"),
        jk("11:49"), jk("11:59"), jk("12:09"),
        jk("12:19"), jk("12:29"), jk("12:39"),
        jk("12:49"), jk("12:59"), jk("13:08"),
        jk("13:19"), jk("13:29"), jk("13:38"),
        jk("13:49"), jk("13:59"), jk("14:09"),
        jk("14:19"), jk("14:29"), jk("14:39"),
        jk("14:49"), jk("14:59", to: "Sakuragicho"), jk("15:09", to: "Kamata"),
        jk("15:19", to: "Isogo"), jk("15:29", to: "Sakuragicho"), jk("15:39", to: "Kamata"),
        jk("15:49", to: "Isogo"), jk("15:58", to: "Sakuragicho"), jk("16:08", to: "Isogo"),
        jk("16:18"), jk("16:28"), jk("16:36"),
        jk("16:45"), jk("16:51", to: "Sakuragicho"), jk("16:55"),
        jk("17:00", to: "Isogo"), jk("17:03"), jk("17:09"),
        jk("17:16"), jk("17:20", to: "Kamata"), jk("17:25", to: "Sakuragicho"),
        jk("17:30", to: "Kamata"), jk("17:35", to: "Tsurumi"), jk("17:39"),
        jk("17:45"), jk("17:49", to: "Isogo"), jk("17:54"),
        jk("17:59", to: "Sakuragicho"), jk("18:05", to: "Tsurumi"), jk("18:11"),
        jk("18:18", to: "Isogo"), jk("18:23", to: "Kamata"), jk("18:30", to: "Isogo"),
        jk("18:35"), jk("18:40", to: "Isogo"), jk("18:46", to: "Kamata"),
        jk("18:51", to: "Isogo"), jk("18:55"), jk("19:02", to: "Kamata"),
        jk("19:06"), jk("19:10", to: "Isogo"), jk("19:15", to: "Kamata"),
        jk("19:19"), jk("19:23", to: "Isogo"), jk("19:28", to: "Sakuragicho"),
        jk("19:33"), jk("19:37", to: "Sakuragicho"), jk("19:42"),
        jk("19:48", to: "Isogo"), jk("19:52"), jk("19:58", to: "Isogo"),
        jk("20:02"), jk("20:07", to: "Sakuragicho"), jk("20:13"),
        jk("20:18", to: "Isogo"), jk("20:23"), jk("20:29", to: "Isogo"),
        jk("20:33"), jk("20:43"), jk("20:49", to: "Sakuragicho"),
        jk("20:55"), jk("21:02", to: "Sakuragicho"), jk("21:12", to: "Sakuragicho"),
        jk("21:20"), jk("21:26", to: "Sakuragicho"), jk("21:32"),
        jk("21:41", to: "Isogo"), jk("21:49"), jk("21:55", to: "Isogo"),
        jk("22:03", to: "Sakuragicho"), jk("22:08"), jk("22:15", to: "Isogo"),
        jk("22:20"), jk("22:27", to: "Sakuragicho"), jk("22:32"),
        jk("22:42", to: "Isogo"), jk("22:50"), jk("23:00", to: "Isogo"),
        jk("23:07", to: "Sakuragicho"), jk("23:14", to: "Kamata"), jk("23:22", to: "Kamata"),
        jk("23:30", to: "Kamata"), jk("23:38", to: "Kamata"), jk("23:44", to: "Akabane"),
        jk("23:51", to: "Akabane"), jk("23:57", to: "Akabane"), jk("24:15", to: "Akabane"),
    ]

    private static let keihinTohokuDownOmiyaHol: [ExactRun] = [
        jk("04:28"), jk("04:47"), jk("05:16"),
        jk("05:27"), jk("05:45"), jk("05:59", to: "Isogo"),
        jk("06:11"), jk("06:21"), jk("06:32"),
        jk("06:43", to: "Kamata"), jk("06:51"), jk("06:58", to: "Isogo"),
        jk("07:08", to: "Tsurumi"), jk("07:13"), jk("07:17"),
        jk("07:23", to: "Isogo"), jk("07:27", to: "Kamata"), jk("07:33"),
        jk("07:37"), jk("07:43", to: "Isogo"), jk("07:47", to: "Tsurumi"),
        jk("07:53"), jk("07:57"), jk("08:03", to: "Isogo"),
        jk("08:07"), jk("08:13", to: "Isogo"), jk("08:18", to: "Kamata"),
        jk("08:24"), jk("08:27", to: "Isogo"), jk("08:33"),
        jk("08:37", to: "Isogo"), jk("08:43"), jk("08:47", to: "Isogo"),
        jk("08:53"), jk("08:57", to: "Kamata"), jk("09:03"),
        jk("09:07", to: "Isogo"), jk("09:13"), jk("09:17", to: "Kamata"),
        jk("09:23"), jk("09:27", to: "Isogo"), jk("09:33"),
        jk("09:37", to: "Isogo"), jk("09:44", to: "Kamata"), jk("09:54", to: "Kamata"),
        jk("10:04", to: "Kamata"), jk("10:14", to: "Isogo"), jk("10:19"),
        jk("10:28"), jk("10:38"), jk("10:48"),
        jk("10:58"), jk("11:09"), jk("11:19"),
        jk("11:29"), jk("11:39"), jk("11:49"),
        jk("11:59"), jk("12:09"), jk("12:19"),
        jk("12:29"), jk("12:39"), jk("12:49"),
        jk("12:59"), jk("13:09"), jk("13:19"),
        jk("13:29"), jk("13:39"), jk("13:49"),
        jk("13:59"), jk("14:09"), jk("14:19"),
        jk("14:29"), jk("14:39"), jk("14:48"),
        jk("14:59", to: "Kamata"), jk("15:09", to: "Isogo"), jk("15:19", to: "Isogo"),
        jk("15:29", to: "Kamata"), jk("15:39"), jk("15:49", to: "Isogo"),
        jk("15:59", to: "Isogo"), jk("16:09", to: "Kamata"), jk("16:19", to: "Isogo"),
        jk("16:28"), jk("16:39"), jk("16:44", to: "Isogo"),
        jk("16:54"), jk("16:59"), jk("17:08"),
        jk("17:14"), jk("17:19", to: "Tsurumi"), jk("17:29", to: "Sakuragicho"),
        jk("17:34"), jk("17:39", to: "Sakuragicho"), jk("17:49", to: "Isogo"),
        jk("17:54"), jk("18:04"), jk("18:09", to: "Sakuragicho"),
        jk("18:14"), jk("18:19", to: "Isogo"), jk("18:24"),
        jk("18:29"), jk("18:34", to: "Sakuragicho"), jk("18:39"),
        jk("18:49"), jk("18:53", to: "Sakuragicho"), jk("19:04", to: "Isogo"),
        jk("19:09"), jk("19:19"), jk("19:29", to: "Sakuragicho"),
        jk("19:35"), jk("19:41", to: "Isogo"), jk("19:51", to: "Isogo"),
        jk("19:59"), jk("20:10"), jk("20:20"),
        jk("20:29", to: "Isogo"), jk("20:39"), jk("20:46", to: "Isogo"),
        jk("20:54"), jk("21:04"), jk("21:17", to: "Sakuragicho"),
        jk("21:28", to: "Sakuragicho"), jk("21:42"), jk("21:55"),
        jk("22:02", to: "Sakuragicho"), jk("22:14", to: "Isogo"), jk("22:23"),
        jk("22:32"), jk("22:43", to: "Isogo"), jk("22:50"),
        jk("23:00", to: "Isogo"), jk("23:07", to: "Sakuragicho"), jk("23:14", to: "Kamata"),
        jk("23:22", to: "Kamata"), jk("23:29", to: "Kamata"), jk("23:38", to: "Kamata"),
        jk("23:43", to: "Akabane"), jk("23:57", to: "Akabane"), jk("24:15", to: "Akabane"),
    ]

    private static let keihinTohokuDownMinamiUrawaWd: [ExactRun] = [
        jk("04:30"), jk("04:49"), jk("05:11"),
        jk("05:33"), jk("06:05"), jk("06:15", to: "Isogo"),
        jk("06:24", to: "Isogo"), jk("06:43", to: "Tsurumi"), jk("06:55"),
        jk("07:04", to: "Tsurumi"), jk("07:15", to: "Kamata"), jk("07:26", to: "Kamata"),
        jk("07:40", to: "Tsurumi"), jk("07:54"), jk("08:05", to: "Kamata"),
        jk("08:14", to: "Kamata"), jk("08:23"), jk("08:35", to: "Kamata"),
        jk("08:42", to: "Kamata"), jk("08:53", to: "Kamata"), jk("10:25", to: "Isogo"),
        jk("10:41"), jk("10:56", to: "Kamata"), jk("11:16", to: "Kamata"),
        jk("11:26", to: "Isogo"), jk("11:36", to: "Kamata"), jk("11:46", to: "Isogo"),
        jk("11:56", to: "Kamata"), jk("12:06", to: "Isogo"), jk("12:16", to: "Kamata"),
        jk("12:26", to: "Isogo"), jk("12:36", to: "Kamata"), jk("12:46", to: "Isogo"),
        jk("12:56", to: "Kamata"), jk("13:06", to: "Isogo"), jk("13:16", to: "Kamata"),
        jk("13:26", to: "Isogo"), jk("13:36", to: "Kamata"), jk("13:46", to: "Isogo"),
        jk("13:56", to: "Kamata"), jk("14:06", to: "Isogo"), jk("14:16", to: "Isogo"),
        jk("14:26", to: "Kamata"), jk("14:36"), jk("14:46", to: "Kamata"),
        jk("14:56", to: "Isogo"), jk("15:06"), jk("15:16"),
        jk("15:26"), jk("15:36"), jk("15:46"),
        jk("15:56"), jk("16:06"), jk("16:15"),
        jk("16:25"), jk("16:35", to: "Isogo"), jk("16:44", to: "Sakuragicho"),
        jk("16:53", to: "Sakuragicho"), jk("17:02"), jk("17:18", to: "Sakuragicho"),
        jk("17:27", to: "Tsurumi"), jk("17:36"), jk("17:44"),
        jk("17:55", to: "Kamata"), jk("18:04", to: "Kamata"), jk("18:15"),
        jk("18:22", to: "Isogo"), jk("18:29", to: "Kamata"), jk("18:39"),
        jk("18:56"), jk("19:10", to: "Isogo"), jk("20:50", to: "Isogo"),
        jk("21:20"), jk("21:50"), jk("22:51", to: "Isogo"),
        jk("23:08", to: "Isogo"),
    ]

    private static let keihinTohokuDownMinamiUrawaHol: [ExactRun] = [
        jk("04:30"), jk("04:49"), jk("05:11"),
        jk("05:33"), jk("05:49"), jk("06:16"),
        jk("06:27"), jk("06:38"), jk("06:50"),
        jk("07:15"), jk("10:01"), jk("10:11"),
        jk("10:21"), jk("10:36", to: "Kamata"), jk("10:46", to: "Isogo"),
        jk("10:56", to: "Kamata"), jk("11:06", to: "Isogo"), jk("11:16", to: "Kamata"),
        jk("11:26", to: "Isogo"), jk("11:36", to: "Kamata"), jk("11:46", to: "Isogo"),
        jk("11:56", to: "Kamata"), jk("12:06", to: "Isogo"), jk("12:16", to: "Kamata"),
        jk("12:26", to: "Isogo"), jk("12:36", to: "Kamata"), jk("12:46", to: "Isogo"),
        jk("12:56", to: "Kamata"), jk("13:06", to: "Isogo"), jk("13:16", to: "Kamata"),
        jk("13:25", to: "Isogo"), jk("13:36", to: "Kamata"), jk("13:46", to: "Isogo"),
        jk("13:56", to: "Isogo"), jk("14:06", to: "Kamata"), jk("14:16", to: "Isogo"),
        jk("14:26", to: "Isogo"), jk("14:36", to: "Kamata"), jk("14:46", to: "Isogo"),
        jk("14:56", to: "Isogo"), jk("15:06"), jk("15:09", to: "Isogo"),
        jk("15:16"), jk("15:26"), jk("15:36"),
        jk("15:46", to: "Isogo"), jk("15:56"), jk("16:06"),
        jk("16:16"), jk("16:26"), jk("16:36"),
        jk("16:46", to: "Tsurumi"), jk("17:00"), jk("17:16", to: "Tsurumi"),
        jk("17:36"), jk("17:56"), jk("18:11", to: "Sakuragicho"),
        jk("18:56", to: "Isogo"), jk("19:10"), jk("19:26", to: "HigashiKanagawa"),
        jk("19:36", to: "Isogo"), jk("19:59"), jk("20:17", to: "Isogo"),
        jk("20:29", to: "Isogo"), jk("20:47"), jk("21:11", to: "Isogo"),
        jk("21:23", to: "Isogo"), jk("21:34"), jk("21:47"),
        jk("22:01", to: "Isogo"), jk("22:21"), jk("22:50", to: "Isogo"),
        jk("24:02", to: "Akabane"),
    ]

    private static let keihinTohokuDownAkabaneWd: [ExactRun] = [
        jk("08:43", to: "Isogo"), jk("09:05"), jk("09:29"),
        jk("09:46", to: "Kamata"), jk("09:58"), jk("10:28", to: "Kamata"),
    ]

    private static let keihinTohokuDownAkabaneHol: [ExactRun] = [
        jk("06:16"),
    ]

    private static let keihinTohokuDownHigashiJujoWd: [ExactRun] = [
        jk("04:32"), jk("05:34"), jk("06:56"),
    ]

    private static let keihinTohokuDownHigashiJujoHol: [ExactRun] = [
        jk("04:32"), jk("05:34", to: "Isogo"), jk("07:15"),
    ]

    private static let keihinTohokuDownTabataWd: [ExactRun] = [
        jk("04:25"),
    ]

    private static let keihinTohokuDownTabataHol: [ExactRun] = [
        jk("04:25"),
    ]

    private static let keihinTohokuDownKamataWd: [ExactRun] = [
        jk("04:33"), jk("04:49", to: "Sakuragicho"), jk("05:56"),
        jk("06:06"), jk("06:15", to: "Sakuragicho"), jk("06:37", to: "Sakuragicho"),
        jk("06:48"), jk("07:09", to: "Isogo"),
    ]

    private static let keihinTohokuDownKamataHol: [ExactRun] = [
        jk("04:33"), jk("04:49", to: "Sakuragicho"),
    ]

    private static let keihinTohokuDownHigashiKanagawaWd: [ExactRun] = [
        jk("04:34"), jk("05:26", to: "Sakuragicho"), jk("05:50", to: "Sakuragicho", thru: true),
        jk("06:10", to: "Sakuragicho", thru: true), jk("06:39", to: "Sakuragicho", thru: true), jk("07:00", to: "Sakuragicho", thru: true),
        jk("07:13"), jk("07:40", to: "Sakuragicho", thru: true), jk("07:53", to: "Isogo", thru: true),
        jk("08:05", to: "Sakuragicho", thru: true), jk("08:12", to: "Isogo", thru: true), jk("08:19", to: "Sakuragicho", thru: true),
        jk("08:25", to: "Isogo", thru: true), jk("08:35", thru: true), jk("08:42", to: "Isogo", thru: true),
        jk("09:03", thru: true), jk("09:27", to: "Sakuragicho", thru: true), jk("09:39", to: "Sakuragicho", thru: true),
        jk("09:47", to: "Sakuragicho", thru: true), jk("09:54", thru: true), jk("10:07", to: "Sakuragicho", thru: true),
        jk("10:19", to: "Sakuragicho", thru: true), jk("10:29", to: "Sakuragicho", thru: true), jk("10:38", to: "Sakuragicho", thru: true),
        jk("10:49", to: "Sakuragicho", thru: true), jk("10:58", to: "Sakuragicho", thru: true), jk("11:09", to: "Sakuragicho", thru: true),
        jk("11:19", to: "Sakuragicho", thru: true), jk("11:29", to: "Sakuragicho", thru: true), jk("11:39", to: "Sakuragicho", thru: true),
        jk("11:49", to: "Sakuragicho", thru: true), jk("11:59", to: "Sakuragicho", thru: true), jk("12:09", to: "Sakuragicho", thru: true),
        jk("12:19", to: "Sakuragicho", thru: true), jk("12:29", to: "Sakuragicho", thru: true), jk("12:39", to: "Sakuragicho", thru: true),
        jk("12:49", to: "Sakuragicho", thru: true), jk("12:59", to: "Sakuragicho", thru: true), jk("13:09", to: "Sakuragicho", thru: true),
        jk("13:19", to: "Sakuragicho", thru: true), jk("13:29", to: "Sakuragicho", thru: true), jk("13:39", to: "Sakuragicho", thru: true),
        jk("13:50", to: "Sakuragicho", thru: true), jk("13:59", to: "Sakuragicho", thru: true), jk("14:09", to: "Sakuragicho", thru: true),
        jk("14:19", to: "Sakuragicho", thru: true), jk("14:29", to: "Sakuragicho", thru: true), jk("14:39", to: "Sakuragicho", thru: true),
        jk("14:50", to: "Sakuragicho", thru: true), jk("14:59", to: "Sakuragicho", thru: true), jk("15:09", to: "Sakuragicho", thru: true),
        jk("15:19", to: "Sakuragicho", thru: true), jk("15:29", to: "Sakuragicho", thru: true), jk("15:39", to: "Sakuragicho", thru: true),
        jk("15:50", to: "Sakuragicho", thru: true), jk("15:59", to: "Sakuragicho", thru: true), jk("16:11", to: "Sakuragicho", thru: true),
        jk("16:20", to: "Sakuragicho", thru: true), jk("16:26", to: "Isogo", thru: true), jk("16:40", to: "Sakuragicho", thru: true),
        jk("16:55", to: "Isogo", thru: true), jk("17:09", to: "Sakuragicho", thru: true), jk("17:33", to: "Sakuragicho", thru: true),
        jk("17:44", to: "Sakuragicho", thru: true), jk("18:00", to: "Isogo", thru: true), jk("18:43", to: "Isogo", thru: true),
        jk("19:05", to: "Isogo", thru: true), jk("19:27", to: "Isogo", thru: true), jk("20:04", to: "Sakuragicho", thru: true),
        jk("20:12", to: "Sakuragicho", thru: true), jk("20:33", to: "Sakuragicho", thru: true), jk("21:24", to: "Sakuragicho", thru: true),
        jk("22:05", to: "Sakuragicho", thru: true), jk("23:08", to: "Sakuragicho", thru: true),
    ]

    private static let keihinTohokuDownHigashiKanagawaHol: [ExactRun] = [
        jk("04:33"), jk("05:24", to: "Sakuragicho"), jk("05:50", to: "Sakuragicho", thru: true),
        jk("06:31", to: "Sakuragicho", thru: true), jk("06:52", to: "Sakuragicho", thru: true), jk("07:34", to: "Isogo", thru: true),
        jk("07:50", to: "Sakuragicho", thru: true), jk("08:12", to: "Isogo", thru: true), jk("08:35", thru: true),
        jk("08:47", thru: true), jk("08:56", to: "Sakuragicho", thru: true), jk("09:09", to: "Sakuragicho", thru: true),
        jk("09:34", to: "Sakuragicho", thru: true), jk("09:44", thru: true), jk("09:58", to: "Sakuragicho", thru: true),
        jk("10:18", to: "Sakuragicho", thru: true), jk("10:29", to: "Sakuragicho", thru: true), jk("10:38", to: "Sakuragicho", thru: true),
        jk("10:49", to: "Sakuragicho", thru: true), jk("10:58", to: "Sakuragicho", thru: true), jk("11:09", to: "Sakuragicho", thru: true),
        jk("11:18", to: "Sakuragicho", thru: true), jk("11:29", to: "Sakuragicho", thru: true), jk("11:38", to: "Sakuragicho", thru: true),
        jk("11:49", to: "Sakuragicho", thru: true), jk("11:58", to: "Sakuragicho", thru: true), jk("12:09", to: "Sakuragicho", thru: true),
        jk("12:18", to: "Sakuragicho", thru: true), jk("12:29", to: "Sakuragicho", thru: true), jk("12:38", to: "Sakuragicho", thru: true),
        jk("12:49", to: "Sakuragicho", thru: true), jk("12:58", to: "Sakuragicho", thru: true), jk("13:09", to: "Sakuragicho", thru: true),
        jk("13:18", to: "Sakuragicho", thru: true), jk("13:29", to: "Sakuragicho", thru: true), jk("13:38", to: "Sakuragicho", thru: true),
        jk("13:49", to: "Sakuragicho", thru: true), jk("13:58", to: "Sakuragicho", thru: true), jk("14:09", to: "Sakuragicho", thru: true),
        jk("14:18", to: "Sakuragicho", thru: true), jk("14:29", to: "Sakuragicho", thru: true), jk("14:38", to: "Sakuragicho", thru: true),
        jk("14:49", to: "Sakuragicho", thru: true), jk("15:00", to: "Sakuragicho", thru: true), jk("15:09", to: "Sakuragicho", thru: true),
        jk("15:18", to: "Sakuragicho", thru: true), jk("15:29", to: "Sakuragicho", thru: true), jk("15:38", to: "Sakuragicho", thru: true),
        jk("15:49", to: "Sakuragicho", thru: true), jk("15:58", to: "Sakuragicho", thru: true), jk("16:09", to: "Sakuragicho", thru: true),
        jk("16:18", to: "Sakuragicho", thru: true), jk("16:29", to: "Sakuragicho", thru: true), jk("16:38", to: "Sakuragicho", thru: true),
        jk("16:49", to: "Sakuragicho", thru: true), jk("16:58", to: "Sakuragicho", thru: true), jk("17:09", to: "Sakuragicho", thru: true),
        jk("17:18", to: "Sakuragicho", thru: true), jk("17:29", to: "Sakuragicho", thru: true), jk("17:38", to: "Sakuragicho", thru: true),
        jk("17:58", to: "Sakuragicho", thru: true), jk("18:18", to: "Isogo", thru: true), jk("18:30", to: "Sakuragicho", thru: true),
        jk("19:04", to: "Isogo", thru: true), jk("19:55", to: "Isogo", thru: true), jk("20:44", to: "Sakuragicho", thru: true),
        jk("21:35", to: "Sakuragicho", thru: true), jk("22:19", to: "Sakuragicho", thru: true), jk("23:06", to: "Sakuragicho", thru: true),
    ]

    private static let keihinTohokuDownIsogoWd: [ExactRun] = [
        jk("07:10"),
    ]

    private static let keihinTohokuDownIsogoHol: [ExactRun] = [
    ]

    private static let keihinTohokuUpOfunaWd: [ExactRun] = [
        jk("04:43"), jk("05:15"), jk("05:31"),
        jk("05:45"), jk("05:59", to: "MinamiUrawa"), jk("06:10", to: "MinamiUrawa"),
        jk("06:21"), jk("06:33"), jk("06:43"),
        jk("06:47"), jk("06:51", to: "Akabane"), jk("06:54"),
        jk("07:00"), jk("07:04"), jk("07:07", to: "MinamiUrawa"),
        jk("07:12"), jk("07:15", to: "MinamiUrawa"), jk("07:22"),
        jk("07:27"), jk("07:31", to: "MinamiUrawa"), jk("07:39"),
        jk("07:43", to: "MinamiUrawa"), jk("07:53", to: "Akabane"), jk("08:00"),
        jk("08:07"), jk("08:17", to: "MinamiUrawa"), jk("08:27", to: "MinamiUrawa"),
        jk("08:35", to: "Akabane"), jk("08:43", to: "MinamiUrawa"), jk("08:50"),
        jk("08:55", to: "MinamiUrawa"), jk("09:00"), jk("09:06", to: "MinamiUrawa"),
        jk("09:11"), jk("09:18"), jk("09:26", to: "MinamiUrawa"),
        jk("09:31"), jk("09:46", to: "MinamiUrawa"), jk("09:57", to: "MinamiUrawa"),
        jk("10:05", to: "MinamiUrawa"), jk("10:11"), jk("10:20"),
        jk("10:26", to: "MinamiUrawa"), jk("10:41"), jk("10:52"),
        jk("11:01"), jk("11:12"), jk("11:21"),
        jk("11:31"), jk("11:42"), jk("11:51"),
        jk("12:02"), jk("12:11"), jk("12:22"),
        jk("12:31"), jk("12:42"), jk("12:51"),
        jk("13:02"), jk("13:11"), jk("13:21"),
        jk("13:31"), jk("13:42"), jk("13:51"),
        jk("14:01"), jk("14:11"), jk("14:22"),
        jk("14:32", to: "MinamiUrawa"), jk("14:41"), jk("14:51"),
        jk("15:02"), jk("15:12"), jk("15:22"),
        jk("15:32"), jk("15:42"), jk("15:51"),
        jk("16:03"), jk("16:11"), jk("16:21", to: "MinamiUrawa"),
        jk("16:31"), jk("16:41"), jk("16:48"),
        jk("16:55"), jk("17:06", to: "MinamiUrawa"), jk("17:16"),
        jk("17:28"), jk("17:34"), jk("17:44", to: "MinamiUrawa"),
        jk("17:53", to: "MinamiUrawa"), jk("18:01"), jk("18:10"),
        jk("18:21"), jk("18:27", to: "MinamiUrawa"), jk("18:36"),
        jk("18:46", to: "MinamiUrawa"), jk("18:53"), jk("19:01", to: "MinamiUrawa"),
        jk("19:05"), jk("19:12"), jk("19:21"),
        jk("19:27"), jk("19:35"), jk("19:43"),
        jk("19:47", to: "MinamiUrawa"), jk("19:55", to: "MinamiUrawa"), jk("20:07"),
        jk("20:16"), jk("20:24"), jk("20:37", to: "MinamiUrawa"),
        jk("20:48"), jk("20:52", to: "HigashiKanagawa", cont: true), jk("21:03"),
        jk("21:07", to: "MinamiUrawa"), jk("21:16"), jk("21:29"),
        jk("21:35", to: "HigashiKanagawa", cont: true), jk("21:42"), jk("21:52"),
        jk("22:02"), jk("22:12"), jk("22:22"),
        jk("22:35"), jk("22:47"), jk("22:57", to: "MinamiUrawa"),
        jk("23:10", to: "MinamiUrawa"), jk("23:29", to: "Ueno"), jk("23:48", to: "Kamata"),
        jk("24:09", to: "Isogo"),
    ]

    private static let keihinTohokuUpOfunaHol: [ExactRun] = [
        jk("04:43"), jk("05:12"), jk("05:32"),
        jk("05:45"), jk("05:58"), jk("06:12"),
        jk("06:24"), jk("06:35"), jk("06:46"),
        jk("06:54"), jk("07:02"), jk("07:07"),
        jk("07:12"), jk("07:22"), jk("07:28"),
        jk("07:32"), jk("07:42", to: "MinamiUrawa"), jk("07:47"),
        jk("07:52", to: "MinamiUrawa"), jk("07:57"), jk("08:02", to: "MinamiUrawa"),
        jk("08:11"), jk("08:17", to: "MinamiUrawa"), jk("08:21"),
        jk("08:27"), jk("08:32", to: "MinamiUrawa"), jk("08:43"),
        jk("08:50", to: "MinamiUrawa"), jk("08:57"), jk("09:02", to: "MinamiUrawa"),
        jk("09:11", to: "MinamiUrawa"), jk("09:20"), jk("09:31"),
        jk("09:41"), jk("09:51"), jk("10:01"),
        jk("10:11"), jk("10:21"), jk("10:31"),
        jk("10:42"), jk("10:51"), jk("11:02"),
        jk("11:11"), jk("11:21"), jk("11:31"),
        jk("11:41"), jk("11:51"), jk("12:01"),
        jk("12:11"), jk("12:21"), jk("12:31"),
        jk("12:41"), jk("12:51"), jk("13:01"),
        jk("13:11"), jk("13:21"), jk("13:31"),
        jk("13:41"), jk("13:51"), jk("14:01"),
        jk("14:11"), jk("14:21"), jk("14:31", to: "MinamiUrawa"),
        jk("14:41", to: "MinamiUrawa"), jk("14:51"), jk("15:05"),
        jk("15:15", to: "MinamiUrawa"), jk("15:25"), jk("15:34", to: "MinamiUrawa"),
        jk("15:46"), jk("15:55"), jk("16:06"),
        jk("16:14"), jk("16:23"), jk("16:31"),
        jk("16:41", to: "MinamiUrawa"), jk("16:53"), jk("17:02", to: "MinamiUrawa"),
        jk("17:11"), jk("17:22"), jk("17:34", to: "MinamiUrawa"),
        jk("17:41", to: "HigashiKanagawa", cont: true), jk("17:45", to: "MinamiUrawa"), jk("17:51"),
        jk("17:55", to: "HigashiKanagawa", cont: true), jk("18:01"), jk("18:11"),
        jk("18:20"), jk("18:30"), jk("18:37"),
        jk("18:46"), jk("18:56"), jk("19:03", to: "MinamiUrawa"),
        jk("19:06"), jk("19:16"), jk("19:22", to: "MinamiUrawa"),
        jk("19:31", to: "MinamiUrawa"), jk("19:41", to: "MinamiUrawa"), jk("19:52", to: "MinamiUrawa"),
        jk("20:04", to: "MinamiUrawa"), jk("20:17", to: "MinamiUrawa"), jk("20:29"),
        jk("20:34"), jk("20:42", to: "MinamiUrawa"), jk("20:49"),
        jk("21:01"), jk("21:08"), jk("21:17"),
        jk("21:32"), jk("21:48", to: "HigashiKanagawa", cont: true), jk("21:52"),
        jk("21:59", to: "MinamiUrawa"), jk("22:13", to: "MinamiUrawa"), jk("22:22"),
        jk("22:34"), jk("22:46"), jk("22:57", to: "MinamiUrawa"),
        jk("23:10", to: "MinamiUrawa"), jk("23:29", to: "Ueno"), jk("23:48", to: "Kamata"),
        jk("24:09", to: "Isogo"),
    ]

    private static let keihinTohokuUpIsogoWd: [ExactRun] = [
        jk("04:20"), jk("04:32"), jk("04:44"),
        jk("05:13"), jk("05:39"), jk("05:57"),
        jk("06:09"), jk("06:22"), jk("06:34", to: "MinamiUrawa"),
        jk("06:46", to: "MinamiUrawa"), jk("06:57"), jk("07:14"),
        jk("07:35"), jk("07:52", to: "MinamiUrawa"), jk("08:03", to: "MinamiUrawa"),
        jk("08:12"), jk("08:27", to: "HigashiKanagawa", cont: true), jk("08:40", to: "HigashiKanagawa", cont: true),
        jk("08:54", to: "HigashiKanagawa", cont: true), jk("09:14", to: "HigashiKanagawa", cont: true), jk("09:52", to: "MinamiUrawa"),
        jk("10:07"), jk("10:47"), jk("11:04", to: "MinamiUrawa"),
        jk("11:23", to: "MinamiUrawa"), jk("11:43", to: "MinamiUrawa"), jk("12:03", to: "MinamiUrawa"),
        jk("12:23", to: "MinamiUrawa"), jk("12:43", to: "MinamiUrawa"), jk("13:03", to: "MinamiUrawa"),
        jk("13:23", to: "MinamiUrawa"), jk("13:43", to: "MinamiUrawa"), jk("14:03", to: "MinamiUrawa"),
        jk("14:23", to: "MinamiUrawa"), jk("14:43"), jk("15:04"),
        jk("15:23"), jk("15:43"), jk("16:01"),
        jk("16:15"), jk("16:44", to: "MinamiUrawa"), jk("16:54"),
        jk("17:01", to: "HigashiKanagawa", cont: true), jk("17:20"), jk("17:28", to: "HigashiKanagawa", cont: true),
        jk("17:41", to: "MinamiUrawa"), jk("17:47"), jk("17:58"),
        jk("18:05"), jk("18:20"), jk("18:30", to: "HigashiKanagawa", cont: true),
        jk("18:57"), jk("19:13", to: "HigashiKanagawa", cont: true), jk("19:33", to: "HigashiKanagawa", cont: true),
        jk("19:47", to: "MinamiUrawa"), jk("19:55", to: "HigashiKanagawa", cont: true), jk("20:08"),
        jk("20:17"), jk("20:28"), jk("20:49"),
        jk("21:13"), jk("21:28"), jk("21:48"),
        jk("22:03"), jk("23:07", to: "MinamiUrawa"),
    ]

    private static let keihinTohokuUpIsogoHol: [ExactRun] = [
        jk("04:20"), jk("04:30"), jk("04:41"),
        jk("05:14"), jk("05:39"), jk("05:57"),
        jk("06:09"), jk("06:24"), jk("06:35"),
        jk("06:48"), jk("06:58"), jk("07:07"),
        jk("07:54"), jk("08:22", to: "HigashiKanagawa", cont: true), jk("08:40", to: "HigashiKanagawa", cont: true),
        jk("08:53"), jk("09:25"), jk("09:42", to: "MinamiUrawa"),
        jk("10:02", to: "MinamiUrawa"), jk("10:23", to: "MinamiUrawa"), jk("10:43", to: "MinamiUrawa"),
        jk("11:03", to: "MinamiUrawa"), jk("11:23", to: "MinamiUrawa"), jk("11:43", to: "MinamiUrawa"),
        jk("12:03", to: "MinamiUrawa"), jk("12:23", to: "MinamiUrawa"), jk("12:43", to: "MinamiUrawa"),
        jk("13:03", to: "MinamiUrawa"), jk("13:23", to: "MinamiUrawa"), jk("13:43", to: "MinamiUrawa"),
        jk("14:03", to: "MinamiUrawa"), jk("14:23", to: "MinamiUrawa"), jk("14:34", to: "MinamiUrawa"),
        jk("14:43"), jk("15:03"), jk("15:15"),
        jk("15:27"), jk("15:36"), jk("15:57"),
        jk("16:07", to: "MinamiUrawa"), jk("16:27"), jk("16:35"),
        jk("16:52"), jk("17:06", to: "MinamiUrawa"), jk("17:16"),
        jk("17:31"), jk("17:47"), jk("17:54"),
        jk("18:22", to: "MinamiUrawa"), jk("18:41", to: "MinamiUrawa"), jk("18:49", to: "HigashiKanagawa", cont: true),
        jk("19:35", to: "HigashiKanagawa", cont: true), jk("19:52"), jk("20:14"),
        jk("20:24", to: "HigashiKanagawa", cont: true), jk("20:39"), jk("21:10"),
        jk("21:41"), jk("21:53"), jk("22:00", to: "MinamiUrawa"),
        jk("22:21"),
    ]

    private static let keihinTohokuUpSakuragichoWd: [ExactRun] = [
        jk("04:18"), jk("05:30"), jk("05:39", to: "HigashiKanagawa", cont: true),
        jk("06:06", to: "HigashiKanagawa", cont: true), jk("06:24", to: "HigashiKanagawa", cont: true), jk("06:43"),
        jk("06:53", to: "HigashiKanagawa", cont: true), jk("07:05"), jk("07:15", to: "HigashiKanagawa", cont: true),
        jk("07:32", to: "MinamiUrawa"), jk("07:54", to: "HigashiKanagawa", cont: true), jk("08:04", to: "Akabane"),
        jk("08:18", to: "HigashiKanagawa", cont: true), jk("08:32", to: "HigashiKanagawa", cont: true), jk("08:43", to: "MinamiUrawa"),
        jk("09:10"), jk("09:42", to: "HigashiKanagawa", cont: true), jk("09:51", to: "HigashiKanagawa", cont: true),
        jk("10:01", to: "HigashiKanagawa", cont: true), jk("10:21", to: "HigashiKanagawa", cont: true), jk("10:31", to: "HigashiKanagawa", cont: true),
        jk("10:42", to: "HigashiKanagawa", cont: true), jk("10:52", to: "HigashiKanagawa", cont: true), jk("11:01", to: "HigashiKanagawa", cont: true),
        jk("11:12", to: "HigashiKanagawa", cont: true), jk("11:22", to: "HigashiKanagawa", cont: true), jk("11:32", to: "HigashiKanagawa", cont: true),
        jk("11:42", to: "HigashiKanagawa", cont: true), jk("11:52", to: "HigashiKanagawa", cont: true), jk("12:01", to: "HigashiKanagawa", cont: true),
        jk("12:12", to: "HigashiKanagawa", cont: true), jk("12:21", to: "HigashiKanagawa", cont: true), jk("12:32", to: "HigashiKanagawa", cont: true),
        jk("12:42", to: "HigashiKanagawa", cont: true), jk("12:52", to: "HigashiKanagawa", cont: true), jk("13:01", to: "HigashiKanagawa", cont: true),
        jk("13:12", to: "HigashiKanagawa", cont: true), jk("13:21", to: "HigashiKanagawa", cont: true), jk("13:32", to: "HigashiKanagawa", cont: true),
        jk("13:42", to: "HigashiKanagawa", cont: true), jk("13:52", to: "HigashiKanagawa", cont: true), jk("14:02", to: "HigashiKanagawa", cont: true),
        jk("14:12", to: "HigashiKanagawa", cont: true), jk("14:21", to: "HigashiKanagawa", cont: true), jk("14:32", to: "HigashiKanagawa", cont: true),
        jk("14:42", to: "HigashiKanagawa", cont: true), jk("14:53", to: "HigashiKanagawa", cont: true), jk("15:02", to: "HigashiKanagawa", cont: true),
        jk("15:12", to: "HigashiKanagawa", cont: true), jk("15:21", to: "HigashiKanagawa", cont: true), jk("15:32", to: "HigashiKanagawa", cont: true),
        jk("15:42", to: "HigashiKanagawa", cont: true), jk("15:52", to: "HigashiKanagawa", cont: true), jk("16:02", to: "HigashiKanagawa", cont: true),
        jk("16:15", to: "HigashiKanagawa", cont: true), jk("16:23", to: "HigashiKanagawa", cont: true), jk("16:33", to: "HigashiKanagawa", cont: true),
        jk("16:43"), jk("16:57", to: "HigashiKanagawa", cont: true), jk("17:11"),
        jk("17:25", to: "HigashiKanagawa", cont: true), jk("17:37"), jk("17:47", to: "HigashiKanagawa", cont: true),
        jk("18:01", to: "HigashiKanagawa", cont: true), jk("18:15"), jk("18:24"),
        jk("18:36", to: "MinamiUrawa"), jk("19:01"), jk("19:17"),
        jk("19:43", to: "MinamiUrawa"), jk("20:17", to: "HigashiKanagawa", cont: true), jk("20:31", to: "HigashiKanagawa", cont: true),
        jk("20:49", to: "HigashiKanagawa", cont: true), jk("21:10"), jk("21:19", to: "MinamiUrawa"),
        jk("21:37", to: "HigashiKanagawa", cont: true), jk("21:49", to: "MinamiUrawa"), jk("22:18", to: "HigashiKanagawa", cont: true),
        jk("22:34"), jk("22:45", to: "MinamiUrawa"), jk("22:57", to: "MinamiUrawa"),
        jk("23:10", to: "MinamiUrawa"), jk("23:22", to: "HigashiKanagawa", cont: true),
    ]

    private static let keihinTohokuUpSakuragichoHol: [ExactRun] = [
        jk("04:18"), jk("05:18"), jk("05:37", to: "HigashiKanagawa", cont: true),
        jk("06:03", to: "HigashiKanagawa", cont: true), jk("06:55", to: "HigashiKanagawa", cont: true), jk("07:12", to: "HigashiKanagawa", cont: true),
        jk("07:45"), jk("08:03", to: "HigashiKanagawa", cont: true), jk("09:09", to: "HigashiKanagawa", cont: true),
        jk("09:21", to: "HigashiKanagawa", cont: true), jk("10:01", to: "HigashiKanagawa", cont: true), jk("10:21", to: "HigashiKanagawa", cont: true),
        jk("10:32", to: "HigashiKanagawa", cont: true), jk("10:41", to: "HigashiKanagawa", cont: true), jk("10:52", to: "HigashiKanagawa", cont: true),
        jk("11:01", to: "HigashiKanagawa", cont: true), jk("11:12", to: "HigashiKanagawa", cont: true), jk("11:21", to: "HigashiKanagawa", cont: true),
        jk("11:32", to: "HigashiKanagawa", cont: true), jk("11:41", to: "HigashiKanagawa", cont: true), jk("11:52", to: "HigashiKanagawa", cont: true),
        jk("12:01", to: "HigashiKanagawa", cont: true), jk("12:12", to: "HigashiKanagawa", cont: true), jk("12:21", to: "HigashiKanagawa", cont: true),
        jk("12:32", to: "HigashiKanagawa", cont: true), jk("12:41", to: "HigashiKanagawa", cont: true), jk("12:52", to: "HigashiKanagawa", cont: true),
        jk("13:01", to: "HigashiKanagawa", cont: true), jk("13:12", to: "HigashiKanagawa", cont: true), jk("13:21", to: "HigashiKanagawa", cont: true),
        jk("13:32", to: "HigashiKanagawa", cont: true), jk("13:41", to: "HigashiKanagawa", cont: true), jk("13:52", to: "HigashiKanagawa", cont: true),
        jk("14:01", to: "HigashiKanagawa", cont: true), jk("14:12", to: "HigashiKanagawa", cont: true), jk("14:21", to: "HigashiKanagawa", cont: true),
        jk("14:32", to: "HigashiKanagawa", cont: true), jk("14:41", to: "HigashiKanagawa", cont: true), jk("14:52", to: "HigashiKanagawa", cont: true),
        jk("15:01", to: "HigashiKanagawa", cont: true), jk("15:12", to: "HigashiKanagawa", cont: true), jk("15:21", to: "HigashiKanagawa", cont: true),
        jk("15:31", to: "HigashiKanagawa", cont: true), jk("15:41", to: "HigashiKanagawa", cont: true), jk("15:51", to: "HigashiKanagawa", cont: true),
        jk("16:01", to: "HigashiKanagawa", cont: true), jk("16:11", to: "HigashiKanagawa", cont: true), jk("16:21", to: "HigashiKanagawa", cont: true),
        jk("16:32", to: "HigashiKanagawa", cont: true), jk("16:41", to: "HigashiKanagawa", cont: true), jk("16:53", to: "HigashiKanagawa", cont: true),
        jk("17:01", to: "HigashiKanagawa", cont: true), jk("17:12", to: "HigashiKanagawa", cont: true), jk("17:21", to: "HigashiKanagawa", cont: true),
        jk("17:30", to: "HigashiKanagawa", cont: true), jk("17:41", to: "HigashiKanagawa", cont: true), jk("17:53", to: "HigashiKanagawa", cont: true),
        jk("18:16", to: "HigashiKanagawa", cont: true), jk("18:43", to: "HigashiKanagawa", cont: true), jk("19:09", to: "MinamiUrawa"),
        jk("19:20", to: "MinamiUrawa"), jk("19:39", to: "MinamiUrawa"), jk("19:53"),
        jk("20:15"), jk("20:39"), jk("20:59", to: "HigashiKanagawa", cont: true),
        jk("21:49", to: "HigashiKanagawa", cont: true), jk("22:47", to: "HigashiKanagawa", cont: true), jk("22:57", to: "MinamiUrawa"),
        jk("23:09", to: "MinamiUrawa"), jk("23:22", to: "HigashiKanagawa", cont: true),
    ]

    private static let keihinTohokuUpHigashiKanagawaWd: [ExactRun] = [
        jk("16:11"),
    ]

    private static let keihinTohokuUpHigashiKanagawaHol: [ExactRun] = [
    ]

    private static let keihinTohokuUpTsurumiWd: [ExactRun] = [
        jk("08:08", to: "MinamiUrawa"), jk("08:41", to: "MinamiUrawa"), jk("08:47", to: "Akabane"),
        jk("08:59"), jk("09:07"), jk("09:15"),
        jk("09:55", to: "MinamiUrawa"), jk("18:59"),
    ]

    private static let keihinTohokuUpTsurumiHol: [ExactRun] = [
        jk("08:48"), jk("09:23", to: "MinamiUrawa"), jk("18:07", to: "MinamiUrawa"),
        jk("18:37", to: "MinamiUrawa"), jk("18:57", to: "MinamiUrawa"),
    ]

    private static let keihinTohokuUpKamataWd: [ExactRun] = [
        jk("04:22"), jk("05:38"), jk("05:59"),
        jk("06:17"), jk("06:26"), jk("06:34"),
        jk("06:43"), jk("06:54"), jk("07:14"),
        jk("07:30", to: "MinamiUrawa"), jk("07:38", to: "MinamiUrawa"), jk("07:48", to: "MinamiUrawa"),
        jk("08:03", to: "Akabane"), jk("08:13", to: "MinamiUrawa"), jk("08:26"),
        jk("08:39"), jk("10:30"), jk("10:50"),
        jk("11:06", to: "MinamiUrawa"), jk("11:26", to: "MinamiUrawa"), jk("11:46", to: "MinamiUrawa"),
        jk("12:06", to: "MinamiUrawa"), jk("12:26", to: "MinamiUrawa"), jk("12:46", to: "MinamiUrawa"),
        jk("13:06", to: "MinamiUrawa"), jk("13:26", to: "MinamiUrawa"), jk("13:46", to: "MinamiUrawa"),
        jk("14:06", to: "MinamiUrawa"), jk("14:26", to: "MinamiUrawa"), jk("14:46", to: "MinamiUrawa"),
        jk("15:06", to: "MinamiUrawa"), jk("15:26"), jk("15:45"),
        jk("16:06"), jk("16:46"), jk("17:03", to: "MinamiUrawa"),
        jk("17:14"), jk("17:24", to: "MinamiUrawa"), jk("17:36", to: "MinamiUrawa"),
        jk("17:43", to: "MinamiUrawa"), jk("17:50"), jk("17:59"),
        jk("18:05", to: "MinamiUrawa"), jk("18:11"), jk("18:23", to: "MinamiUrawa"),
    ]

    private static let keihinTohokuUpKamataHol: [ExactRun] = [
        jk("04:22"), jk("05:24"), jk("05:55"),
        jk("06:07"), jk("06:17"), jk("06:27"),
        jk("06:52"), jk("07:12"), jk("10:27", to: "MinamiUrawa"),
        jk("10:47", to: "MinamiUrawa"), jk("11:06", to: "MinamiUrawa"), jk("11:26", to: "MinamiUrawa"),
        jk("11:46", to: "MinamiUrawa"), jk("12:06", to: "MinamiUrawa"), jk("12:26", to: "MinamiUrawa"),
        jk("12:46", to: "MinamiUrawa"), jk("13:06", to: "MinamiUrawa"), jk("13:26", to: "MinamiUrawa"),
        jk("13:46", to: "MinamiUrawa"), jk("14:06", to: "MinamiUrawa"), jk("14:26", to: "MinamiUrawa"),
        jk("14:46", to: "MinamiUrawa"), jk("15:26"), jk("15:45", to: "MinamiUrawa"),
        jk("16:20"), jk("16:50"), jk("17:35"),
    ]

    private static let keihinTohokuUpUenoWd: [ExactRun] = [
        jk("04:28"),
    ]

    private static let keihinTohokuUpUenoHol: [ExactRun] = [
        jk("04:28"),
    ]

    private static let keihinTohokuUpMinamiUrawaWd: [ExactRun] = [
        jk("05:11"), jk("05:30"), jk("05:46"),
        jk("05:57"), jk("06:13"), jk("06:25"),
        jk("06:30"), jk("06:41"), jk("06:50"),
        jk("06:57"), jk("07:04"), jk("07:14"),
        jk("07:24"),
    ]

    private static let keihinTohokuUpMinamiUrawaHol: [ExactRun] = [
        jk("05:09"),
    ]

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
                    first: "04:51", last: "23:46",
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
                    "りんかい線", "Rinkai Line", "新木場方面", "for Shin-Kiba",
                    to: "Railway:TWR.Rinkai"),
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
            through("Keiyo.IchikawaShiohama", .ascending,
                    "武蔵野線", "JR Musashino Line",
                    "西船橋・南流山方面", "for Nishi-Funabashi & Minami-Nagareyama",
                    to: "Railway:JR-East.KeiyoBranch"),
        ]
    )
}
