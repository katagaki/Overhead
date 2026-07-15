import Foundation
import SwiftUI
import Combine
import Backbone

// MARK: - Journey View Model (Location-Driven)

@MainActor
final class JourneyViewModel: ObservableObject {

    // Published state
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

    // Services
    private let locationTracker = LocationTracker()
    private var cancellables = Set<AnyCancellable>()
    private var timetableCache: [String: [TrainService]] = [:]
    private var linesLoaded = false

    // A journey selected while another is active waits here until the user
    // confirms overwriting the one in progress.
    private var pendingStart: (() -> Void)?

    // A Live Activity held back because the location permission prompt is
    // still up — it starts the moment the user grants access.
    private var pendingActivityStart: (() -> Void)?

    init(previewMode: Bool = false) {
        bindLocationTracker()
        if previewMode {
            loadPreviewData()
        }
    }

    /// Subscribe to LocationTracker's published position state
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

        // Resolve the line to ride — this may span a through-service (直通)
        // junction onto a connecting line when the alighting station is past it.
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

        // Find the best matching service
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

        // Start location-based tracking — this drives everything
        locationTracker.startTracking(journey: journey, delay: nil)

        // Compute initial position from timetable while GPS locks on
        positionState = TrainPositionEngine.computePosition(
            journey: journey, delay: nil
        )

        // Start Live Activity
        if let state = positionState {
            startLiveActivity(
                journey: journey,
                positionState: state,
                lineColorHex: line.colorHex
            )
        }

        isStartingJourney = false
    }

    /// Starts the Live Activity only once location is authorized — without
    /// location keeping the app alive in the background, the activity would
    /// freeze at its last state. While the permission prompt is undecided,
    /// the start waits for the grant; a denial drops it.
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

    /// All boardable itineraries visiting `stationNames` in order (from, any
    /// midpoints, to — matched by Japanese name across lines), departing at
    /// or after `departure`. `transferMinutes` is the platform-walk time
    /// assumed at each transfer, from the user's walking speed.
    func searchTrainCandidates(
        stationNames: [String],
        departure: Date,
        transferMinutes: Double = StaticTrainData.transferBufferMinutes,
        avoidingLineIds: Set<String> = [],
        limit: Int = 12
    ) -> [TrainCandidate] {
        guard stationNames.count >= 2,
              let fromName = stationNames.first,
              let toName = stationNames.last
        else { return [] }

        let calendar = ScheduleCalendar.current(at: departure)
        var jstCal = Calendar(identifier: .gregorian)
        jstCal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let comps = jstCal.dateComponents([.hour, .minute], from: departure)
        let target = (comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60
        // Just after midnight, trains published as 24:00+ on the previous
        // service day are the ones to show.
        let targetSec = target < 4 * 3600 ? target + 24 * 3600 : target

        // Without midpoints, single-train routes (including 直通) win outright.
        if stationNames.count == 2 {
            let direct = directCandidates(
                fromName: fromName, toName: toName,
                targetSec: targetSec, calendar: calendar,
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
            targetSec: targetSec, calendar: calendar,
            transferMinutes: transferMinutes, limit: 8
        )
    }

    /// Whether a route (direct or with transfers) exists between each
    /// consecutive pair of station names.
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
        targetSec: Int,
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
                              departingAtOrAfter: targetSec, calendar: calendar,
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

        return Array(candidates.sorted { $0.departureSeconds < $1.departureSeconds }.prefix(limit))
    }

    // MARK: - Timetable-less Route Search (時刻表無視)

    /// Route alternatives with no times attached: every direct line option,
    /// plus transfer plans (the best one, then variations that avoid the
    /// lines already suggested). Durations are hop-time estimates.
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

    /// Synthetic no-times service riding `staticLine` between two of its
    /// stations, with the covered stations in travel order (loop-aware).
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
        targetSec: Int,
        calendar: ScheduleCalendar,
        transferMinutes: Double,
        limit: Int
    ) -> [TrainCandidate] {
        guard let firstLeg = plan.first else { return [] }

        let bufferSec = Int(transferMinutes * 60)
        let firstRides = rides(on: firstLeg.staticLine,
                               fromId: firstLeg.fromStation.id, toId: firstLeg.toStation.id,
                               departingAtOrAfter: targetSec, calendar: calendar,
                               limit: limit)

        // A plan that stayed on one line is plain direct rides — no composite.
        if plan.count == 1 {
            return firstRides.map { ride in
                let line = firstLeg.staticLine.trainLine
                let leg = CandidateLeg(
                    service: ride.service,
                    line: line,
                    fromStation: firstLeg.fromStation,
                    toStation: firstLeg.toStation,
                    departureSeconds: ride.departure,
                    arrivalSeconds: ride.arrival
                )
                return TrainCandidate(
                    id: "\(ride.service.id)|\(firstLeg.staticLine.id)|\(firstLeg.fromStation.id)|\(firstLeg.toStation.id)",
                    legs: [leg],
                    isThrough: false,
                    journeyLine: line,
                    journeyService: ride.service,
                    fromStation: firstLeg.fromStation,
                    toStation: firstLeg.toStation
                )
            }
        }

        var candidates: [TrainCandidate] = []
        for firstRide in firstRides {
            var legs: [CandidateLeg] = [CandidateLeg(
                service: firstRide.service,
                line: firstLeg.staticLine.trainLine,
                fromStation: firstLeg.fromStation,
                toStation: firstLeg.toStation,
                departureSeconds: firstRide.departure,
                arrivalSeconds: firstRide.arrival
            )]

            var cursor = firstRide.arrival + bufferSec
            var complete = true
            for planLeg in plan.dropFirst() {
                guard let ride = rides(on: planLeg.staticLine,
                                       fromId: planLeg.fromStation.id, toId: planLeg.toStation.id,
                                       departingAtOrAfter: cursor, calendar: calendar,
                                       limit: 1).first
                else { complete = false; break }
                legs.append(CandidateLeg(
                    service: ride.service,
                    line: planLeg.staticLine.trainLine,
                    fromStation: planLeg.fromStation,
                    toStation: planLeg.toStation,
                    departureSeconds: ride.departure,
                    arrivalSeconds: ride.arrival
                ))
                cursor = ride.arrival + bufferSec
            }
            guard complete, let candidate = compositeCandidate(legs: legs) else { continue }
            candidates.append(candidate)
        }

        // Connections can converge on the same onward train — keep the
        // latest-departing first leg for each distinct arrival.
        var seen = Set<String>()
        var unique: [TrainCandidate] = []
        for candidate in candidates.sorted(by: { $0.departureSeconds > $1.departureSeconds }) {
            let key = candidate.legs.dropFirst().map { $0.service.id }.joined(separator: "|")
            if seen.insert(key).inserted {
                unique.append(candidate)
            }
        }
        return unique.sorted { $0.departureSeconds < $1.departureSeconds }
    }

    /// Concrete services on a line between two of its stations.
    private func rides(
        on staticLine: StaticTrainLine,
        fromId: String,
        toId: String,
        departingAtOrAfter targetSec: Int,
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
                      ?? service.timetable[toIdx].departureSeconds(),
                  depSec >= targetSec
            else { continue }
            result.append((service, depSec, arrSec))
        }
        return Array(result.sorted { $0.1 < $1.1 }.prefix(limit))
    }

    /// Merges connecting legs into one linear line + service so that position
    /// tracking and the Live Activity treat the itinerary as a single journey.
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
                    // The transfer station is already in `stations` under the
                    // previous leg's ID — merge this leg's departure into it.
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
                guard let entry = entryByStationId[station.id] else { return nil }
                stations.append(station)
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

        // The boarded line at station 0, plus each connecting line at its
        // transfer station.
        let journeyStations = journey.journeyStations
        var legLines: [TrainJourneyAttributes.LegLine] = []
        for (index, leg) in candidate.legs.enumerated() {
            let stationIndex = index == 0
                ? 0
                : journeyStations.firstIndex { $0.id == candidate.legs[index - 1].toStation.id }
            guard let stationIndex else { continue }
            legLines.append(.init(
                stationIndex: stationIndex,
                lineSymbol: leg.line.lineSymbol,
                lineColorHex: leg.line.colorHex,
                lineName: leg.line.name,
                lineNameEn: leg.line.nameEn
            ))
        }

        if let state = positionState {
            startLiveActivity(
                journey: journey,
                positionState: state,
                lineColorHex: candidate.journeyLine.colorHex,
                legLines: legLines
            )
        }
    }

    // MARK: - Manual Station Flipping (schedule-less journeys)

    func stepManualStation(_ delta: Int) {
        locationTracker.stepManualStation(delta)
    }

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
        pendingActivityStart = nil
        activeJourney = nil
        positionState = nil
        currentDelay = nil
    }

    // MARK: - Force Refresh (from Live Activity button)

    /// Triggered by the Live Activity refresh deep link.
    /// Recomputes the position and re-pushes to Live Activity.
    func forceRefresh() {
        guard activeJourney != nil else { return }
        locationTracker.forceRefresh()
        LiveActivityManager.shared.markDelayRefreshed()
    }

    // MARK: - Station Timetable

    func loadStationTimetable(stationId: String) {
        isLoadingTimetable = true
        stationTimetable = []

        // Generate from bundled data whenever the station is covered
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

    /// Where and how to check for delays on a line (from bundled data).
    /// Composite through-journey line IDs ("A+B") fall back to the origin line.
    func delayCheckInfo(for lineId: String) -> DelayCheckInfo? {
        if let info = StaticTrainData.delayCheckInfo(forLineId: lineId) {
            return info
        }
        guard let originId = lineId.split(separator: "+").first else { return nil }
        return StaticTrainData.delayCheckInfo(forLineId: String(originId))
    }

    /// Returns a localized direction name for a rail direction ID
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
