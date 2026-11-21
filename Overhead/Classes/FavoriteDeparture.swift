import Foundation
import Backbone

/// Starting a favorite's ride, from its card or from the Control Center control.
@MainActor
enum FavoriteDeparture {

    /// How the saved pair is rideable: one train, 直通, or with transfers.
    enum RouteMode {
        case direct
        case through
        case transfer
    }

    typealias Resolved = (line: TrainLine, from: Station, to: Station, vias: [Station], mode: RouteMode)

    static func resolve(_ place: SavedPlace, lines: [TrainLine]) -> Resolved? {
        guard let line = lines.first(where: { $0.id == place.lineId }),
              let from = line.stations.first(where: { $0.id == place.fromStationId })
        else { return nil }

        func station(withId id: String) -> Station? {
            for line in lines {
                if let station = line.stations.first(where: { $0.id == id }) { return station }
            }
            return nil
        }

        let vias = place.viaStationIds.compactMap(station(withId:))
        guard vias.count == place.viaStationIds.count else { return nil }

        if let to = line.stations.first(where: { $0.id == place.toStationId }) {
            return (line, from, to, vias, vias.isEmpty ? .direct : .transfer)
        }

        for group in StaticTrainData.throughDestinations(fromLineId: line.id, boardingStationId: from.id) {
            if let to = group.stations.first(where: { $0.id == place.toStationId }) {
                return (line, from, to, vias, vias.isEmpty ? .through : .transfer)
            }
        }

        if let to = station(withId: place.toStationId) {
            return (line, from, to, vias, .transfer)
        }
        return nil
    }

    /// One-train favorites report no more trains today; with changes, past the last train
    /// the next day's first itinerary is started, and the untimed plan only when none is found.
    static func start(_ place: SavedPlace, resolved: Resolved, viewModel: JourneyViewModel) async {
        let waypoints = [resolved.from] + resolved.vias + [resolved.to]
        let avoided = Set(place.avoidedLineIds)
        let transferMinutes = place.walkingSpeed.transferMinutes

        func startCandidate(_ candidate: TrainCandidate?) {
            if let candidate {
                viewModel.startJourney(candidate: candidate)
            } else {
                viewModel.startFailure = .noRoute
            }
        }

        if place.ignoreTimetable || JourneyMode.current.ignoresTimetable {
            startCandidate(await viewModel.searchRouteOptions(
                stations: waypoints,
                transferMinutes: transferMinutes,
                walkPace: place.walkingSpeed.paceMultiplier,
                priority: place.routePriority,
                avoidingLineIds: avoided
            ).first)
            return
        }

        if resolved.mode != .transfer {
            await viewModel.startJourney(
                line: resolved.line,
                from: resolved.from,
                to: resolved.to
            )
            return
        }

        if let timed = await viewModel.searchTrainCandidates(
            stations: waypoints,
            anchor: .departure(RailClock.now),
            transferMinutes: transferMinutes,
            walkPace: place.walkingSpeed.paceMultiplier,
            priority: place.routePriority,
            avoidingLineIds: avoided,
            preferringOriginating: place.preferOriginating,
            rollingOverToNextDay: true
        ).first {
            startCandidate(timed)
            return
        }
        startCandidate(await viewModel.searchRouteOptions(
            stations: waypoints,
            transferMinutes: transferMinutes,
            walkPace: place.walkingSpeed.paceMultiplier,
            priority: place.routePriority,
            avoidingLineIds: avoided
        ).first)
    }

    /// Rides the place id the control widget staged, exactly once, whichever tab is in front.
    static func consumePending(viewModel: JourneyViewModel) {
        let defaults = AppGroup.defaults
        guard let idString = defaults.string(forKey: BoardSnapshotStore.pendingPlaceKey) else { return }
        defaults.removeObject(forKey: BoardSnapshotStore.pendingPlaceKey)
        guard let id = UUID(uuidString: idString) else { return }
        #if DEBUG
        NSLog("[OverheadDepart] consuming pending departure %@", idString)
        #endif
        Task {
            await viewModel.loadLines()
            guard let place = SavedPlaceStore.load().first(where: { $0.id == id }) else { return }
            guard let resolved = resolve(place, lines: viewModel.availableLines) else {
                viewModel.startFailure = .noRoute
                return
            }
            await start(place, resolved: resolved, viewModel: viewModel)
        }
    }
}
