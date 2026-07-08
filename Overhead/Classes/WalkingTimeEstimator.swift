import Foundation
import Combine
import CoreLocation
import MapKit
import Backbone

// MARK: - Walking Time Estimator

/// One-shot estimate of the walking time from the user's current location to
/// a station, used to exclude departures the user cannot reach in time.
final class WalkingTimeEstimator: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Walking seconds to `station`, or nil when location or coordinates are
    /// unavailable. Falls back to a straight-line estimate when the MapKit
    /// ETA request fails (e.g. offline).
    func walkingSeconds(to station: Station) async -> TimeInterval? {
        guard let lat = station.latitude, let lon = station.longitude,
              let origin = await currentLocation()
        else { return nil }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
        ))
        request.transportType = .walking

        if let eta = try? await MKDirections(request: request).calculateETA() {
            return eta.expectedTravelTime
        }

        // Straight-line distance with a detour factor, at 80m/min
        let meters = origin.distance(from: CLLocation(latitude: lat, longitude: lon))
        return meters * 1.4 / (80.0 / 60.0)
    }

    private func currentLocation() async -> CLLocation? {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return nil
        default:
            break
        }
        guard continuation == nil else { return nil }

        return await withCheckedContinuation { cont in
            continuation = cont
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            } else {
                locationManager.requestLocation()
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            break
        default:
            continuation?.resume(returning: nil)
            continuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.last)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }
}
