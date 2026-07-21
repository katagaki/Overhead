import SwiftUI

/// Which in-car LCD simulation tops the journey sheet.
enum TrainLCDStyle: String, CaseIterable, Identifiable {
    case joban
    case keihinTohoku
    case yamanote
    case tokyoMetro
    case ledMatrix
    case kivotos
    case shinkansen
    case hankyu
    case tube
    case find
    case neon
    case galaxy

    static let storageKey = "journey.lcdStyle"

    /// Stored preference, mapping the pre-rename "chuoSobu" value.
    init(stored: String) {
        self = TrainLCDStyle(rawValue: stored)
            ?? (stored == "chuoSobu" ? .keihinTohoku : .joban)
    }

    var id: String { rawValue }

    /// PiP frame cadence: marquee/starfield styles need video-rate frames;
    /// the blinking-marker styles need the 2 Hz blink.
    var pipFrameInterval: TimeInterval {
        switch self {
        case .ledMatrix, .shinkansen, .tube, .neon: return 1.0 / 24.0
        case .galaxy: return 1.0 / 8.0
        case .joban, .keihinTohoku, .tokyoMetro: return 0.5
        default: return 1.0
        }
    }

    /// Japanese aesthetic label, shown verbatim.
    var label: String {
        switch self {
        case .joban: return "常磐線風"
        case .keihinTohoku: return "京浜東北線風"
        case .yamanote: return "山手線風"
        case .tokyoMetro: return "東京メトロ風"
        case .ledMatrix: return "3色LED風"
        case .kivotos: return "キヴォトス広域都市鉄道風"
        case .shinkansen: return "新幹線テロップ風"
        case .hankyu: return "阪急風"
        case .tube: return "ロンドン地下鉄風"
        case .find: return "NY地下鉄FIND風"
        case .neon: return "近未来メトロ風"
        case .galaxy: return "銀河急行風"
        }
    }
}

/// Section grouping for the LCD style picker.
enum TrainLCDStyleCategory: String, CaseIterable, Identifiable {
    case standard
    case strips
    case fictional

    var id: String { rawValue }

    /// Japanese section header, shown verbatim.
    var label: String {
        switch self {
        case .standard: return "標準"
        case .strips: return "ストリップ"
        case .fictional: return "架空"
        }
    }

    var styles: [TrainLCDStyle] {
        switch self {
        case .standard: return [.joban, .yamanote, .keihinTohoku, .tokyoMetro, .hankyu, .find]
        case .strips: return [.ledMatrix, .shinkansen, .tube]
        case .fictional: return [.kivotos, .neon, .galaxy]
        }
    }
}
