import Foundation

// MARK: - JR East Line Data (Extended)

private func st(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                _ code: String, _ lat: Double, _ lon: Double) -> Station {
    Station(
        id: "Station:JR-East.\(line).\(suffix)",
        name: ja, nameEn: en, stationCode: code,
        latitude: lat, longitude: lon
    )
}

private func pattern(_ first: String, _ last: String, _ bands: [(String, Double)],
                     _ trainType: TrainService.TrainType = .local) -> ServicePattern {
    ServicePattern(
        first: first, last: last,
        bands: bands.map { HeadwayBand(from: $0.0, headwayMinutes: $0.1) },
        trainType: trainType
    )
}

private func direction(_ line: String, _ suffix: String, _ ja: String, _ en: String,
                       ascending: Bool,
                       weekday: ServicePattern, holiday: ServicePattern,
                       intermediateOrigins: [IntermediateOrigin] = []) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:JR-East.\(line).\(suffix)",
        nameJa: ja, nameEn: en,
        isAscending: ascending,
        weekday: weekday, saturdayHoliday: holiday,
        intermediateOrigins: intermediateOrigins
    )
}

/// Pattern backed by real exact runs; first/last are informative only.
private func exact(_ runs: [ExactRun], first: String, last: String,
                   _ type: TrainService.TrainType = .local) -> ServicePattern {
    ServicePattern(first: first, last: last, bands: [], trainType: type, exactRuns: runs)
}

/// Joban Local exact run: terminus suffix resolves to a JobanLocal station id;
/// `thru: true` marks a through-run entering at the origin (not 当駅始発).
private func jl(_ dep: String, to: String? = nil, thru: Bool = false) -> ExactRun {
    ExactRun(dep, terminusStationId: to.map { "Station:JR-East.JobanLocal.\($0)" }, startsHere: !thru)
}

/// Joban Rapid exact run (same shape, JobanRapid station ids).
private func jj(_ dep: String, to: String? = nil, thru: Bool = false) -> ExactRun {
    ExactRun(dep, terminusStationId: to.map { "Station:JR-East.JobanRapid.\($0)" }, startsHere: !thru)
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

extension JREastLineData {

    static var extendedLines: [StaticTrainLine] {
        [
            jobanRapid, jobanLocal, yokosukaSobu, tokaido, shonanShinjuku,
            utsunomiya, takasaki, yokohamaLine, nambu, musashino, keiyoBranch,
            ome, itsukaichi,
        ]
    }

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

    // MARK: - Joban Local Real Runs (July-2026 revision)

private static let jobanLocalDownWeekday: [ExactRun] = [
    jl("04:58", to: "Abiko", thru: true), jl("05:19", to: "Abiko", thru: true), jl("05:40", to: "Toride", thru: true), jl("05:45", to: "Toride"),
    jl("05:53", to: "Toride", thru: true), jl("06:00", to: "Matsudo"), jl("06:06", to: "Toride", thru: true), jl("06:12", to: "Toride"),
    jl("06:17", to: "Abiko", thru: true), jl("06:20", to: "Toride"), jl("06:27", to: "Toride", thru: true), jl("06:33", to: "Toride"),
    jl("06:39", to: "Kashiwa", thru: true), jl("06:43", to: "Toride", thru: true), jl("06:47", to: "Toride", thru: true), jl("06:53", to: "Kashiwa", thru: true),
    jl("06:58", to: "Toride", thru: true), jl("07:03", to: "Kashiwa", thru: true), jl("07:07", to: "Toride", thru: true), jl("07:11", to: "Kashiwa", thru: true),
    jl("07:16", to: "Toride", thru: true), jl("07:22", to: "Kashiwa", thru: true), jl("07:25", to: "Abiko", thru: true), jl("07:30", to: "Matsudo", thru: true),
    jl("07:36", to: "Abiko", thru: true), jl("07:43", to: "Abiko", thru: true), jl("07:51", to: "Abiko", thru: true), jl("07:55", to: "Matsudo", thru: true),
    jl("08:02", to: "Abiko", thru: true), jl("08:13", to: "Abiko", thru: true), jl("08:17", to: "Matsudo", thru: true), jl("08:24", to: "Abiko", thru: true),
    jl("08:32", to: "Abiko", thru: true), jl("08:41", to: "Abiko", thru: true), jl("08:49", to: "Abiko", thru: true), jl("08:53", to: "Matsudo", thru: true),
    jl("08:56", to: "Abiko", thru: true), jl("09:07", to: "Abiko", thru: true), jl("09:13", to: "Abiko", thru: true), jl("09:18", to: "Abiko", thru: true),
    jl("09:26", to: "Abiko", thru: true), jl("09:31", to: "Matsudo", thru: true), jl("09:34", to: "Abiko", thru: true), jl("09:42", to: "Abiko", thru: true),
    jl("09:51", to: "Abiko", thru: true), jl("09:54", to: "Matsudo", thru: true), jl("10:02", to: "Abiko", thru: true), jl("10:10", to: "Abiko", thru: true),
    jl("10:20", to: "Abiko", thru: true), jl("10:30", to: "Abiko", thru: true), jl("10:40", to: "Abiko", thru: true), jl("10:50", to: "Abiko", thru: true),
    jl("11:00", to: "Abiko", thru: true), jl("11:10", to: "Abiko", thru: true), jl("11:20", to: "Abiko", thru: true), jl("11:30", to: "Abiko", thru: true),
    jl("11:40", to: "Abiko", thru: true), jl("11:50", to: "Abiko", thru: true), jl("12:00", to: "Abiko", thru: true), jl("12:10", to: "Abiko", thru: true),
    jl("12:20", to: "Abiko", thru: true), jl("12:30", to: "Abiko", thru: true), jl("12:40", to: "Abiko", thru: true), jl("12:50", to: "Abiko", thru: true),
    jl("13:00", to: "Abiko", thru: true), jl("13:10", to: "Abiko", thru: true), jl("13:20", to: "Abiko", thru: true), jl("13:30", to: "Abiko", thru: true),
    jl("13:40", to: "Abiko", thru: true), jl("13:50", to: "Abiko", thru: true), jl("14:00", to: "Abiko", thru: true), jl("14:10", to: "Abiko", thru: true),
    jl("14:20", to: "Abiko", thru: true), jl("14:30", to: "Abiko", thru: true), jl("14:40", to: "Abiko", thru: true), jl("14:50", to: "Abiko", thru: true),
    jl("15:00", to: "Abiko", thru: true), jl("15:10", to: "Abiko", thru: true), jl("15:20", to: "Abiko", thru: true), jl("15:30", to: "Abiko", thru: true),
    jl("15:40", to: "Abiko", thru: true), jl("15:50", to: "Abiko", thru: true), jl("16:00", to: "Abiko", thru: true), jl("16:10", to: "Abiko", thru: true),
    jl("16:20", to: "Abiko", thru: true), jl("16:31", to: "Abiko", thru: true), jl("16:40", to: "Abiko", thru: true), jl("16:49", to: "Abiko", thru: true),
    jl("16:55", to: "Abiko", thru: true), jl("17:03", to: "Abiko", thru: true), jl("17:13", to: "Abiko", thru: true), jl("17:20", to: "Abiko", thru: true),
    jl("17:27", to: "Toride", thru: true), jl("17:32", to: "Abiko", thru: true), jl("17:39", to: "Kashiwa", thru: true), jl("17:44", to: "Toride", thru: true),
    jl("17:48", to: "Abiko", thru: true), jl("17:54", to: "Kashiwa", thru: true), jl("17:58", to: "Toride", thru: true), jl("18:04", to: "Abiko", thru: true),
    jl("18:08", to: "Kashiwa", thru: true), jl("18:12", to: "Toride", thru: true), jl("18:17", to: "Abiko", thru: true), jl("18:21", to: "Kashiwa", thru: true),
    jl("18:26", to: "Toride", thru: true), jl("18:29", to: "Abiko", thru: true), jl("18:33", to: "Kashiwa", thru: true), jl("18:38", to: "Toride", thru: true),
    jl("18:42", to: "Abiko", thru: true), jl("18:48", to: "Kashiwa", thru: true), jl("18:53", to: "Toride", thru: true), jl("18:57", to: "Abiko", thru: true),
    jl("19:00", to: "Kashiwa", thru: true), jl("19:03", to: "Toride", thru: true), jl("19:06", to: "Toride", thru: true), jl("19:12", to: "Kashiwa", thru: true),
    jl("19:17", to: "Toride", thru: true), jl("19:22", to: "Kashiwa", thru: true), jl("19:29", to: "Toride", thru: true), jl("19:36", to: "Kashiwa", thru: true),
    jl("19:43", to: "Abiko", thru: true), jl("19:47", to: "Kashiwa", thru: true), jl("19:53", to: "Abiko", thru: true), jl("20:00", to: "Abiko", thru: true),
    jl("20:05", to: "Abiko", thru: true), jl("20:10", to: "Abiko", thru: true), jl("20:16", to: "Abiko", thru: true), jl("20:22", to: "Abiko", thru: true),
    jl("20:28", to: "Abiko", thru: true), jl("20:34", to: "Abiko", thru: true), jl("20:41", to: "Abiko", thru: true), jl("20:48", to: "Kashiwa", thru: true),
    jl("20:55", to: "Abiko", thru: true), jl("21:03", to: "Abiko", thru: true), jl("21:12", to: "Abiko", thru: true), jl("21:21", to: "Abiko", thru: true),
    jl("21:29", to: "Abiko", thru: true), jl("21:35", to: "Abiko", thru: true), jl("21:45", to: "Abiko", thru: true), jl("21:54", to: "Abiko", thru: true),
    jl("22:01", to: "Abiko", thru: true), jl("22:11", to: "Abiko", thru: true), jl("22:22", to: "Abiko", thru: true), jl("22:32", to: "Abiko", thru: true),
    jl("22:41", to: "Abiko", thru: true), jl("22:51", to: "Abiko", thru: true), jl("23:00", to: "Abiko", thru: true), jl("23:08", to: "Abiko", thru: true),
    jl("23:18", to: "Abiko", thru: true), jl("23:28", to: "Abiko", thru: true), jl("23:38", to: "Abiko", thru: true), jl("23:47", to: "Abiko", thru: true),
    jl("24:00", to: "Abiko", thru: true), jl("24:10", to: "Abiko", thru: true), jl("24:18", to: "Abiko", thru: true), jl("24:26", to: "Abiko", thru: true),
    jl("24:42", to: "Matsudo", thru: true), jl("24:52", to: "Matsudo", thru: true),
]

private static let jobanLocalDownHoliday: [ExactRun] = [
    jl("04:58", to: "Abiko", thru: true), jl("05:19", to: "Abiko", thru: true), jl("05:40", to: "Abiko", thru: true), jl("05:55", to: "Abiko", thru: true),
    jl("06:09", to: "Abiko", thru: true), jl("06:19", to: "Abiko", thru: true), jl("06:29", to: "Abiko", thru: true), jl("06:38", to: "Abiko", thru: true),
    jl("06:47", to: "Abiko", thru: true), jl("06:55", to: "Abiko", thru: true), jl("07:03", to: "Abiko", thru: true), jl("07:11", to: "Abiko", thru: true),
    jl("07:20", to: "Abiko", thru: true), jl("07:31", to: "Abiko", thru: true), jl("07:40", to: "Abiko", thru: true), jl("07:47", to: "Abiko", thru: true),
    jl("07:54", to: "Abiko", thru: true), jl("08:02", to: "Abiko", thru: true), jl("08:10", to: "Abiko", thru: true), jl("08:20", to: "Abiko", thru: true),
    jl("08:27", to: "Abiko", thru: true), jl("08:35", to: "Abiko", thru: true), jl("08:43", to: "Abiko", thru: true), jl("08:50", to: "Abiko", thru: true),
    jl("09:00", to: "Abiko", thru: true), jl("09:10", to: "Abiko", thru: true), jl("09:17", to: "Abiko", thru: true), jl("09:25", to: "Abiko", thru: true),
    jl("09:31", to: "Abiko", thru: true), jl("09:37", to: "Abiko", thru: true), jl("09:42", to: "Abiko", thru: true), jl("09:49", to: "Matsudo", thru: true),
    jl("09:55", to: "Abiko", thru: true), jl("10:05", to: "Abiko", thru: true), jl("10:12", to: "Abiko", thru: true), jl("10:20", to: "Abiko", thru: true),
    jl("10:25", to: "Abiko", thru: true), jl("10:30", to: "Abiko", thru: true), jl("10:40", to: "Abiko", thru: true), jl("10:50", to: "Abiko", thru: true),
    jl("11:00", to: "Abiko", thru: true), jl("11:10", to: "Abiko", thru: true), jl("11:20", to: "Abiko", thru: true), jl("11:30", to: "Abiko", thru: true),
    jl("11:40", to: "Abiko", thru: true), jl("11:50", to: "Abiko", thru: true), jl("12:00", to: "Abiko", thru: true), jl("12:10", to: "Abiko", thru: true),
    jl("12:20", to: "Abiko", thru: true), jl("12:30", to: "Abiko", thru: true), jl("12:40", to: "Abiko", thru: true), jl("12:50", to: "Abiko", thru: true),
    jl("13:00", to: "Abiko", thru: true), jl("13:10", to: "Abiko", thru: true), jl("13:20", to: "Abiko", thru: true), jl("13:30", to: "Abiko", thru: true),
    jl("13:40", to: "Abiko", thru: true), jl("13:50", to: "Abiko", thru: true), jl("14:00", to: "Abiko", thru: true), jl("14:10", to: "Abiko", thru: true),
    jl("14:20", to: "Abiko", thru: true), jl("14:30", to: "Abiko", thru: true), jl("14:40", to: "Abiko", thru: true), jl("14:50", to: "Abiko", thru: true),
    jl("15:00", to: "Abiko", thru: true), jl("15:10", to: "Abiko", thru: true), jl("15:21", to: "Abiko", thru: true), jl("15:31", to: "Abiko", thru: true),
    jl("15:41", to: "Abiko", thru: true), jl("15:51", to: "Abiko", thru: true), jl("16:01", to: "Abiko", thru: true), jl("16:11", to: "Abiko", thru: true),
    jl("16:21", to: "Abiko", thru: true), jl("16:31", to: "Abiko", thru: true), jl("16:41", to: "Abiko", thru: true), jl("16:51", to: "Abiko", thru: true),
    jl("17:01", to: "Abiko", thru: true), jl("17:11", to: "Abiko", thru: true), jl("17:21", to: "Abiko", thru: true), jl("17:31", to: "Abiko", thru: true),
    jl("17:41", to: "Abiko", thru: true), jl("17:51", to: "Abiko", thru: true), jl("18:01", to: "Abiko", thru: true), jl("18:10", to: "Abiko", thru: true),
    jl("18:20", to: "Abiko", thru: true), jl("18:30", to: "Abiko", thru: true), jl("18:40", to: "Abiko", thru: true), jl("18:51", to: "Abiko", thru: true),
    jl("19:02", to: "Abiko", thru: true), jl("19:13", to: "Abiko", thru: true), jl("19:20", to: "Abiko", thru: true), jl("19:30", to: "Abiko", thru: true),
    jl("19:40", to: "Abiko", thru: true), jl("19:51", to: "Abiko", thru: true), jl("20:02", to: "Abiko", thru: true), jl("20:13", to: "Abiko", thru: true),
    jl("20:22", to: "Abiko", thru: true), jl("20:32", to: "Abiko", thru: true), jl("20:42", to: "Abiko", thru: true), jl("20:54", to: "Abiko", thru: true),
    jl("21:06", to: "Abiko", thru: true), jl("21:17", to: "Abiko", thru: true), jl("21:24", to: "Abiko", thru: true), jl("21:31", to: "Abiko", thru: true),
    jl("21:41", to: "Abiko", thru: true), jl("21:49", to: "Abiko", thru: true), jl("22:00", to: "Abiko", thru: true), jl("22:10", to: "Abiko", thru: true),
    jl("22:19", to: "Abiko", thru: true), jl("22:29", to: "Abiko", thru: true), jl("22:38", to: "Abiko", thru: true), jl("22:52", to: "Abiko", thru: true),
    jl("23:11", to: "Abiko", thru: true), jl("23:29", to: "Abiko", thru: true), jl("23:47", to: "Abiko", thru: true), jl("24:01", to: "Abiko", thru: true),
    jl("24:08", to: "Abiko", thru: true), jl("24:23", to: "Abiko", thru: true), jl("24:42", to: "Matsudo", thru: true), jl("24:52", to: "Matsudo", thru: true),
]

private static let jobanLocalDownMatsudoWd: [ExactRun] = [
    jl("04:43", to: "Abiko"),
]

private static let jobanLocalDownMatsudoHol: [ExactRun] = [
    jl("04:43", to: "Abiko"),
]

private static let jobanLocalUpToride: [ExactRun] = [
    jl("06:26"), jl("06:37"), jl("06:46"), jl("06:50"),
    jl("06:56"), jl("07:06"), jl("07:12"), jl("07:22"),
    jl("07:30"), jl("07:40"), jl("07:43"), jl("07:54"),
    jl("08:04"), jl("18:16"), jl("18:29"), jl("18:55"),
    jl("19:04"), jl("19:13"), jl("19:29"), jl("19:44"),
    jl("19:53"), jl("19:58"), jl("20:07"), jl("20:17"),
]

private static let jobanLocalUpAbikoWd: [ExactRun] = [
    jl("04:29"), jl("04:51"), jl("05:11"), jl("05:36"),
    jl("05:57"), jl("06:11"), jl("06:19"), jl("06:27"),
    jl("06:40"), jl("06:50"), jl("07:00"), jl("07:06"),
    jl("07:16"), jl("07:25"), jl("07:41"), jl("08:06"),
    jl("08:18"), jl("08:25"), jl("08:34"), jl("08:44"),
    jl("08:54"), jl("09:04"), jl("09:13"), jl("09:20"),
    jl("09:28"), jl("09:36"), jl("09:46"), jl("09:55"),
    jl("10:06"), jl("10:16"), jl("10:26"), jl("10:36"),
    jl("10:46"), jl("10:56"), jl("11:06"), jl("11:16"),
    jl("11:26"), jl("11:36"), jl("11:46"), jl("11:56"),
    jl("12:06"), jl("12:16"), jl("12:26"), jl("12:36"),
    jl("12:46"), jl("12:56"), jl("13:06"), jl("13:16"),
    jl("13:26"), jl("13:36"), jl("13:46"), jl("13:56"),
    jl("14:06"), jl("14:16"), jl("14:26"), jl("14:36"),
    jl("14:46"), jl("14:56"), jl("15:06"), jl("15:16"),
    jl("15:26"), jl("15:36"), jl("15:46"), jl("15:56"),
    jl("16:06"), jl("16:16"), jl("16:26"), jl("16:36"),
    jl("16:46"), jl("16:55"), jl("17:07"), jl("17:14"),
    jl("17:22"), jl("17:27"), jl("17:35"), jl("17:41"),
    jl("17:52"), jl("18:01"), jl("18:15"), jl("18:32"),
    jl("18:46"), jl("18:58"), jl("19:14"), jl("19:26"),
    jl("19:40"), jl("20:28"), jl("20:33"), jl("20:38"),
    jl("20:48"), jl("20:54"), jl("21:04"), jl("21:14"),
    jl("21:24"), jl("21:36"), jl("21:43"), jl("21:50"),
    jl("22:00"), jl("22:09"), jl("22:21"), jl("22:33"),
    jl("22:41"), jl("22:49"), jl("23:00"), jl("23:11"),
    jl("23:20"), jl("23:34"), jl("23:56"), jl("24:12", to: "Matsudo"),
    jl("24:29", to: "Matsudo"),
]

private static let jobanLocalUpAbikoHol: [ExactRun] = [
    jl("04:29"), jl("04:51"), jl("05:11"), jl("05:32"),
    jl("05:41"), jl("05:49"), jl("05:59"), jl("06:09"),
    jl("06:17"), jl("06:26"), jl("06:39"), jl("06:47"),
    jl("06:53"), jl("06:58"), jl("07:07"), jl("07:13"),
    jl("07:22"), jl("07:28"), jl("07:33"), jl("07:43"),
    jl("07:49"), jl("07:55"), jl("08:01"), jl("08:08"),
    jl("08:17"), jl("08:24"), jl("08:30"), jl("08:35"),
    jl("08:42"), jl("08:51"), jl("08:59"), jl("09:08"),
    jl("09:16"), jl("09:24"), jl("09:32"), jl("09:39"),
    jl("09:49"), jl("09:59"), jl("10:07"), jl("10:17"),
    jl("10:26"), jl("10:36"), jl("10:46"), jl("10:56"),
    jl("11:06"), jl("11:16"), jl("11:26"), jl("11:36"),
    jl("11:46"), jl("11:56"), jl("12:06"), jl("12:16"),
    jl("12:26"), jl("12:36"), jl("12:46"), jl("12:56"),
    jl("13:06"), jl("13:16"), jl("13:26"), jl("13:36"),
    jl("13:46"), jl("13:56"), jl("14:06"), jl("14:16"),
    jl("14:26"), jl("14:36"), jl("14:47"), jl("14:58"),
    jl("15:09"), jl("15:19"), jl("15:29"), jl("15:39"),
    jl("15:49"), jl("15:59"), jl("16:09"), jl("16:19"),
    jl("16:29"), jl("16:39"), jl("16:49"), jl("16:59"),
    jl("17:09"), jl("17:19"), jl("17:29"), jl("17:39"),
    jl("17:49"), jl("17:59"), jl("18:09"), jl("18:19"),
    jl("18:29"), jl("18:39"), jl("18:46"), jl("18:56"),
    jl("19:06"), jl("19:17"), jl("19:28"), jl("19:40"),
    jl("19:50"), jl("19:58"), jl("20:09"), jl("20:19"),
    jl("20:28"), jl("20:41"), jl("20:53"), jl("21:09"),
    jl("21:22"), jl("21:33"), jl("21:49"), jl("22:04"),
    jl("22:18"), jl("22:27"), jl("22:37"), jl("22:50"),
    jl("23:07"), jl("23:19"), jl("23:33"), jl("23:56"),
    jl("24:12", to: "Matsudo"), jl("24:29", to: "Matsudo"),
]

private static let jobanLocalUpKashiwaWd: [ExactRun] = [
    jl("07:16"), jl("07:28"), jl("07:40"), jl("07:50"),
    jl("08:03"), jl("18:16"), jl("18:34"), jl("18:48"),
    jl("19:00"), jl("19:13"), jl("19:24"), jl("19:38"),
    jl("19:51"), jl("20:02"), jl("20:15"), jl("20:25"),
    jl("21:26"),
]

private static let jobanLocalUpMatsudoWd: [ExactRun] = [
    jl("04:27"), jl("06:06"), jl("06:23"), jl("06:43"),
    jl("07:00"), jl("07:51"), jl("08:17"), jl("08:38"),
    jl("16:05"), jl("17:22"),
]

private static let jobanLocalUpMatsudoHol: [ExactRun] = [
    jl("04:27"), jl("05:42"), jl("06:53"), jl("15:05"),
]

    // MARK: - Joban Local Line (JL)

    static let jobanLocal = StaticTrainLine(
        id: "Railway:JR-East.JobanLocal",
        nameJa: "常磐線各駅停車",
        nameEn: "Joban Local Line",
        operatorId: "Operator:JR-East",
        // JR East signage renders the Joban Local (JL) line in gray
        colorHex: "#999999",
        stations: [
            st("JobanLocal", "Ayase", "綾瀬", "Ayase", "JL19", 35.7620, 139.8247),
            st("JobanLocal", "Kameari", "亀有", "Kameari", "JL20", 35.7669, 139.8488),
            st("JobanLocal", "Kanamachi", "金町", "Kanamachi", "JL21", 35.7692, 139.8709),
            st("JobanLocal", "Matsudo", "松戸", "Matsudo", "JL22", 35.7841, 139.9010),
            st("JobanLocal", "KitaMatsudo", "北松戸", "Kita-Matsudo", "JL23", 35.7988, 139.9130),
            st("JobanLocal", "Mabashi", "馬橋", "Mabashi", "JL24", 35.8093, 139.9200),
            st("JobanLocal", "ShimMatsudo", "新松戸", "Shim-Matsudo", "JL25", 35.8260, 139.9336),
            st("JobanLocal", "KitaKogane", "北小金", "Kita-Kogane", "JL26", 35.8332, 139.9442),
            st("JobanLocal", "MinamiKashiwa", "南柏", "Minami-Kashiwa", "JL27", 35.8460, 139.9600),
            st("JobanLocal", "Kashiwa", "柏", "Kashiwa", "JL28", 35.8622, 139.9707),
            st("JobanLocal", "KitaKashiwa", "北柏", "Kita-Kashiwa", "JL29", 35.8722, 139.9932),
            st("JobanLocal", "Abiko", "我孫子", "Abiko", "JL30", 35.8687, 140.0277),
            st("JobanLocal", "Tennodai", "天王台", "Tennodai", "JL31", 35.8700, 140.0672),
            st("JobanLocal", "Toride", "取手", "Toride", "JL32", 35.8973, 140.0629),
        ],
        hopTimesMinutes: [3, 2, 4, 3, 2, 2, 2, 3, 3, 3, 3, 3, 4],
        // Real per-station times per run (641 grid) → 1:1 station timetables.
        exactStationTimes: jobanLocalTimetable,
        // Real exact runs, July-2026 revision (timetables.jreast.co.jp),
        // including per-train termini: most down trains terminate at 我孫子,
        // 取手 is reached only by weekday rush trains (none on holidays), and
        // 松戸/柏 short-turns exist. Up trains originate at 取手 (weekday
        // rush), 我孫子 (all day), 柏, and 松戸; through-runs from the
        // 千代田線 enter at 綾瀬 and are not 当駅始発 there (thru: true).
        directions: [
            direction("JobanLocal", "Toride", "取手方面", "For Toride", ascending: true,
                      weekday: exact(jobanLocalDownWeekday, first: "04:58", last: "24:52"),
                      holiday: exact(jobanLocalDownHoliday, first: "04:58", last: "24:52"),
                      intermediateOrigins: [
                          IntermediateOrigin(stationId: "Station:JR-East.JobanLocal.Matsudo",
                                             weekdayRuns: jobanLocalDownMatsudoWd,
                                             saturdayHolidayRuns: jobanLocalDownMatsudoHol),
                      ]),
            direction("JobanLocal", "Ayase", "綾瀬方面", "For Ayase", ascending: false,
                      weekday: exact(jobanLocalUpToride, first: "06:26", last: "20:17"),
                      holiday: exact([], first: "00:00", last: "00:00"),
                      intermediateOrigins: [
                          IntermediateOrigin(stationId: "Station:JR-East.JobanLocal.Abiko",
                                             weekdayRuns: jobanLocalUpAbikoWd,
                                             saturdayHolidayRuns: jobanLocalUpAbikoHol),
                          IntermediateOrigin(stationId: "Station:JR-East.JobanLocal.Kashiwa",
                                             weekdayRuns: jobanLocalUpKashiwaWd,
                                             saturdayHolidayRuns: []),
                          IntermediateOrigin(stationId: "Station:JR-East.JobanLocal.Matsudo",
                                             weekdayRuns: jobanLocalUpMatsudoWd,
                                             saturdayHolidayRuns: jobanLocalUpMatsudoHol),
                      ]),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("JobanLocal.Ayase", .descending,
                    "東京メトロ千代田線", "Tokyo Metro Chiyoda Line",
                    "代々木上原・小田急線方面", "for Yoyogi-Uehara & the Odakyu Line",
                    to: "Railway:TokyoMetro.Chiyoda"),
        ]
    )

    // MARK: - Yokosuka / Sobu Rapid Line (JO)

    static let yokosukaSobu = StaticTrainLine(
        id: "Railway:JR-East.YokosukaSobu",
        nameJa: "横須賀・総武線快速",
        nameEn: "Yokosuka-Sobu Rapid Line",
        operatorId: "Operator:JR-East",
        colorHex: "#0072BC",
        stations: [
            st("YokosukaSobu", "Kurihama", "久里浜", "Kurihama", "JO01", 35.2333, 139.7057),
            st("YokosukaSobu", "Kinugasa", "衣笠", "Kinugasa", "JO02", 35.2512, 139.6688),
            st("YokosukaSobu", "Yokosuka", "横須賀", "Yokosuka", "JO03", 35.2872, 139.6598),
            st("YokosukaSobu", "Taura", "田浦", "Taura", "JO04", 35.3012, 139.6358),
            st("YokosukaSobu", "HigashiZushi", "東逗子", "Higashi-Zushi", "JO05", 35.3012, 139.6008),
            st("YokosukaSobu", "Zushi", "逗子", "Zushi", "JO06", 35.2953, 139.5798),
            st("YokosukaSobu", "Kamakura", "鎌倉", "Kamakura", "JO07", 35.3192, 139.5468),
            st("YokosukaSobu", "KitaKamakura", "北鎌倉", "Kita-Kamakura", "JO08", 35.3372, 139.5468),
            st("YokosukaSobu", "Ofuna", "大船", "Ofuna", "JO09", 35.3540, 139.5313),
            st("YokosukaSobu", "Totsuka", "戸塚", "Totsuka", "JO10", 35.4008, 139.5342),
            st("YokosukaSobu", "HigashiTotsuka", "東戸塚", "Higashi-Totsuka", "JO11", 35.4232, 139.5578),
            st("YokosukaSobu", "Hodogaya", "保土ケ谷", "Hodogaya", "JO12", 35.4442, 139.5968),
            st("YokosukaSobu", "Yokohama", "横浜", "Yokohama", "JO13", 35.4657, 139.6224),
            st("YokosukaSobu", "ShinKawasaki", "新川崎", "Shin-Kawasaki", "JO14", 35.5352, 139.6468),
            st("YokosukaSobu", "MusashiKosugi", "武蔵小杉", "Musashi-Kosugi", "JO15", 35.5766, 139.6597),
            st("YokosukaSobu", "NishiOi", "西大井", "Nishi-Oi", "JO16", 35.6012, 139.7218),
            st("YokosukaSobu", "Shinagawa", "品川", "Shinagawa", "JO17", 35.6285, 139.7388),
            st("YokosukaSobu", "Shimbashi", "新橋", "Shimbashi", "JO18", 35.6663, 139.7583),
            st("YokosukaSobu", "Tokyo", "東京", "Tokyo", "JO19", 35.6812, 139.7671),
            st("YokosukaSobu", "ShinNihombashi", "新日本橋", "Shin-Nihombashi", "JO20", 35.6892, 139.7738),
            st("YokosukaSobu", "Bakurocho", "馬喰町", "Bakurocho", "JO21", 35.6932, 139.7828),
            st("YokosukaSobu", "Kinshicho", "錦糸町", "Kinshicho", "JO22", 35.6967, 139.8140),
            st("YokosukaSobu", "ShinKoiwa", "新小岩", "Shin-Koiwa", "JO23", 35.7167, 139.8578),
            st("YokosukaSobu", "Ichikawa", "市川", "Ichikawa", "JO24", 35.7297, 139.9078),
            st("YokosukaSobu", "Funabashi", "船橋", "Funabashi", "JO25", 35.7019, 139.9853),
            st("YokosukaSobu", "Tsudanuma", "津田沼", "Tsudanuma", "JO26", 35.6913, 140.0200),
            st("YokosukaSobu", "Inage", "稲毛", "Inage", "JO27", 35.6333, 140.0900),
            st("YokosukaSobu", "Chiba", "千葉", "Chiba", "JO28", 35.6131, 140.1136),
        ],
        // Measured from real July-2026 train pairs (median, both directions);
        // 横浜→新川崎 is 9, 武蔵小杉→西大井 5 (was overstated).
        hopTimesMinutes: [
            6, 5, 3, 4, 3, 4, 3, 3, 5, 4, 5, 3, 9, 3,
            5, 5, 5, 3, 2, 2, 4, 5, 5, 6, 4, 7, 4,
        ],
        // Real per-train timetable (station-page scrape) → 1:1 station timetables.
        timetableRuns: yokosukaSobuTimetable,
        directions: [
            direction("YokosukaSobu", "Chiba", "東京・千葉方面", "For Tokyo & Chiba", ascending: true,
                      weekday: pattern("04:31", "23:11", [
                          ("04:31", 15), ("06:30", 15), ("09:30", 20), ("16:30", 15), ("20:00", 20), ("22:00", 30),
                      ], .rapid),
                      holiday: pattern("04:31", "23:11", [
                          ("04:31", 15), ("07:00", 15), ("10:00", 20), ("20:00", 25),
                      ], .rapid)),
            direction("YokosukaSobu", "Kurihama", "横浜・久里浜方面", "For Yokohama & Kurihama", ascending: false,
                      weekday: pattern("04:45", "24:15", [
                          ("04:45", 10), ("06:30", 8.5), ("09:30", 9), ("16:30", 7), ("20:00", 9), ("22:00", 12),
                      ], .rapid),
                      holiday: pattern("04:45", "24:15", [
                          ("04:45", 10), ("07:00", 7), ("10:00", 9), ("20:00", 10),
                      ], .rapid)),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("YokosukaSobu.Chiba", .ascending,
                    "総武本線・成田線", "JR Sobu Main & Narita Lines",
                    "成田空港・君津方面", "for Narita Airport & Kimitsu"),
        ]
    )

    // MARK: - Tokaido Line (JT)

    static let tokaido = StaticTrainLine(
        id: "Railway:JR-East.Tokaido",
        nameJa: "東海道線",
        nameEn: "Tokaido Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F68B1E",
        stations: [
            st("Tokaido", "Tokyo", "東京", "Tokyo", "JT01", 35.6812, 139.7671),
            st("Tokaido", "Shimbashi", "新橋", "Shimbashi", "JT02", 35.6663, 139.7583),
            st("Tokaido", "Shinagawa", "品川", "Shinagawa", "JT03", 35.6285, 139.7388),
            st("Tokaido", "Kawasaki", "川崎", "Kawasaki", "JT04", 35.5308, 139.6970),
            st("Tokaido", "Yokohama", "横浜", "Yokohama", "JT05", 35.4657, 139.6224),
            st("Tokaido", "Totsuka", "戸塚", "Totsuka", "JT06", 35.4008, 139.5342),
            st("Tokaido", "Ofuna", "大船", "Ofuna", "JT07", 35.3540, 139.5313),
            st("Tokaido", "Fujisawa", "藤沢", "Fujisawa", "JT08", 35.3387, 139.4872),
            st("Tokaido", "Tsujido", "辻堂", "Tsujido", "JT09", 35.3362, 139.4468),
            st("Tokaido", "Chigasaki", "茅ケ崎", "Chigasaki", "JT10", 35.3302, 139.4068),
            st("Tokaido", "Hiratsuka", "平塚", "Hiratsuka", "JT11", 35.3272, 139.3498),
            st("Tokaido", "Oiso", "大磯", "Oiso", "JT12", 35.3112, 139.3128),
            st("Tokaido", "Ninomiya", "二宮", "Ninomiya", "JT13", 35.2992, 139.2558),
            st("Tokaido", "Kozu", "国府津", "Kozu", "JT14", 35.2812, 139.2128),
            st("Tokaido", "Kamonomiya", "鴨宮", "Kamonomiya", "JT15", 35.2682, 139.1828),
            st("Tokaido", "Odawara", "小田原", "Odawara", "JT16", 35.2563, 139.1552),
            st("Tokaido", "Hayakawa", "早川", "Hayakawa", "JT17", 35.2382, 139.1498),
            st("Tokaido", "Nebukawa", "根府川", "Nebukawa", "JT18", 35.2082, 139.1358),
            st("Tokaido", "Manazuru", "真鶴", "Manazuru", "JT19", 35.1622, 139.1218),
            st("Tokaido", "Yugawara", "湯河原", "Yugawara", "JT20", 35.1472, 139.1078),
            st("Tokaido", "Atami", "熱海", "Atami", "JT21", 35.1038, 139.0778),
        ],
        // Measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [
            3, 5, 9, 8, 10, 5, 5, 4, 4, 5, 4, 5, 4, 3, 4, 3, 4, 5, 4, 5,
        ],
        // Real per-train timetable (station-page scrape) → 1:1 station timetables.
        timetableRuns: tokaidoTimetable,
        directions: [
            direction("Tokaido", "Atami", "小田原・熱海方面", "For Odawara & Atami", ascending: true,
                      weekday: pattern("05:20", "23:54", [
                          ("05:20", 10), ("06:30", 5), ("09:30", 9), ("16:30", 7), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:20", "23:54", [
                          ("05:20", 10), ("07:00", 7), ("10:00", 9), ("20:00", 11),
                      ])),
            // 熱海 departures run ~3/h all day (verified July-2026); mid-line
            // 小田原/平塚 origins are not expressible in the band model.
            direction("Tokaido", "Tokyo", "東京方面", "For Tokyo", ascending: false,
                      weekday: pattern("04:35", "23:07", [
                          ("04:35", 20),
                      ]),
                      holiday: pattern("04:35", "23:07", [
                          ("04:35", 20),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Tokaido.Tokyo", .descending,
                    "宇都宮線（上野東京ライン）", "JR Utsunomiya Line (via Ueno-Tokyo Line)",
                    "宇都宮方面", "for Utsunomiya",
                    to: "Railway:JR-East.Utsunomiya"),
            through("Tokaido.Tokyo", .descending,
                    "高崎線（上野東京ライン）", "JR Takasaki Line (via Ueno-Tokyo Line)",
                    "高崎方面", "for Takasaki",
                    to: "Railway:JR-East.Takasaki"),
            through("Tokaido.Ofuna", .descending,
                    "湘南新宿ライン", "Shonan-Shinjuku Line",
                    "渋谷・新宿方面", "for Shibuya & Shinjuku",
                    to: "Railway:JR-East.ShonanShinjuku"),
            through("Tokaido.Atami", .ascending,
                    "伊東線", "JR Ito Line", "伊東方面", "for Ito"),
        ]
    )

    // MARK: - Shonan-Shinjuku Line (JS)

    static let shonanShinjuku = StaticTrainLine(
        id: "Railway:JR-East.ShonanShinjuku",
        nameJa: "湘南新宿ライン",
        nameEn: "Shonan-Shinjuku Line",
        operatorId: "Operator:JR-East",
        colorHex: "#E21F26",
        stations: [
            st("ShonanShinjuku", "Zushi", "逗子", "Zushi", "JS06", 35.2953, 139.5798),
            st("ShonanShinjuku", "Kamakura", "鎌倉", "Kamakura", "JS07", 35.3192, 139.5468),
            st("ShonanShinjuku", "KitaKamakura", "北鎌倉", "Kita-Kamakura", "JS08", 35.3372, 139.5468),
            st("ShonanShinjuku", "Ofuna", "大船", "Ofuna", "JS09", 35.3540, 139.5313),
            st("ShonanShinjuku", "Totsuka", "戸塚", "Totsuka", "JS10", 35.4008, 139.5342),
            st("ShonanShinjuku", "HigashiTotsuka", "東戸塚", "Higashi-Totsuka", "JS11", 35.4232, 139.5578),
            st("ShonanShinjuku", "Hodogaya", "保土ケ谷", "Hodogaya", "JS12", 35.4442, 139.5968),
            st("ShonanShinjuku", "Yokohama", "横浜", "Yokohama", "JS13", 35.4657, 139.6224),
            st("ShonanShinjuku", "ShinKawasaki", "新川崎", "Shin-Kawasaki", "JS14", 35.5352, 139.6468),
            st("ShonanShinjuku", "MusashiKosugi", "武蔵小杉", "Musashi-Kosugi", "JS15", 35.5766, 139.6597),
            st("ShonanShinjuku", "NishiOi", "西大井", "Nishi-Oi", "JS16", 35.6012, 139.7218),
            st("ShonanShinjuku", "Osaki", "大崎", "Osaki", "JS17", 35.6197, 139.7286),
            st("ShonanShinjuku", "Ebisu", "恵比寿", "Ebisu", "JS18", 35.6467, 139.7101),
            st("ShonanShinjuku", "Shibuya", "渋谷", "Shibuya", "JS19", 35.6580, 139.7016),
            st("ShonanShinjuku", "Shinjuku", "新宿", "Shinjuku", "JS20", 35.6896, 139.7006),
            st("ShonanShinjuku", "Ikebukuro", "池袋", "Ikebukuro", "JS21", 35.7295, 139.7109),
            st("ShonanShinjuku", "Akabane", "赤羽", "Akabane", "JS22", 35.7782, 139.7208),
            st("ShonanShinjuku", "Urawa", "浦和", "Urawa", "JS23", 35.8593, 139.6570),
            st("ShonanShinjuku", "Omiya", "大宮", "Omiya", "JS24", 35.9064, 139.6238),
        ],
        hopTimesMinutes: [
            4, 3, 3, 5, 4, 5, 3, 9, 3, 5, 4, 4, 2, 5, 6, 10, 9, 6,
        ],
        // Real per-train timetable (station-page scrape) → 1:1 station timetables.
        timetableRuns: shonanShinjukuTimetable,
        directions: [
            // 逗子 has a real morning service GAP (07:47→09:34 weekday,
            // 06:57→09:28 holiday), then ~30-min clockface — verified July-2026.
            direction("ShonanShinjuku", "Omiya", "新宿・大宮方面", "For Shinjuku & Omiya", ascending: true,
                      weekday: pattern("06:54", "21:11", [
                          ("06:54", 25), ("07:47", 107), ("09:34", 30),
                      ], .rapid),
                      holiday: pattern("06:57", "21:34", [
                          ("06:57", 151), ("09:28", 30),
                      ], .rapid)),
            direction("ShonanShinjuku", "Zushi", "横浜・逗子方面", "For Yokohama & Zushi", ascending: false,
                      weekday: pattern("06:07", "22:26", [
                          ("06:07", 15), ("07:00", 12), ("09:30", 25), ("16:30", 15), ("20:00", 25),
                      ], .rapid),
                      holiday: pattern("06:07", "22:25", [
                          ("06:07", 15), ("08:00", 15), ("10:00", 25), ("20:00", 25),
                      ], .rapid)),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("ShonanShinjuku.Omiya", .ascending,
                    "宇都宮線", "JR Utsunomiya Line",
                    "宇都宮方面", "for Utsunomiya",
                    to: "Railway:JR-East.Utsunomiya"),
            through("ShonanShinjuku.Omiya", .ascending,
                    "高崎線", "JR Takasaki Line",
                    "高崎方面", "for Takasaki",
                    to: "Railway:JR-East.Takasaki"),
            through("ShonanShinjuku.Ofuna", .descending,
                    "東海道線", "JR Tokaido Line",
                    "藤沢・小田原方面", "for Fujisawa & Odawara",
                    to: "Railway:JR-East.Tokaido"),
        ]
    )

    // MARK: - Utsunomiya Line (JU)

    static let utsunomiya = StaticTrainLine(
        id: "Railway:JR-East.Utsunomiya",
        nameJa: "宇都宮線",
        nameEn: "Utsunomiya Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F68B1E",
        stations: [
            st("Utsunomiya", "Tokyo", "東京", "Tokyo", "JU01", 35.6812, 139.7671),
            st("Utsunomiya", "Ueno", "上野", "Ueno", "JU02", 35.7141, 139.7774),
            st("Utsunomiya", "Oku", "尾久", "Oku", "JU03", 35.7423, 139.7568),
            st("Utsunomiya", "Akabane", "赤羽", "Akabane", "JU04", 35.7782, 139.7208),
            st("Utsunomiya", "Urawa", "浦和", "Urawa", "JU05", 35.8593, 139.6570),
            st("Utsunomiya", "SaitamaShintoshin", "さいたま新都心", "Saitama-Shintoshin", "JU06", 35.8940, 139.6339),
            st("Utsunomiya", "Omiya", "大宮", "Omiya", "JU07", 35.9064, 139.6238),
            st("Utsunomiya", "Toro", "土呂", "Toro", "", 35.9288, 139.6318),
            st("Utsunomiya", "HigashiOmiya", "東大宮", "Higashi-Omiya", "", 35.9500, 139.6480),
            st("Utsunomiya", "Hasuda", "蓮田", "Hasuda", "", 35.9900, 139.6600),
            st("Utsunomiya", "Shiraoka", "白岡", "Shiraoka", "", 36.0182, 139.6718),
            st("Utsunomiya", "ShinShiraoka", "新白岡", "Shin-Shiraoka", "", 36.0378, 139.6798),
            st("Utsunomiya", "Kuki", "久喜", "Kuki", "", 36.0638, 139.6688),
            st("Utsunomiya", "HigashiWashinomiya", "東鷲宮", "Higashi-Washinomiya", "", 36.0872, 139.6718),
            st("Utsunomiya", "Kurihashi", "栗橋", "Kurihashi", "", 36.1369, 139.6942),
            st("Utsunomiya", "Koga", "古河", "Koga", "", 36.1832, 139.7078),
            st("Utsunomiya", "Nogi", "野木", "Nogi", "", 36.2158, 139.7148),
            st("Utsunomiya", "Mamada", "間々田", "Mamada", "", 36.2558, 139.7358),
            st("Utsunomiya", "Oyama", "小山", "Oyama", "", 36.3135, 139.8080),
            st("Utsunomiya", "Koganei", "小金井", "Koganei", "", 36.3550, 139.8570),
            st("Utsunomiya", "Jichiidai", "自治医大", "Jichiidai", "", 36.3912, 139.8668),
            st("Utsunomiya", "Ishibashi", "石橋", "Ishibashi", "", 36.4258, 139.8658),
            st("Utsunomiya", "Suzumenomiya", "雀宮", "Suzumenomiya", "", 36.4978, 139.8718),
            st("Utsunomiya", "Utsunomiya", "宇都宮", "Utsunomiya", "", 36.5591, 139.8988),
        ],
        hopTimesMinutes: [
            6, 6, 5, 9, 4, 3, 4, 3, 4, 4, 3, 3, 3, 5, 7, 4, 4, 6, 7, 3, 4, 6, 7,
        ],
        // Real per-train timetable (station-page scrape) → 1:1 station timetables.
        timetableRuns: utsunomiyaTimetable,
        directions: [
            // First departure from Tokyo is 06:30 — earlier Ueno-Tokyo Line
            // departures on this corridor are Takasaki Line trains
            direction("Utsunomiya", "Utsunomiya", "宇都宮方面", "For Utsunomiya", ascending: true,
                      weekday: pattern("06:30", "23:32", [
                          ("06:30", 15), ("09:30", 20), ("16:30", 10), ("20:00", 20),
                      ]),
                      holiday: pattern("06:30", "23:32", [
                          ("06:30", 25), ("10:00", 20), ("20:00", 20),
                      ])),
            direction("Utsunomiya", "Tokyo", "上野・東京方面", "For Ueno & Tokyo", ascending: false,
                      weekday: pattern("04:37", "22:42", [
                          ("04:37", 15), ("06:00", 15), ("09:30", 20), ("16:30", 10), ("20:00", 20),
                      ]),
                      holiday: pattern("04:37", "22:42", [
                          ("04:37", 15), ("07:00", 12), ("10:00", 20), ("20:00", 20),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Utsunomiya.Tokyo", .descending,
                    "東海道線（上野東京ライン）", "JR Tokaido Line (via Ueno-Tokyo Line)",
                    "横浜・熱海方面", "for Yokohama & Atami",
                    to: "Railway:JR-East.Tokaido"),
            through("Utsunomiya.Omiya", .descending,
                    "湘南新宿ライン", "Shonan-Shinjuku Line",
                    "新宿・横浜方面", "for Shinjuku & Yokohama",
                    to: "Railway:JR-East.ShonanShinjuku"),
        ]
    )

    // MARK: - Takasaki Line (JU)

    static let takasaki = StaticTrainLine(
        id: "Railway:JR-East.Takasaki",
        nameJa: "高崎線",
        nameEn: "Takasaki Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F68B1E",
        stations: [
            st("Takasaki", "Tokyo", "東京", "Tokyo", "JU01", 35.6812, 139.7671),
            st("Takasaki", "Ueno", "上野", "Ueno", "JU02", 35.7141, 139.7774),
            st("Takasaki", "Oku", "尾久", "Oku", "JU03", 35.7423, 139.7568),
            st("Takasaki", "Akabane", "赤羽", "Akabane", "JU04", 35.7782, 139.7208),
            st("Takasaki", "Urawa", "浦和", "Urawa", "JU05", 35.8593, 139.6570),
            st("Takasaki", "SaitamaShintoshin", "さいたま新都心", "Saitama-Shintoshin", "JU06", 35.8940, 139.6339),
            st("Takasaki", "Omiya", "大宮", "Omiya", "JU07", 35.9064, 139.6238),
            st("Takasaki", "Miyahara", "宮原", "Miyahara", "", 35.9438, 139.6098),
            st("Takasaki", "Ageo", "上尾", "Ageo", "", 35.9698, 139.5898),
            st("Takasaki", "KitaAgeo", "北上尾", "Kita-Ageo", "", 35.9878, 139.5848),
            st("Takasaki", "Okegawa", "桶川", "Okegawa", "", 36.0060, 139.5580),
            st("Takasaki", "Kitamoto", "北本", "Kitamoto", "", 36.0268, 139.5318),
            st("Takasaki", "Konosu", "鴻巣", "Konosu", "", 36.0658, 139.5218),
            st("Takasaki", "KitaKonosu", "北鴻巣", "Kita-Konosu", "", 36.0928, 139.4958),
            st("Takasaki", "Fukiage", "吹上", "Fukiage", "", 36.1088, 139.4588),
            st("Takasaki", "Gyoda", "行田", "Gyoda", "", 36.1248, 139.4338),
            st("Takasaki", "Kumagaya", "熊谷", "Kumagaya", "", 36.1398, 139.3898),
            st("Takasaki", "Kagohara", "籠原", "Kagohara", "", 36.1658, 139.3258),
            st("Takasaki", "Fukaya", "深谷", "Fukaya", "", 36.1928, 139.2808),
            st("Takasaki", "Okabe", "岡部", "Okabe", "", 36.2108, 139.2398),
            st("Takasaki", "Honjo", "本庄", "Honjo", "", 36.2428, 139.1858),
            st("Takasaki", "Jimbohara", "神保原", "Jimbohara", "", 36.2568, 139.1418),
            st("Takasaki", "Shinmachi", "新町", "Shinmachi", "", 36.2698, 139.1128),
            st("Takasaki", "Kuragano", "倉賀野", "Kuragano", "", 36.3038, 139.0488),
            st("Takasaki", "Takasaki", "高崎", "Takasaki", "", 36.3222, 139.0128),
        ],
        hopTimesMinutes: [
            6, 6, 5, 9, 4, 3, 5, 4, 3, 3, 4, 4, 4, 4, 3, 5, 6, 5, 4, 5, 4, 4, 5, 5,
        ],
        // Real per-train timetable (station-page scrape) → 1:1 station timetables.
        timetableRuns: takasakiTimetable,
        directions: [
            // Last departure from Tokyo is 23:19 — later Ueno-Tokyo Line
            // departures on this corridor are Utsunomiya Line trains
            direction("Takasaki", "Takasaki", "高崎方面", "For Takasaki", ascending: true,
                      weekday: pattern("05:53", "23:19", [
                          ("05:53", 15), ("06:30", 15), ("09:30", 18), ("16:30", 10), ("20:00", 25),
                      ]),
                      holiday: pattern("05:53", "23:19", [
                          ("05:53", 15), ("07:00", 15), ("10:00", 18), ("20:00", 20),
                      ])),
            // 高崎-origin mornings run only ~2-4/h (verified July-2026); the
            // dense 06:00 headway was a down-corridor figure, not the origin's.
            direction("Takasaki", "Tokyo", "上野・東京方面", "For Ueno & Tokyo", ascending: false,
                      weekday: pattern("05:10", "23:06", [
                          ("05:10", 20), ("06:00", 20), ("09:30", 30), ("16:30", 12), ("20:00", 20),
                      ]),
                      holiday: pattern("05:10", "23:06", [
                          ("05:10", 15), ("07:00", 15), ("10:00", 30), ("20:00", 15),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Takasaki.Tokyo", .descending,
                    "東海道線（上野東京ライン）", "JR Tokaido Line (via Ueno-Tokyo Line)",
                    "横浜・熱海方面", "for Yokohama & Atami",
                    to: "Railway:JR-East.Tokaido"),
            through("Takasaki.Omiya", .descending,
                    "湘南新宿ライン", "Shonan-Shinjuku Line",
                    "新宿・横浜方面", "for Shinjuku & Yokohama",
                    to: "Railway:JR-East.ShonanShinjuku"),
            through("Takasaki.Takasaki", .ascending,
                    "両毛線", "JR Ryomo Line", "前橋方面", "for Maebashi"),
        ]
    )

    // MARK: - Yokohama Line (JH)

    static let yokohamaLine = StaticTrainLine(
        id: "Railway:JR-East.Yokohama",
        nameJa: "横浜線",
        nameEn: "Yokohama Line",
        operatorId: "Operator:JR-East",
        colorHex: "#7FC342",
        stations: [
            st("Yokohama", "HigashiKanagawa", "東神奈川", "Higashi-Kanagawa", "JH13", 35.4772, 139.6343),
            st("Yokohama", "Oguchi", "大口", "Oguchi", "JH14", 35.4870, 139.6296),
            st("Yokohama", "Kikuna", "菊名", "Kikuna", "JH15", 35.5093, 139.6303),
            st("Yokohama", "ShinYokohama", "新横浜", "Shin-Yokohama", "JH16", 35.5070, 139.6170),
            st("Yokohama", "Kozukue", "小机", "Kozukue", "JH17", 35.5095, 139.6010),
            st("Yokohama", "Kamoi", "鴨居", "Kamoi", "JH18", 35.5098, 139.5678),
            st("Yokohama", "Nakayama", "中山", "Nakayama", "JH19", 35.5149, 139.5387),
            st("Yokohama", "Tokaichiba", "十日市場", "Tokaichiba", "JH20", 35.5184, 139.5168),
            st("Yokohama", "Nagatsuta", "長津田", "Nagatsuta", "JH21", 35.5318, 139.4944),
            st("Yokohama", "Naruse", "成瀬", "Naruse", "JH22", 35.5315, 139.4682),
            st("Yokohama", "Machida", "町田", "Machida", "JH23", 35.5421, 139.4451),
            st("Yokohama", "Kobuchi", "古淵", "Kobuchi", "JH24", 35.5547, 139.4212),
            st("Yokohama", "Fuchinobe", "淵野辺", "Fuchinobe", "JH25", 35.5683, 139.3968),
            st("Yokohama", "Yabe", "矢部", "Yabe", "JH26", 35.5737, 139.3882),
            st("Yokohama", "Sagamihara", "相模原", "Sagamihara", "JH27", 35.5796, 139.3733),
            st("Yokohama", "Hashimoto", "橋本", "Hashimoto", "JH28", 35.5948, 139.3449),
            st("Yokohama", "Aihara", "相原", "Aihara", "JH29", 35.6058, 139.3347),
            st("Yokohama", "HachiojiMinamino", "八王子みなみ野", "Hachioji-Minamino", "JH30", 35.6282, 139.3323),
            st("Yokohama", "Katakura", "片倉", "Katakura", "JH31", 35.6421, 139.3352),
            st("Yokohama", "Hachioji", "八王子", "Hachioji", "JH32", 35.6553, 139.3390),
        ],
        // Hops measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [
            3, 3, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 3, 3, 2, 3,
        ],
        // Real per-train timetable (608 grid) → 1:1 station timetables.
        timetableRuns: yokohamaLineTimetable,
        directions: [
            direction("Yokohama", "Hachioji", "八王子方面", "For Hachioji", ascending: true,
                      weekday: pattern("04:53", "24:04", [
                          ("04:53", 8), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:53", "24:04", [
                          ("04:53", 8), ("07:00", 6), ("10:00", 8), ("20:00", 9),
                      ])),
            // 八王子 departures run a flat ~6/h through the day (verified
            // July-2026); the descending bands are NOT mirrors of ascending.
            direction("Yokohama", "HigashiKanagawa", "東神奈川方面", "For Higashi-Kanagawa", ascending: false,
                      weekday: pattern("04:53", "24:11", [
                          ("04:53", 10), ("06:30", 7), ("09:00", 10), ("21:00", 12),
                      ]),
                      holiday: pattern("04:53", "24:11", [
                          ("04:53", 10), ("07:00", 9), ("10:00", 10), ("20:00", 10),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Yokohama.HigashiKanagawa", .descending,
                    "根岸線", "JR Negishi Line",
                    "桜木町・大船方面", "for Sakuragicho & Ofuna",
                    to: "Railway:JR-East.KeihinTohoku"),
        ]
    )

    // MARK: - Nambu Line (JN)

    static let nambu = StaticTrainLine(
        id: "Railway:JR-East.Nambu",
        nameJa: "南武線",
        nameEn: "Nambu Line",
        operatorId: "Operator:JR-East",
        colorHex: "#FFE100",
        stations: [
            st("Nambu", "Kawasaki", "川崎", "Kawasaki", "JN01", 35.5308, 139.6970),
            st("Nambu", "Shitte", "尻手", "Shitte", "JN02", 35.5288, 139.6818),
            st("Nambu", "Yako", "矢向", "Yako", "JN03", 35.5322, 139.6718),
            st("Nambu", "Kashimada", "鹿島田", "Kashimada", "JN04", 35.5452, 139.6648),
            st("Nambu", "Hirama", "平間", "Hirama", "JN05", 35.5542, 139.6577),
            st("Nambu", "Mukaigawara", "向河原", "Mukaigawara", "JN06", 35.5632, 139.6542),
            st("Nambu", "MusashiKosugi", "武蔵小杉", "Musashi-Kosugi", "JN07", 35.5766, 139.6597),
            st("Nambu", "MusashiNakahara", "武蔵中原", "Musashi-Nakahara", "JN08", 35.5832, 139.6443),
            st("Nambu", "MusashiShinjo", "武蔵新城", "Musashi-Shinjo", "JN09", 35.5872, 139.6277),
            st("Nambu", "MusashiMizonokuchi", "武蔵溝ノ口", "Musashi-Mizonokuchi", "JN10", 35.5998, 139.6103),
            st("Nambu", "Tsudayama", "津田山", "Tsudayama", "JN11", 35.6062, 139.6008),
            st("Nambu", "Kuji", "久地", "Kuji", "JN12", 35.6122, 139.5918),
            st("Nambu", "Shukugawara", "宿河原", "Shukugawara", "JN13", 35.6182, 139.5808),
            st("Nambu", "Noborito", "登戸", "Noborito", "JN14", 35.6205, 139.5702),
            st("Nambu", "Nakanoshima", "中野島", "Nakanoshima", "JN15", 35.6282, 139.5538),
            st("Nambu", "Inadazutsumi", "稲田堤", "Inadazutsumi", "JN16", 35.6332, 139.5448),
            st("Nambu", "Yanokuchi", "矢野口", "Yanokuchi", "JN17", 35.6382, 139.5278),
            st("Nambu", "InagiNaganuma", "稲城長沼", "Inagi-Naganuma", "JN18", 35.6412, 139.5098),
            st("Nambu", "MinamiTama", "南多摩", "Minami-Tama", "JN19", 35.6432, 139.4928),
            st("Nambu", "FuchuHommachi", "府中本町", "Fuchu-Hommachi", "JN20", 35.6618, 139.4788),
            st("Nambu", "Bubaigawara", "分倍河原", "Bubaigawara", "JN21", 35.6683, 139.4667),
            st("Nambu", "Nishifu", "西府", "Nishifu", "JN22", 35.6722, 139.4578),
            st("Nambu", "Yaho", "谷保", "Yaho", "JN23", 35.6782, 139.4468),
            st("Nambu", "Yagawa", "矢川", "Yagawa", "JN24", 35.6842, 139.4378),
            st("Nambu", "NishiKunitachi", "西国立", "Nishi-Kunitachi", "JN25", 35.6932, 139.4228),
            st("Nambu", "Tachikawa", "立川", "Tachikawa", "JN26", 35.6980, 139.4139),
        ],
        // Hops measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [
            3, 2, 2, 2, 2, 2, 3, 2, 3, 2, 2, 2, 2, 3, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2,
        ],
        // Real per-train timetable (703 grid) → 1:1 station timetables.
        timetableRuns: nambuTimetable,
        directions: [
            // 川崎 morning peak is ~20 trains/h (verified July-2026) — far
            // denser than the reverse direction.
            direction("Nambu", "Tachikawa", "立川方面", "For Tachikawa", ascending: true,
                      weekday: pattern("04:48", "24:26", [
                          ("04:48", 8), ("06:30", 4), ("09:30", 7), ("16:30", 5.5), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:48", "24:26", [
                          ("04:48", 8), ("07:00", 6), ("10:00", 7.5), ("20:00", 9),
                      ])),
            direction("Nambu", "Kawasaki", "川崎方面", "For Kawasaki", ascending: false,
                      weekday: pattern("04:46", "24:02", [
                          ("04:46", 8), ("06:30", 6), ("09:30", 7), ("16:30", 9), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("04:46", "24:02", [
                          ("04:46", 8), ("07:00", 6), ("10:00", 7.5), ("20:00", 9),
                      ])),
        ],
        delayInfo: delayInfo
    )

    // MARK: - Musashino Line (JM)

    static let musashino = StaticTrainLine(
        id: "Railway:JR-East.Musashino",
        nameJa: "武蔵野線",
        nameEn: "Musashino Line",
        operatorId: "Operator:JR-East",
        colorHex: "#EB6100",
        stations: [
            st("Musashino", "NishiFunabashi", "西船橋", "Nishi-Funabashi", "JM10", 35.7075, 139.9594),
            st("Musashino", "FunabashiHoten", "船橋法典", "Funabashi-Hoten", "JM11", 35.7182, 139.9448),
            st("Musashino", "IchikawaOno", "市川大野", "Ichikawa-Ono", "JM12", 35.7420, 139.9277),
            st("Musashino", "HigashiMatsudo", "東松戸", "Higashi-Matsudo", "JM13", 35.7706, 139.9438),
            st("Musashino", "ShinYahashira", "新八柱", "Shin-Yahashira", "JM14", 35.7772, 139.9368),
            st("Musashino", "ShimMatsudo", "新松戸", "Shim-Matsudo", "JM15", 35.8260, 139.9336),
            st("Musashino", "MinamiNagareyama", "南流山", "Minami-Nagareyama", "JM16", 35.8378, 139.9028),
            st("Musashino", "Misato", "三郷", "Misato", "JM17", 35.8283, 139.8790),
            st("Musashino", "ShinMisato", "新三郷", "Shin-Misato", "JM18", 35.8383, 139.8727),
            st("Musashino", "Yoshikawaminami", "吉川美南", "Yoshikawaminami", "JM19", 35.8502, 139.8558),
            st("Musashino", "Yoshikawa", "吉川", "Yoshikawa", "JM20", 35.8628, 139.8418),
            st("Musashino", "KoshigayaLaketown", "越谷レイクタウン", "Koshigaya-Laketown", "JM21", 35.8758, 139.8247),
            st("Musashino", "MinamiKoshigaya", "南越谷", "Minami-Koshigaya", "JM22", 35.8758, 139.7918),
            st("Musashino", "HigashiKawaguchi", "東川口", "Higashi-Kawaguchi", "JM23", 35.8712, 139.7478),
            st("Musashino", "HigashiUrawa", "東浦和", "Higashi-Urawa", "JM24", 35.8618, 139.7062),
            st("Musashino", "MinamiUrawa", "南浦和", "Minami-Urawa", "JM25", 35.8446, 139.6656),
            st("Musashino", "MusashiUrawa", "武蔵浦和", "Musashi-Urawa", "JM26", 35.8456, 139.6484),
            st("Musashino", "NishiUrawa", "西浦和", "Nishi-Urawa", "JM27", 35.8478, 139.6218),
            st("Musashino", "KitaAsaka", "北朝霞", "Kita-Asaka", "JM28", 35.8088, 139.5918),
            st("Musashino", "Niiza", "新座", "Niiza", "JM29", 35.7928, 139.5618),
            st("Musashino", "HigashiTokorozawa", "東所沢", "Higashi-Tokorozawa", "JM30", 35.7828, 139.5218),
            st("Musashino", "ShinAkitsu", "新秋津", "Shin-Akitsu", "JM31", 35.7722, 139.4878),
            st("Musashino", "ShinKodaira", "新小平", "Shin-Kodaira", "JM32", 35.7282, 139.4738),
            st("Musashino", "NishiKokubunji", "西国分寺", "Nishi-Kokubunji", "JM33", 35.6997, 139.4665),
            st("Musashino", "KitaFuchu", "北府中", "Kita-Fuchu", "JM34", 35.6788, 139.4738),
            st("Musashino", "FuchuHommachi", "府中本町", "Fuchu-Hommachi", "JM35", 35.6618, 139.4788),
        ],
        // Hops measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [
            3, 3, 2, 2, 4, 2, 2, 2, 2, 2, 2, 3, 4, 4, 3, 3, 2, 4, 3, 3, 3, 5, 3, 3, 2,
        ],
        // Real per-train timetable (708 grid) → 1:1 station timetables.
        timetableRuns: musashinoTimetable,
        directions: [
            direction("Musashino", "FuchuHommachi", "府中本町方面", "For Fuchu-Hommachi", ascending: true,
                      weekday: pattern("04:59", "24:02", [
                          ("04:59", 10), ("06:30", 5), ("09:30", 10), ("16:30", 8), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("04:59", "24:02", [
                          ("04:59", 10), ("07:00", 8), ("10:00", 10), ("20:00", 12),
                      ])),
            direction("Musashino", "NishiFunabashi", "西船橋方面", "For Nishi-Funabashi", ascending: false,
                      weekday: pattern("05:02", "24:01", [
                          ("05:02", 10), ("06:30", 6), ("09:30", 10), ("16:30", 8), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:01", "24:01", [
                          ("05:01", 10), ("07:00", 8), ("10:00", 10), ("20:00", 12),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Musashino.NishiFunabashi", .descending,
                    "京葉線", "JR Keiyo Line",
                    "東京方面", "for Tokyo",
                    to: "Railway:JR-East.KeiyoBranch"),
        ]
    )

    // MARK: - Keiyo Line Nishi-Funabashi Branch

    /// Bridge line for the 武蔵野線⇄京葉線 through service: the 西船橋–市川塩浜
    /// connecting track is on neither line's station list, so through
    /// resolution needs it as its own line (same pattern as 西武有楽町線).
    /// Windows/headways verified against the real 西船橋 東京方面 and
    /// 市川塩浜 西船橋方面 pages, July-2026 revision (~3 through trains/h).
    static let keiyoBranch = StaticTrainLine(
        id: "Railway:JR-East.KeiyoBranch",
        nameJa: "京葉線（西船橋支線）",
        nameEn: "Keiyo Line Nishi-Funabashi Branch",
        operatorId: "Operator:JR-East",
        colorHex: "#C9242F",
        stations: [
            // 西船橋 has no JE number (it is JM10/JB30), so it stays empty —
            // the line symbol falls through to 市川塩浜's JE09, badging the
            // branch as JE like the Keiyo mainline.
            st("KeiyoBranch", "NishiFunabashi", "西船橋", "Nishi-Funabashi", "", 35.7075, 139.9594),
            st("KeiyoBranch", "IchikawaShiohama", "市川塩浜", "Ichikawa-Shiohama", "JE09", 35.6569, 139.9343),
        ],
        hopTimesMinutes: [6],
        directions: [
            direction("KeiyoBranch", "IchikawaShiohama", "市川塩浜・東京方面", "For Ichikawa-Shiohama & Tokyo",
                      ascending: true,
                      weekday: pattern("05:45", "23:27", [
                          ("05:45", 25), ("07:00", 9), ("09:00", 20),
                      ]),
                      holiday: pattern("05:45", "23:28", [
                          ("05:45", 25), ("07:00", 15), ("09:00", 20),
                      ])),
            direction("KeiyoBranch", "NishiFunabashi", "西船橋方面", "For Nishi-Funabashi",
                      ascending: false,
                      weekday: pattern("06:25", "23:56", [
                          ("06:25", 20), ("17:00", 15), ("20:00", 20),
                      ]),
                      holiday: pattern("06:38", "23:56", [
                          ("06:38", 20),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("KeiyoBranch.NishiFunabashi", .descending,
                    "武蔵野線", "JR Musashino Line",
                    "南流山・府中本町方面", "for Minami-Nagareyama & Fuchu-Hommachi",
                    to: "Railway:JR-East.Musashino"),
            through("KeiyoBranch.IchikawaShiohama", .ascending,
                    "京葉線", "JR Keiyo Line",
                    "東京方面", "for Tokyo",
                    to: "Railway:JR-East.Keiyo"),
        ]
    )

    // MARK: - Ome Line (JC)

    static let ome = StaticTrainLine(
        id: "Railway:JR-East.Ome",
        nameJa: "青梅線",
        nameEn: "Ome Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F15A22",
        stations: [
            st("Ome", "Tachikawa", "立川", "Tachikawa", "JC19", 35.6980, 139.4139),
            st("Ome", "NishiTachikawa", "西立川", "Nishi-Tachikawa", "JC51", 35.7012, 139.4028),
            st("Ome", "HigashiNakagami", "東中神", "Higashi-Nakagami", "JC52", 35.7022, 139.3918),
            st("Ome", "Nakagami", "中神", "Nakagami", "JC53", 35.7032, 139.3828),
            st("Ome", "Akishima", "昭島", "Akishima", "JC54", 35.7058, 139.3698),
            st("Ome", "Haijima", "拝島", "Haijima", "JC55", 35.7088, 139.3532),
            st("Ome", "Ushihama", "牛浜", "Ushihama", "JC56", 35.7290, 139.3350),
            st("Ome", "Fussa", "福生", "Fussa", "JC57", 35.7380, 139.3270),
            st("Ome", "Hamura", "羽村", "Hamura", "JC58", 35.7620, 139.3110),
            st("Ome", "Ozaku", "小作", "Ozaku", "JC59", 35.7758, 139.2958),
            st("Ome", "Kabe", "河辺", "Kabe", "JC60", 35.7878, 139.2828),
            st("Ome", "HigashiOme", "東青梅", "Higashi-Ome", "JC61", 35.7898, 139.2648),
            st("Ome", "Ome", "青梅", "Ome", "JC62", 35.7878, 139.2438),
        ],
        // Hops measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [3, 2, 2, 2, 3, 3, 2, 3, 3, 3, 2, 2],
        // Real per-train timetable (652 grid) → 1:1 station timetables.
        timetableRuns: omeTimetable,
        directions: [
            direction("Ome", "Ome", "青梅方面", "For Ome", ascending: true,
                      weekday: pattern("04:46", "24:23", [
                          ("04:46", 10), ("06:30", 6), ("09:30", 11), ("16:30", 8), ("20:00", 7.5), ("22:00", 14),
                      ]),
                      holiday: pattern("04:46", "24:21", [
                          ("04:46", 10), ("07:00", 8), ("10:00", 10), ("20:00", 12),
                      ])),
            // 青梅 departures run ~5/h nearly all day (verified July-2026);
            // NOT a mirror of the 立川 volumes.
            direction("Ome", "Tachikawa", "立川方面", "For Tachikawa", ascending: false,
                      weekday: pattern("04:35", "23:58", [
                          ("04:35", 12), ("06:00", 9), ("09:30", 12), ("20:00", 12), ("22:00", 15),
                      ]),
                      holiday: pattern("04:35", "23:56", [
                          ("04:35", 12), ("07:00", 12), ("10:00", 13), ("20:00", 15),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Ome.Tachikawa", .descending,
                    "中央線快速", "JR Chuo Rapid Line", "東京方面", "for Tokyo",
                    to: "Railway:JR-East.ChuoRapid"),
            through("Ome.Haijima", .ascending,
                    "五日市線", "JR Itsukaichi Line",
                    "武蔵五日市方面", "for Musashi-Itsukaichi",
                    to: "Railway:JR-East.Itsukaichi"),
            through("Ome.Ome", .ascending,
                    "青梅線（東京アドベンチャーライン）", "JR Ome Line (Tokyo Adventure Line)",
                    "奥多摩方面", "for Okutama"),
        ]
    )

    // MARK: - Itsukaichi Line (JC)

    static let itsukaichi = StaticTrainLine(
        id: "Railway:JR-East.Itsukaichi",
        nameJa: "五日市線",
        nameEn: "Itsukaichi Line",
        operatorId: "Operator:JR-East",
        colorHex: "#F15A22",
        stations: [
            st("Itsukaichi", "Haijima", "拝島", "Haijima", "JC55", 35.7088, 139.3532),
            st("Itsukaichi", "Kumagawa", "熊川", "Kumagawa", "JC81", 35.7095, 139.3405),
            st("Itsukaichi", "HigashiAkiru", "東秋留", "Higashi-Akiru", "JC82", 35.7140, 139.3110),
            st("Itsukaichi", "Akigawa", "秋川", "Akigawa", "JC83", 35.7180, 139.2920),
            st("Itsukaichi", "MusashiHikida", "武蔵引田", "Musashi-Hikida", "JC84", 35.7210, 139.2740),
            st("Itsukaichi", "MusashiMasuko", "武蔵増戸", "Musashi-Masuko", "JC85", 35.7240, 139.2560),
            st("Itsukaichi", "MusashiItsukaichi", "武蔵五日市", "Musashi-Itsukaichi", "JC86", 35.7253, 139.2177),
        ],
        // Hops measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [2, 3, 4, 2, 2, 4],
        // Real per-train timetable (652 grid) → 1:1 station timetables.
        timetableRuns: itsukaichiTimetable,
        directions: [
            direction("Itsukaichi", "MusashiItsukaichi", "武蔵五日市方面", "For Musashi-Itsukaichi", ascending: true,
                      weekday: pattern("05:48", "24:18", [
                          ("05:48", 20), ("06:30", 20), ("09:30", 25), ("16:30", 15), ("20:00", 20), ("22:00", 25),
                      ]),
                      holiday: pattern("05:57", "24:18", [
                          ("05:57", 20), ("07:00", 20), ("10:00", 22), ("20:00", 25),
                      ])),
            direction("Itsukaichi", "Haijima", "拝島・立川方面", "For Haijima & Tachikawa", ascending: false,
                      weekday: pattern("05:20", "23:53", [
                          ("05:20", 20), ("06:30", 15), ("09:30", 25), ("16:30", 15), ("20:00", 20), ("22:00", 25),
                      ]),
                      holiday: pattern("05:22", "23:49", [
                          ("05:22", 20), ("07:00", 17), ("10:00", 22), ("20:00", 25),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Itsukaichi.Haijima", .descending,
                    "青梅線・中央線", "JR Ome & Chuo Lines", "立川方面", "for Tachikawa",
                    to: "Railway:JR-East.Ome"),
        ]
    )
}
