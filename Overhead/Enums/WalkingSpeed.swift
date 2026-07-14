import SwiftUI
import Backbone

/// How fast the user walks — scales transfer buffers and walking ETAs.
/// `none` ignores walking entirely: no transfer buffer, no walk-to-station offset.
enum WalkingSpeed: String, CaseIterable, Identifiable {
    case slow
    case normal
    case fast
    case none

    var id: String { rawValue }

    /// Platform-walk time assumed at each transfer.
    var transferMinutes: Double {
        switch self {
        case .slow: return 8
        case .normal: return StaticTrainData.transferBufferMinutes
        case .fast: return 3
        case .none: return 0
        }
    }

    /// Scales MapKit's average-pace walking ETA.
    var paceMultiplier: Double {
        switch self {
        case .slow: return 1.3
        case .normal: return 1.0
        case .fast: return 0.8
        case .none: return 0
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .slow: return "WalkingSpeed.Slow"
        case .normal: return "WalkingSpeed.Normal"
        case .fast: return "WalkingSpeed.Fast"
        case .none: return "WalkingSpeed.None"
        }
    }
}
