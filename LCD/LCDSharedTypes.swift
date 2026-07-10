import Foundation
import SwiftUI
import ActivityKit

// MARK: - Shared types needed by both the app target and the widget extension.
// These must match the definitions in the main app exactly.

// MARK: - Live Activity Attributes

struct TrainJourneyAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var currentStationIndex: Int?
        var nextStationName: String
        var nextStationNameEn: String
        var delayMinutes: Int
        var estimatedArrivalTimestamp: Double
        var statusRaw: String
        var trackingModeRaw: String
        var lastRefreshTimestamp: Double
        // Scheduled departure from the boarding station (delay-adjusted).
        // Together with the arrival timestamp this drives timer-based views
        // that keep advancing while the app is suspended (no GPS needed).
        var departureTimestamp: Double
        // Delay-adjusted scheduled window of the current inter-station
        // segment; drives the self-advancing next-station countdown that
        // stays live even when no further updates arrive.
        var segmentStartTimestamp: Double
        var nextStationArrivalTimestamp: Double

        var status: TrainPositionStatus {
            TrainPositionStatus(rawValue: statusRaw) ?? .onTime
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
    let stationStops: [Bool]
    // Scheduled time at each station (epoch seconds, no delay applied;
    // skipped stations carry the previous stop's time). Static for the whole
    // journey, so self-updating views can lean on it without updates.
    let stationTimes: [Double]
    let refreshURLString: String
}

// MARK: - Train Position Status (widget-side mirror)

enum TrainPositionStatus: String, Codable {
    case onTime = "onTime"
    case delayed = "delayed"
    case arrived = "arrived"
    case notStarted = "notStarted"
    case suspended = "suspended"
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        if hex.count == 6 {
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        } else {
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
