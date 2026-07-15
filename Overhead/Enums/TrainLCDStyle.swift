import SwiftUI

/// Which in-car LCD simulation tops the journey sheet.
enum TrainLCDStyle: String, CaseIterable, Identifiable {
    case joban
    case chuoSobu
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

    var id: String { rawValue }

    /// Japanese aesthetic label, shown verbatim.
    var label: String {
        switch self {
        case .joban: return "常磐線風"
        case .chuoSobu: return "中央総武線（旧）風"
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
        case .standard: return [.joban, .yamanote, .chuoSobu, .tokyoMetro, .hankyu, .find]
        case .strips: return [.ledMatrix, .shinkansen, .tube]
        case .fictional: return [.kivotos, .neon, .galaxy]
        }
    }
}
