import Foundation
import CoreLocation
import Backbone

// MARK: - Route Endpoint

/// 出発/到着: a station, or somewhere you walk to and from a station.
enum RouteEndpoint: Identifiable {
    case station(StationSearchHit)
    case currentLocation
    case place(SearchedPlace)

    var id: String {
        switch self {
        case .station(let hit): return hit.id
        case .currentLocation: return "currentLocation"
        case .place(let place): return place.id
        }
    }

    var hit: StationSearchHit? {
        if case .station(let hit) = self { return hit }
        return nil
    }

    var station: Station? { hit?.station }
}

// MARK: - Searched Place

/// A landmark or address picked from the map search.
struct SearchedPlace: Codable, Hashable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double

    var id: String { "place|\(latitude),\(longitude)|\(name)" }

    var location: CLLocation { CLLocation(latitude: latitude, longitude: longitude) }
}

// MARK: - Place Access

/// A station you can walk to from a place, and how long the walk takes.
struct PlaceAccess {
    let station: Station
    let seconds: Int

    /// Furthest a station counts as walkable from a place.
    static let radiusMeters: Double = 1500
    static let maxStations = 8

    /// Nearby stations by estimated walk, whole minutes so times line up on the clock.
    static func stations(near location: CLLocation, lines: [TrainLine], speed: WalkingSpeed) -> [PlaceAccess] {
        // Ignoring walking still has to walk somewhere; assume the usual pace.
        let pace = speed.paceMetersPerMinute ?? WalkingSpeed.normal.paceMetersPerMinute ?? 80
        let accessMinutes = speed == .none ? WalkingSpeed.normal.stationAccessMinutes : speed.stationAccessMinutes
        return NearbyStationsProvider
            .nearest(to: location, lines: lines.filter { !$0.isCustom },
                     limit: maxStations, radiusMeters: radiusMeters)
            .map { nearby in
                let minutes = nearby.distanceMeters * 1.3 / pace + accessMinutes
                return PlaceAccess(station: nearby.hit.station, seconds: Int(minutes.rounded(.up)) * 60)
            }
            .sorted { $0.seconds < $1.seconds }
    }
}
