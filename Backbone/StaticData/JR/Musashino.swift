import Foundation

extension JREastLineData {

    // MARK: - Musashino Line (JM)

    static let musashino = StaticTrainLine(
        id: "Railway:JR-East.Musashino",
        nameJa: "武蔵野線",
        nameEn: "Musashino Line",
        operatorId: "Operator:JR-East",
        colorHex: "#EB6100",
        stations: [
            st("Musashino", "NishiFunabashi", "西船橋", "Nishi-Funabashi", "JM10", 35.7075, 139.9594),
            st("Musashino", "FunabashiHoten", "船橋法典", "Funabashi-Hoten", "JM11", 35.7182, 139.9448),
            st("Musashino", "IchikawaOno", "市川大野", "Ichikawa-Ono", "JM12", 35.7420, 139.9277),
            st("Musashino", "HigashiMatsudo", "東松戸", "Higashi-Matsudo", "JM13", 35.7706, 139.9438),
            st("Musashino", "ShinYahashira", "新八柱", "Shin-Yahashira", "JM14", 35.7772, 139.9368),
            st("Musashino", "ShimMatsudo", "新松戸", "Shim-Matsudo", "JM15", 35.8260, 139.9336),
            st("Musashino", "MinamiNagareyama", "南流山", "Minami-Nagareyama", "JM16", 35.8378, 139.9028),
            st("Musashino", "Misato", "三郷", "Misato", "JM17", 35.8283, 139.8790),
            st("Musashino", "ShinMisato", "新三郷", "Shin-Misato", "JM18", 35.8383, 139.8727),
            st("Musashino", "Yoshikawaminami", "吉川美南", "Yoshikawaminami", "JM19", 35.8502, 139.8558),
            st("Musashino", "Yoshikawa", "吉川", "Yoshikawa", "JM20", 35.8628, 139.8418),
            st("Musashino", "KoshigayaLaketown", "越谷レイクタウン", "Koshigaya-Laketown", "JM21", 35.8758, 139.8247),
            st("Musashino", "MinamiKoshigaya", "南越谷", "Minami-Koshigaya", "JM22", 35.8758, 139.7918),
            st("Musashino", "HigashiKawaguchi", "東川口", "Higashi-Kawaguchi", "JM23", 35.8712, 139.7478),
            st("Musashino", "HigashiUrawa", "東浦和", "Higashi-Urawa", "JM24", 35.8618, 139.7062),
            st("Musashino", "MinamiUrawa", "南浦和", "Minami-Urawa", "JM25", 35.8446, 139.6656),
            st("Musashino", "MusashiUrawa", "武蔵浦和", "Musashi-Urawa", "JM26", 35.8456, 139.6484),
            st("Musashino", "NishiUrawa", "西浦和", "Nishi-Urawa", "JM27", 35.8478, 139.6218),
            st("Musashino", "KitaAsaka", "北朝霞", "Kita-Asaka", "JM28", 35.8088, 139.5918),
            st("Musashino", "Niiza", "新座", "Niiza", "JM29", 35.7928, 139.5618),
            st("Musashino", "HigashiTokorozawa", "東所沢", "Higashi-Tokorozawa", "JM30", 35.7828, 139.5218),
            st("Musashino", "ShinAkitsu", "新秋津", "Shin-Akitsu", "JM31", 35.7722, 139.4878),
            st("Musashino", "ShinKodaira", "新小平", "Shin-Kodaira", "JM32", 35.7282, 139.4738),
            st("Musashino", "NishiKokubunji", "西国分寺", "Nishi-Kokubunji", "JM33", 35.6997, 139.4665),
            st("Musashino", "KitaFuchu", "北府中", "Kita-Fuchu", "JM34", 35.6788, 139.4738),
            st("Musashino", "FuchuHommachi", "府中本町", "Fuchu-Hommachi", "JM35", 35.6618, 139.4788),
        ],
        // Hops measured from real July-2026 train pairs (median, both directions).
        hopTimesMinutes: [
            3, 3, 2, 2, 4, 2, 2, 2, 2, 2, 2, 3, 4, 4, 3, 3, 2, 4, 3, 3, 3, 5, 3, 3, 2,
        ],
        // Real per-train timetable (708 grid) → 1:1 station timetables.
        timetableRuns: musashinoTimetable,
        directions: [
            direction("Musashino", "FuchuHommachi", "府中本町方面", "For Fuchu-Hommachi", ascending: true,
                      weekday: pattern("04:59", "24:02", [
                          ("04:59", 10), ("06:30", 5), ("09:30", 10), ("16:30", 8), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("04:59", "24:02", [
                          ("04:59", 10), ("07:00", 8), ("10:00", 10), ("20:00", 12),
                      ])),
            direction("Musashino", "NishiFunabashi", "西船橋方面", "For Nishi-Funabashi", ascending: false,
                      weekday: pattern("05:02", "24:01", [
                          ("05:02", 10), ("06:30", 6), ("09:30", 10), ("16:30", 8), ("20:00", 10), ("22:00", 12),
                      ]),
                      holiday: pattern("05:01", "24:01", [
                          ("05:01", 10), ("07:00", 8), ("10:00", 10), ("20:00", 12),
                      ])),
        ],
        delayInfo: delayInfo,
        throughServices: [
            through("Musashino.NishiFunabashi", .descending,
                    "京葉線", "JR Keiyo Line",
                    "東京方面", "for Tokyo",
                    to: "Railway:JR-East.KeiyoBranch"),
        ]
    )
}
