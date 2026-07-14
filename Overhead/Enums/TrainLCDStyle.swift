import SwiftUI

/// Which in-car LCD simulation tops the journey sheet.
enum TrainLCDStyle: String, CaseIterable, Identifiable {
    case joban
    case yamanote
    case tokyoMetro
    case ledMatrix
    case millennium

    static let storageKey = "journey.lcdStyle"

    var id: String { rawValue }

    /// Style names are Japanese aesthetic labels, shown verbatim like the
    /// LCD strings themselves.
    var label: String {
        switch self {
        case .joban: return "常磐線風"
        case .yamanote: return "山手線風"
        case .tokyoMetro: return "東京メトロ風"
        case .ledMatrix: return "3色LED風"
        case .millennium: return "ミレニアムモノレール風"
        }
    }
}
