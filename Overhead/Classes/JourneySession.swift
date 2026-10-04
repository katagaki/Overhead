import Foundation
import SwiftUI
import Combine
import Backbone

// MARK: - Journey Session

/// One journey in progress, with its own tracking, Live Activity and alerts,
/// so several can run side by side.
@MainActor
final class JourneySession: ObservableObject, Identifiable {

    let id = UUID()

    @Published private(set) var journey: Journey
    @Published private(set) var line: TrainLine
    @Published private(set) var positionState: TrainPositionState?
    @Published private(set) var currentDelay: DelayInfo?
    @Published private(set) var trackingMode: TrackingMode = .timetable

    private let liveActivity = LiveActivityManager()
    private lazy var locationTracker = LocationTracker(liveActivity: liveActivity)
    private var cancellables = Set<AnyCancellable>()
    private var pendingActivityStart: (() -> Void)?
    private var isTracking = false

    /// Transfer station ID → the line boarded there; kept so alerts can be rescheduled.
    private(set) var transferLines: [String: TrainLine] = [:]

    /// Live Activity leg markers, kept so a mid-journey change can reuse them.
    private(set) var legLines: [TrainJourneyAttributes.LegLine] = []

    /// LCD colour per leg, `lcdOverrides` already applied.
    private(set) var legColors: [LegColor] = []

    struct LegColor {
        let stationIndex: Int
        let color: Color
    }

    typealias UpcomingTransfer = (station: Station, time: Date, line: TrainLine?)
    typealias ReplanAnchor = JourneyViewModel.ReplanAnchor

    init(
        journey: Journey,
        line: TrainLine,
        legLines: [TrainJourneyAttributes.LegLine] = [],
        legColors: [LegColor] = [],
        transferLines: [String: TrainLine] = [:]
    ) {
        self.journey = journey
        self.line = line
        bindLocationTracker()
        install(journey: journey, line: line, legLines: legLines,
                legColors: legColors, transferLines: transferLines)
    }

    convenience init(candidate: TrainCandidate) {
        let parts = Self.parts(of: candidate)
        self.init(journey: parts.journey, line: candidate.journeyLine, legLines: parts.legLines,
                  legColors: parts.legColors, transferLines: parts.transferLines)
    }

    /// Screenshot harness and previews: a fixed state, nothing tracked.
    init(journey: Journey, line: TrainLine, fixedState: TrainPositionState, delay: DelayInfo? = nil) {
        self.journey = journey
        self.line = line
        positionState = fixedState
        currentDelay = delay
    }

    private func bindLocationTracker() {
        // Every observer re-renders on a publish; the 10s tick often repeats itself.
        locationTracker.$positionState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, let state else { return }
                self.positionState = state
            }
            .store(in: &cancellables)

        locationTracker.$trackingMode
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in self?.trackingMode = mode }
            .store(in: &cancellables)

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

    // MARK: - Install

    /// Replaces the journey; the Live Activity restarts rather than updates.
    func install(
        journey: Journey,
        line: TrainLine,
        legLines: [TrainJourneyAttributes.LegLine],
        legColors: [LegColor],
        transferLines: [String: TrainLine]
    ) {
        liveActivity.endActivity()
        pendingActivityStart = nil

        self.journey = journey
        self.line = line
        self.transferLines = transferLines
        self.legLines = legLines
        self.legColors = legColors

        isTracking = true
        locationTracker.startTracking(journey: journey, delay: nil)
        positionState = journey.hasSchedule
            ? TrainPositionEngine.computePosition(journey: journey, delay: nil)
            : locationTracker.positionState

        if let state = positionState {
            startLiveActivity(state: state)
        }
        JourneyNotificationManager.shared.schedule(id: id, journey: journey, transferLines: transferLines)
    }

    func install(candidate: TrainCandidate) {
        let parts = Self.parts(of: candidate)
        install(journey: parts.journey, line: candidate.journeyLine, legLines: parts.legLines,
                legColors: parts.legColors, transferLines: parts.transferLines)
    }

    private static func parts(of candidate: TrainCandidate) -> (
        journey: Journey,
        legLines: [TrainJourneyAttributes.LegLine],
        legColors: [LegColor],
        transferLines: [String: TrainLine]
    ) {
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

        let journeyStations = journey.journeyStations
        var legLines: [TrainJourneyAttributes.LegLine] = []
        var legColors: [LegColor] = []
        var transferLines: [String: TrainLine] = [:]
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
            legColors.append(LegColor(stationIndex: stationIndex, color: JourneyViewModel.lcdColor(leg.line)))
        }
        return (journey, legLines, legColors, transferLines)
    }

    private func startLiveActivity(state: TrainPositionState) {
        let journey = journey
        let lineColorHex = line.colorHex
        let legLines = legLines
        guard locationTracker.isLocationAuthorized else {
            pendingActivityStart = { [weak self] in
                guard let self, self.journey.id == journey.id else { return }
                self.liveActivity.startActivity(
                    journey: journey,
                    positionState: self.positionState ?? state,
                    lineColorHex: lineColorHex,
                    legLines: legLines
                )
            }
            return
        }
        liveActivity.startActivity(
            journey: journey,
            positionState: state,
            lineColorHex: lineColorHex,
            legLines: legLines
        )
    }

    // MARK: - Stop

    func stop() {
        if isTracking { locationTracker.stopTracking() }
        isTracking = false
        liveActivity.endActivity()
        JourneyNotificationManager.shared.cancel(id: id)
        pendingActivityStart = nil
    }

    // MARK: - Controls

    func stepManualStation(_ delta: Int) {
        locationTracker.stepManualStation(delta)
    }

    func forceRefresh() {
        guard isTracking else { return }
        locationTracker.forceRefresh()
        liveActivity.markDelayRefreshed()
    }

    /// Re-applies the alert settings to this journey.
    func rescheduleNotifications() {
        JourneyNotificationManager.shared.schedule(id: id, journey: journey, transferLines: transferLines)
    }

    // MARK: - Transfers

    /// Every 乗り換え still ahead of the train, in order, delay-adjusted.
    var upcomingTransfers: [UpcomingTransfer] {
        guard journey.hasSchedule,
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

    // MARK: - Mid-Journey Replanning

    /// Stops ahead of the train, destination excluded; past stops of the current
    /// leg included so a rider who overshot can double back.
    var replanAnchors: [ReplanAnchor] {
        guard journey.hasSchedule,
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
        }
        return anchors
    }

    /// Stops past `anchor` the train has yet to reach.
    func onwardStops(from anchor: ReplanAnchor) -> [ReplanAnchor] {
        replanAnchors.filter { $0.stationIndex > anchor.stationIndex && !$0.isPast }
    }

    /// Same train, shorter trip — boarding station and start time carry over.
    func changeDestination(to anchor: ReplanAnchor) {
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
            legLines: legLines.filter { $0.stationIndex <= anchor.stationIndex },
            legColors: legColors.filter { $0.stationIndex <= anchor.stationIndex },
            transferLines: transferLines.filter { kept.contains($0.key) }
        )
    }

    /// Boarding station → `anchor`, split back into one leg per train so an
    /// anchor beyond a 乗り換え keeps it; nil at the boarding station.
    func rideInProgressLegs(upTo anchor: ReplanAnchor) -> [CandidateLeg]? {
        guard anchor.stationIndex > 0 else { return nil }
        let stations = journey.journeyStations
        let timetable = journey.journeyTimetable
        let transferIds = Set(journey.transferStationIds)

        var splits = [0]
        for index in 1..<anchor.stationIndex where transferIds.contains(stations[index].id) {
            splits.append(index)
        }
        splits.append(anchor.stationIndex)

        // A composite journey joins its leg line IDs with "+".
        let lineIds = journey.line.id.components(separatedBy: "+")

        var legs: [CandidateLeg] = []
        for legIndex in 0..<(splits.count - 1) {
            let boundary = stations[splits[legIndex]]
            let toStation = stations[splits[legIndex + 1]]

            var line = journey.line
            if legIndex > 0, let boarded = transferLines[boundary.id] {
                line = boarded
            } else if lineIds.indices.contains(legIndex),
                      let resolved = StaticTrainData.line(withId: lineIds[legIndex])?.trainLine {
                line = resolved
            }
            // The journey keeps the arriving leg's station at a transfer; the
            // boarding side lives on the next line under its own ID.
            let fromStation = legIndex == 0
                ? boundary
                : (line.stations.first(where: { $0.name == boundary.name }) ?? boundary)

            guard let depEntry = timetable.first(where: { $0.stationId == boundary.id }),
                  let arrEntry = timetable.first(where: { $0.stationId == toStation.id }),
                  let dep = depEntry.departureSeconds() ?? depEntry.arrivalSeconds(),
                  let arr = arrEntry.arrivalSeconds() ?? arrEntry.departureSeconds()
            else { return nil }

            legs.append(CandidateLeg(
                service: journey.service,
                line: line,
                fromStation: fromStation,
                toStation: toStation,
                departureSeconds: dep,
                arrivalSeconds: arr
            ))
        }
        return legs.isEmpty ? nil : legs
    }

    // MARK: - LCD Colour

    /// The colour every LCD shows now; a new leg takes over once its train departs.
    var currentLineColor: Color {
        let fallback = JourneyViewModel.lcdColor(line)
        guard !legColors.isEmpty else { return fallback }
        let next = max(positionState?.status == .arrived ? Int.max : positionState?.segmentTo ?? Int.max, 1)
        let leg = legColors.last { $0.stationIndex < next } ?? legColors.first
        return leg?.color ?? fallback
    }

    /// Badge colour for the line ridden into a journey station.
    func badgeLineColor(arrivingAt stationId: String) -> Color {
        // Through-lines and untimed rides carry no legs.
        if let owner = StaticTrainData.line(containingStationId: stationId) {
            return owner.trainLine.color
        }
        let fallback = journey.line.color
        guard !legLines.isEmpty,
              let index = journey.journeyStations.firstIndex(where: { $0.id == stationId }),
              let leg = legLines.last(where: { $0.stationIndex < max(index, 1) })
                ?? legLines.first
        else { return fallback }
        return Color(hex: leg.lineColorHex)
    }
}
