import Foundation
import SwiftUI
import Combine
import Backbone

// MARK: - Journey View Model (Location-Driven)

@MainActor
final class JourneyViewModel: ObservableObject {

    @Published var availableLines: [TrainLine] = []
    @Published var selectedLine: TrainLine?
    @Published var activeJourney: Journey?
    @Published var positionState: TrainPositionState?
    @Published var currentDelay: DelayInfo?
    @Published var trackingMode: TrackingMode = .timetable
    @Published var isLoading = false
    @Published var isStartingJourney = false
    @Published var showOverwriteConfirmation = false
    @Published var errorMessage: String?
    @Published var locationError: String?
    @Published var stationTimetable: [StationTimetableData] = []
    @Published var isLoadingTimetable = false
    @Published var railDirections: [String: (ja: String, en: String)] = [:]

    private let locationTracker = LocationTracker()
    private var cancellables = Set<AnyCancellable>()
    private var timetableCache: [String: [TrainService]] = [:]
    private var linesLoaded = false

    private var pendingStart: (() -> Void)?

    private var pendingActivityStart: (() -> Void)?

    /// Transfer station ID → the line boarded there; kept so alerts can be rescheduled.
    private var transferLines: [String: TrainLine] = [:]

    typealias UpcomingTransfer = (station: Station, time: Date, line: TrainLine?)

    /// Every 乗り換え still ahead of the train, in order, delay-adjusted.
    var upcomingTransfers: [UpcomingTransfer] {
        guard let journey = activeJourney, journey.hasSchedule,
              let state = positionState, state.status != .arrived,
              !journey.transferStationIds.isEmpty
        else { return [] }

        let stations = journey.journeyStations
        let times = journey.scheduledStationTimes
        guard stations.count == times.count else { return [] }

        let current = min(state.currentStationIndex ?? state.segmentTo, max(0, stations.count - 1))
        let transferIds = Set(journey.transferStationIds)
        let delay = TimeInterval(state.delayMinutes * 60)

        return stations.indices[current...]
            .filter { transferIds.contains(stations[$0].id) }
            .map { (stations[$0], times[$0].addingTimeInterval(delay), transferLines[stations[$0].id]) }
    }

    /// The next 乗り換え ahead of the train, with its delay-adjusted time.
    var upcomingTransfer: UpcomingTransfer? { upcomingTransfers.first }

    /// Live Activity leg markers, kept so a mid-journey change can reuse them.
    private var journeyLegLines: [TrainJourneyAttributes.LegLine] = []

    /// LCD colour per leg, `lcdOverrides` already applied.
    private var journeyLegColors: [LegColor] = []

    struct LegColor {
        let stationIndex: Int
        let color: Color
    }

    init(previewMode: Bool = false) {
        bindLocationTracker()
        if previewMode {
            loadPreviewData()
        }
    }

    private func bindLocationTracker() {
        locationTracker.$positionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, let state else { return }
                self.positionState = state
            }
            .store(in: &cancellables)

        locationTracker.$trackingMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                guard let self else { return }
                self.trackingMode = mode
            }
            .store(in: &cancellables)

        locationTracker.$locationError
            .receive(on: DispatchQueue.main)
            .assign(to: &$locationError)

        // Granting location mid-prompt releases a held-back Live Activity
        locationTracker.$isLocationAuthorized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authorized in
                guard let self, authorized else { return }
                self.pendingActivityStart?()
                self.pendingActivityStart = nil
            }
            .store(in: &cancellables)
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
        if activeJourney != nil {
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

        activeJourney = journey
        selectedLine = journeyLine
        transferLines = [:]
        journeyLegLines = []
        journeyLegColors = []

        // Start location-based tracking — this drives everything
        locationTracker.startTracking(journey: journey, delay: nil)

        // Compute initial position from timetable while GPS locks on
        positionState = TrainPositionEngine.computePosition(
            journey: journey, delay: nil
        )

        if let state = positionState {
            startLiveActivity(
                journey: journey,
                positionState: state,
                lineColorHex: line.colorHex
            )
        }
        JourneyNotificationManager.shared.schedule(journey: journey)

        isStartingJourney = false
    }

    private func startLiveActivity(
        journey: Journey,
        positionState: TrainPositionState,
        lineColorHex: String,
        legLines: [TrainJourneyAttributes.LegLine] = []
    ) {
        guard locationTracker.isLocationAuthorized else {
            pendingActivityStart = { [weak self] in
                guard let self, self.activeJourney?.id == journey.id else { return }
                LiveActivityManager.shared.startActivity(
                    journey: journey,
                    positionState: self.positionState ?? positionState,
                    lineColorHex: lineColorHex,
                    legLines: legLines
                )
            }
            return
        }
        LiveActivityManager.shared.startActivity(
            journey: journey,
            positionState: positionState,
            lineColorHex: lineColorHex,
            legLines: legLines
        )
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
        stationNames: [String],
        anchor: TimeAnchor,
        transferMinutes: Double = StaticTrainData.transferBufferMinutes,
        avoidingLineIds: Set<String> = [],
        notDepartingBefore earliest: Date? = nil,
        limit: Int = 12
    ) -> [TrainCandidate] {
        guard stationNames.count >= 2,
              let fromName = stationNames.first,
              let toName = stationNames.last
        else { return [] }

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

        // Without midpoints, single-train routes (including 直通) win outright.
        if stationNames.count == 2 {
            let direct = directCandidates(
                fromName: fromName, toName: toName,
                anchor: rideAnchor, floorSec: floorSec, calendar: calendar,
                avoidingLineIds: avoidingLineIds, limit: limit
            )
            if !direct.isEmpty { return direct }
        }

        guard let plan = StaticTrainData.planTransferRoute(
            throughStationNames: stationNames,
            transferMinutes: transferMinutes,
            avoidingLineIds: avoidingLineIds
        ) else { return [] }

        return candidates(
            forPlan: plan,
            anchor: rideAnchor, floorSec: floorSec, calendar: calendar,
            transferMinutes: transferMinutes, limit: 8
        )
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

    func routeExists(through stationNames: [String], avoidingLineIds: Set<String> = []) -> Bool {
        guard stationNames.count >= 2 else { return false }
        return zip(stationNames, stationNames.dropFirst()).allSatisfy { from, to in
            from != to
                && (!StaticTrainData.directRoutes(fromStationName: from, toStationName: to,
                                                  avoidingLineIds: avoidingLineIds).isEmpty
                    || StaticTrainData.planTransferRoute(fromStationName: from, toStationName: to,
                                                         avoidingLineIds: avoidingLineIds) != nil)
        }
    }

    private func directCandidates(
        fromName: String,
        toName: String,
        anchor: RideAnchor,
        floorSec: Int?,
        calendar: ScheduleCalendar,
        avoidingLineIds: Set<String>,
        limit: Int
    ) -> [TrainCandidate] {
        let routes = StaticTrainData.directRoutes(
            fromStationName: fromName,
            toStationName: toName,
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

        return Array(sorted(candidates, anchor: anchor).prefix(limit))
    }

    /// 到着時刻 searches lead with the latest itinerary that still makes it.
    private func sorted(_ candidates: [TrainCandidate], anchor: RideAnchor) -> [TrainCandidate] {
        switch anchor {
        case .departAtOrAfter:
            return candidates.sorted { $0.departureSeconds < $1.departureSeconds }
        case .arriveAtOrBefore:
            return candidates.sorted {
                $0.arrivalSeconds == $1.arrivalSeconds
                    ? $0.departureSeconds > $1.departureSeconds
                    : $0.arrivalSeconds > $1.arrivalSeconds
            }
        }
    }

    // MARK: - Timetable-less Route Search (時刻表無視)

    func searchRouteOptions(
        stationNames: [String],
        transferMinutes: Double,
        avoidingLineIds: Set<String> = []
    ) -> [TrainCandidate] {
        guard stationNames.count >= 2,
              let fromName = stationNames.first,
              let toName = stationNames.last
        else { return [] }

        var results: [TrainCandidate] = []
        var seen = Set<String>()
        func add(_ candidate: TrainCandidate?) {
            guard let candidate else { return }
            let key = candidate.legs
                .map { "\($0.line.id)|\($0.fromStation.id)|\($0.toStation.id)" }
                .joined(separator: "+")
            if seen.insert(key).inserted { results.append(candidate) }
        }

        if stationNames.count == 2 {
            for route in StaticTrainData.directRoutes(
                fromStationName: fromName, toStationName: toName,
                avoidingLineIds: avoidingLineIds
            ) {
                add(untimedCandidate(for: route))
            }
        }

        // Re-plan with each found plan's lines excluded to surface variety.
        var avoid = avoidingLineIds
        for _ in 0..<3 {
            guard let plan = StaticTrainData.planTransferRoute(
                throughStationNames: stationNames,
                transferMinutes: transferMinutes,
                avoidingLineIds: avoid
            ) else { break }
            add(untimedCandidate(forPlan: plan, transferMinutes: transferMinutes))
            let planLines = Set(plan.map(\.staticLine.id))
            if planLines.isSubset(of: avoid) { break }
            avoid.formUnion(planLines)
        }

        return results.sorted { $0.durationMinutes < $1.durationMinutes }
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

    private func untimedCandidate(for route: StaticTrainData.DirectRouteOption) -> TrainCandidate? {
        guard let ride = untimedRide(
            on: route.staticLine, from: route.fromStation, to: route.toStation
        ) else { return nil }
        let leg = CandidateLeg(
            service: ride.service,
            line: route.boardingLine.trainLine,
            fromStation: route.fromStation,
            toStation: route.toStation,
            departureSeconds: 0,
            arrivalSeconds: ride.minutes * 60
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

        if plan.count == 1 {
            guard let ride = untimedRide(
                on: firstLeg.staticLine, from: firstLeg.fromStation, to: firstLeg.toStation
            ) else { return nil }
            let leg = CandidateLeg(
                service: ride.service,
                line: firstLeg.staticLine.trainLine,
                fromStation: firstLeg.fromStation,
                toStation: firstLeg.toStation,
                departureSeconds: 0,
                arrivalSeconds: ride.minutes * 60
            )
            return TrainCandidate(
                id: "untimed|\(firstLeg.staticLine.id)|\(firstLeg.fromStation.id)|\(firstLeg.toStation.id)",
                legs: [leg],
                isThrough: false,
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
            legs.append(CandidateLeg(
                service: ride.service,
                line: planLeg.staticLine.trainLine,
                fromStation: planLeg.fromStation,
                toStation: planLeg.toStation,
                departureSeconds: cursor,
                arrivalSeconds: cursor + ride.minutes * 60
            ))
            cursor += ride.minutes * 60 + Int(transferMinutes * 60)
            // The transfer station keeps the arriving leg's station ID.
            stations.append(contentsOf: index == 0 ? ride.stations : Array(ride.stations.dropFirst()))
        }

        let compositeId = plan.map(\.staticLine.trainLine.id).joined(separator: "+")
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
            name: plan.map(\.staticLine.trainLine.name).joined(separator: "〜"),
            nameEn: plan.map(\.staticLine.trainLine.nameEn).joined(separator: " – "),
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

    /// Builds boardable itineraries along a planned route (one or more legs).
    private func candidates(
        forPlan plan: [StaticTrainData.TransferLeg],
        anchor: RideAnchor,
        floorSec: Int?,
        calendar: ScheduleCalendar,
        transferMinutes: Double,
        limit: Int
    ) -> [TrainCandidate] {
        // Search the anchored end first, then chain away from it.
        let anchoredLeg = anchor.isArrival ? plan.last : plan.first
        guard let anchoredLeg else { return [] }

        let bufferSec = Int(transferMinutes * 60)
        // The floor only binds the leg boarded first.
        let anchorIsOrigin = !anchor.isArrival || plan.count == 1
        let anchoredRides = rides(on: anchoredLeg.staticLine,
                                  fromId: anchoredLeg.fromStation.id, toId: anchoredLeg.toStation.id,
                                  anchor: anchor,
                                  notDepartingBefore: anchorIsOrigin ? floorSec : nil,
                                  calendar: calendar,
                                  limit: limit)

        func leg(_ planLeg: StaticTrainData.TransferLeg,
                 _ ride: (service: TrainService, departure: Int, arrival: Int)) -> CandidateLeg {
            CandidateLeg(
                service: ride.service,
                line: planLeg.staticLine.trainLine,
                fromStation: planLeg.fromStation,
                toStation: planLeg.toStation,
                departureSeconds: ride.departure,
                arrivalSeconds: ride.arrival
            )
        }

        // A plan that stayed on one line is plain direct rides — no composite.
        if plan.count == 1 {
            return anchoredRides.map { ride in
                TrainCandidate(
                    id: "\(ride.service.id)|\(anchoredLeg.staticLine.id)|\(anchoredLeg.fromStation.id)|\(anchoredLeg.toStation.id)",
                    legs: [leg(anchoredLeg, ride)],
                    isThrough: false,
                    journeyLine: anchoredLeg.staticLine.trainLine,
                    journeyService: ride.service,
                    fromStation: anchoredLeg.fromStation,
                    toStation: anchoredLeg.toStation
                )
            }
        }

        var candidates: [TrainCandidate] = []
        for anchoredRide in anchoredRides {
            var legs: [CandidateLeg] = [leg(anchoredLeg, anchoredRide)]
            let remaining = anchor.isArrival
                ? Array(plan.dropLast().reversed())
                : Array(plan.dropFirst())
            var cursor = anchor.isArrival
                ? anchoredRide.departure - bufferSec
                : anchoredRide.arrival + bufferSec
            var complete = true

            for (index, planLeg) in remaining.enumerated() {
                let legAnchor: RideAnchor = anchor.isArrival
                    ? .arriveAtOrBefore(cursor)
                    : .departAtOrAfter(cursor)
                let isOrigin = anchor.isArrival && index == remaining.count - 1
                guard let ride = rides(on: planLeg.staticLine,
                                       fromId: planLeg.fromStation.id, toId: planLeg.toStation.id,
                                       anchor: legAnchor,
                                       notDepartingBefore: isOrigin ? floorSec : nil,
                                       calendar: calendar,
                                       limit: 1).first
                else { complete = false; break }
                if anchor.isArrival {
                    legs.insert(leg(planLeg, ride), at: 0)
                    cursor = ride.departure - bufferSec
                } else {
                    legs.append(leg(planLeg, ride))
                    cursor = ride.arrival + bufferSec
                }
            }
            guard complete, let candidate = compositeCandidate(legs: legs) else { continue }
            candidates.append(candidate)
        }

        // Keep the tightest connection per distinct set of chained trains.
        var seen = Set<String>()
        var unique: [TrainCandidate] = []
        let ordered = anchor.isArrival
            ? candidates.sorted { $0.arrivalSeconds < $1.arrivalSeconds }
            : candidates.sorted { $0.departureSeconds > $1.departureSeconds }
        for candidate in ordered {
            let chained = anchor.isArrival ? candidate.legs.dropLast() : candidate.legs.dropFirst()
            let key = chained.map { $0.service.id }.joined(separator: "|")
            if seen.insert(key).inserted {
                unique.append(candidate)
            }
        }
        return sorted(unique, anchor: anchor)
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
        let cacheKey = "\(staticLine.id)|\(calendar.rawValue)"
        if timetableCache[cacheKey] == nil {
            timetableCache[cacheKey] = StaticTimetableGenerator.services(
                for: staticLine, calendar: calendar
            )
        }
        guard let services = timetableCache[cacheKey] else { return [] }

        var result: [(TrainService, Int, Int)] = []
        for service in services {
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

    private func compositeCandidate(legs: [CandidateLeg]) -> TrainCandidate? {
        guard let first = legs.first, let last = legs.last else { return nil }

        var stations: [Station] = []
        var entries: [TimetableEntry] = []
        let compositeId = legs.map(\.line.id).joined(separator: "+")

        for (legIndex, leg) in legs.enumerated() {
            guard let fromIdx = leg.line.stations.firstIndex(where: { $0.id == leg.fromStation.id }),
                  let toIdx = leg.line.stations.firstIndex(where: { $0.id == leg.toStation.id })
            else { return nil }
            let slice: [Station] = fromIdx <= toIdx
                ? Array(leg.line.stations[fromIdx...toIdx])
                : Array(leg.line.stations[toIdx...fromIdx].reversed())

            let entryByStationId = Dictionary(
                leg.service.timetable.map { ($0.stationId, $0) },
                uniquingKeysWith: { first, _ in first }
            )

            for (i, station) in slice.enumerated() {
                let isTransferIn = legIndex > 0 && i == 0
                if isTransferIn {
                    guard let prev = entries.popLast() else { return nil }
                    let depTime = entryByStationId[station.id]?.departureTime
                        ?? entryByStationId[station.id]?.arrivalTime
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
        if activeJourney != nil {
            pendingStart = { [weak self] in self?.performStartJourney(candidate: candidate) }
            showOverwriteConfirmation = true
            return
        }
        performStartJourney(candidate: candidate)
    }

    private func performStartJourney(candidate: TrainCandidate) {
        LiveActivityManager.shared.endActivity()

        let journey = Journey(
            id: UUID(),
            service: candidate.journeyService,
            line: candidate.journeyLine,
            boardingStationId: candidate.fromStation.id,
            alightingStationId: candidate.toStation.id,
            startedAt: Date(),
            transferStationIds: candidate.transferStationIds,
            hasSchedule: candidate.hasSchedule
        )

        activeJourney = journey
        selectedLine = candidate.journeyLine
        errorMessage = nil

        locationTracker.startTracking(journey: journey, delay: nil)
        positionState = candidate.hasSchedule
            ? TrainPositionEngine.computePosition(journey: journey, delay: nil)
            : locationTracker.positionState

        let journeyStations = journey.journeyStations
        var legLines: [TrainJourneyAttributes.LegLine] = []
        var legColors: [LegColor] = []
        transferLines = [:]
        for (index, leg) in candidate.legs.enumerated() {
            let stationIndex = index == 0
                ? 0
                : journeyStations.firstIndex { $0.id == candidate.legs[index - 1].toStation.id }
            guard let stationIndex else { continue }
            // Keyed by the previous leg's arrival station ID, per operator.
            if index > 0 { transferLines[candidate.legs[index - 1].toStation.id] = leg.line }
            legLines.append(.init(
                stationIndex: stationIndex,
                lineSymbol: leg.line.lineSymbol,
                lineColorHex: leg.line.colorHex,
                lineName: leg.line.name,
                lineNameEn: leg.line.nameEn
            ))
            legColors.append(LegColor(stationIndex: stationIndex, color: Self.lcdColor(leg.line)))
        }

        journeyLegLines = legLines
        journeyLegColors = legColors

        if let state = positionState {
            startLiveActivity(
                journey: journey,
                positionState: state,
                lineColorHex: candidate.journeyLine.colorHex,
                legLines: legLines
            )
        }
        JourneyNotificationManager.shared.schedule(journey: journey, transferLines: transferLines)
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

    /// Stops of the leg being ridden, destination excluded; past stops included
    /// so a rider who overshot can double back.
    var replanAnchors: [ReplanAnchor] {
        guard let journey = activeJourney, journey.hasSchedule,
              let state = positionState, state.status != .arrived
        else { return [] }

        let stations = journey.journeyStations
        let times = journey.scheduledStationTimes
        guard stations.count > 1, stations.count == times.count else { return [] }

        let current = min(state.currentStationIndex ?? state.segmentTo, stations.count - 1)
        let delay = TimeInterval(state.delayMinutes * 60)
        let transferIds = Set(journey.transferStationIds)

        // Walk back to the 乗り換え this leg was boarded at, or the boarding stop.
        var legStart = current
        while legStart > 0, !transferIds.contains(stations[legStart].id) {
            legStart -= 1
        }

        var anchors: [ReplanAnchor] = []
        for index in legStart..<(stations.count - 1) {
            anchors.append(ReplanAnchor(
                stationIndex: index,
                station: stations[index],
                time: times[index].addingTimeInterval(delay),
                isPast: index < current
            ))
            if index >= current, transferIds.contains(stations[index].id) { break }
        }
        return anchors
    }

    /// Stops past `anchor` the train has yet to reach.
    func onwardStops(from anchor: ReplanAnchor) -> [ReplanAnchor] {
        replanAnchors.filter { $0.stationIndex > anchor.stationIndex && !$0.isPast }
    }

    /// Alternative itineraries from `anchor` onward, soonest first.
    func replanCandidates(
        from anchor: ReplanAnchor,
        to destinationName: String,
        transferMinutes: Double = StaticTrainData.transferBufferMinutes,
        avoidingLineIds: Set<String> = [],
        limit: Int = 8
    ) -> [TrainCandidate] {
        guard anchor.station.name != destinationName else { return [] }
        // Past stops have a departure time behind us; search from now.
        let from = max(anchor.time, Date())
        return searchTrainCandidates(
            stationNames: [anchor.station.name, destinationName],
            anchor: .departure(from.addingTimeInterval(Self.sameStationBufferMinutes * 60)),
            transferMinutes: transferMinutes,
            avoidingLineIds: avoidingLineIds,
            limit: limit
        )
    }

    /// Same train, shorter trip — boarding station and start time carry over.
    func changeDestination(to anchor: ReplanAnchor) {
        guard let journey = activeJourney else { return }
        let stations = journey.journeyStations
        guard anchor.stationIndex > 0, anchor.stationIndex < stations.count else { return }

        let kept = Set(stations.prefix(anchor.stationIndex + 1).map(\.id))
        let revised = Journey(
            id: UUID(),
            service: journey.service,
            line: journey.line,
            boardingStationId: journey.boardingStationId,
            alightingStationId: stations[anchor.stationIndex].id,
            startedAt: journey.startedAt,
            transferStationIds: journey.transferStationIds.filter { kept.contains($0) },
            hasSchedule: journey.hasSchedule
        )

        install(
            journey: revised,
            line: journey.line,
            legLines: journeyLegLines.filter { $0.stationIndex <= anchor.stationIndex },
            legColors: journeyLegColors.filter { $0.stationIndex <= anchor.stationIndex },
            transferLines: transferLines.filter { kept.contains($0.key) }
        )
    }

    /// Swaps the rest of the itinerary for `onward`, boarded at `anchor`.
    func replan(from anchor: ReplanAnchor, to onward: TrainCandidate) {
        performStartJourney(candidate: stitched(from: anchor, to: onward) ?? onward)
    }

    /// `onward` with the ride in progress prepended as a leg; nil if they can't join.
    func stitched(from anchor: ReplanAnchor, to onward: TrainCandidate) -> TrainCandidate? {
        guard let head = rideInProgressLeg(upTo: anchor) else { return nil }
        return compositeCandidate(legs: [head] + onward.legs)
    }

    /// Boarding station → `anchor` as one leg; nil at the boarding station.
    private func rideInProgressLeg(upTo anchor: ReplanAnchor) -> CandidateLeg? {
        guard let journey = activeJourney,
              let boarding = journey.journeyStations.first,
              boarding.id != anchor.station.id
        else { return nil }

        let timetable = journey.journeyTimetable
        guard let depEntry = timetable.first(where: { $0.stationId == boarding.id }),
              let arrEntry = timetable.first(where: { $0.stationId == anchor.station.id }),
              let dep = depEntry.departureSeconds() ?? depEntry.arrivalSeconds(),
              let arr = arrEntry.arrivalSeconds() ?? arrEntry.departureSeconds()
        else { return nil }

        return CandidateLeg(
            service: journey.service,
            line: journey.line,
            fromStation: boarding,
            toStation: anchor.station,
            departureSeconds: dep,
            arrivalSeconds: arr
        )
    }

    /// Replaces the active journey; the Live Activity restarts rather than updates.
    private func install(
        journey: Journey,
        line: TrainLine,
        legLines: [TrainJourneyAttributes.LegLine],
        legColors: [LegColor],
        transferLines: [String: TrainLine]
    ) {
        LiveActivityManager.shared.endActivity()

        activeJourney = journey
        selectedLine = line
        errorMessage = nil
        self.transferLines = transferLines
        journeyLegLines = legLines
        journeyLegColors = legColors

        locationTracker.startTracking(journey: journey, delay: nil)
        positionState = journey.hasSchedule
            ? TrainPositionEngine.computePosition(journey: journey, delay: nil)
            : locationTracker.positionState

        if let state = positionState {
            startLiveActivity(
                journey: journey,
                positionState: state,
                lineColorHex: line.colorHex,
                legLines: legLines
            )
        }
        JourneyNotificationManager.shared.schedule(journey: journey, transferLines: transferLines)
    }

    // MARK: - Custom (DIY) Line Journeys

    func startCustomJourney(line: CustomLine, fromId: String, toId: String) {
        if activeJourney != nil {
            pendingStart = { [weak self] in self?.performStartCustomJourney(line: line, fromId: fromId, toId: toId) }
            showOverwriteConfirmation = true
            return
        }
        performStartCustomJourney(line: line, fromId: fromId, toId: toId)
    }

    private func performStartCustomJourney(line: CustomLine, fromId: String, toId: String) {
        LiveActivityManager.shared.endActivity()

        let scheduled = CustomJourneyBuilder.scheduledService(line: line, fromId: fromId, toId: toId)
        guard let service = scheduled
            ?? CustomJourneyBuilder.untimedService(line: line, fromId: fromId, toId: toId)
        else {
            errorMessage = "No matching train found for this time"
            return
        }
        let hasSchedule = scheduled != nil
        let journeyLine = line.trainLine

        let journey = Journey(
            id: UUID(),
            service: service,
            line: journeyLine,
            boardingStationId: fromId,
            alightingStationId: toId,
            startedAt: Date(),
            hasSchedule: hasSchedule
        )

        activeJourney = journey
        selectedLine = journeyLine
        errorMessage = nil
        transferLines = [:]
        journeyLegLines = []
        journeyLegColors = []

        locationTracker.startTracking(journey: journey, delay: nil)
        positionState = hasSchedule
            ? TrainPositionEngine.computePosition(journey: journey, delay: nil)
            : locationTracker.positionState

        if let state = positionState {
            startLiveActivity(
                journey: journey,
                positionState: state,
                lineColorHex: journeyLine.colorHex
            )
        }
        JourneyNotificationManager.shared.schedule(journey: journey)
    }

    // MARK: - Manual Station Flipping (schedule-less journeys)

    func stepManualStation(_ delta: Int) {
        locationTracker.stepManualStation(delta)
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
        activeJourney = best.journey
        selectedLine = staticLine.trainLine
        positionState = best.state
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

    // MARK: - Stop Journey

    func stopJourney() {
        locationTracker.stopTracking()
        LiveActivityManager.shared.endActivity()
        JourneyNotificationManager.shared.cancelAll()
        pendingActivityStart = nil
        transferLines = [:]
        journeyLegLines = []
        journeyLegColors = []
        activeJourney = nil
        positionState = nil
        currentDelay = nil
    }

    // MARK: - Journey Notifications

    /// Re-applies the alert settings to the journey in progress.
    func rescheduleNotifications() {
        guard let journey = activeJourney else {
            JourneyNotificationManager.shared.cancelAll()
            return
        }
        JourneyNotificationManager.shared.schedule(journey: journey, transferLines: transferLines)
    }

    // MARK: - LCD Colour

    /// The colour every LCD shows now; a new leg takes over once its train departs.
    var currentLineColor: Color {
        let fallback = selectedLine.map(Self.lcdColor) ?? .gray
        guard !journeyLegColors.isEmpty else { return fallback }
        let next = max(positionState?.status == .arrived ? Int.max : positionState?.segmentTo ?? Int.max, 1)
        let leg = journeyLegColors.last { $0.stationIndex < next } ?? journeyLegColors.first
        return leg?.color ?? fallback
    }

    /// LCD-only line colour; a through-service takes its first component's.
    static func lcdColor(_ line: TrainLine) -> Color {
        let baseId = line.id.split(separator: "+").first.map(String.init) ?? line.id
        guard let hex = LineColors.lcdOverrides[baseId] else { return line.color }
        return Color(hex: hex)
    }

    // MARK: - Force Refresh (from Live Activity button)

    func forceRefresh() {
        guard activeJourney != nil else { return }
        locationTracker.forceRefresh()
        LiveActivityManager.shared.markDelayRefreshed()
    }

    // MARK: - Station Timetable

    func loadStationTimetable(stationId: String) {
        isLoadingTimetable = true
        stationTimetable = []

        if let staticLine = StaticTrainData.line(containingStationId: stationId) {
            stationTimetable = StaticTimetableGenerator.stationTimetables(
                for: staticLine,
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

        selectedLine = line
        activeJourney = Journey(
            id: UUID(), service: service, line: line,
            boardingStationId: "s1", alightingStationId: "s8", startedAt: Date()
        )
        currentDelay = DelayInfo(lineId: line.id, delayMinutes: 3, cause: "混雑のため", updatedAt: Date())
        positionState = TrainPositionState(
            progress: 0.35, segmentFrom: 2, segmentTo: 3,
            segmentProgress: 0.6, currentStationIndex: nil,
            nextStationName: "阿佐ヶ谷", nextStationNameEn: "Asagaya",
            delayMinutes: 3, estimatedArrival: Date().addingTimeInterval(1200),
            status: .delayed,
            trackingModeRaw: "Timetable"
        )
    }
}
