import SwiftUI
import Backbone

/// How the planner trades travel time against changes of train.
enum RoutePriority: String, CaseIterable, Identifiable {
    case balanced
    case time
    case efficiency

    static let storageKey = "journey.routePriority"

    var id: String { rawValue }

    /// Minutes of travel a saved transfer is worth, on top of walk and wait.
    var transferAversionMinutes: Double {
        switch self {
        case .balanced: return StaticTrainData.defaultTransferAversionMinutes
        case .time: return 0
        case .efficiency: return 20
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .balanced: return "RoutePriority.Balanced"
        case .time: return "RoutePriority.Time"
        case .efficiency: return "RoutePriority.Efficiency"
        }
    }

    var detail: LocalizedStringKey {
        switch self {
        case .balanced: return "RoutePriority.Balanced.Detail"
        case .time: return "RoutePriority.Time.Detail"
        case .efficiency: return "RoutePriority.Efficiency.Detail"
        }
    }

    var iconName: String {
        switch self {
        case .balanced: return "scale.3d"
        case .time: return "stopwatch"
        case .efficiency: return "arrow.triangle.merge"
        }
    }
}
