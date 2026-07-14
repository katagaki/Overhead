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

    /// Average pace in meters per minute. MapKit's walking ETA assumes
    /// roughly the `normal` pace.
    var paceMetersPerMinute: Double? {
        switch self {
        case .slow: return 55
        case .normal: return 80
        case .fast: return 100
        case .none: return nil
        }
    }

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
        guard let pace = paceMetersPerMinute else { return 0 }
        return 80 / pace
    }

    /// Fixed overhead from the station entrance to the platform (gates,
    /// stairs) — independent of the walk distance.
    var stationAccessMinutes: Double {
        switch self {
        case .slow: return 3
        case .normal: return 2
        case .fast: return 1.5
        case .none: return 0
        }
    }

    var iconName: String {
        switch self {
        case .slow: return "tortoise"
        case .normal: return "figure.walk"
        case .fast: return "hare"
        case .none: return "nosign"
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
