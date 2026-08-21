import Foundation
import Backbone

/// Which lines a saved journey needs, and whether they are downloaded.
///
/// A favourite outlives the data it was made against: the user can remove a
/// line, or restore onto a device that has not downloaded it yet. The catalog
/// still knows every line, so a favourite can say what is missing instead of
/// quietly failing to resolve.
enum SavedPlaceLineData {

    /// Every line the journey touches: the ridden line — composites name more
    /// than one — plus whatever owns its stations.
    static func requiredLineIds(for place: SavedPlace) -> Set<String> {
        var ids = Set(place.lineId.split(separator: "+").map(String.init))
        let stationIds = [place.fromStationId, place.toStationId] + place.viaStationIds
        for stationId in stationIds where !stationId.isEmpty {
            if let owner = Catalog.current.stations.first(where: { $0.id == stationId })?.lineId {
                ids.insert(owner)
            }
        }
        return ids.filter { !$0.hasPrefix("Custom:") }
    }

    /// Lines the journey needs that are in the catalog but not on the device.
    static func missingLines(for place: SavedPlace) -> [CatalogLine] {
        requiredLineIds(for: place)
            .compactMap(Catalog.line(id:))
            .filter { !LineDataStore.isPresent(folder: $0.folder) }
            .sorted { $0.id < $1.id }
    }

    static func missingLines(for places: [SavedPlace]) -> [CatalogLine] {
        var seen = Set<String>()
        return places
            .flatMap(missingLines(for:))
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.id < $1.id }
    }

    /// True when the favourite is unresolvable only because data is missing —
    /// as opposed to naming a line that no longer exists at all.
    static func isMissingDataOnly(_ place: SavedPlace) -> Bool {
        !missingLines(for: place).isEmpty
    }
}
