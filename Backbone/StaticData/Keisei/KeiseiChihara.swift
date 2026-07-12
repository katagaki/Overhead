import Foundation

extension KeiseiLineData {

    static let chihara = StaticTrainLine(
        id: "Railway:Keisei.Chihara",
        nameJa: "京成千原線",
        nameEn: "Keisei Chihara Line",
        operatorId: "Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.Chihara", "Chibachuo", "千葉中央", "Chiba-Chuo", "KS60", 35.6073, 140.1178),
            st("Keisei.Chihara", "Chibadera", "千葉寺", "Chibadera", "KS61", 35.5903, 140.1322),
            st("Keisei.Chihara", "Omoridai", "大森台", "Omoridai", "KS62", 35.5842, 140.1494),
            st("Keisei.Chihara", "Gakuemmae", "学園前", "Gakuemmae", "KS63", 35.5608, 140.1584),
            st("Keisei.Chihara", "Oyumino", "おゆみ野", "Oyumino", "KS64", 35.5500, 140.1663),
            st("Keisei.Chihara", "Chiharadai", "ちはら台", "Chiharadai", "KS65", 35.5338, 140.1702),
        ],
        hopTimesMinutes: [3, 2, 4, 2, 3],
        directions: [
            direction("Keisei.Chihara", "Chiharadai", "ちはら台方面", "For Chiharadai", ascending: true,
                      weekday: chiharaWeekday("05:49", "23:49"), holiday: chiharaHoliday("05:49", "23:49")),
            direction("Keisei.Chihara", "Chibachuo", "千葉中央方面", "For Chiba-Chuo", ascending: false,
                      weekday: chiharaWeekday("05:34", "23:21"), holiday: chiharaHoliday("05:34", "23:21")),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Keisei.Chihara.Chibachuo", .descending,
                    "京成千葉線", "Keisei Chiba Line",
                    "京成津田沼方面", "for Keisei-Tsudanuma",
                    to: "Railway:Keisei.Chiba"),
        ]
    )

    // MARK: Keisei Chihara Line (KS)

    private static func chiharaWeekday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 15), ("07:00", 10), ("09:30", 20), ("17:00", 15), ("20:00", 20),
        ])
    }

    private static func chiharaHoliday(_ first: String, _ last: String) -> ServicePattern {
        pattern(first, last, [
            (first, 20),
        ])
    }

}
