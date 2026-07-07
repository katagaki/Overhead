import Foundation

// MARK: - Minatomirai Line Data

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
        junctionStationId: "Station:\(junction)",
        end: end,
        lineNameJa: lineJa, lineNameEn: lineEn,
        towardJa: towardJa, towardEn: towardEn,
        connectingLineId: connectingLineId
    )
}

enum MinatomiraiLineData {

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.mm21railway.co.jp/",
        statusPageURLEn: "https://www.mm21railway.co.jp/",
        xAccount: nil,
        checkMethodJa: "横浜高速鉄道の公式サイトまたは東急線アプリで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Yokohama Minatomirai Railway website or the Tokyu Lines app. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        minatomirai,
    ]

    // MARK: - Minatomirai Line (MM)

    static let minatomirai = StaticTrainLine(
        id: "Railway:Minatomirai.Minatomirai",
        nameJa: "みなとみらい線",
        nameEn: "Minatomirai Line",
        operatorId: "Operator:Minatomirai",
        colorHex: "#004098",
        stations: [
            st("Minatomirai.Minatomirai", "Yokohama", "横浜", "Yokohama", "MM01", 35.4657, 139.6224),
            st("Minatomirai.Minatomirai", "Shintakashima", "新高島", "Shin-takashima", "MM02", 35.4627, 139.6297),
            st("Minatomirai.Minatomirai", "Minatomirai", "みなとみらい", "Minatomirai", "MM03", 35.4577, 139.6377),
            st("Minatomirai.Minatomirai", "Bashamichi", "馬車道", "Bashamichi", "MM04", 35.4507, 139.6357),
            st("Minatomirai.Minatomirai", "NihonOdori", "日本大通り", "Nihon-odori", "MM05", 35.4477, 139.6407),
            st("Minatomirai.Minatomirai", "MotomachiChukagai", "元町・中華街", "Motomachi-Chukagai", "MM06", 35.4437, 139.6507),
        ],
        hopTimesMinutes: [2, 2, 2, 2, 2],
        directions: [
            direction("Minatomirai.Minatomirai", "MotomachiChukagai", "元町・中華街方面", "For Motomachi-Chukagai",
                      ascending: true,
                      weekday: pattern("05:10", "23:58", [
                          ("05:10", 8), ("06:30", 4), ("09:30", 5), ("16:30", 4), ("20:00", 5), ("22:00", 8),
                      ]),
                      holiday: pattern("05:10", "23:58", [
                          ("05:10", 8), ("07:00", 5), ("10:00", 5), ("20:00", 7),
                      ])),
            direction("Minatomirai.Minatomirai", "Yokohama", "横浜・渋谷方面", "For Yokohama & Shibuya",
                      ascending: false,
                      weekday: pattern("04:57", "23:55", [
                          ("04:57", 8), ("06:30", 4), ("09:30", 5), ("16:30", 4), ("20:00", 5), ("22:00", 8),
                      ]),
                      holiday: pattern("04:57", "23:55", [
                          ("04:57", 8), ("07:00", 5), ("10:00", 5), ("20:00", 7),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Minatomirai.Minatomirai.Yokohama", .descending,
                    "東急東横線", "Tokyu Toyoko Line",
                    "渋谷・副都心線方面", "for Shibuya & the Fukutoshin Line",
                    to: "Railway:Tokyu.Toyoko"),
        ]
    )
}
