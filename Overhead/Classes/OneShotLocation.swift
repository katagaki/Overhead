import Foundation
import Combine
import CoreLocation

/// Fetches a single current-location fix on demand — used by the custom-station
/// editor's "record current location" action. Separate from LocationTracker,
/// which drives continuous journey tracking.
@MainActor
final class OneShotLocation: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isRequesting = false
    @Published var lastError: String?

    private let manager = CLLocationManager()
    private var completion: ((CLLocationCoordinate2D?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation(_ completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        self.completion = completion
        lastError = nil
        isRequesting = true

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            finish(with: nil, error: "位置情報の利用が許可されていません")
        }
    }

    private func finish(with coordinate: CLLocationCoordinate2D?, error: String?) {
        isRequesting = false
        lastError = error
        completion?(coordinate)
        completion = nil
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard isRequesting else { return }
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                finish(with: nil, error: "位置情報の利用が許可されていません")
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor in finish(with: coordinate, error: nil) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in finish(with: nil, error: error.localizedDescription) }
    }
}
