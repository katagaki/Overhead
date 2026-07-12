import Foundation

public struct TrainPositionState: Codable {
    public let progress: Double           // 0.0 ... 1.0 along the full journey
    public let segmentFrom: Int           // Index into journeyStations
    public let segmentTo: Int
    public let segmentProgress: Double    // 0.0 ... 1.0 within current segment
    public let currentStationIndex: Int?  // Non-nil if dwelling at a station
    public let nextStationName: String
    public let nextStationNameEn: String
    public let delayMinutes: Int
    public let estimatedArrival: Date     // ETA at final destination
    public let status: Status
    public let trackingModeRaw: String    // "GPS", "Timetable", or "Blended"

    public init(progress: Double, segmentFrom: Int, segmentTo: Int, segmentProgress: Double, currentStationIndex: Int?, nextStationName: String, nextStationNameEn: String, delayMinutes: Int, estimatedArrival: Date, status: Status, trackingModeRaw: String) {
        self.progress = progress
        self.segmentFrom = segmentFrom
        self.segmentTo = segmentTo
        self.segmentProgress = segmentProgress
        self.currentStationIndex = currentStationIndex
        self.nextStationName = nextStationName
        self.nextStationNameEn = nextStationNameEn
        self.delayMinutes = delayMinutes
        self.estimatedArrival = estimatedArrival
        self.status = status
        self.trackingModeRaw = trackingModeRaw
    }

    public var isTimetableMode: Bool {
        trackingModeRaw == "Timetable"
    }

    public var isBlendedMode: Bool {
        trackingModeRaw == "Blended"
    }

    public enum Status: String, Codable {
        case onTime = "onTime"
        case delayed = "delayed"
        case arrived = "arrived"
        case notStarted = "notStarted"
        case suspended = "suspended"
    }
}
