import Foundation
import ActivityKit
import SwiftUI

// MARK: - Live Activity Attributes

struct TrainJourneyAttributes: ActivityAttributes {
    /// Dynamic state updated during the journey
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var currentStationIndex: Int?
        var nextStationName: String
        var nextStationNameEn: String
        var delayMinutes: Int
        var estimatedArrivalTimestamp: Double
        var statusRaw: String
        var trackingModeRaw: String          // "GPS", "Timetable", "Blended"
        var lastRefreshTimestamp: Double      // When delay data was last fetched

        var status: TrainPositionState.Status {
            TrainPositionState.Status(rawValue: statusRaw) ?? .onTime
        }

        var isDelayed: Bool { delayMinutes > 0 }

        var isTimetableMode: Bool { trackingModeRaw == "Timetable" }

        var estimatedArrival: Date {
            Date(timeIntervalSince1970: estimatedArrivalTimestamp)
        }

        var lastRefresh: Date {
            Date(timeIntervalSince1970: lastRefreshTimestamp)
        }
    }

    // Static journey info (doesn't change during the activity)
    let lineName: String
    let lineNameEn: String
    let lineColorHex: String
    let originName: String
    let originNameEn: String
    let destinationName: String
    let destinationNameEn: String
    let trainType: String
    let stationNames: [String]
    let stationNamesEn: [String]
    let stationCount: Int
    /// URL scheme for the refresh deep link
    let refreshURLString: String
}

// MARK: - Live Activity Manager

final class LiveActivityManager {

    static let shared = LiveActivityManager()
    private init() {}

    /// The URL scheme that the Live Activity refresh button opens
    static let refreshURLScheme = "overhead://refresh-delay"

    private var currentActivity: Activity<TrainJourneyAttributes>?
    private var lastDelayFetchTime = Date()

    func startActivity(
        journey: Journey,
        positionState: TrainPositionState,
        lineColorHex: String
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let stations = journey.journeyStations

        let attributes = TrainJourneyAttributes(
            lineName: journey.line.name,
            lineNameEn: journey.line.nameEn,
            lineColorHex: lineColorHex,
            originName: stations.first?.name ?? "",
            originNameEn: stations.first?.nameEn ?? "",
            destinationName: stations.last?.name ?? "",
            destinationNameEn: stations.last?.nameEn ?? "",
            trainType: journey.service.trainType.displayNameJa,
            stationNames: stations.map(\.name),
            stationNamesEn: stations.map(\.nameEn),
            stationCount: stations.count,
            refreshURLString: Self.refreshURLScheme
        )

        lastDelayFetchTime = Date()
        let state = contentState(from: positionState)

        do {
            let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(120))
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
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(120))

        Task {
            await activity.update(content)
        }
    }

    /// Called after a successful delay data refresh
    func markDelayRefreshed() {
        lastDelayFetchTime = Date()
    }

    func endActivity() {
        guard let activity = currentActivity else { return }
        let finalState = TrainJourneyAttributes.ContentState(
            progress: 1.0,
            currentStationIndex: nil,
            nextStationName: "",
            nextStationNameEn: "",
            delayMinutes: 0,
            estimatedArrivalTimestamp: Date().timeIntervalSince1970,
            statusRaw: TrainPositionState.Status.arrived.rawValue,
            trackingModeRaw: "Timetable",
            lastRefreshTimestamp: Date().timeIntervalSince1970
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        Task {
            await activity.end(content, dismissalPolicy: .after(.now + 300))
        }
        currentActivity = nil
    }

    private func contentState(from state: TrainPositionState) -> TrainJourneyAttributes.ContentState {
        .init(
            progress: state.progress,
            currentStationIndex: state.currentStationIndex,
            nextStationName: state.nextStationName,
            nextStationNameEn: state.nextStationNameEn,
            delayMinutes: state.delayMinutes,
            estimatedArrivalTimestamp: state.estimatedArrival.timeIntervalSince1970,
            statusRaw: state.status.rawValue,
            trackingModeRaw: state.trackingModeRaw,
            lastRefreshTimestamp: lastDelayFetchTime.timeIntervalSince1970
        )
    }
}
