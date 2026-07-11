import Foundation

// MARK: - Tama Toshi Monorail Line Data

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
                       weekday: ServicePattern, holiday: ServicePattern,
                       origins: [IntermediateOrigin] = []) -> StaticLineDirection {
    StaticLineDirection(
        id: "static.RailDirection:\(path).\(suffix)",
        nameJa: ja, nameEn: en,
        isAscending: ascending,
        weekday: weekday, saturdayHoliday: holiday,
        intermediateOrigins: origins
    )
}

// 当駅始発 origin with EXACT departure times from ODPT (odpt:originStation).
private func origin(_ stationId: String, _ weekday: [String], _ holiday: [String]) -> IntermediateOrigin {
    IntermediateOrigin(stationId: stationId, weekday: weekday, saturdayHoliday: holiday)
}

enum TamaMonorailLineData {

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.tama-monorail.co.jp/",
        statusPageURLEn: "https://www.tama-monorail.co.jp/",
        xAccount: nil,
        checkMethodJa: "多摩都市モノレールの公式サイトで確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Tama Toshi Monorail website. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        tamaMonorail,
    ]

    static let tamaMonorail = StaticTrainLine(
        id: "Railway:TamaMonorail.TamaMonorail",
        nameJa: "多摩都市モノレール線",
        nameEn: "Tama Toshi Monorail Line",
        operatorId: "Operator:TamaMonorail",
        colorHex: "#F08300",
        stations: [
            st("TamaMonorail.TamaMonorail", "TamaCenter", "多摩センター", "Tama Center", "TT01", 35.6239, 139.4228),
            st("TamaMonorail.TamaMonorail", "Matsugaya", "松が谷", "Matsugaya", "TT02", 35.6318, 139.422),
            st("TamaMonorail.TamaMonorail", "OtsukaTeikyoDaigaku", "大塚・帝京大学", "Otsuka-teikyo-daigaku", "TT03", 35.6369, 139.4164),
            st("TamaMonorail.TamaMonorail", "ChuoDaigakuMeiseiDaigaku", "中央大学・明星大学", "Chuo-daigaku-meisei-daigaku", "TT04", 35.6419, 139.4087),
            st("TamaMonorail.TamaMonorail", "TamaDobutsukoen", "多摩動物公園", "Tama-dobutsukoen", "TT05", 35.6485, 139.4038),
            st("TamaMonorail.TamaMonorail", "Hodokubo", "程久保", "Hodokubo", "TT06", 35.6552, 139.4108),
            st("TamaMonorail.TamaMonorail", "Takahatafudo", "高幡不動", "Takahatafudo", "TT07", 35.6613, 139.4152),
            st("TamaMonorail.TamaMonorail", "Manganji", "万願寺", "Manganji", "TT08", 35.6713, 139.4199),
            st("TamaMonorail.TamaMonorail", "Koshukaido", "甲州街道", "Koshukaido", "TT09", 35.6782, 139.4092),
            st("TamaMonorail.TamaMonorail", "ShibasakiTaiikukan", "柴崎体育館", "Shibasaki-taiikukan", "TT10", 35.6898, 139.4093),
            st("TamaMonorail.TamaMonorail", "TachikawaMinami", "立川南", "Tachikawa-minami", "TT11", 35.6962, 139.4126),
            st("TamaMonorail.TamaMonorail", "TachikawaKita", "立川北", "Tachikawa-kita", "TT12", 35.6995, 139.4127),
            st("TamaMonorail.TamaMonorail", "Takamatsu", "高松", "Takamatsu", "TT13", 35.71, 139.4133),
            st("TamaMonorail.TamaMonorail", "Tachihi", "立飛", "Tachihi", "TT14", 35.7143, 139.4171),
            st("TamaMonorail.TamaMonorail", "IzumiTaiikukan", "泉体育館", "Izumi-taiikukan", "TT15", 35.7188, 139.4196),
            st("TamaMonorail.TamaMonorail", "SunagawaNanaban", "砂川七番", "Sunagawa-nanaban", "TT16", 35.7234, 139.4181),
            st("TamaMonorail.TamaMonorail", "TamagawaJosui", "玉川上水", "Tamagawa-josui", "TT17", 35.7322, 139.4177),
            st("TamaMonorail.TamaMonorail", "Sakurakaido", "桜街道", "Sakurakaido", "TT18", 35.739, 139.4166),
            st("TamaMonorail.TamaMonorail", "Kamikitadai", "上北台", "Kamikitadai", "TT19", 35.7458, 139.4159),
        ],
        hopTimesMinutes: [2, 2, 2, 3, 2, 2, 3, 2, 3, 2, 2, 3, 2, 2, 1, 2, 2, 2],
        directions: [
            direction("TamaMonorail.TamaMonorail", "Kamikitadai", "上北台方面", "For Kamikitadai", ascending: true,
                      // Last full-line 上北台行 departs 23:28; later 立川北行 short turns run to 23:45.
                      weekday: pattern("05:24", "23:28", [
                          ("05:00", 12), ("06:00", 9), ("07:00", 7), ("08:00", 6), ("09:00", 9), ("11:00", 10), ("16:00", 7), ("17:00", 8), ("18:00", 7), ("19:00", 8), ("20:00", 10), ("22:00", 12), ("23:00", 18),
                      ]),
                      holiday: pattern("05:24", "23:28", [
                          ("05:00", 13), ("06:00", 10), ("07:00", 9), ("20:00", 10), ("21:00", 15), ("23:00", 18),
                      ]),
                      origins: [
                          origin("Station:TamaMonorail.TamaMonorail.Takahatafudo",
                                 ["05:23"],
                                 ["05:23"]),
                      ]),
            direction("TamaMonorail.TamaMonorail", "TamaCenter", "多摩センター方面", "For Tama Center", ascending: false,
                      weekday: pattern("05:15", "23:35", [
                          ("05:00", 12), ("06:00", 9), ("07:00", 6), ("08:00", 8), ("09:00", 9), ("10:00", 10), ("16:00", 8), ("17:00", 7), ("18:00", 8), ("19:00", 9), ("20:00", 10), ("21:00", 12), ("22:00", 18), ("23:00", 20),
                      ]),
                      holiday: pattern("05:15", "23:35", [
                          ("05:00", 12), ("06:00", 10), ("07:00", 9), ("20:00", 10), ("21:00", 12), ("22:00", 18), ("23:00", 20),
                      ]),
                      origins: [
                          origin("Station:TamaMonorail.TamaMonorail.Takamatsu",
                                 ["05:12", "06:29", "15:43"],
                                 ["05:12"]),
                      ]),
        ],
        delayInfo: delayInfo
    )
}
