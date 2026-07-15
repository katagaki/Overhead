import Foundation
import ActivityKit
import SwiftUI
import Backbone

// MARK: - Live Activity Attributes

struct TrainJourneyAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var currentStationIndex: Int?
        // Segment target; valid between stations, nil once arrived.
        var nextStationIndex: Int?
        var nextStationName: String
        var nextStationNameEn: String
        var delayMinutes: Int
        var estimatedArrivalTimestamp: Double
        var statusRaw: String
        var trackingModeRaw: String          // "GPS", "Timetable", "Blended"
        var lastRefreshTimestamp: Double      // When delay data was last fetched
        // Delay-adjusted; drives timer-based views while the app is suspended.
        var departureTimestamp: Double
        // Delay-adjusted segment window; drives the self-advancing next-station countdown.
        var segmentStartTimestamp: Double
        var nextStationArrivalTimestamp: Double

        var status: TrainPositionState.Status {
            TrainPositionState.Status(rawValue: statusRaw) ?? .onTime
        }

        var isDelayed: Bool { delayMinutes > 0 }

        var isTimetableMode: Bool { trackingModeRaw == "Timetable" }

        var estimatedArrival: Date {
            Date(timeIntervalSince1970: estimatedArrivalTimestamp)
        }

        var departure: Date {
            Date(timeIntervalSince1970: departureTimestamp)
        }

        /// Timer interval covering the scheduled ride, clamped to stay valid.
        var journeyInterval: ClosedRange<Date> {
            let start = departure
            let end = max(estimatedArrival, start.addingTimeInterval(60))
            return start...end
        }

        /// Timer interval of the current segment (to the next station).
        var segmentInterval: ClosedRange<Date> {
            let start = Date(timeIntervalSince1970: segmentStartTimestamp)
            let end = max(Date(timeIntervalSince1970: nextStationArrivalTimestamp),
                          start.addingTimeInterval(1))
            return start...end
        }

        var lastRefresh: Date {
            Date(timeIntervalSince1970: lastRefreshTimestamp)
        }
    }

    /// The line ridden from `stationIndex` onward; each transfer adds an entry.
    struct LegLine: Codable, Hashable {
        let stationIndex: Int
        let lineSymbol: String
        let lineColorHex: String
        let lineName: String
        let lineNameEn: String
    }

    let lineName: String
    let lineNameEn: String
    let lineColorHex: String
    let lineSymbol: String
    let originName: String
    let originNameEn: String
    let destinationName: String
    let destinationNameEn: String
    let trainType: String
    let stationNames: [String]
    let stationNamesEn: [String]
    let stationCount: Int
    // Whether the train stops at each station (false = express skip)
    let stationStops: [Bool]
    // Scheduled time per station (epoch seconds, no delay); skipped stations carry the previous stop's time.
    let stationTimes: [Double]
    // Empty string where a station has no code.
    let stationCodes: [String]
    // Per-station line color (hex); through-service stops keep their own line's color.
    let stationColors: [String]
    let legLines: [LegLine]
    let refreshURLString: String

    var destinationCode: String { stationCodes.last ?? "" }

    /// The next station's own line color, for its station-number badge.
    func stationColorHex(at index: Int?) -> String {
        guard let idx = index, stationColors.indices.contains(idx) else {
            return lineColorHex
        }
        return stationColors[idx]
    }

    var destinationColorHex: String { stationColors.last ?? lineColorHex }

    /// Still the arriving leg at the transfer station; the new leg takes over on departure.
    func currentLeg(nextIndex: Int?) -> LegLine? {
        guard !legLines.isEmpty else { return nil }
        let next = max(nextIndex ?? stationCount, 1)
        return legLines.last { $0.stationIndex < next } ?? legLines.first
    }

    /// Nil for the rest of a straight (one-seat) ride.
    func upcomingTransfer(nextIndex: Int?) -> LegLine? {
        guard let next = nextIndex else { return nil }
        return legLines.first { $0.stationIndex > 0 && $0.stationIndex >= max(next, 1) }
    }
}

// MARK: - Live Activity Manager

final class LiveActivityManager {

    static let shared = LiveActivityManager()
    private init() {}

    static let refreshURLScheme = "overhead://refresh-delay"

    private(set) var currentActivity: Activity<TrainJourneyAttributes>?
    private var lastDelayFetchTime = Date()
    // Scheduled departure/arrival (pre-delay); drives the self-updating timer interval.
    private var scheduledDeparture: Date?
    private var scheduledArrival: Date?
    // Scheduled time per station (aligned with stationNames); drives the per-segment countdown.
    private var stationTimes: [Date] = []

    var hasActiveActivity: Bool { currentActivity != nil }

    func startActivity(
        journey: Journey,
        positionState: TrainPositionState,
        lineColorHex: String,
        legLines: [TrainJourneyAttributes.LegLine] = []
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Self-advancing views are schedule-driven; need journey times.
        guard journey.hasSchedule else { return }

        let stations = journey.journeyStations
        let timetableIds = Set(journey.journeyTimetable.map(\.stationId))
        let stationStops = stations.map { timetableIds.contains($0.id) }

        // Each station keeps its own line's color (matches the in-app LCD views).
        let stationColors = stations.map {
            StaticTrainData.line(containingStationId: $0.id)?.trainLine.colorHex ?? lineColorHex
        }

        // A one-seat ride stays on the journey line the whole way.
        let resolvedLegLines = legLines.isEmpty
            ? [TrainJourneyAttributes.LegLine(
                stationIndex: 0,
                lineSymbol: journey.line.lineSymbol,
                lineColorHex: lineColorHex,
                lineName: journey.line.name,
                lineNameEn: journey.line.nameEn
            )]
            : legLines

        lastDelayFetchTime = Date()
        (scheduledDeparture, scheduledArrival) = Self.scheduledTimes(for: journey)
        stationTimes = Self.stationTimes(for: journey)

        let attributes = TrainJourneyAttributes(
            lineName: journey.line.name,
            lineNameEn: journey.line.nameEn,
            lineColorHex: lineColorHex,
            lineSymbol: journey.line.lineSymbol,
            originName: stations.first?.name ?? "",
            originNameEn: stations.first?.nameEn ?? "",
            destinationName: stations.last?.name ?? "",
            destinationNameEn: stations.last?.nameEn ?? "",
            trainType: journey.service.trainType.displayNameJa,
            stationNames: stations.map(\.name),
            stationNamesEn: stations.map(\.nameEn),
            stationCount: stations.count,
            stationStops: stationStops,
            stationTimes: stationTimes.map(\.timeIntervalSince1970),
            stationCodes: stations.map(\.stationCode),
            stationColors: stationColors,
            legLines: resolvedLegLines,
            refreshURLString: Self.refreshURLScheme
        )

        let state = contentState(from: positionState)

        do {
            let content = ActivityContent(state: state, staleDate: staleDate(for: state))
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil  // No server — all updates are local
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateActivity(positionState: TrainPositionState) {
        guard let activity = currentActivity else { return }
        let state = contentState(from: positionState)
        let content = ActivityContent(state: state, staleDate: staleDate(for: state))

        Task {
            await activity.update(content)
        }
    }

    // Timer-driven views self-advance, so it only goes stale well past arrival.
    private func staleDate(for state: TrainJourneyAttributes.ContentState) -> Date {
        max(state.estimatedArrival.addingTimeInterval(600), Date().addingTimeInterval(600))
    }

    func markDelayRefreshed() {
        lastDelayFetchTime = Date()
    }

    func endActivity() {
        guard let activity = currentActivity else { return }
        let finalState = TrainJourneyAttributes.ContentState(
            progress: 1.0,
            currentStationIndex: nil,
            nextStationIndex: nil,
            nextStationName: "",
            nextStationNameEn: "",
            delayMinutes: 0,
            estimatedArrivalTimestamp: Date().timeIntervalSince1970,
            statusRaw: TrainPositionState.Status.arrived.rawValue,
            trackingModeRaw: "Timetable",
            lastRefreshTimestamp: Date().timeIntervalSince1970,
            departureTimestamp: (scheduledDeparture ?? Date()).timeIntervalSince1970,
            segmentStartTimestamp: Date().timeIntervalSince1970,
            nextStationArrivalTimestamp: Date().timeIntervalSince1970
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        Task {
            // Remove immediately rather than leaving the arrived state on the lock screen.
            await activity.end(content, dismissalPolicy: .immediate)
        }
        currentActivity = nil
        scheduledDeparture = nil
        scheduledArrival = nil
        stationTimes = []
    }

    private func contentState(from state: TrainPositionState) -> TrainJourneyAttributes.ContentState {
        let delaySeconds = TimeInterval(state.delayMinutes * 60)
        let departure = (scheduledDeparture ?? Date()).addingTimeInterval(delaySeconds)

        // Delay-adjusted segment window; the next-station countdown runs off these fixed dates.
        var segmentStart = departure
        var nextArrival = (scheduledArrival ?? Date()).addingTimeInterval(delaySeconds)
        if stationTimes.indices.contains(state.segmentFrom),
           stationTimes.indices.contains(state.segmentTo) {
            segmentStart = stationTimes[state.segmentFrom].addingTimeInterval(delaySeconds)
            nextArrival = stationTimes[state.segmentTo].addingTimeInterval(delaySeconds)
        }

        return .init(
            progress: state.progress,
            currentStationIndex: state.currentStationIndex,
            nextStationIndex: state.status == .arrived ? nil : state.segmentTo,
            nextStationName: state.nextStationName,
            nextStationNameEn: state.nextStationNameEn,
            delayMinutes: state.delayMinutes,
            estimatedArrivalTimestamp: state.estimatedArrival.timeIntervalSince1970,
            statusRaw: state.status.rawValue,
            trackingModeRaw: state.trackingModeRaw,
            lastRefreshTimestamp: lastDelayFetchTime.timeIntervalSince1970,
            departureTimestamp: departure.timeIntervalSince1970,
            segmentStartTimestamp: segmentStart.timeIntervalSince1970,
            nextStationArrivalTimestamp: nextArrival.timeIntervalSince1970
        )
    }

    /// Scheduled time per station (arrival else departure); skipped stations carry the previous time.
    private static func stationTimes(for journey: Journey) -> [Date] {
        let timetable = journey.journeyTimetable
        var times: [Date] = []
        var last: Date?
        for station in journey.journeyStations {
            if let entry = timetable.first(where: { $0.stationId == station.id }),
               let secs = entry.arrivalSeconds() ?? entry.departureSeconds() {
                last = dateFromRailSeconds(secs)
            }
            times.append(last ?? Date())
        }
        return times
    }

    /// Scheduled departure and arrival dates from the journey's timetable.
    private static func scheduledTimes(for journey: Journey) -> (departure: Date?, arrival: Date?) {
        let timetable = journey.journeyTimetable
        let depSec = timetable.first.flatMap { $0.departureSeconds() ?? $0.arrivalSeconds() }
        let arrSec = timetable.last.flatMap { $0.arrivalSeconds() ?? $0.departureSeconds() }
        return (depSec.map(dateFromRailSeconds), arrSec.map(dateFromRailSeconds))
    }

    private static func dateFromRailSeconds(_ seconds: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = seconds / 3600
        comps.minute = (seconds % 3600) / 60
        comps.second = seconds % 60
        if comps.hour! >= 24 {
            comps.hour! -= 24
            if let d = cal.date(from: comps) {
                return cal.date(byAdding: .day, value: 1, to: d) ?? d
            }
        }
        return cal.date(from: comps) ?? Date()
    }
}
