import Foundation
import SwiftUI
import Combine
import Backbone

// MARK: - Journey View Model (Location-Driven)

@MainActor
final class JourneyViewModel: ObservableObject {

    @Published var availableLines: [TrainLine] = []
    /// Every journey in progress, oldest first; each belongs to one tab.
    @Published private(set) var sessions: [JourneySession] = []
    /// The selected tab's journey: a new start there replaces it, and PiP follows it.
    @Published var focusedSessionID: UUID? {
        didSet { if focusedSessionID != oldValue { updatePiP() } }
    }
    @Published var isLoading = false
    @Published var isStartingJourney = false
    @Published var showOverwriteConfirmation = false
    @Published var errorMessage: String?
    @Published var stationTimetable: [StationTimetableData] = []
    @Published var isLoadingTimetable = false
    @Published var railDirections: [String: (ja: String, en: String)] = [:]
    @Published var plannerFromRequest: StationSearchHit?
    @Published var plannerToRequest: StationSearchHit?

    private var cancellables = Set<AnyCancellable>()
    private var pipStatusObservation: AnyCancellable?
    private var timetableCache: [String: [TrainService]] = [:]
    private var linesLoaded = false

    private var pendingStart: (() -> Void)?

    init(previewMode: Bool = false) {
        bindLineData()
        // Journeys do not outlive the app, so neither do their alerts.
        JourneyNotificationManager.shared.cancelAll()
        if previewMode {
            loadPreviewData()
        }
    }

    /// Line data arrives after launch on a fresh install, and again whenever an
    /// update patches a line. Debounced: a download absorbs a batch at a time.
    private func bindLineData() {
        NotificationCenter.default.publisher(for: StaticTrainData.didChangeNotification)
            .debounce(for: .seconds(0.75), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in await self?.forceRefreshLines() }
            }
            .store(in: &cancellables)
    }

    // MARK: - Sessions

    var focusedSession: JourneySession? {
        focusedSessionID.flatMap(session(id:))
    }

    func session(id: UUID) -> JourneySession? {
        sessions.first { $0.id == id }
    }

    /// Adds a journey; one started where another was focused takes its place.
    private func begin(_ session: JourneySession) {
        if let replaced = focusedSession { stopJourney(replaced) }
        sessions.append(session)
        errorMessage = nil
        updatePiP()
    }

    func stopJourney(_ session: JourneySession) {
        session.stop()
        sessions.removeAll { $0.id == session.id }
        updatePiP()
    }

    // MARK: - Picture in Picture

    /// One PiP window: the focused journey's, or the newest one's.
    var pipSession: JourneySession? {
        focusedSession ?? sessions.last
    }

    private func updatePiP() {
        guard let session = pipSession else {
            pipStatusObservation = nil
            LCDPiPManager.shared.teardown()
            return
        }
        LCDPiPManager.shared.prepare { [weak self] in
            self?.pipSession?.renderLCDImage(scale: 2, padded: false)
        }
        pipStatusObservation = session.$positionState
            .map { $0?.status }
            .removeDuplicates()
            .sink { status in
                LCDPiPManager.shared.setAutoStartAllowed(status != .arrived)
            }
    }

    // MARK: - Load Lines

    func loadLines() async {
        guard !linesLoaded else { return }

        availableLines = StaticTrainData.trainLines()
        linesLoaded = true
        errorMessage = nil
        loadRailDirections()
    }

    func forceRefreshLines() async {
        linesLoaded = false
        await loadLines()
    }

    // MARK: - Start Journey

    func startJourney(
        line: TrainLine,
        from boardingStation: Station,
        to alightingStation: Station
    ) async {
        if focusedSession != nil {
            pendingStart = { [weak self] in
                Task { await self?.performStartJourney(line: line, from: boardingStation, to: alightingStation) }
            }
            showOverwriteConfirmation = true
            return
        }
        await performStartJourney(line: line, from: boardingStation, to: alightingStation)
    }

    private func performStartJourney(
        line: TrainLine,
        from boardingStation: Station,
        to alightingStation: Station
    ) async {
        isStartingJourney = true

        guard let resolved = StaticTrainData.resolveJourneyLine(
            lineId: line.id,
            fromStationId: boardingStation.id,
            toStationId: alightingStation.id
        ) else {
            errorMessage = "No timetable data available"
            isStartingJourney = false
            return
        }

        let journeyStaticLine = resolved.staticLine
        let journeyLine = journeyStaticLine.trainLine

        if timetableCache[journeyStaticLine.id] == nil {
            timetableCache[journeyStaticLine.id] = StaticTimetableGenerator.services(
                for: journeyStaticLine, calendar: .current()
            )
        }

        guard let services = timetableCache[journeyStaticLine.id] else {
            errorMessage = "No timetable data available"
            isStartingJourney = false
            return
        }

        let service = findBestService(
            services: services,
            from: boardingStation.id,
            to: alightingStation.id,
            at: Date()
        )

        guard let service else {
            errorMessage = "No matching train found for this time"
            isStartingJourney = false
            return
        }

        let journey = Journey(
            id: UUID(),
            service: service,
            line: journeyLine,
            boardingStationId: boardingStation.id,
            alightingStationId: alightingStation.id,
            startedAt: Date()
        )

        begin(JourneySession(journey: journey, line: journeyLine))
        isStartingJourney = false
    }

    // MARK: - Departure Search (乗換案内-style)

    /// Which end of the itinerary the user pinned to a clock time.
    enum TimeAnchor {
        case departure(Date)
        case arrival(Date)

        var date: Date {
            switch self {
            case .departure(let date), .arrival(let date): return date
            }
        }

        var isArrival: Bool {
            if case .arrival = self { return true }
            return false
        }
    }

    /// A ride constraint in rail seconds, in whichever direction the search runs.
    fileprivate enum RideAnchor {
        case departAtOrAfter(Int)
        case arriveAtOrBefore(Int)

        var isArrival: Bool {
            if case .arriveAtOrBefore = self { return true }
            return false
        }
    }

    /// Where a wall-clock date falls relative to another date's service day.
    private enum ServiceDayPosition {
        case earlier
        case same(Int)
        case later
    }

    func searchTrainCandidates(
        stations: [Station],
        anchor: TimeAnchor,
        transferMinutes: Double = StaticTrainData.transferBufferMinutes,
        walkPace: Double = 1,
        priority: RoutePriority = .balanced,
        avoidingLineIds: Set<String> = [],
        notDepartingBefore earliest: Date? = nil,
        preferringOriginating: Bool = false,
        limit: Int = 12
    ) async -> [TrainCandidate] {
        guard stations.count >= 2 else { return [] }

        let calendar = ScheduleCalendar.current(at: anchor.date)
        let targetSec = railSeconds(of: anchor.date)
        let rideAnchor: RideAnchor = anchor.isArrival
            ? .arriveAtOrBefore(targetSec)
            : .departAtOrAfter(targetSec)

        // Trains that have already left — or that you couldn't walk to in time.
        var floorSec: Int?
        if let earliest {
            switch position(of: earliest, onServiceDayOf: anchor.date) {
            case .same(let sec): floorSec = sec
            case .earlier: break
            case .later: return []
            }
        }

        // Every single-train ride, so slower trains and 始発 stay on the list.
        var direct: [TrainCandidate] = []
        if stations.count == 2 {
            direct = directCandidates(
                from: stations[0], to: stations[1],
                anchor: rideAnchor, floorSec: floorSec, calendar: calendar,
                avoidingLineIds: avoidingLineIds,
                preferringOriginating: preferringOriginating, limit: limit
            )
        }

        let ids = stations.map(\.id)
        let routerAnchor: TransitRouter.Anchor = anchor.isArrival
            ? .arriveAtOrBefore(targetSec)
            : .departAtOrAfter(targetSec)
        let preferences = TransitRouter.Preferences(
            transferMinutes: transferMinutes,
            walkPace: walkPace,
            transferAversionMinutes: priority.transferAversionMinutes,
            avoidingLineIds: avoidingLineIds
        )
        let date = anchor.date
        let itineraries = await Task.detached(priority: .userInitiated) {
            TransitRouter.search(through: ids, anchor: routerAnchor, on: date,
                                 preferences: preferences, notDepartingBefore: floorSec, limit: limit)
        }.value
        let routed = itineraries.compactMap { candidate(for: $0, calendar: calendar) }

        // Drop changes that don't earn their keep against a simpler option
        // leaving no earlier and arriving no later, give or take the aversion.
        let aversion = Int(priority.transferAversionMinutes * 60)
        var merged: [TrainCandidate] = []
        var seen = Set<String>()
        for candidate in direct + routed {
            // One train leaving one platform at one minute is the same ride,
            // even when a 直通 composite times its arrival a minute apart.
            let key = candidate.transferCount == 0
                ? "\(candidate.departureSeconds)|\(candidate.legs[0].line.id)|\(candidate.fromStation.id)"
                : "\(candidate.departureSeconds)|\(candidate.arrivalSeconds)|\(candidate.transferCount)"
            if seen.insert(key).inserted { merged.append(candidate) }
        }
        let kept = merged.filter { candidate in
            !merged.contains { other in
                guard other.transferCount < candidate.transferCount else { return false }
                let slack = aversion * (candidate.transferCount - other.transferCount)
                return anchor.isArrival
                    ? other.arrivalSeconds <= candidate.arrivalSeconds
                        && other.departureSeconds + slack >= candidate.departureSeconds
                    : other.departureSeconds >= candidate.departureSeconds
                        && other.arrivalSeconds <= candidate.arrivalSeconds + slack
            }
        }

        let mixesRoutes = kept.contains { $0.transferCount > 0 }
        return Array(sorted(kept, anchor: rideAnchor,
                            preferringOriginating: preferringOriginating,
                            soonestArrival: mixesRoutes).prefix(limit))
    }

    /// Seconds since the service day's midnight; hours past 24 for post-midnight trains.
    private func railSeconds(of date: Date) -> Int {
        var jstCal = Calendar(identifier: .gregorian)
        jstCal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let comps = jstCal.dateComponents([.hour, .minute], from: date)
        let sec = (comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60
        return sec < 4 * 3600 ? sec + 24 * 3600 : sec
    }

    private func position(of date: Date, onServiceDayOf reference: Date) -> ServiceDayPosition {
        var jstCal = Calendar(identifier: .gregorian)
        jstCal.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        // The service day rolls over at 04:00, so early hours belong to the day before.
        func serviceDay(_ date: Date) -> Date {
            let day = jstCal.startOfDay(for: date)
            guard railSeconds(of: date) >= 24 * 3600 else { return day }
            return jstCal.date(byAdding: .day, value: -1, to: day) ?? day
        }

        let day = serviceDay(date)
        let referenceDay = serviceDay(reference)
        if day == referenceDay { return .same(railSeconds(of: date)) }
        return day < referenceDay ? .earlier : .later
    }

    func routeExists(through stations: [Station], avoidingLineIds: Set<String> = []) -> Bool {
        Self.routeExists(through: stations, avoidingLineIds: avoidingLineIds)
    }

    /// True when every hop is rideable: one train, 直通, or via transfers.
    nonisolated static func routeExists(through stations: [Station], avoidingLineIds: Set<String> = []) -> Bool {
        guard stations.count >= 2 else { return false }
        let links = StaticTrainData.stationLinks()
        return zip(stations, stations.dropFirst()).allSatisfy { from, to in
            !links.isSameStation(from.id, to.id)
                && (!StaticTrainData.directRoutes(fromStationId: from.id, toStationId: to.id,
                                                  avoidingLineIds: avoidingLineIds).isEmpty
                    || StaticTrainData.planTransferRoute(fromStationId: from.id, toStationId: to.id,
                                                         avoidingLineIds: avoidingLineIds) != nil)
        }
    }

    private func directCandidates(
        from origin: Station,
        to destination: Station,
        anchor: RideAnchor,
        floorSec: Int?,
        calendar: ScheduleCalendar,
        avoidingLineIds: Set<String>,
        preferringOriginating: Bool,
        limit: Int
    ) -> [TrainCandidate] {
        let routes = StaticTrainData.directRoutes(
            fromStationId: origin.id,
            toStationId: destination.id,
            avoidingLineIds: avoidingLineIds
        )

        var candidates: [TrainCandidate] = []
        for route in routes {
            for ride in rides(on: route.staticLine,
                              fromId: route.fromStation.id, toId: route.toStation.id,
                              anchor: anchor, notDepartingBefore: floorSec, calendar: calendar,
                              limit: limit) {
                let line = route.staticLine.trainLine
                let leg = CandidateLeg(
                    service: ride.service,
                    line: route.boardingLine.trainLine,
                    fromStation: route.fromStation,
                    toStation: route.toStation,
                    departureSeconds: ride.departure,
                    arrivalSeconds: ride.arrival
                )
                candidates.append(TrainCandidate(
                    id: "\(ride.service.id)|\(route.id)",
                    legs: [leg],
                    isThrough: route.isThrough,
                    journeyLine: line,
                    journeyService: ride.service,
                    fromStation: route.fromStation,
                    toStation: route.toStation
                ))
            }
        }

        return Array(sorted(candidates, anchor: anchor,
                            preferringOriginating: preferringOriginating).prefix(limit))
    }

    /// 到着時刻 searches lead with the latest itinerary that still makes it.
    /// 始発優先 outranks the clock: a seat is worth waiting for.
    private func sorted(
        _ candidates: [TrainCandidate],
        anchor: RideAnchor,
        preferringOriginating: Bool = false,
        soonestArrival: Bool = false
    ) -> [TrainCandidate] {
        let byTime: (TrainCandidate, TrainCandidate) -> Bool
        switch anchor {
        case .departAtOrAfter where soonestArrival:
            byTime = {
                $0.arrivalSeconds == $1.arrivalSeconds
                    ? $0.departureSeconds > $1.departureSeconds
                    : $0.arrivalSeconds < $1.arrivalSeconds
            }
        case .departAtOrAfter:
            byTime = { $0.departureSeconds < $1.departureSeconds }
        case .arriveAtOrBefore:
            byTime = {
                $0.arrivalSeconds == $1.arrivalSeconds
                    ? $0.departureSeconds > $1.departureSeconds
                    : $0.arrivalSeconds > $1.arrivalSeconds
            }
        }
        guard preferringOriginating else { return candidates.sorted(by: byTime) }
        return candidates.sorted {
            $0.startsAtBoarding == $1.startsAtBoarding
                ? byTime($0, $1)
                : $0.startsAtBoarding
        }
    }

    // MARK: - Timetable-less Route Search (時刻表無視)

    func searchRouteOptions(
        stations: [Station],
        transferMinutes: Double,
        walkPace: Double = 1,
        priority: RoutePriority = .balanced,
        avoidingLineIds: Set<String> = []
    ) async -> [TrainCandidate] {
        guard stations.count >= 2, let from = stations.first, let to = stations.last else { return [] }
        // Expresses come from today's timetable, built off the main thread.
        let expressHops = await Task.detached(priority: .userInitiated) {
            TransitRouter.expressHops(on: Date())
        }.value

        var results: [TrainCandidate] = []
        var seen = Set<String>()
        func add(_ candidate: TrainCandidate?) {
            guard let candidate else { return }
            let key = candidate.legs
                .map { "\($0.line.id)|\($0.fromStation.id)|\($0.toStation.id)" }
                .joined(separator: "+")
            if seen.insert(key).inserted { results.append(candidate) }
        }

        if stations.count == 2 {
            for route in StaticTrainData.directRoutes(
                fromStationId: from.id, toStationId: to.id,
                avoidingLineIds: avoidingLineIds
            ) {
                add(untimedCandidate(for: route, expressHops: expressHops))
            }
        }

        // Re-plan with each found plan's lines excluded to surface variety.
        var avoid = avoidingLineIds
        for _ in 0..<3 {
            guard let plan = StaticTrainData.planTransferRoute(
                throughStationIds: stations.map(\.id),
                transferMinutes: transferMinutes,
                walkPace: walkPace,
                transferAversionMinutes: priority.transferAversionMinutes,
                avoidingLineIds: avoid,
                expressHops: expressHops
            ) else { break }
            add(untimedCandidate(forPlan: plan, transferMinutes: transferMinutes))
            // A 直通 leg's composite ID joins its lines with "+".
            let planLines = Set(plan.flatMap { $0.staticLine.id.split(separator: "+").map(String.init) })
            if planLines.isSubset(of: avoid) { break }
            avoid.formUnion(planLines)
        }

        guard priority == .efficiency else {
            return results.sorted { $0.durationMinutes < $1.durationMinutes }
        }
        return results.sorted {
            $0.legs.count == $1.legs.count
                ? $0.durationMinutes < $1.durationMinutes
                : $0.legs.count < $1.legs.count
        }
    }

    private func untimedRide(
        on staticLine: StaticTrainLine,
        from: Station,
        to: Station
    ) -> (service: TrainService, stations: [Station], minutes: Int)? {
        guard let ride = StaticTrainData.estimatedRide(
            on: staticLine, fromStationId: from.id, toStationId: to.id
        ) else { return nil }

        let entries = ride.stations.enumerated().map { i, station in
            TimetableEntry(
                id: "untimed_\(staticLine.id)_\(i)",
                stationId: station.id,
                arrivalTime: nil,
                departureTime: nil
            )
        }
        let service = TrainService(
            id: "untimed.\(staticLine.id).\(from.id).\(to.id)",
            lineId: staticLine.id,
            trainType: .local,
            direction: .outbound,
            timetable: entries,
            destinationStationId: to.id
        )
        return (service, ride.stations, Int(ride.minutes.rounded(.up)))
    }

    private func untimedCandidate(
        for route: StaticTrainData.DirectRouteOption,
        expressHops: TransitRouter.ExpressHops
    ) -> TrainCandidate? {
        guard let ride = untimedRide(
            on: route.staticLine, from: route.fromStation, to: route.toStation
        ) else { return nil }
        // Timed on the route's own lines alone, so its expresses count.
        let ownLines = Set(route.staticLine.id.split(separator: "+").map(String.init))
        let planned = StaticTrainData.planTransferRoute(
            fromStationId: route.fromStation.id,
            toStationId: route.toStation.id,
            maxTransfers: 0,
            avoidingLineIds: Set(availableLines.map(\.id)).subtracting(ownLines),
            expressHops: expressHops
        )
        let minutes = planned?.count == 1
            ? planned?[0].minutes.map { Int($0.rounded(.up)) } ?? ride.minutes
            : ride.minutes
        let leg = CandidateLeg(
            service: ride.service,
            line: route.boardingLine.trainLine,
            fromStation: route.fromStation,
            toStation: route.toStation,
            departureSeconds: 0,
            arrivalSeconds: minutes * 60
        )
        return TrainCandidate(
            id: "untimed|\(route.id)",
            legs: [leg],
            isThrough: route.isThrough,
            journeyLine: route.staticLine.trainLine,
            journeyService: ride.service,
            fromStation: route.fromStation,
            toStation: route.toStation,
            hasSchedule: false
        )
    }

    private func untimedCandidate(
        forPlan plan: [StaticTrainData.TransferLeg],
        transferMinutes: Double
    ) -> TrainCandidate? {
        guard let firstLeg = plan.first, let lastLeg = plan.last else { return nil }

        // Planned minutes know about expresses; hop sums assume every stop.
        func minutes(_ planLeg: StaticTrainData.TransferLeg, _ fallback: Int) -> Int {
            planLeg.minutes.map { Int($0.rounded(.up)) } ?? fallback
        }

        if plan.count == 1 {
            guard let ride = untimedRide(
                on: firstLeg.staticLine, from: firstLeg.fromStation, to: firstLeg.toStation
            ) else { return nil }
            let leg = CandidateLeg(
                service: ride.service,
                line: firstLeg.boardingLine.trainLine,
                fromStation: firstLeg.fromStation,
                toStation: firstLeg.toStation,
                departureSeconds: 0,
                arrivalSeconds: minutes(firstLeg, ride.minutes) * 60
            )
            return TrainCandidate(
                id: "untimed|\(firstLeg.staticLine.id)|\(firstLeg.fromStation.id)|\(firstLeg.toStation.id)",
                legs: [leg],
                isThrough: firstLeg.isThrough,
                journeyLine: firstLeg.staticLine.trainLine,
                journeyService: ride.service,
                fromStation: firstLeg.fromStation,
                toStation: firstLeg.toStation,
                hasSchedule: false
            )
        }

        var legs: [CandidateLeg] = []
        var stations: [Station] = []
        var cursor = 0
        for (index, planLeg) in plan.enumerated() {
            guard let ride = untimedRide(
                on: planLeg.staticLine, from: planLeg.fromStation, to: planLeg.toStation
            ) else { return nil }
            let rideMinutes = minutes(planLeg, ride.minutes)
            legs.append(CandidateLeg(
                service: ride.service,
                line: planLeg.boardingLine.trainLine,
                fromStation: planLeg.fromStation,
                toStation: planLeg.toStation,
                departureSeconds: cursor,
                arrivalSeconds: cursor + rideMinutes * 60
            ))
            cursor += rideMinutes * 60 + Int(transferMinutes * 60)
            // The transfer station keeps the arriving leg's station ID.
            stations.append(contentsOf: index == 0 ? ride.stations : Array(ride.stations.dropFirst()))
        }

        let compositeId = plan.map(\.boardingLine.id).joined(separator: "+")
        let entries = stations.enumerated().map { i, station in
            TimetableEntry(
                id: "untimed_\(compositeId)_\(i)",
                stationId: station.id,
                arrivalTime: nil,
                departureTime: nil
            )
        }
        guard let destination = stations.last else { return nil }

        let first = legs[0]
        let journeyLine = TrainLine(
            id: compositeId,
            name: plan.map(\.boardingLine.trainLine.name).joined(separator: "〜"),
            nameEn: plan.map(\.boardingLine.trainLine.nameEn).joined(separator: " – "),
            operatorId: first.line.operatorId,
            stations: stations,
            colorHex: first.line.colorHex
        )
        let journeyService = TrainService(
            id: "untimed.composite.\(compositeId)",
            lineId: compositeId,
            trainType: .local,
            direction: .outbound,
            timetable: entries,
            destinationStationId: destination.id
        )
        return TrainCandidate(
            id: "untimed|\(compositeId)|\(first.fromStation.id)|\(lastLeg.toStation.id)",
            legs: legs,
            isThrough: false,
            journeyLine: journeyLine,
            journeyService: journeyService,
            fromStation: first.fromStation,
            toStation: lastLeg.toStation,
            hasSchedule: false
        )
    }

    // MARK: - Routed Itineraries

    /// A router itinerary as a candidate, with each leg's real service behind it.
    private func candidate(for itinerary: TransitRouter.Itinerary, calendar: ScheduleCalendar) -> TrainCandidate? {
        var legs: [CandidateLeg] = []
        var through: StaticTrainData.ResolvedJourneyLine?
        for routed in itinerary.legs {
            guard let first = routed.rides.first,
                  let boardingLine = StaticTrainData.line(withId: first.lineId),
                  let fromStation = boardingLine.stations.first(where: { $0.id == routed.fromStationId })
            else { return nil }

            var runs: [TrainService] = []
            for ride in routed.rides {
                guard let line = StaticTrainData.line(withId: ride.lineId),
                      let run = services(on: line, calendar: calendar).first(where: { $0.id == ride.serviceId })
                else { return nil }
                runs.append(run)
            }

            let service: TrainService
            let toStation: Station
            if routed.rides.allSatisfy({ $0.lineId == first.lineId }) {
                guard let station = boardingLine.stations.first(where: { $0.id == routed.toStationId })
                else { return nil }
                toStation = station
                service = runs.count == 1
                    ? runs[0]
                    : Self.joinedService(runs, lineId: boardingLine.id, direction: runs[0].direction)
            } else {
                // 直通: the journey runs on the composite line the rides make up.
                guard let resolved = StaticTrainData.resolveJourneyLine(
                          lineId: first.lineId, fromStationId: routed.fromStationId, toStationId: routed.toStationId),
                      resolved.isThrough,
                      let station = resolved.staticLine.stations.first(where: { $0.id == routed.toStationId })
                else { return nil }
                toStation = station
                service = Self.joinedService(runs, lineId: resolved.staticLine.id, direction: .outbound)
                if itinerary.legs.count == 1 { through = resolved }
            }

            legs.append(CandidateLeg(
                service: service,
                line: boardingLine.trainLine,
                fromStation: fromStation,
                toStation: toStation,
                departureSeconds: routed.departure,
                arrivalSeconds: routed.arrival
            ))
        }

        guard let only = legs.first, legs.count == 1 else { return compositeCandidate(legs: legs) }
        let journeyLine = through?.staticLine.trainLine ?? only.line
        return TrainCandidate(
            id: "\(only.service.id)|\(journeyLine.id)|\(only.fromStation.id)|\(only.toStation.id)",
            legs: legs,
            isThrough: through != nil,
            journeyLine: journeyLine,
            journeyService: only.service,
            fromStation: only.fromStation,
            toStation: only.toStation
        )
    }

    /// One train across consecutive runs: a loop's next circuit, or the
    /// partner line's run it carries on as. The joining stop keeps the
    /// first run's station ID, as composite lines do.
    private static func joinedService(_ services: [TrainService], lineId: String,
                                      direction: TrainService.Direction) -> TrainService {
        var entries: [TimetableEntry] = []
        for service in services {
            var timetable = service.timetable[...]
            if let last = entries.last, let joining = timetable.first {
                entries[entries.count - 1] = TimetableEntry(
                    id: last.id,
                    stationId: last.stationId,
                    arrivalTime: last.arrivalTime ?? last.departureTime,
                    departureTime: joining.departureTime ?? joining.arrivalTime
                )
                timetable = timetable.dropFirst()
            }
            entries.append(contentsOf: timetable)
        }
        let first = services[0], last = services[services.count - 1]
        return TrainService(
            id: services.map(\.id).joined(separator: "+"),
            lineId: lineId,
            trainType: first.trainType,
            direction: direction,
            timetable: entries,
            destinationStationId: entries.last?.stationId ?? last.destinationStationId,
            originatesAtStart: first.originatesAtStart,
            throughDestination: last.throughDestination
        )
    }

    private func services(on staticLine: StaticTrainLine, calendar: ScheduleCalendar) -> [TrainService] {
        let cacheKey = "\(staticLine.id)|\(calendar.rawValue)"
        if let cached = timetableCache[cacheKey] { return cached }
        let built = StaticTimetableGenerator.services(for: staticLine, calendar: calendar)
        timetableCache[cacheKey] = built
        return built
    }

    /// Concrete services on a line between two of its stations.
    private func rides(
        on staticLine: StaticTrainLine,
        fromId: String,
        toId: String,
        anchor: RideAnchor,
        notDepartingBefore floorSec: Int? = nil,
        calendar: ScheduleCalendar,
        limit: Int
    ) -> [(service: TrainService, departure: Int, arrival: Int)] {
        var result: [(TrainService, Int, Int)] = []
        for service in services(on: staticLine, calendar: calendar) {
            let stationIds = service.timetable.map(\.stationId)
            guard let fromIdx = stationIds.firstIndex(of: fromId),
                  let toIdx = stationIds.firstIndex(of: toId),
                  fromIdx < toIdx,
                  let depSec = service.timetable[fromIdx].departureSeconds()
                      ?? service.timetable[fromIdx].arrivalSeconds(),
                  let arrSec = service.timetable[toIdx].arrivalSeconds()
                      ?? service.timetable[toIdx].departureSeconds()
            else { continue }
            switch anchor {
            case .departAtOrAfter(let targetSec):
                guard depSec >= targetSec else { continue }
            case .arriveAtOrBefore(let targetSec):
                guard arrSec <= targetSec else { continue }
            }
            if let floorSec, depSec < floorSec { continue }
            result.append((service, depSec, arrSec))
        }
        // Nearest to the anchor first, so the limit keeps the relevant rides.
        return anchor.isArrival
            ? Array(result.sorted { $0.2 > $1.2 }.prefix(limit))
            : Array(result.sorted { $0.1 < $1.1 }.prefix(limit))
    }

    /// A loop leg's stations in the direction its train actually runs.
    private static func loopSlice(on line: StaticTrainLine, leg: CandidateLeg) -> [Station]? {
        let stations = line.stations, count = stations.count
        let timetable = leg.service.timetable
        guard line.isLoop,
              let fromIdx = stations.firstIndex(where: { $0.id == leg.fromStation.id }),
              let toIdx = stations.firstIndex(where: { $0.id == leg.toStation.id }),
              fromIdx != toIdx,
              let entry = timetable.firstIndex(where: { $0.stationId == leg.fromStation.id }),
              entry + 1 < timetable.count,
              let nextIdx = stations.firstIndex(where: { $0.id == timetable[entry + 1].stationId })
        else { return nil }
        let step = (nextIdx - fromIdx + count) % count <= count / 2 ? 1 : -1
        var path = [stations[fromIdx]]
        var idx = fromIdx
        while idx != toIdx {
            idx = ((idx + step) % count + count) % count
            path.append(stations[idx])
        }
        return path
    }

    private func compositeCandidate(legs: [CandidateLeg]) -> TrainCandidate? {
        guard let first = legs.first, let last = legs.last else { return nil }

        var stations: [Station] = []
        var entries: [TimetableEntry] = []
        let compositeId = legs.map(\.line.id).joined(separator: "+")

        for (legIndex, leg) in legs.enumerated() {
            // estimatedRide takes a loop's short way round; index order alone
            // would send a 有楽町→東京 leg the wrong way about the 山手線.
            // A train staying aboard past a loop's seam may take the long way.
            let staticLine = StaticTrainData.line(withId: leg.line.id)
            let slice: [Station]
            if let staticLine, let path = Self.loopSlice(on: staticLine, leg: leg) {
                slice = path
            } else if let staticLine,
               let ride = StaticTrainData.estimatedRide(
                   on: staticLine, fromStationId: leg.fromStation.id, toStationId: leg.toStation.id
               ) {
                slice = ride.stations
            } else if let fromIdx = leg.line.stations.firstIndex(where: { $0.id == leg.fromStation.id }),
                      let toIdx = leg.line.stations.firstIndex(where: { $0.id == leg.toStation.id }) {
                slice = fromIdx <= toIdx
                    ? Array(leg.line.stations[fromIdx...toIdx])
                    : Array(leg.line.stations[toIdx...fromIdx].reversed())
            } else if let composite = StaticTrainData.resolveJourneyLine(
                          lineId: leg.line.id, fromStationId: leg.fromStation.id, toStationId: leg.toStation.id
                      )?.staticLine,
                      let fromIdx = composite.stations.firstIndex(where: { $0.id == leg.fromStation.id }),
                      let toIdx = composite.stations.firstIndex(where: { $0.id == leg.toStation.id }),
                      fromIdx < toIdx {
                // A 直通 leg boards one line and leaves another.
                slice = Array(composite.stations[fromIdx...toIdx])
            } else {
                return nil
            }

            let entryByStationId = Dictionary(
                leg.service.timetable.map { ($0.stationId, $0) },
                uniquingKeysWith: { first, _ in first }
            )

            for (i, station) in slice.enumerated() {
                let isTransferIn = legIndex > 0 && i == 0
                if isTransferIn {
                    guard let prev = entries.popLast() else { return nil }
                    // Falls back to the merged entry a replan's head legs carry:
                    // their shared timetable keys the boundary by the arriving ID.
                    let depTime = entryByStationId[station.id]?.departureTime
                        ?? entryByStationId[station.id]?.arrivalTime
                        ?? prev.departureTime
                    entries.append(TimetableEntry(
                        id: prev.id,
                        stationId: prev.stationId,
                        arrivalTime: prev.arrivalTime ?? prev.departureTime,
                        departureTime: depTime
                    ))
                    continue
                }
                stations.append(station)
                // An express contributes no entry at the stops it skips.
                guard let entry = entryByStationId[station.id] else { continue }
                entries.append(TimetableEntry(
                    id: "composite_\(compositeId)_\(entries.count)",
                    stationId: station.id,
                    arrivalTime: entry.arrivalTime,
                    departureTime: entry.departureTime
                ))
            }
        }

        guard stations.count >= 2, let destination = stations.last else { return nil }

        let nameJa = legs.map(\.line.name).joined(separator: "〜")
        let nameEn = legs.map(\.line.nameEn).joined(separator: " – ")
        let journeyLine = TrainLine(
            id: compositeId,
            name: nameJa,
            nameEn: nameEn,
            operatorId: first.line.operatorId,
            stations: stations,
            colorHex: first.line.colorHex
        )
        let journeyService = TrainService(
            id: "composite.\(compositeId).\(first.departureTime)",
            lineId: compositeId,
            trainType: first.service.trainType,
            direction: .outbound,
            timetable: entries,
            destinationStationId: destination.id
        )

        return TrainCandidate(
            id: journeyService.id + "|" + legs.map { $0.service.id }.joined(separator: "|"),
            legs: legs,
            isThrough: false,
            journeyLine: journeyLine,
            journeyService: journeyService,
            fromStation: first.fromStation,
            toStation: last.toStation
        )
    }

    /// Starts a journey on a specific itinerary chosen from the departure search.
    func startJourney(candidate: TrainCandidate) {
        if focusedSession != nil {
            pendingStart = { [weak self] in self?.begin(JourneySession(candidate: candidate)) }
            showOverwriteConfirmation = true
            return
        }
        begin(JourneySession(candidate: candidate))
    }

    // MARK: - Mid-Journey Replanning

    /// A stop the replan can start from, with its delay-adjusted time.
    struct ReplanAnchor: Identifiable, Equatable {
        let stationIndex: Int
        let station: Station
        let time: Date
        /// Already behind the train; the rider is doubling back or off-schedule.
        var isPast: Bool = false

        var id: Int { stationIndex }
    }

    /// Less slack than a planned transfer — no concourse walk.
    static let sameStationBufferMinutes: Double = 1

    /// Alternative itineraries from `anchor` onward, soonest first.
    func replanCandidates(
        from anchor: ReplanAnchor,
        to destination: Station,
        transferMinutes: Double = StaticTrainData.transferBufferMinutes,
        walkPace: Double = 1,
        priority: RoutePriority = .balanced,
        avoidingLineIds: Set<String> = [],
        limit: Int = 8
    ) async -> [TrainCandidate] {
        guard !StaticTrainData.stationLinks().isSameStation(anchor.station.id, destination.id) else { return [] }
        // Past stops have a departure time behind us; search from now.
        let from = max(anchor.time, Date())
        return await searchTrainCandidates(
            stations: [anchor.station, destination],
            anchor: .departure(from.addingTimeInterval(Self.sameStationBufferMinutes * 60)),
            transferMinutes: transferMinutes,
            walkPace: walkPace,
            priority: priority,
            avoidingLineIds: avoidingLineIds,
            limit: limit
        )
    }

    /// Swaps the rest of the session's itinerary for `onward`, boarded at `anchor`.
    func replan(_ session: JourneySession, from anchor: ReplanAnchor, to onward: TrainCandidate) {
        session.install(candidate: stitched(session, from: anchor, to: onward) ?? onward)
    }

    /// `onward` with the ride in progress prepended; nil if they can't join.
    func stitched(_ session: JourneySession, from anchor: ReplanAnchor, to onward: TrainCandidate) -> TrainCandidate? {
        guard let head = session.rideInProgressLegs(upTo: anchor) else { return nil }
        return compositeCandidate(legs: head + onward.legs)
    }

    // MARK: - Custom (DIY) Line Journeys

    func startCustomJourney(line: CustomLine, fromId: String, toId: String) {
        if focusedSession != nil {
            pendingStart = { [weak self] in self?.performStartCustomJourney(line: line, fromId: fromId, toId: toId) }
            showOverwriteConfirmation = true
            return
        }
        performStartCustomJourney(line: line, fromId: fromId, toId: toId)
    }

    private func performStartCustomJourney(line: CustomLine, fromId: String, toId: String) {
        let scheduled = CustomJourneyBuilder.scheduledService(line: line, fromId: fromId, toId: toId)
        guard let service = scheduled
            ?? CustomJourneyBuilder.untimedService(line: line, fromId: fromId, toId: toId)
        else {
            errorMessage = "No matching train found for this time"
            return
        }
        let journeyLine = line.trainLine

        let journey = Journey(
            id: UUID(),
            service: service,
            line: journeyLine,
            boardingStationId: fromId,
            alightingStationId: toId,
            startedAt: Date(),
            hasSchedule: scheduled != nil
        )

        begin(JourneySession(journey: journey, line: journeyLine))
    }

#if DEBUG
    /// Screenshot harness: starts a journey as if boarded minutes ago.
    func debugStartJourney(lineId: String, fromId: String, toId: String, minutesAgo: Double) async {
        guard let resolved = StaticTrainData.resolveJourneyLine(
            lineId: lineId, fromStationId: fromId, toStationId: toId
        ) else { return }
        let staticLine = resolved.staticLine
        if timetableCache[staticLine.id] == nil {
            timetableCache[staticLine.id] = StaticTimetableGenerator.services(
                for: staticLine, calendar: .current()
            )
        }
        guard let services = timetableCache[staticLine.id] else { return }
        // Keep the ride whose progress lands closest to mid-journey.
        var best: (journey: Journey, state: TrainPositionState, score: Double)?
        for offset in stride(from: minutesAgo, through: 5, by: -2.5) {
            let boarded = Date().addingTimeInterval(-offset * 60)
            guard let service = findBestService(services: services, from: fromId, to: toId, at: boarded)
            else { continue }
            let journey = Journey(
                id: UUID(),
                service: service,
                line: staticLine.trainLine,
                boardingStationId: fromId,
                alightingStationId: toId,
                startedAt: boarded
            )
            let state = TrainPositionEngine.computePosition(journey: journey, delay: nil)
            let score = abs(state.progress - 0.55)
            if state.status != .arrived, score < (best?.score ?? .infinity) {
                best = (journey, state, score)
            }
        }
        guard let best else { return }
        begin(JourneySession(journey: best.journey, line: staticLine.trainLine, fixedState: best.state))
    }

#endif

    // MARK: - Overwrite Confirmation

    /// Proceeds with a journey that was held back because another was active.
    func confirmOverwrite() {
        let start = pendingStart
        pendingStart = nil
        start?()
    }

    /// Discards the held-back journey, keeping the one in progress.
    func cancelOverwrite() {
        pendingStart = nil
    }

    // MARK: - Journey Notifications

    /// Re-applies the alert settings to every journey in progress.
    func rescheduleNotifications() {
        sessions.forEach { $0.rescheduleNotifications() }
    }

    // MARK: - LCD Colour

    /// LCD-only line colour; a through-service takes its first component's.
    static func lcdColor(_ line: TrainLine) -> Color {
        let baseId = line.id.split(separator: "+").first.map(String.init) ?? line.id
        guard let hex = LineColors.lcdOverrides[baseId] else { return line.color }
        return Color(hex: hex)
    }

    // MARK: - Force Refresh (from Live Activity button)

    func forceRefresh() {
        sessions.forEach { $0.forceRefresh() }
    }

    // MARK: - Station Timetable

    func loadStationTimetable(stationId: String) {
        isLoadingTimetable = true
        stationTimetable = []

        if let staticLine = StaticTrainData.line(containingStationId: stationId) {
            stationTimetable = StaticTimetableGenerator.stationTimetables(
                forLineId: staticLine.id,
                stationId: stationId,
                calendar: .current()
            )
        }

        isLoadingTimetable = false
    }

    // MARK: - Rail Directions

    func loadRailDirections() {
        guard railDirections.isEmpty else { return }
        railDirections = StaticTrainData.railDirections
    }

    // MARK: - Delay Check Sources

    func delayCheckInfo(for lineId: String) -> DelayCheckInfo? {
        if let info = StaticTrainData.delayCheckInfo(forLineId: lineId) {
            return info
        }
        guard let originId = lineId.split(separator: "+").first else { return nil }
        return StaticTrainData.delayCheckInfo(forLineId: String(originId))
    }

    func directionName(for directionId: String) -> String {
        guard let names = railDirections[directionId] else {
            return directionId
        }
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        switch lang {
        case "en": return names.en.isEmpty ? names.ja : names.en
        default: return names.ja
        }
    }

    // MARK: - Train Matching

    private func findBestService(
        services: [TrainService],
        from: String, to: String,
        at date: Date
    ) -> TrainService? {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents(in: TimeZone(identifier: "Asia/Tokyo")!, from: date)
        let nowSec = (comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60

        let candidates = services.filter { svc in
            let stationIds = svc.timetable.map(\.stationId)
            guard let fromIdx = stationIds.firstIndex(of: from),
                  let toIdx = stationIds.firstIndex(of: to),
                  fromIdx < toIdx else { return false }
            return true
        }

        let sorted = candidates.compactMap { svc -> (TrainService, Int)? in
            guard let entry = svc.timetable.first(where: { $0.stationId == from }),
                  let dep = entry.departureSeconds() else { return nil }
            return (svc, dep)
        }.sorted { $0.1 < $1.1 }

        return sorted.first(where: { $0.1 >= nowSec })?.0 ?? sorted.first?.0
    }

    // MARK: - Preview Data

    private func loadPreviewData() {
        let stations = [
            Station(id: "s1", name: "新宿", nameEn: "Shinjuku", stationCode: "JC05",
                    latitude: 35.6896, longitude: 139.7006),
            Station(id: "s2", name: "中野", nameEn: "Nakano", stationCode: "JC06",
                    latitude: 35.7056, longitude: 139.6659),
            Station(id: "s3", name: "高円寺", nameEn: "Koenji", stationCode: "JC07",
                    latitude: 35.7053, longitude: 139.6496),
            Station(id: "s4", name: "阿佐ヶ谷", nameEn: "Asagaya", stationCode: "JC08",
                    latitude: 35.7043, longitude: 139.6358),
            Station(id: "s5", name: "荻窪", nameEn: "Ogikubo", stationCode: "JC09",
                    latitude: 35.7041, longitude: 139.6200),
            Station(id: "s6", name: "西荻窪", nameEn: "Nishi-Ogikubo", stationCode: "JC10",
                    latitude: 35.7032, longitude: 139.5993),
            Station(id: "s7", name: "吉祥寺", nameEn: "Kichijoji", stationCode: "JC11",
                    latitude: 35.7030, longitude: 139.5796),
            Station(id: "s8", name: "三鷹", nameEn: "Mitaka", stationCode: "JC12",
                    latitude: 35.7027, longitude: 139.5607),
        ]

        let line = TrainLine(
            id: "Railway:JR-East.ChuoRapid",
            name: "中央線快速", nameEn: "Chuo Rapid Line",
            operatorId: "Operator:JR-East",
            stations: stations,
            colorHex: LineColors.chuoRapid
        )

        let timetable = [
            TimetableEntry(id: "t1", stationId: "s1", arrivalTime: nil, departureTime: "08:00"),
            TimetableEntry(id: "t2", stationId: "s2", arrivalTime: "08:04", departureTime: "08:05"),
            TimetableEntry(id: "t3", stationId: "s3", arrivalTime: "08:07", departureTime: "08:08"),
            TimetableEntry(id: "t4", stationId: "s4", arrivalTime: "08:10", departureTime: "08:11"),
            TimetableEntry(id: "t5", stationId: "s5", arrivalTime: "08:13", departureTime: "08:14"),
            TimetableEntry(id: "t6", stationId: "s6", arrivalTime: "08:16", departureTime: "08:17"),
            TimetableEntry(id: "t7", stationId: "s7", arrivalTime: "08:19", departureTime: "08:20"),
            TimetableEntry(id: "t8", stationId: "s8", arrivalTime: "08:23", departureTime: nil),
        ]

        let service = TrainService(
            id: "preview_001", lineId: line.id,
            trainType: .rapid, direction: .outbound,
            timetable: timetable, destinationStationId: "s8"
        )

        let journey = Journey(
            id: UUID(), service: service, line: line,
            boardingStationId: "s1", alightingStationId: "s8", startedAt: Date()
        )
        let state = TrainPositionState(
            progress: 0.35, segmentFrom: 2, segmentTo: 3,
            segmentProgress: 0.6, currentStationIndex: nil,
            nextStationName: "阿佐ヶ谷", nextStationNameEn: "Asagaya",
            delayMinutes: 3, estimatedArrival: Date().addingTimeInterval(1200),
            status: .delayed,
            trackingModeRaw: "Timetable"
        )
        sessions = [JourneySession(
            journey: journey, line: line, fixedState: state,
            delay: DelayInfo(lineId: line.id, delayMinutes: 3, cause: "混雑のため", updatedAt: Date())
        )]
    }
}
