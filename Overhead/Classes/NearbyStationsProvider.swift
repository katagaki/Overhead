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

// MARK: - Nearby Station Group

/// One physical station (deduped by name) with every line that serves it.
struct NearbyStationGroup: Identifiable {
    let name: String
    let distanceMeters: Double
    /// One hit per line serving this station name, in operator order.
    let hits: [StationSearchHit]

    var id: String { name }
    var station: Station { hits[0].station }
}

// MARK: - Nearby Stations Provider

/// One-shot location lookup that surfaces the closest stations in the
/// station picker and the home-screen 付近の駅 rail.
final class NearbyStationsProvider: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var nearestStations: [NearbyStation] = []
    @Published var nearestGroups: [NearbyStationGroup] = []
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isReducedAccuracy = false
    @Published private(set) var isLocating = false
    @Published private(set) var lastUpdated: Date?
    /// True when the last fix attempt failed and no earlier fix exists.
    @Published private(set) var fixFailed = false

    private let locationManager = CLLocationManager()
    private var lines: [TrainLine] = []
    private let maxResults = 5
    /// Groups beyond this radius are dropped; the home rail shows 圏外 instead.
    private let groupRadiusMeters: Double = 2000
    /// GPS jitter under this granularity must not reorder the rail.
    private let distanceBucketMeters: Double = 50
    private let refreshInterval: TimeInterval = 60

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        isReducedAccuracy = locationManager.accuracyAuthorization == .reducedAccuracy
    }

    /// Requests permission if needed and refreshes the nearest-station list.
    func refresh(lines: [TrainLine]) {
        self.lines = lines

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            requestFix()
        default:
            nearestStations = []
        }
    }

    /// Prompts for permission — call only from an explicit user tap, never on appear.
    func requestPermission(lines: [TrainLine]) {
        self.lines = lines
        locationManager.requestWhenInUseAuthorization()
    }

    /// Refreshes without ever prompting; throttled unless forced.
    func refreshIfNeeded(lines: [TrainLine], force: Bool = false) {
        self.lines = lines
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else { return }
        if !force, let last = lastUpdated, Date().timeIntervalSince(last) < refreshInterval { return }
        requestFix()
    }

    private func requestFix() {
        isLocating = lastUpdated == nil
        fixFailed = false
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        isReducedAccuracy = manager.accuracyAuthorization == .reducedAccuracy
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if !lines.isEmpty {
                requestFix()
            }
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        compute(around: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLocating = false
            self.fixFailed = self.lastUpdated == nil
        }
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

        let groups = groupedStations(nearest: Array(nearest))

        DispatchQueue.main.async {
            self.nearestStations = Array(nearest)
            self.nearestGroups = groups
            self.isLocating = false
            self.lastUpdated = Date()
        }
    }

    private func groupedStations(nearest: [NearbyStation]) -> [NearbyStationGroup] {
        nearest
            .filter { $0.distanceMeters <= groupRadiusMeters }
            .map { entry in
                // Every line whose stations include this name, in operator order.
                let serving = lines.compactMap { line -> StationSearchHit? in
                    guard !line.isCustom,
                          let station = line.stations.first(where: { $0.name == entry.hit.station.name })
                    else { return nil }
                    return StationSearchHit(line: line, station: station)
                }
                // Same ordering as the 路線 list: operator sections, then symbol sort.
                let byLineId = Dictionary(uniqueKeysWithValues: serving.map { ($0.line.id, $0) })
                let ordered = OperatorSections.sections(for: serving.map(\.line))
                    .flatMap(\.lines)
                    .compactMap { byLineId[$0.id] }
                return NearbyStationGroup(
                    name: entry.hit.station.name,
                    distanceMeters: entry.distanceMeters,
                    hits: ordered.isEmpty ? [entry.hit] : ordered
                )
            }
            // Bucketed sort: jitter within 50m keeps the previous order stable.
            .sorted { a, b in
                let ba = Int(a.distanceMeters / distanceBucketMeters)
                let bb = Int(b.distanceMeters / distanceBucketMeters)
                if ba != bb { return ba < bb }
                return a.name < b.name
            }
    }
}
