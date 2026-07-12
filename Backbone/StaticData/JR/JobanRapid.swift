import Foundation

extension JREastLineData {

    // MARK: - Joban Rapid Line (JJ)

    static let jobanRapid = StaticTrainLine(
        id: "Railway:JR-East.JobanRapid",
        nameJa: "常磐線快速",
        nameEn: "Joban Rapid Line",
        operatorId: "Operator:JR-East",
        colorHex: "#00B261",
        // The 品川–東京–上野 corridor (上野東京ライン) is part of the official
        // JJ line: through trains all continue to 品川, so it is modeled as
        // line stations rather than a through service.
        stations: [
            st("JobanRapid", "Shinagawa", "品川", "Shinagawa", "JJ01", 35.6285, 139.7388),
            st("JobanRapid", "Shimbashi", "新橋", "Shimbashi", "JJ02", 35.6663, 139.7583),
            st("JobanRapid", "Tokyo", "東京", "Tokyo", "JJ03", 35.6812, 139.7671),
            st("JobanRapid", "Ueno", "上野", "Ueno", "JJ04", 35.7141, 139.7774),
            st("JobanRapid", "Nippori", "日暮里", "Nippori", "JJ05", 35.7278, 139.7708),
            st("JobanRapid", "Mikawashima", "三河島", "Mikawashima", "JJ06", 35.7325, 139.7794),
            st("JobanRapid", "MinamiSenju", "南千住", "Minami-Senju", "JJ07", 35.7333, 139.7995),
            st("JobanRapid", "KitaSenju", "北千住", "Kita-Senju", "JJ08", 35.7497, 139.8047),
            st("JobanRapid", "Matsudo", "松戸", "Matsudo", "JJ09", 35.7841, 139.9010),
            st("JobanRapid", "Kashiwa", "柏", "Kashiwa", "JJ10", 35.8622, 139.9707),
            st("JobanRapid", "Abiko", "我孫子", "Abiko", "JJ11", 35.8687, 140.0277),
            st("JobanRapid", "Tennodai", "天王台", "Tennodai", "JJ12", 35.8700, 140.0672),
            st("JobanRapid", "Toride", "取手", "Toride", "JJ13", 35.8973, 140.0629),
        ],
        // Down-direction medians (dep-to-dep per hop) from the July-2026 grid
        // (642d1/d2): 東京→上野 7 (Ueno dwell), 北千住→松戸 9, 松戸→柏 8, 柏→我孫子 5.
        hopTimesMinutes: [5, 4, 7, 3, 2, 3, 3, 9, 8, 5, 3, 4],
        // Up trains run a different profile (medians from the July-2026 up grid,
        // 快速/普通 all-stops): slower over 柏/我孫子 (dwell), faster on the 上野
        // approach. 取手→松戸 is 22 min up vs 20 down, so up times no longer
        // land early. Same ascending orientation as hopTimesMinutes.
        upHopTimesMinutes: [5, 3, 6, 3, 2, 3, 3, 9, 9, 5, 4, 4],
        // Real per-station times per run (642 grids) → station timetables match
        // the source 1:1; hop projection above is only the fallback for any run
        // without a grid match. See JobanRapidTimetable.swift.
        exactStationTimes: jobanRapidTimetable,
        // Real exact runs, July-2026 revision (timetables.jreast.co.jp).
        // Down trains originate at 品川 (through-corridor, 06:35–22:56 only),
        // 上野 (the many 上野始発, incl. the 04:33 first), plus single
        // 松戸/我孫子 short-turn origins; up trains enter at 取手 (● =
        // 取手始発, rest through from 土浦方面), at 我孫子 (成田線直通,
        // 20/day), and 松戸. Termini within the line (上野行き/松戸行き/
        // 我孫子行き incl. 成田線直通 leaving at 我孫子) are honored.
        // 特急ひたち・ときわ and 特別快速 are excluded (their stop patterns
        // skip stations the all-stops line model cannot express).
        directions: [
            direction("JobanRapid", "Toride", "取手方面", "For Toride", ascending: true,
                      weekday: exact(jobanRapidDownShinagawaWd, first: "06:35", last: "22:56", .rapid),
                      holiday: exact(jobanRapidDownShinagawaHol, first: "06:35", last: "22:56", .rapid),
                      intermediateOrigins: [
                          IntermediateOrigin(stationId: "Station:JR-East.JobanRapid.Ueno",
                                             weekdayRuns: jobanRapidDownUenoWd,
                                             saturdayHolidayRuns: jobanRapidDownUenoHol),
                          IntermediateOrigin(stationId: "Station:JR-East.JobanRapid.Matsudo",
                                             weekdayRuns: jobanRapidDownMatsudoWd,
                                             saturdayHolidayRuns: jobanRapidDownMatsudoHol),
                          IntermediateOrigin(stationId: "Station:JR-East.JobanRapid.Abiko",
                                             weekdayRuns: jobanRapidDownAbikoWd,
                                             saturdayHolidayRuns: jobanRapidDownAbikoHol),
                      ]),
            direction("JobanRapid", "Ueno", "上野・品川方面", "For Ueno & Shinagawa", ascending: false,
                      weekday: exact(jobanRapidUpTorideWd, first: "04:44", last: "24:18", .rapid),
                      holiday: exact(jobanRapidUpTorideHol, first: "04:44", last: "24:18", .rapid),
                      intermediateOrigins: [
                          IntermediateOrigin(stationId: "Station:JR-East.JobanRapid.Abiko",
                                             weekdayRuns: jobanRapidUpAbikoWd,
                                             saturdayHolidayRuns: jobanRapidUpAbikoHol),
                          IntermediateOrigin(stationId: "Station:JR-East.JobanRapid.Matsudo",
                                             weekdayRuns: jobanRapidUpMatsudoWd,
                                             saturdayHolidayRuns: jobanRapidUpMatsudoHol),
                      ]),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("JobanRapid.Toride", .ascending,
                    "常磐線", "JR Joban Line", "土浦・水戸方面", "for Tsuchiura & Mito"),
        ]
    )

    // MARK: - Joban Rapid Real Runs (July-2026 revision)

private static let jobanRapidDownShinagawaWd: [ExactRun] = [
    jj("06:35"), jj("07:22"), jj("09:09"), jj("09:38"),
    jj("09:52"), jj("10:17"), jj("10:36"), jj("10:55"),
    jj("11:17"), jj("11:35"), jj("11:55"), jj("12:17"),
    jj("12:35"), jj("12:55"), jj("13:17"), jj("13:35"),
    jj("13:55"), jj("14:17"), jj("14:35"), jj("15:17"),
    jj("15:35"), jj("16:17"), jj("16:35"), jj("16:55"),
    jj("17:06"), jj("17:22"), jj("17:30"), jj("17:48"),
    jj("18:07", to: "Abiko"), jj("18:24"), jj("18:33", to: "Abiko"), jj("18:55"),
    jj("19:09"), jj("19:27"), jj("19:34", to: "Abiko"), jj("19:54"),
    jj("20:04"), jj("20:25"), jj("20:33", to: "Abiko"), jj("20:54"),
    jj("21:06"), jj("21:26"), jj("21:39"), jj("21:55"),
    jj("22:07"), jj("22:26", to: "Abiko"), jj("22:36"), jj("22:56"),
]

private static let jobanRapidDownUenoWd: [ExactRun] = [
    jj("04:33"), jj("05:03"), jj("05:11"), jj("05:31"),
    jj("05:51"), jj("06:04"), jj("06:13"), jj("06:22"),
    jj("06:31"), jj("06:41"), jj("06:54"), jj("07:02"),
    jj("07:10"), jj("07:16", to: "Abiko"), jj("07:24"), jj("07:33"),
    jj("07:50"), jj("07:57"), jj("08:06"), jj("08:14"),
    jj("08:25"), jj("08:35"), jj("08:39", to: "Abiko"), jj("08:49"),
    jj("08:55"), jj("09:06"), jj("09:12"), jj("09:20"),
    jj("09:35", to: "Abiko"), jj("09:45"), jj("10:16"), jj("10:20", to: "Matsudo"),
    jj("10:39", to: "Abiko"), jj("11:02"), jj("11:22"), jj("11:42", to: "Abiko"),
    jj("12:02"), jj("12:22"), jj("12:42", to: "Abiko"), jj("13:02"),
    jj("13:22"), jj("13:42", to: "Abiko"), jj("14:02"), jj("14:22"),
    jj("14:42", to: "Abiko"), jj("15:02"), jj("15:13"), jj("15:22"),
    jj("15:42", to: "Abiko"), jj("16:02"), jj("16:13"), jj("16:23"),
    jj("16:42"), jj("17:02"), jj("17:32"), jj("17:54"),
    jj("18:03", to: "Abiko"), jj("18:14"), jj("18:20"), jj("18:33"),
    jj("18:45"), jj("18:54"), jj("19:03"), jj("19:14", to: "Abiko"),
    jj("19:22"), jj("19:36"), jj("19:54"), jj("20:04"),
    jj("20:25"), jj("20:33"), jj("20:56"), jj("21:07"),
    jj("21:34"), jj("22:02", to: "Abiko"), jj("22:32"), jj("23:02"),
    jj("23:21"), jj("23:31"), jj("23:42"), jj("23:49"),
    jj("24:00"), jj("24:12", to: "Abiko"), jj("24:23", to: "Matsudo"), jj("24:33", to: "Matsudo"),
]

private static let jobanRapidDownMatsudoWd: [ExactRun] = [
    jj("04:36"), jj("06:00"),
]

private static let jobanRapidDownAbikoWd: [ExactRun] = [
    jj("06:26"),
]

private static let jobanRapidUpTorideWd: [ExactRun] = [
    jj("04:44", to: "Ueno"), jj("05:03", to: "Ueno"), jj("05:34", to: "Ueno"), jj("05:47", thru: true),
    jj("05:53", to: "Ueno"), jj("06:11", to: "Ueno", thru: true), jj("06:20", to: "Ueno"), jj("06:27", to: "Ueno"),
    jj("06:37", to: "Ueno"), jj("06:41", thru: true), jj("06:53"), jj("06:58", to: "Ueno", thru: true),
    jj("07:02", to: "Ueno"), jj("07:05", thru: true), jj("07:11", to: "Ueno", thru: true), jj("07:21"),
    jj("07:27", thru: true), jj("07:33"), jj("07:38", to: "Ueno", thru: true), jj("07:45", thru: true),
    jj("07:49", to: "Ueno"), jj("07:55", to: "Ueno", thru: true), jj("07:59", to: "Ueno"), jj("08:03", thru: true),
    jj("08:12", to: "Ueno", thru: true), jj("08:21", to: "Ueno"), jj("08:30", thru: true), jj("08:38", to: "Ueno"),
    jj("08:47", thru: true), jj("08:57", to: "Ueno"), jj("09:07", thru: true), jj("09:16", to: "Ueno"),
    jj("09:33", thru: true), jj("09:46", to: "Ueno"), jj("09:55", thru: true), jj("10:04", to: "Ueno"),
    jj("10:16", to: "Ueno", thru: true), jj("10:27", to: "Ueno"), jj("10:42", thru: true), jj("10:55", thru: true),
    jj("11:04", to: "Ueno"), jj("11:21", thru: true), jj("11:27", to: "Ueno"), jj("11:42", thru: true),
    jj("11:59", thru: true), jj("12:04", to: "Ueno"), jj("12:21", thru: true), jj("12:28", to: "Ueno"),
    jj("12:42", thru: true), jj("12:59", thru: true), jj("13:04", to: "Ueno"), jj("13:21", thru: true),
    jj("13:28", to: "Ueno"), jj("13:42", thru: true), jj("13:59", thru: true), jj("14:04", to: "Ueno"),
    jj("14:21", thru: true), jj("14:28", to: "Ueno"), jj("14:42", thru: true), jj("14:59", thru: true),
    jj("15:04", to: "Ueno"), jj("15:21", thru: true), jj("15:28", to: "Ueno"), jj("15:35", thru: true),
    jj("15:49", to: "Ueno"), jj("16:02", thru: true), jj("16:18", to: "Ueno", thru: true), jj("16:27", to: "Ueno"),
    jj("16:34", thru: true), jj("16:44"), jj("16:53", to: "Ueno", thru: true), jj("16:58", to: "Ueno"),
    jj("17:07", thru: true), jj("17:18", to: "Ueno"), jj("17:26", to: "Ueno", thru: true), jj("17:32", to: "Ueno"),
    jj("17:44", thru: true), jj("17:58", to: "Ueno", thru: true), jj("18:04", to: "Ueno"), jj("18:15", thru: true),
    jj("18:24"), jj("18:30", to: "Ueno", thru: true), jj("18:40", to: "Ueno"), jj("18:45", thru: true),
    jj("18:52", to: "Ueno"), jj("19:02", to: "Ueno", thru: true), jj("19:10"), jj("19:17", thru: true),
    jj("19:22", to: "Ueno"), jj("19:28", to: "Ueno", thru: true), jj("19:40"), jj("19:47", thru: true),
    jj("19:57", to: "Ueno"), jj("20:04", thru: true), jj("20:19"), jj("20:24", to: "Ueno", thru: true),
    jj("20:40", thru: true), jj("20:52", to: "Ueno"), jj("21:01", to: "Ueno", thru: true), jj("21:12"),
    jj("21:23", thru: true), jj("21:33", to: "Ueno"), jj("21:49", thru: true), jj("22:00", to: "Ueno"),
    jj("22:13", to: "Ueno", thru: true), jj("22:31", to: "Ueno", thru: true), jj("22:47", to: "Ueno", thru: true), jj("23:01", to: "Ueno"),
    jj("23:10", to: "Ueno", thru: true), jj("23:22", to: "Ueno"), jj("23:33", to: "Ueno"), jj("23:45", to: "Ueno"),
    jj("23:50", to: "Abiko", thru: true), jj("23:54", to: "Ueno"), jj("24:05", to: "Matsudo"), jj("24:18", to: "Matsudo"),
]

private static let jobanRapidUpAbikoWd: [ExactRun] = [
    jj("05:31", to: "Ueno", thru: true), jj("06:13", to: "Ueno", thru: true), jj("06:56", to: "Ueno", thru: true), jj("07:21", thru: true),
    jj("07:32", to: "Ueno", thru: true), jj("07:49", thru: true), jj("08:15", to: "Ueno", thru: true), jj("09:35", to: "Ueno", thru: true),
    jj("10:57", to: "Ueno", thru: true), jj("11:57", to: "Ueno", thru: true), jj("12:57", to: "Ueno", thru: true), jj("13:57", to: "Ueno", thru: true),
    jj("14:57", to: "Ueno", thru: true), jj("16:05", to: "Ueno", thru: true), jj("18:02", to: "Ueno", thru: true), jj("18:29", to: "Ueno", thru: true),
    jj("19:04", thru: true), jj("20:37", thru: true), jj("22:31", to: "Ueno", thru: true), jj("23:01", to: "Ueno", thru: true),
]

private static let jobanRapidUpMatsudoWd: [ExactRun] = [
    jj("04:36", to: "Ueno"), jj("16:41"),
]

private static let jobanRapidDownShinagawaHol: [ExactRun] = [
    jj("06:35"), jj("07:23"), jj("08:56"), jj("09:09"),
    jj("09:23"), jj("09:55"), jj("10:16"), jj("10:33"),
    jj("10:55"), jj("11:17"), jj("11:35"), jj("11:55"),
    jj("12:17"), jj("12:35"), jj("12:55"), jj("13:17"),
    jj("13:36"), jj("13:55"), jj("14:17"), jj("14:35"),
    jj("15:17"), jj("15:35"), jj("16:17"), jj("16:35"),
    jj("16:54"), jj("17:06"), jj("17:17"), jj("17:35", to: "Abiko"),
    jj("17:53"), jj("18:04", to: "Abiko"), jj("18:24"), jj("18:33", to: "Abiko"),
    jj("18:54"), jj("19:02"), jj("19:26"), jj("19:33"),
    jj("19:54"), jj("20:02"), jj("20:25"), jj("20:32", to: "Abiko"),
    jj("20:54"), jj("21:06"), jj("21:27"), jj("21:39"),
    jj("21:55"), jj("22:07"), jj("22:26", to: "Abiko"), jj("22:36"),
    jj("22:56"),
]

private static let jobanRapidDownUenoHol: [ExactRun] = [
    jj("04:33"), jj("05:03"), jj("05:11"), jj("05:31"),
    jj("05:51"), jj("06:04"), jj("06:13"), jj("06:22"),
    jj("06:31"), jj("06:41"), jj("06:54"), jj("07:02"),
    jj("07:10"), jj("07:16", to: "Abiko"), jj("07:24"), jj("07:33"),
    jj("07:47"), jj("07:54"), jj("08:02"), jj("08:12"),
    jj("08:18"), jj("08:24"), jj("08:35", to: "Abiko"), jj("08:42"),
    jj("08:49"), jj("08:57"), jj("09:05"), jj("09:18"),
    jj("09:34", to: "Abiko"), jj("09:38"), jj("09:54"), jj("10:08"),
    jj("10:17", to: "Matsudo"), jj("10:23", to: "Abiko"), jj("10:39", to: "Abiko"), jj("11:02"),
    jj("11:22"), jj("11:42", to: "Abiko"), jj("12:02"), jj("12:22"),
    jj("12:42", to: "Abiko"), jj("13:02"), jj("13:22"), jj("13:42", to: "Abiko"),
    jj("14:02"), jj("14:22"), jj("14:42", to: "Abiko"), jj("15:02"),
    jj("15:13"), jj("15:22"), jj("15:42", to: "Abiko"), jj("16:02"),
    jj("16:13"), jj("16:24", to: "Abiko"), jj("16:42"), jj("17:03"),
    jj("17:40"), jj("17:47"), jj("18:02"), jj("18:24"),
    jj("18:34"), jj("18:54"), jj("19:02"), jj("19:24"),
    jj("19:33"), jj("19:54"), jj("20:04", to: "Abiko"), jj("20:24"),
    jj("20:33"), jj("20:56"), jj("21:07"), jj("21:34"),
    jj("22:02", to: "Abiko"), jj("22:32"), jj("23:02"), jj("23:21"),
    jj("23:31"), jj("23:42"), jj("23:49"), jj("24:00"),
    jj("24:12", to: "Abiko"), jj("24:23", to: "Matsudo"), jj("24:33", to: "Matsudo"),
]

private static let jobanRapidDownMatsudoHol: [ExactRun] = [
    jj("04:36"),
]

private static let jobanRapidDownAbikoHol: [ExactRun] = [
    jj("06:26"),
]

private static let jobanRapidUpTorideHol: [ExactRun] = [
    jj("04:44", to: "Ueno"), jj("05:03", to: "Ueno"), jj("05:34", to: "Ueno"), jj("05:47", thru: true),
    jj("05:53", to: "Ueno"), jj("06:11", to: "Ueno", thru: true), jj("06:20", to: "Ueno"), jj("06:27", to: "Ueno"),
    jj("06:37", to: "Ueno"), jj("06:41", thru: true), jj("06:57", to: "Ueno", thru: true), jj("07:01", to: "Ueno"),
    jj("07:09", to: "Ueno", thru: true), jj("07:19", to: "Ueno"), jj("07:32", thru: true), jj("07:35", to: "Ueno"),
    jj("07:45", to: "Ueno", thru: true), jj("07:53", to: "Ueno"), jj("08:00", thru: true), jj("08:04", to: "Ueno"),
    jj("08:11", thru: true), jj("08:21", to: "Ueno"), jj("08:30", thru: true), jj("08:36", to: "Ueno"),
    jj("08:44", thru: true), jj("08:50", to: "Ueno"), jj("08:56", thru: true), jj("09:03", to: "Ueno"),
    jj("09:08", thru: true), jj("09:15", to: "Ueno"), jj("09:31", to: "Ueno"), jj("09:41", thru: true),
    jj("09:49", to: "Ueno"), jj("09:58", thru: true), jj("10:04", to: "Ueno"), jj("10:16", to: "Ueno", thru: true),
    jj("10:27", to: "Ueno"), jj("10:42", thru: true), jj("10:55", thru: true), jj("11:04", to: "Ueno"),
    jj("11:21", thru: true), jj("11:27", to: "Ueno"), jj("11:42", thru: true), jj("11:59", thru: true),
    jj("12:04", to: "Ueno"), jj("12:21", thru: true), jj("12:28", to: "Ueno"), jj("12:42", thru: true),
    jj("12:59", thru: true), jj("13:04", to: "Ueno"), jj("13:21", thru: true), jj("13:28", to: "Ueno"),
    jj("13:42", thru: true), jj("13:59", thru: true), jj("14:04", to: "Ueno"), jj("14:21", thru: true),
    jj("14:28", to: "Ueno"), jj("14:42", thru: true), jj("14:59", thru: true), jj("15:04", to: "Ueno"),
    jj("15:21", thru: true), jj("15:28", to: "Ueno"), jj("15:42", thru: true), jj("15:58", thru: true),
    jj("16:04", to: "Ueno"), jj("16:18", to: "Ueno", thru: true), jj("16:27"), jj("16:34", thru: true),
    jj("16:44", to: "Ueno"), jj("16:53", to: "Ueno", thru: true), jj("17:07", thru: true), jj("17:18"),
    jj("17:26", to: "Ueno", thru: true), jj("17:31", to: "Ueno"), jj("17:41", thru: true), jj("17:47"),
    jj("17:54", to: "Ueno", thru: true), jj("18:11"), jj("18:18", thru: true), jj("18:27", to: "Ueno", thru: true),
    jj("18:31", to: "Ueno"), jj("18:45", thru: true), jj("18:49"), jj("19:02", to: "Ueno", thru: true),
    jj("19:10"), jj("19:17", thru: true), jj("19:27", to: "Ueno", thru: true), jj("19:40", to: "Ueno"),
    jj("19:47", thru: true), jj("19:57"), jj("20:04", thru: true), jj("20:15", to: "Ueno"),
    jj("20:20"), jj("20:24", to: "Ueno", thru: true), jj("20:40", thru: true), jj("20:52", to: "Ueno"),
    jj("21:01", to: "Ueno", thru: true), jj("21:12"), jj("21:23", thru: true), jj("21:33", to: "Ueno"),
    jj("21:49", thru: true), jj("22:00", to: "Ueno"), jj("22:13", to: "Ueno", thru: true), jj("22:31", to: "Ueno", thru: true),
    jj("22:47", to: "Ueno", thru: true), jj("23:01", to: "Ueno"), jj("23:10", to: "Ueno", thru: true), jj("23:22", to: "Ueno"),
    jj("23:33", to: "Ueno"), jj("23:45", to: "Ueno"), jj("23:50", to: "Abiko", thru: true), jj("23:54", to: "Ueno"),
    jj("24:05", to: "Matsudo"), jj("24:18", to: "Matsudo"),
]

private static let jobanRapidUpAbikoHol: [ExactRun] = [
    jj("05:31", to: "Ueno", thru: true), jj("06:13", to: "Ueno", thru: true), jj("06:56", to: "Ueno", thru: true), jj("07:19", thru: true),
    jj("07:32", to: "Ueno", thru: true), jj("07:49", thru: true), jj("08:16", to: "Ueno", thru: true), jj("09:34", to: "Ueno", thru: true),
    jj("10:57", to: "Ueno", thru: true), jj("11:57", to: "Ueno", thru: true), jj("12:57", to: "Ueno", thru: true), jj("13:57", to: "Ueno", thru: true),
    jj("14:57", to: "Ueno", thru: true), jj("16:01", to: "Ueno", thru: true), jj("17:05", to: "Ueno", thru: true), jj("18:07", to: "Ueno", thru: true),
    jj("19:03", to: "Ueno", thru: true), jj("20:37", thru: true), jj("22:31", to: "Ueno", thru: true), jj("23:01", to: "Ueno", thru: true),
]

private static let jobanRapidUpMatsudoHol: [ExactRun] = [
    jj("04:36", to: "Ueno"),
]

}
