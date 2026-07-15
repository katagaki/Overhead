import SwiftUI

/// Which way the LCD stop progressions travel. Headers never flip; only the
/// route strips (columns, bands, arrows) mirror.
enum TrainLCDOrientation: String, CaseIterable, Identifiable {
    case left
    case right

    static let storageKey = "journey.lcdOrientation"

    var id: String { rawValue }

    /// Shown verbatim like the LCD style labels.
    var label: String {
        switch self {
        case .left: return "左向き"
        case .right: return "右向き"
        }
    }
}
