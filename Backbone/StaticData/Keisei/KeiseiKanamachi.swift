import Foundation

extension KeiseiLineData {

    // MARK: Keisei Kanamachi Line (KS)

    static let kanamachi = StaticTrainLine(
        id: "Railway:Keisei.Kanamachi",
        nameJa: "京成金町線",
        nameEn: "Keisei Kanamachi Line",
        operatorId: "Operator:Keisei",
        colorHex: "#005AAA",
        stations: [
            st("Keisei.Kanamachi", "KeiseiTakasago", "京成高砂", "Keisei-Takasago", "KS10", 35.7498, 139.8658),
            st("Keisei.Kanamachi", "Shibamata", "柴又", "Shibamata", "KS50", 35.7565, 139.8753),
            st("Keisei.Kanamachi", "KeiseiKanamachi", "京成金町", "Keisei-Kanamachi", "KS51", 35.7685, 139.8705),
        ],
        hopTimesMinutes: [2.5, 2.5],
        directions: [
            direction("Keisei.Kanamachi", "KeiseiKanamachi", "京成金町方面", "For Keisei-Kanamachi", ascending: true,
                      weekday: pattern("05:01", "24:04", [
                          ("05:01", 12), ("07:00", 8), ("09:30", 15), ("22:00", 15),
                      ]),
                      holiday: pattern("05:01", "24:04", [
                          ("05:01", 15), ("22:00", 15),
                      ])),
            direction("Keisei.Kanamachi", "KeiseiTakasago", "京成高砂方面", "For Keisei-Takasago", ascending: false,
                      weekday: pattern("05:10", "24:12", [
                          ("05:10", 12), ("07:00", 8), ("09:30", 15), ("22:00", 15),
                      ]),
                      holiday: pattern("05:10", "24:12", [
                          ("05:10", 15), ("22:00", 15),
                      ])),
        ],
        delayInfo: delayInfo
    )

}
