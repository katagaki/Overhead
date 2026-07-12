import Foundation

extension TobuLineData {

    static let kameido = StaticTrainLine(
        id: "Railway:Tobu.Kameido",
        nameJa: "東武亀戸線",
        nameEn: "Tobu Kameido Line",
        operatorId: "Operator:Tobu",
        colorHex: "#0067C0",
        stations: [
            st("Tobu.Kameido", "Hikifune", "曳舟", "Hikifune", "TS04", 35.7168, 139.8172),
            st("Tobu.Kameido", "Omurai", "小村井", "Omurai", "TS41", 35.7101, 139.8280),
            st("Tobu.Kameido", "HigashiAzuma", "東あずま", "Higashi-Azuma", "TS42", 35.7071, 139.8319),
            st("Tobu.Kameido", "KameidoSuijin", "亀戸水神", "Kameido-Suijin", "TS43", 35.7003, 139.8337),
            st("Tobu.Kameido", "Kameido", "亀戸", "Kameido", "TS44", 35.6976, 139.8261),
        ],
        hopTimesMinutes: [3, 1, 2, 2],
        directions: [
            direction("Tobu.Kameido", "Kameido", "亀戸方面", "For Kameido", ascending: true,
                      weekday: kameidoWeekday("05:34", "24:18"), holiday: kameidoHoliday("05:34", "24:18")),
            direction("Tobu.Kameido", "Hikifune", "曳舟方面", "For Hikifune", ascending: false,
                      weekday: kameidoWeekday("05:43", "24:29"), holiday: kameidoHoliday("05:43", "24:29")),
        ],
        delayInfo: delayInfo
    )

    // MARK: Tobu Kameido Line (TS)

    private static func kameidoWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 10), ("07:00", 8), ("09:30", 10), ("22:00", 12),
        ])
    }

    private static func kameidoHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 10), ("22:00", 12),
        ])
    }

}
