import Foundation

extension KeiseiLineData {

    static let skyAccess = StaticTrainLine(
        id: "Railway:Keisei.NaritaSkyAccess",
        nameJa: "成田スカイアクセス線",
        nameEn: "Narita Sky Access Line",
        operatorId: "Operator:Keisei",
        colorHex: "#EC7B02",
        stations: [
            st("Keisei.NaritaSkyAccess", "KeiseiTakasago", "京成高砂", "Keisei-Takasago", "KS10", 35.7498, 139.8658),
            st("Keisei.NaritaSkyAccess", "HigashiMatsudo", "東松戸", "Higashi-Matsudo", "HS05", 35.7699, 139.9429),
            st("Keisei.NaritaSkyAccess", "ShinKamagaya", "新鎌ヶ谷", "Shin-Kamagaya", "HS08", 35.7795, 139.9983),
            st("Keisei.NaritaSkyAccess", "ChibaNewTown", "千葉ニュータウン中央", "Chiba New Town Chuo", "HS12", 35.8002, 140.1164),
            st("Keisei.NaritaSkyAccess", "ImbaNihonIdai", "印旛日本医大", "Imba-Nihon-Idai", "HS14", 35.7876, 140.2033),
            st("Keisei.NaritaSkyAccess", "NaritaYukawa", "成田湯川", "Narita-Yukawa", "KS43", 35.7996, 140.2911),
            st("Keisei.NaritaSkyAccess", "AirportTerminal2", "空港第2ビル", "Narita Airport Terminal 2·3", "KS41", 35.7718, 140.3925),
            st("Keisei.NaritaSkyAccess", "NaritaAirport", "成田空港", "Narita Airport Terminal 1", "KS42", 35.7640, 140.3860),
        ],
        hopTimesMinutes: [8, 5, 9, 7, 7, 8, 2],
        directions: [
            direction("Keisei.NaritaSkyAccess", "NaritaAirport", "成田空港方面", "For Narita Airport", ascending: true,
                      weekday: skyAccessWeekday("05:34", "23:00"), holiday: skyAccessHoliday("05:34", "23:00")),
            direction("Keisei.NaritaSkyAccess", "KeiseiTakasago", "京成高砂方面", "For Keisei-Takasago", ascending: false,
                      weekday: skyAccessWeekday("05:41", "23:08"), holiday: skyAccessHoliday("05:41", "23:08")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            // 押上線 (羽田空港方面) is reached by chaining through 京成本線
            // at 青砥 — 京成高砂 is not on 押上線, so a direct through to it
            // could never resolve.
            through("Keisei.NaritaSkyAccess.KeiseiTakasago", .descending,
                    "京成本線", "Keisei Main Line",
                    "京成上野方面", "for Keisei-Ueno",
                    to: "Railway:Keisei.Main"),
        ]
    )

    // MARK: Narita Sky Access Line (KS)

    private static func skyAccessWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 40), ("06:30", 30), ("09:00", 40), ("17:00", 30), ("20:00", 40),
        ])
    }

    private static func skyAccessHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 40),
        ])
    }

}
