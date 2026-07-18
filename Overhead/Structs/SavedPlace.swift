import Foundation
import Backbone

// MARK: - Saved Place

/// A saved journey on the 旅程 tab: a labelled route the user rides often.
struct SavedPlace: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: Kind
    /// User-provided name; used for `.custom`, optional refinement otherwise.
    var customName: String = ""
    var lineId: String
    var fromStationId: String
    var toStationId: String

    enum Kind: String, Codable, CaseIterable {
        case home
        case work
        case school
        case custom

        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .work: return "briefcase.fill"
            case .school: return "graduationcap.fill"
            case .custom: return "mappin.circle.fill"
            }
        }

        var localizationKey: String {
            switch self {
            case .home: return "Route.Home"
            case .work: return "Route.Work"
            case .school: return "Route.School"
            case .custom: return "Place.Custom"
            }
        }
    }
}

// MARK: - Persistence

enum SavedPlaceStore {
    private static let storageKey = "savedPlaces"

    static func load() -> [SavedPlace] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SavedPlace].self, from: data) else {
            return []
        }
        return decoded
    }

    static func save(_ places: [SavedPlace]) {
        guard let data = try? JSONEncoder().encode(places) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
