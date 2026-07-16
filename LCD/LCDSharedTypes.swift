import Foundation
import SwiftUI
import ActivityKit

// MARK: - Shared types (must match the main app's definitions)

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
        var trackingModeRaw: String
        var lastRefreshTimestamp: Double
        // Delay-adjusted; drives timer-based views while the app is suspended.
        var departureTimestamp: Double
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
    let stationStops: [Bool]
    // Epoch seconds, no delay; skipped stations carry the previous stop's time.
    let stationTimes: [Double]
    // Empty string where a station has no code.
    let stationCodes: [String]
    // Each station keeps its own line's color (through-services differ).
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

    /// Riders are still on the arriving leg at the transfer station itself;
    /// the new leg takes over once the train departs it.
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
