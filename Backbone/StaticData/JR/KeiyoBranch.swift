import Foundation

extension JREastLineData {

    // MARK: - Keiyo Line Nishi-Funabashi Branch

    /// Bridge line for the 武蔵野線⇄京葉線 through service: the 西船橋–市川塩浜
    /// connecting track is on neither line's station list, so through
    /// resolution needs it as its own line (same pattern as 西武有楽町線).
    /// Windows/headways verified against the real 西船橋 東京方面 and
    /// 市川塩浜 西船橋方面 pages, July-2026 revision (~3 through trains/h).
    static let keiyoBranch = StaticTrainLine(
        id: "Railway:JR-East.KeiyoBranch",
        nameJa: "京葉線（西船橋支線）",
        nameEn: "Keiyo Line Nishi-Funabashi Branch",
        operatorId: "Operator:JR-East",
        colorHex: "#C9242F",
        stations: [
            // 西船橋 has no JE number (it is JM10/JB30), so it stays empty —
            // the line symbol falls through to 市川塩浜's JE09, badging the
            // branch as JE like the Keiyo mainline.
            st("KeiyoBranch", "NishiFunabashi", "西船橋", "Nishi-Funabashi", "", 35.7075, 139.9594),
            st("KeiyoBranch", "IchikawaShiohama", "市川塩浜", "Ichikawa-Shiohama", "JE09", 35.6569, 139.9343),
        ],
        hopTimesMinutes: [6],
        directions: [
            direction("KeiyoBranch", "IchikawaShiohama", "市川塩浜・東京方面", "For Ichikawa-Shiohama & Tokyo",
                      ascending: true,
                      weekday: pattern("05:45", "23:27", [
                          ("05:45", 25), ("07:00", 9), ("09:00", 20),
                      ]),
                      holiday: pattern("05:45", "23:28", [
                          ("05:45", 25), ("07:00", 15), ("09:00", 20),
                      ])),
            direction("KeiyoBranch", "NishiFunabashi", "西船橋方面", "For Nishi-Funabashi",
                      ascending: false,
                      weekday: pattern("06:25", "23:56", [
                          ("06:25", 20), ("17:00", 15), ("20:00", 20),
                      ]),
                      holiday: pattern("06:38", "23:56", [
                          ("06:38", 20),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("KeiyoBranch.NishiFunabashi", .descending,
                    "武蔵野線", "JR Musashino Line",
                    "南流山・府中本町方面", "for Minami-Nagareyama & Fuchu-Hommachi",
                    to: "Railway:JR-East.Musashino"),
            through("KeiyoBranch.IchikawaShiohama", .ascending,
                    "京葉線", "JR Keiyo Line",
                    "東京方面", "for Tokyo",
                    to: "Railway:JR-East.Keiyo"),
        ]
    )
}
