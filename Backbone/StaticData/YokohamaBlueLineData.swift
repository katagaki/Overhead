import Foundation

// MARK: - Yokohama Municipal Subway Blue Line Data

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

enum YokohamaBlueLineData {

    // MARK: Delay Check

    static let delayInfo = DelayCheckInfo(
        statusPageURL: "https://www.city.yokohama.lg.jp/kotsu/",
        statusPageURLEn: "https://www.city.yokohama.lg.jp/lang/residents/en/",
        xAccount: nil,
        checkMethodJa: "横浜市交通局の公式サイトで運行情報を確認できます。遅延・運転見合わせが発生した場合に掲載されます。",
        checkMethodEn: "Check the Yokohama City Transportation Bureau website for service information. Delays and suspensions are posted as they occur."
    )

    static let lines: [StaticTrainLine] = [
        yokohamaBlue,
    ]

    static let yokohamaBlue = StaticTrainLine(
        id: "Railway:YokohamaMunicipal.Blue",
        nameJa: "横浜市営地下鉄ブルーライン",
        nameEn: "Yokohama Municipal Subway Blue Line",
        operatorId: "Operator:YokohamaMunicipal",
        colorHex: "#3577BC",
        stations: [
            st("YokohamaMunicipal.Blue", "Shonandai", "湘南台", "Shonandai", "B01", 35.396565, 139.466502),
            st("YokohamaMunicipal.Blue", "Shimoiida", "下飯田", "Shimoiida", "B02", 35.403362, 139.482969),
            st("YokohamaMunicipal.Blue", "Tateba", "立場", "Tateba", "B03", 35.41423, 139.50028),
            st("YokohamaMunicipal.Blue", "Nakada", "中田", "Nakada", "B04", 35.411199, 139.511324),
            st("YokohamaMunicipal.Blue", "Odoriba", "踊場", "Odoriba", "B05", 35.405704, 139.518501),
            st("YokohamaMunicipal.Blue", "Totsuka", "戸塚", "Totsuka", "B06", 35.401142, 139.535125),
            st("YokohamaMunicipal.Blue", "Maioka", "舞岡", "Maioka", "B07", 35.402538, 139.551498),
            st("YokohamaMunicipal.Blue", "Shimonagaya", "下永谷", "Shimonagaya", "B08", 35.402844, 139.559275),
            st("YokohamaMunicipal.Blue", "Kaminagaya", "上永谷", "Kaminagaya", "B09", 35.401456, 139.573079),
            st("YokohamaMunicipal.Blue", "KonanChuo", "港南中央", "Konan-chuo", "B10", 35.401317, 139.591578),
            st("YokohamaMunicipal.Blue", "Kamiooka", "上大岡", "Kamiooka", "B11", 35.408451, 139.595875),
            st("YokohamaMunicipal.Blue", "Gumyoji", "弘明寺", "Gumyoji", "B12", 35.423152, 139.602039),
            st("YokohamaMunicipal.Blue", "Maita", "蒔田", "Maita", "B13", 35.430203, 139.610464),
            st("YokohamaMunicipal.Blue", "Yoshinocho", "吉野町", "Yoshinocho", "B14", 35.435424, 139.61888),
            st("YokohamaMunicipal.Blue", "Bandobashi", "阪東橋", "Bandobashi", "B15", 35.437646, 139.625296),
            st("YokohamaMunicipal.Blue", "IsezakiChojamachi", "伊勢佐木長者町", "Isezaki-chojamachi", "B16", 35.441008, 139.632601),
            st("YokohamaMunicipal.Blue", "Kannai", "関内", "Kannai", "B17", 35.445714, 139.635978),
            st("YokohamaMunicipal.Blue", "Sakuragicho", "桜木町", "Sakuragicho", "B18", 35.449761, 139.630626),
            st("YokohamaMunicipal.Blue", "Takashimacho", "高島町", "Takashimacho", "B19", 35.458945, 139.623477),
            st("YokohamaMunicipal.Blue", "Yokohama", "横浜", "Yokohama", "B20", 35.465624, 139.619948),
            st("YokohamaMunicipal.Blue", "MitsuzawaShimocho", "三ツ沢下町", "Mitsuzawa-shimocho", "B21", 35.476517, 139.615042),
            st("YokohamaMunicipal.Blue", "MitsuzawaKamicho", "三ツ沢上町", "Mitsuzawa-kamicho", "B22", 35.47642, 139.605408),
            st("YokohamaMunicipal.Blue", "Katakuracho", "片倉町", "Katakuracho", "B23", 35.489974, 139.606518),
            st("YokohamaMunicipal.Blue", "KishineKoen", "岸根公園", "Kishine-koen", "B24", 35.495556, 139.616656),
            st("YokohamaMunicipal.Blue", "ShinYokohama", "新横浜", "Shin-yokohama", "B25", 35.508876, 139.617318),
            st("YokohamaMunicipal.Blue", "KitaShinYokohama", "北新横浜", "Kita-shin-yokohama", "B26", 35.519237, 139.612816),
            st("YokohamaMunicipal.Blue", "Nippa", "新羽", "Nippa", "B27", 35.527081, 139.612377),
            st("YokohamaMunicipal.Blue", "Nakamachidai", "仲町台", "Nakamachidai", "B28", 35.53523, 139.589828),
            st("YokohamaMunicipal.Blue", "CenterMinami", "センター南", "Center-minami", "B29", 35.545633, 139.574713),
            st("YokohamaMunicipal.Blue", "CenterKita", "センター北", "Center-kita", "B30", 35.553383, 139.579045),
            st("YokohamaMunicipal.Blue", "Nakagawa", "中川", "Nakagawa", "B31", 35.562659, 139.570296),
            st("YokohamaMunicipal.Blue", "Azamino", "あざみ野", "Azamino", "B32", 35.568022, 139.553876),
        ],
        hopTimesMinutes: [3, 2, 1, 1, 2, 2, 1, 2, 2, 2, 2, 2, 1, 1, 1, 2, 1, 2, 1, 2, 1, 2, 2, 2, 2, 2, 3, 3, 1, 2, 2],
        directions: [
            direction("YokohamaMunicipal.Blue", "Azamino", "あざみ野方面", "For Azamino", ascending: true,
                      // lastDeparture is the last full-line あざみ野行; later 上永谷行 short turns run past 24:00 (not modeled as full-line trips).
                      weekday: pattern("05:20", "23:52", [
                          ("05:00", 10), ("06:00", 5), ("07:00", 4), ("08:00", 5), ("09:00", 10), ("15:00", 7), ("16:00", 6), ("21:00", 10), ("22:00", 11), ("23:00", 12),
                      ]),
                      holiday: pattern("05:20", "23:23", [
                          ("05:00", 12), ("06:00", 7), ("10:00", 10), ("16:00", 8), ("20:00", 9), ("21:00", 10), ("22:00", 13), ("23:00", 14), ("24:00", 9),
                      ]),
                      origins: [
                          origin("Station:YokohamaMunicipal.Blue.Odoriba",
                                 ["05:16", "06:27", "10:40", "11:10", "11:40", "12:10", "12:40", "13:10", "13:40", "14:10", "14:40", "15:12", "15:42", "16:12"],
                                 ["05:16", "09:10", "10:11", "10:41", "11:11", "11:40", "12:10", "12:40", "13:10", "13:40", "14:10", "14:40", "15:10", "15:41", "16:11", "16:41", "17:11", "17:41", "18:11", "18:41", "19:11", "19:41", "20:11"]),
                          origin("Station:YokohamaMunicipal.Blue.Kaminagaya",
                                 ["05:14", "05:44", "06:07", "06:17", "06:26", "06:44"],
                                 ["05:14", "05:45", "06:08"]),
                          origin("Station:YokohamaMunicipal.Blue.Kamiooka",
                                 ["06:03"],
                                 []),
                          origin("Station:YokohamaMunicipal.Blue.Yokohama",
                                 ["05:26"],
                                 ["05:26"]),
                          origin("Station:YokohamaMunicipal.Blue.Nippa",
                                 ["05:15", "05:29", "06:10", "06:27"],
                                 ["05:15", "05:29"]),
                      ]),
            direction("YokohamaMunicipal.Blue", "Shonandai", "湘南台方面", "For Shonandai", ascending: false,
                      // lastDeparture is the last full-line 湘南台行; later 新羽行 short turns run past 24:00.
                      weekday: pattern("05:14", "23:42", [
                          ("05:00", 10), ("06:00", 5), ("08:00", 4), ("09:00", 9), ("10:00", 10), ("14:00", 9), ("15:00", 8), ("16:00", 6), ("21:00", 8), ("22:00", 11), ("23:00", 12), ("24:00", 10),
                      ]),
                      holiday: pattern("05:14", "23:12", [
                          ("05:00", 11), ("06:00", 6), ("07:00", 7), ("09:00", 8), ("10:00", 10), ("15:00", 9), ("16:00", 8), ("21:00", 9), ("22:00", 12), ("24:00", 15),
                      ]),
                      origins: [
                          origin("Station:YokohamaMunicipal.Blue.Kaminagaya",
                                 ["05:12", "05:23", "05:32", "06:22", "06:30", "06:44", "06:53", "07:11"],
                                 ["05:12", "05:23", "05:33", "06:19", "06:34", "09:21", "10:11", "19:40"]),
                          origin("Station:YokohamaMunicipal.Blue.ShinYokohama",
                                 ["05:09"],
                                 ["05:09", "23:38"]),
                          origin("Station:YokohamaMunicipal.Blue.Nippa",
                                 ["05:14", "05:55", "06:23", "06:49", "10:14", "10:44", "11:14", "11:44", "12:14", "12:44", "13:14", "13:44", "14:14", "14:44", "15:14", "15:45", "16:17"],
                                 ["05:14", "09:17", "09:47", "10:17", "10:44", "11:14", "11:44", "12:14", "12:44", "13:14", "13:44", "14:14", "14:44", "15:14", "15:44", "16:16", "16:47", "17:17", "17:47", "18:17", "18:47", "19:17", "19:47", "20:17"]),
                      ]),
        ],
        delayInfo: delayInfo
    )
}
