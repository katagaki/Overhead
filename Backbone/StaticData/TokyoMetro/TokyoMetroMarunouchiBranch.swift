import Foundation

extension TokyoMetroLineData {

    // MARK: - Marunouchi Line Honancho Branch (Mb)

    static let marunouchiBranch = StaticTrainLine(
        id: "Railway:TokyoMetro.MarunouchiBranch",
        nameJa: "丸ノ内線(方南町支線)",
        nameEn: "Marunouchi Line Honancho Branch",
        operatorId: "Operator:TokyoMetro",
        colorHex: "#E60012",
        stations: [
            st("MarunouchiBranch", "Honancho", "方南町", "Honancho", "Mb03", 35.6836, 139.6588),
            st("MarunouchiBranch", "NakanoFujimicho", "中野富士見町", "Nakano-fujimicho", "Mb04", 35.6866, 139.6693),
            st("MarunouchiBranch", "NakanoShimbashi", "中野新橋", "Nakano-shimbashi", "Mb05", 35.6907, 139.6764),
            st("MarunouchiBranch", "NakanoSakaue", "中野坂上", "Nakano-sakaue", "M06", 35.6975, 139.6827),
        ],
        hopTimesMinutes: [
            2, 2, 2,
        ],
        directions: [
            direction("MarunouchiBranch", "NakanoSakaue", "中野坂上方面", "For Nakano-sakaue", ascending: true,
                      weekday: pattern("05:00", "24:09", [
                          ("05:00", 9), ("07:00", 8), ("09:30", 9), ("20:00", 8), ("22:00", 10),
                      ]),
                      holiday: pattern("05:00", "24:09", [
                          ("05:00", 10), ("10:00", 10), ("22:00", 12),
                      ]),
                      origins: [
                          origin("Station:TokyoMetro.MarunouchiBranch.NakanoFujimicho",
                                 ["05:00", "05:12", "06:08", "06:24", "06:38", "06:51", "07:08", "07:23", "07:29", "07:38", "15:21", "15:27", "16:08", "16:18", "16:29"],
                                 ["05:00", "05:12"])
                      ]
            ),
            direction("MarunouchiBranch", "Honancho", "方南町方面", "For Honancho", ascending: false,
                      weekday: pattern("05:09", "24:26", [
                          ("05:09", 9), ("07:00", 8.5), ("09:30", 10), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:09", "24:26", [
                          ("05:09", 10), ("10:00", 10), ("22:00", 12),
                      ]),
                      origins: [
                          origin("Station:TokyoMetro.MarunouchiBranch.NakanoFujimicho",
                                 ["05:20"],
                                 ["05:42"])
                      ]
            ),
        ],
        delayInfo: delayInfo
    )

}
