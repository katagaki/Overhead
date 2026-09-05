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
    var viaStationIds: [String] = []
    var walkingSpeedRaw: String = WalkingSpeed.normal.rawValue
    var preferOriginating: Bool = false
    var avoidedLineIds: [String] = []
    var ignoreTimetable: Bool = false

    var walkingSpeed: WalkingSpeed {
        WalkingSpeed(rawValue: walkingSpeedRaw) ?? .normal
    }

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

// Custom decoding keeps favorites saved before the search settings existed.
extension SavedPlace {
    private enum CodingKeys: String, CodingKey {
        case id, kind, customName, lineId, fromStationId, toStationId
        case viaStationIds, walkingSpeedRaw, preferOriginating, avoidedLineIds, ignoreTimetable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(Kind.self, forKey: .kind)
        customName = try container.decodeIfPresent(String.self, forKey: .customName) ?? ""
        lineId = try container.decode(String.self, forKey: .lineId)
        fromStationId = try container.decode(String.self, forKey: .fromStationId)
        toStationId = try container.decode(String.self, forKey: .toStationId)
        viaStationIds = try container.decodeIfPresent([String].self, forKey: .viaStationIds) ?? []
        walkingSpeedRaw = try container.decodeIfPresent(String.self, forKey: .walkingSpeedRaw)
            ?? WalkingSpeed.normal.rawValue
        preferOriginating = try container.decodeIfPresent(Bool.self, forKey: .preferOriginating) ?? false
        avoidedLineIds = try container.decodeIfPresent([String].self, forKey: .avoidedLineIds) ?? []
        ignoreTimetable = try container.decodeIfPresent(Bool.self, forKey: .ignoreTimetable) ?? false
    }
}

// MARK: - Persistence

enum SavedPlaceStore {
    private static let storageKey = "savedPlaces"

    /// Posted after every save so open views re-read the list.
    static let didChangeNotification = Notification.Name("SavedPlaceStore.didChange")

    /// App Group suite, so the widget extension can read favorites.
    private static var defaults: UserDefaults { AppGroup.defaults }

    static func load() -> [SavedPlace] {
        migrateIfNeeded()
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SavedPlace].self, from: data) else {
            return []
        }
        return decoded
    }

    static func save(_ places: [SavedPlace]) {
        guard let data = try? JSONEncoder().encode(places) else { return }
        defaults.set(data, forKey: storageKey)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    /// Favorites predate the App Group; the old copy stays as a rollback.
    private static func migrateIfNeeded() {
        guard defaults !== UserDefaults.standard,
              defaults.data(forKey: storageKey) == nil,
              let legacy = UserDefaults.standard.data(forKey: storageKey) else { return }
        defaults.set(legacy, forKey: storageKey)
    }
}
