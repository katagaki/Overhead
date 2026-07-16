import Foundation
import Backbone

// MARK: - Saved Place

/// A saved place on the 場所 tab: a labelled route to somewhere the user goes often.
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
    private static let legacyStorageKey = "savedQuickRoutes"

    /// The pre-場所 model: one fixed route per home/work/school slot.
    private struct LegacyQuickRoute: Codable {
        let id: UUID
        let label: String
        let lineId: String
        let fromStationId: String
        let toStationId: String
    }

    /// Line/station ids saved before the "odpt." prefix was dropped are
    /// rewritten to the current scheme (e.g. "odpt.Railway:X" → "Railway:X").
    private static func migratingIds(_ places: [SavedPlace]) -> [SavedPlace] {
        places.map { place in
            var place = place
            place.lineId = place.lineId.replacingOccurrences(of: "odpt.", with: "")
            place.fromStationId = place.fromStationId.replacingOccurrences(of: "odpt.", with: "")
            place.toStationId = place.toStationId.replacingOccurrences(of: "odpt.", with: "")
            return place
        }
    }

    static func load() -> [SavedPlace] {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SavedPlace].self, from: data) {
            let migrated = migratingIds(decoded)
            if migrated != decoded {
                save(migrated)
            }
            return migrated
        }

        // One-time migration from the old fixed-slot quick routes
        if let data = defaults.data(forKey: legacyStorageKey),
           let legacy = try? JSONDecoder().decode([LegacyQuickRoute].self, from: data) {
            let migrated = migratingIds(legacy.map { route in
                SavedPlace(
                    id: route.id,
                    kind: SavedPlace.Kind(rawValue: route.label) ?? .custom,
                    lineId: route.lineId,
                    fromStationId: route.fromStationId,
                    toStationId: route.toStationId
                )
            })
            save(migrated)
            defaults.removeObject(forKey: legacyStorageKey)
            return migrated
        }
        return []
    }

    static func save(_ places: [SavedPlace]) {
        guard let data = try? JSONEncoder().encode(places) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
