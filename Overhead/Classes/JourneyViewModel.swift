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
            LiveActivityManager.shared.startActivity(
                journey: journey,
                positionState: state,
                lineColorHex: line.colorHex
            )
        }

        isStartingJourney = false
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
                targetSec: targetSec, calendar: calendar, limit: limit
            )
            if !direct.isEmpty { return direct }
        }

        guard let plan = StaticTrainData.planTransferRoute(
            throughStationNames: stationNames,
            transferMinutes: transferMinutes
        ) else { return [] }

        return candidates(
            forPlan: plan,
            targetSec: targetSec, calendar: calendar,
            transferMinutes: transferMinutes, limit: 8
        )
    }

    /// Whether a route (direct or with transfers) exists between each
    /// consecutive pair of station names.
    func routeExists(through stationNames: [String]) -> Bool {
        guard stationNames.count >= 2 else { return false }
        return zip(stationNames, stationNames.dropFirst()).allSatisfy { from, to in
            from != to
                && (!StaticTrainData.directRoutes(fromStationName: from, toStationName: to).isEmpty
                    || StaticTrainData.planTransferRoute(fromStationName: from, toStationName: to) != nil)
        }
    }

    private func directCandidates(
        fromName: String,
        toName: String,
        targetSec: Int,
        calendar: ScheduleCalendar,
        limit: Int
    ) -> [TrainCandidate] {
        let routes = StaticTrainData.directRoutes(
            fromStationName: fromName,
            toStationName: toName
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
        LiveActivityManager.shared.endActivity()

        let journey = Journey(
            id: UUID(),
            service: candidate.journeyService,
            line: candidate.journeyLine,
            boardingStationId: candidate.fromStation.id,
            alightingStationId: candidate.toStation.id,
            startedAt: Date(),
            transferStationIds: candidate.transferStationIds
        )

        activeJourney = journey
        selectedLine = candidate.journeyLine
        errorMessage = nil

        locationTracker.startTracking(journey: journey, delay: nil)
        positionState = TrainPositionEngine.computePosition(journey: journey, delay: nil)

        if let state = positionState {
            LiveActivityManager.shared.startActivity(
                journey: journey,
                positionState: state,
                lineColorHex: candidate.journeyLine.colorHex
            )
        }
    }

    // MARK: - Stop Journey

    func stopJourney() {
        locationTracker.stopTracking()
        LiveActivityManager.shared.endActivity()
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
