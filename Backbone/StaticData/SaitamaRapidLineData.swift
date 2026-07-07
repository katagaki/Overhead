import Foundation

// MARK: - Saitama Rapid Railway Line Data

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

enum SaitamaRapidLineData {

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.s-rail.co.jp/",
        statusPageURLEn: "https://www.s-rail.co.jp/",
        xAccount: nil,
        checkMethodJa: "埼玉高速鉄道の公式サイトで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Saitama Railway website. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        saitamaRailway,
    ]

    // MARK: - Saitama Rapid Railway Line (SR, 埼玉スタジアム線)

    static let saitamaRailway = StaticTrainLine(
        id: "odpt.Railway:SaitamaRailway.SaitamaRailway",
        nameJa: "埼玉高速鉄道線",
        nameEn: "Saitama Rapid Railway Line",
        operatorId: "odpt.Operator:SaitamaRailway",
        colorHex: "#0067C0",
        stations: [
            st("SaitamaRailway.SaitamaRailway", "AkabaneIwabuchi", "赤羽岩淵", "Akabane-iwabuchi", "SR19", 35.7837, 139.7217),
            st("SaitamaRailway.SaitamaRailway", "KawaguchiMotogo", "川口元郷", "Kawaguchi-motogo", "SR20", 35.7947, 139.7307),
            st("SaitamaRailway.SaitamaRailway", "MinamiHatogaya", "南鳩ヶ谷", "Minami-hatogaya", "SR21", 35.8087, 139.7357),
            st("SaitamaRailway.SaitamaRailway", "Hatogaya", "鳩ヶ谷", "Hatogaya", "SR22", 35.8227, 139.7407),
            st("SaitamaRailway.SaitamaRailway", "Araijuku", "新井宿", "Araijuku", "SR23", 35.8337, 139.7457),
            st("SaitamaRailway.SaitamaRailway", "TozukaAngyo", "戸塚安行", "Tozuka-angyo", "SR24", 35.8477, 139.7537),
            st("SaitamaRailway.SaitamaRailway", "HigashiKawaguchi", "東川口", "Higashi-kawaguchi", "SR25", 35.8712, 139.7478),
            st("SaitamaRailway.SaitamaRailway", "UrawaMisono", "浦和美園", "Urawa-misono", "SR26", 35.8857, 139.7407),
        ],
        hopTimesMinutes: [2, 2, 2, 2, 2, 3, 3],
        directions: [
            // Last down departure 24:29 per the March 2025 timetable revision
            direction("SaitamaRailway.SaitamaRailway", "UrawaMisono", "浦和美園方面", "For Urawa-misono",
                      ascending: true,
                      weekday: pattern("05:14", "24:29", [
                          ("05:14", 10), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:14", "24:29", [
                          ("05:14", 10), ("07:00", 8), ("10:00", 8), ("20:00", 10),
                      ])),
            direction("SaitamaRailway.SaitamaRailway", "AkabaneIwabuchi", "赤羽岩淵・目黒方面", "For Akabane-iwabuchi & Meguro",
                      ascending: false,
                      weekday: pattern("05:10", "24:06", [
                          ("05:10", 10), ("06:30", 5), ("09:30", 8), ("16:30", 6), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:10", "24:06", [
                          ("05:10", 10), ("07:00", 8), ("10:00", 8), ("20:00", 10),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("SaitamaRailway.SaitamaRailway.AkabaneIwabuchi", .descending,
                    "東京メトロ南北線", "Tokyo Metro Namboku Line",
                    "目黒・東急線方面", "for Meguro & the Tokyu Line",
                    to: "odpt.Railway:TokyoMetro.Namboku"),
        ]
    )
}
