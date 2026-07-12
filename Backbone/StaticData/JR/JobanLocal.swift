import Foundation

extension JREastLineData {

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

}
