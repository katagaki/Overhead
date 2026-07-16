import Foundation
import CoreLocation
import Combine
import Backbone

// MARK: - Nearby Station

struct NearbyStation: Identifiable {
    let hit: StationSearchHit
    let distanceMeters: Double

    var id: String { hit.id }

    var formattedDistance: String {
        if distanceMeters < 1000 {
            return String(format: "%.0fm", distanceMeters)
        }
        return String(format: "%.1fkm", distanceMeters / 1000)
    }
}

// MARK: - Nearby Stations Provider

/// One-shot location lookup that surfaces the closest stations in the
/// station picker. Requests when-in-use permission on first use.
final class NearbyStationsProvider: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var nearestStations: [NearbyStation] = []

    private let locationManager = CLLocationManager()
    private var lines: [TrainLine] = []
    private let maxResults = 5

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Requests permission if needed and refreshes the nearest-station list.
    func refresh(lines: [TrainLine]) {
        self.lines = lines

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            nearestStations = []
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        compute(around: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Leave the list empty — the picker simply shows no nearby section.
    }

    // MARK: - Computation

    private func compute(around location: CLLocation) {
        // Keep only the closest entry per station name.
        var bestByName: [String: NearbyStation] = [:]
        for line in lines {
            for station in line.stations {
                guard let lat = station.latitude, let lon = station.longitude else { continue }
                let distance = location.distance(from: CLLocation(latitude: lat, longitude: lon))
                if let existing = bestByName[station.name], existing.distanceMeters <= distance {
                    continue
                }
                bestByName[station.name] = NearbyStation(
                    hit: StationSearchHit(line: line, station: station),
                    distanceMeters: distance
                )
            }
        }

        let nearest = bestByName.values
            .sorted { $0.distanceMeters < $1.distanceMeters }
            .prefix(maxResults)

        DispatchQueue.main.async {
            self.nearestStations = Array(nearest)
        }
    }
}
