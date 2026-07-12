import Foundation

extension TobuLineData {

    static let daishi = StaticTrainLine(
        id: "Railway:Tobu.Daishi",
        nameJa: "東武大師線",
        nameEn: "Tobu Daishi Line",
        operatorId: "Operator:Tobu",
        colorHex: "#0067C0",
        stations: [
            st("Tobu.Daishi", "Nishiarai", "西新井", "Nishiarai", "TS13", 35.7775, 139.7925),
            st("Tobu.Daishi", "Daishimae", "大師前", "Daishimae", "TS51", 35.7789, 139.7815),
        ],
        hopTimesMinutes: [2],
        directions: [
            direction("Tobu.Daishi", "Daishimae", "大師前方面", "For Daishimae", ascending: true,
                      weekday: daishiPattern("05:28", "24:14"), holiday: daishiPattern("05:28", "24:14")),
            direction("Tobu.Daishi", "Nishiarai", "西新井方面", "For Nishiarai", ascending: false,
                      weekday: daishiPattern("05:32", "24:08"), holiday: daishiPattern("05:32", "24:08")),
        ],
        delayInfo: delayInfo
    )

    // MARK: Tobu Daishi Line (TS)

    private static func daishiPattern(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 10),
        ])
    }

}
