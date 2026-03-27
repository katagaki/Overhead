import Foundation
import SwiftUI

// MARK: - Station

struct Station: Identifiable, Codable, Hashable {
    let id: String          // e.g. "odpt.Station:JR-East.ChuoRapid.Shinjuku"
    let name: String        // Japanese name
    let nameEn: String      // English/Romaji name
    let stationCode: String // e.g. "JC05"
    let latitude: Double?
    let longitude: Double?

    var displayCode: String {
        stationCode.isEmpty ? "" : stationCode
    }
}

// MARK: - Train Line

struct TrainLine: Identifiable, Codable, Hashable {
    let id: String           // e.g. "odpt.Railway:JR-East.ChuoRapid"
    let name: String
    let nameEn: String
    let operatorId: String   // e.g. "odpt.Operator:JR-East"
    let stations: [Station]
    let colorHex: String     // Primary accent color

    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Timetable Entry

struct TimetableEntry: Identifiable, Codable {
    let id: String
    let stationId: String
    let arrivalTime: String?   // "HH:mm" — may be >24:00
    let departureTime: String? // "HH:mm"

    /// Parse a Japanese rail time string (supports 25:30 etc.)
    func arrivalSeconds() -> Int? {
        guard let t = arrivalTime else { return nil }
        return Self.parseRailTime(t)
    }

    func departureSeconds() -> Int? {
        guard let t = departureTime else { return nil }
        return Self.parseRailTime(t)
    }

    /// Parses "HH:mm" where HH can exceed 23 (Japanese rail convention).
    /// Returns seconds since midnight of the service day.
    static func parseRailTime(_ timeStr: String) -> Int? {
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return nil }
        return h * 3600 + m * 60
    }
}

// MARK: - Train Service

struct TrainService: Identifiable, Codable {
    let id: String              // Train number / service ID
    let lineId: String
    let trainType: TrainType
    let direction: Direction
    let timetable: [TimetableEntry]
    let destinationStationId: String

    enum TrainType: String, Codable {
        case local = "Local"
        case rapid = "Rapid"
        case express = "Express"
        case limitedExpress = "LimitedExpress"
        case commuterRapid = "CommuterRapid"
        case specialRapid = "SpecialRapid"

        var displayName: String { rawValue }
        var displayNameJa: String {
            switch self {
            case .local: return "各停"
            case .rapid: return "快速"
            case .express: return "急行"
            case .limitedExpress: return "特急"
            case .commuterRapid: return "通勤快速"
            case .specialRapid: return "特別快速"
            }
        }
    }

    enum Direction: String, Codable {
        case inbound = "Inbound"
        case outbound = "Outbound"
    }
}

// MARK: - Delay Info

struct DelayInfo: Codable {
    let lineId: String
    let delayMinutes: Int
    let cause: String?
    let updatedAt: Date

    var isDelayed: Bool { delayMinutes > 0 }
}

// MARK: - Journey

struct Journey: Identifiable, Codable {
    let id: UUID
    let service: TrainService
    let line: TrainLine
    let boardingStationId: String
    let alightingStationId: String
    let startedAt: Date

    /// Subset of stations the user travels through
    var journeyStations: [Station] {
        guard let startIdx = line.stations.firstIndex(where: { $0.id == boardingStationId }),
              let endIdx = line.stations.firstIndex(where: { $0.id == alightingStationId }) else {
            return []
        }
        if startIdx <= endIdx {
            return Array(line.stations[startIdx...endIdx])
        } else {
            return Array(line.stations[endIdx...startIdx].reversed())
        }
    }

    /// Subset of timetable entries for this journey
    var journeyTimetable: [TimetableEntry] {
        let stationIds = Set(journeyStations.map(\.id))
        return service.timetable.filter { stationIds.contains($0.stationId) }
    }
}

// MARK: - Position State

struct TrainPositionState: Codable {
    let progress: Double           // 0.0 ... 1.0 along the full journey
    let segmentFrom: Int           // Index into journeyStations
    let segmentTo: Int
    let segmentProgress: Double    // 0.0 ... 1.0 within current segment
    let currentStationIndex: Int?  // Non-nil if dwelling at a station
    let nextStationName: String
    let nextStationNameEn: String
    let delayMinutes: Int
    let estimatedArrival: Date     // ETA at final destination
    let status: Status
    let trackingModeRaw: String    // "GPS", "Timetable", or "Blended"

    var isTimetableMode: Bool {
        trackingModeRaw == "Timetable"
    }

    var isBlendedMode: Bool {
        trackingModeRaw == "Blended"
    }

    enum Status: String, Codable {
        case onTime = "onTime"
        case delayed = "delayed"
        case arrived = "arrived"
        case notStarted = "notStarted"
        case suspended = "suspended"
    }
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
