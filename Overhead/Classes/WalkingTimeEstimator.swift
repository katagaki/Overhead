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

    /// Walking seconds to `station` at the given pace, including the fixed
    /// entrance-to-platform overhead. Nil when walking is disabled or location
    /// or coordinates are unavailable. Falls back to a straight-line estimate
    /// when the MapKit ETA request fails (e.g. offline).
    func walkingSeconds(to station: Station, speed: WalkingSpeed) async -> TimeInterval? {
        guard let pace = speed.paceMetersPerMinute,
              let lat = station.latitude, let lon = station.longitude,
              let origin = await currentLocation()
        else { return nil }

        let accessSeconds = speed.stationAccessMinutes * 60

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
        ))
        request.transportType = .walking

        if let eta = try? await MKDirections(request: request).calculateETA() {
            return eta.expectedTravelTime * speed.paceMultiplier + accessSeconds
        }

        // Straight-line distance with a detour factor, at the user's pace
        let meters = origin.distance(from: CLLocation(latitude: lat, longitude: lon))
        return meters * 1.4 / (pace / 60) + accessSeconds
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
