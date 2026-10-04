import Foundation
import Combine
import MapKit

// MARK: - Place Search Model

/// Landmark and address search for the 出発/到着 picker.
@MainActor
final class PlaceSearchModel: ObservableObject {
    @Published private(set) var places: [SearchedPlace] = []

    static let maxResults = 5

    /// Biases results toward the area the dataset covers.
    private static let region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.68, longitude: 139.77),
        span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
    )

    private var task: Task<Void, Never>?
    private var lastQuery = ""

    func update(query: String) {
        guard query != lastQuery else { return }
        lastQuery = query
        task?.cancel()
        guard !query.isEmpty else {
            places = []
            return
        }
        task = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = Self.region
            request.resultTypes = [.pointOfInterest, .address]
            let response = try? await MKLocalSearch(request: request).start()
            guard !Task.isCancelled else { return }

            places = (response?.mapItems ?? []).prefix(Self.maxResults).map { item in
                let coordinate = item.location.coordinate
                return SearchedPlace(
                    name: item.name ?? query,
                    address: item.address?.shortAddress ?? item.address?.fullAddress ?? "",
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            }
        }
    }
}
