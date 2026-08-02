import SwiftUI

enum JourneyMode: String, CaseIterable, Identifiable {
    /// No timetable at all: routes only, position advanced by hand.
    case manual
    case hybrid
    case gps
    case timetable

    static let storageKey = "journeyMode"

    /// The persisted preference — read live so mid-journey changes apply.
    static var current: JourneyMode {
        UserDefaults.standard.string(forKey: storageKey)
            .flatMap(JourneyMode.init(rawValue:)) ?? .hybrid
    }

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .manual: return "JourneyMode.Manual"
        case .hybrid: return "JourneyMode.Hybrid"
        case .gps: return "JourneyMode.GPS"
        case .timetable: return "JourneyMode.Timetable"
        }
    }

    var iconName: String {
        switch self {
        case .manual: return "hand.tap"
        case .hybrid: return "sparkles"
        case .gps: return "location.fill"
        case .timetable: return "tablecells"
        }
    }

    var ignoresTimetable: Bool { self == .manual }
}
