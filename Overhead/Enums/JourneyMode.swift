import SwiftUI

enum JourneyMode: String, CaseIterable, Identifiable {
    case gps
    case hybrid
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
        case .gps: return "JourneyMode.GPS"
        case .hybrid: return "JourneyMode.Hybrid"
        case .timetable: return "JourneyMode.Timetable"
        }
    }
}
