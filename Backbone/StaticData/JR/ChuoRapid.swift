import Foundation

extension JREastLineData {

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
        exactStationTimes: chuoRapidTimetable,
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
}
