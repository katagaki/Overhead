import Foundation
import SwiftUI

// MARK: - Station

public struct Station: Identifiable, Codable, Hashable {
    public let id: String          // e.g. "odpt.Station:JR-East.ChuoRapid.Shinjuku"
    public let name: String        // Japanese name
    public let nameEn: String      // English/Romaji name
    public let nameKo: String      // Korean name
    public let nameZhHans: String  // Simplified Chinese name
    public let nameZhHant: String  // Traditional Chinese name
    public let stationCode: String // e.g. "JC05"
    public let latitude: Double?
    public let longitude: Double?

    /// Convenience initializer for cases that don't have multilingual data
    public init(id: String, name: String, nameEn: String, nameKo: String = "", nameZhHans: String = "", nameZhHant: String = "", stationCode: String, latitude: Double?, longitude: Double?) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.nameKo = nameKo
        self.nameZhHans = nameZhHans
        self.nameZhHant = nameZhHant
        self.stationCode = stationCode
        self.latitude = latitude
        self.longitude = longitude
    }

    public var displayCode: String {
        stationCode.isEmpty ? "" : stationCode
    }

    /// Returns the station name for the user's current language
    public var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        switch lang {
        case "en": return nameEn.isEmpty ? name : nameEn
        case "ko": return nameKo.isEmpty ? name : nameKo
        case "zh":
            let script = Locale.current.language.script?.identifier ?? ""
            if script == "Hant" {
                return nameZhHant.isEmpty ? name : nameZhHant
            }
            return nameZhHans.isEmpty ? name : nameZhHans
        default: return name
        }
    }
}

// MARK: - Train Line

public struct TrainLine: Identifiable, Codable, Hashable {
    public let id: String           // e.g. "odpt.Railway:JR-East.ChuoRapid"
    public let name: String
    public let nameEn: String
    public let nameKo: String
    public let nameZhHans: String
    public let nameZhHant: String
    public let operatorId: String   // e.g. "odpt.Operator:JR-East"
    public let stations: [Station]
    public let colorHex: String     // Primary accent color

    /// Convenience initializer for cases that don't have multilingual data
    public init(id: String, name: String, nameEn: String, nameKo: String = "", nameZhHans: String = "", nameZhHant: String = "", operatorId: String, stations: [Station], colorHex: String) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.nameKo = nameKo
        self.nameZhHans = nameZhHans
        self.nameZhHant = nameZhHant
        self.operatorId = operatorId
        self.stations = stations
        self.colorHex = colorHex
    }

    public var color: Color {
        Color(hex: colorHex)
    }

    /// Line symbol prefix derived from station codes (e.g. "JC", "G", "C")
    public var lineSymbol: String {
        // Try to extract from first station with a code
        if let station = stations.first(where: { !$0.stationCode.isEmpty }) {
            let letters = station.stationCode.prefix(while: \.isLetter)
            if !letters.isEmpty { return String(letters) }
        }
        // Fallback mapping from railway ID
        return Self.symbolForRailwayId[id] ?? ""
    }

    /// Whether this line uses JR-style badges (rounded rectangle)
    public var isJR: Bool {
        lineSymbol.hasPrefix("J")
    }

    /// Comprehensive fallback mapping from railway ID to line symbol
    private static let symbolForRailwayId: [String: String] = [
        // JR East
        "odpt.Railway:JR-East.Yamanote": "JY",
        "odpt.Railway:JR-East.KeihinTohoku": "JK",
        "odpt.Railway:JR-East.ChuoRapid": "JC",
        "odpt.Railway:JR-East.ChuoSobuLocal": "JB",
        "odpt.Railway:JR-East.SaikyoKawagoe": "JA",
        "odpt.Railway:JR-East.Keiyo": "JE",
        "odpt.Railway:JR-East.Yokohama": "JH",
        "odpt.Railway:JR-East.Nambu": "JN",
        "odpt.Railway:JR-East.YokosukaSobu": "JO",
        "odpt.Railway:JR-East.Tokaido": "JT",
        "odpt.Railway:JR-East.Utsunomiya": "JU",
        "odpt.Railway:JR-East.Takasaki": "JU",
        "odpt.Railway:JR-East.ShonanShinjuku": "JS",
        "odpt.Railway:JR-East.JobanRapid": "JJ",
        "odpt.Railway:JR-East.JobanLocal": "JL",
        "odpt.Railway:JR-East.Musashino": "JM",
        "odpt.Railway:JR-East.Tsurumi": "JI",
        "odpt.Railway:JR-East.Ome": "JC",
        "odpt.Railway:JR-East.Itsukaichi": "JC",
        "odpt.Railway:JR-East.NaritaExpress": "JO",
        "odpt.Railway:JR-East.Uchibo": "JR",
        "odpt.Railway:JR-East.Sotobo": "JR",
        "odpt.Railway:JR-East.Sagami": "JR",
        // Tokyo Metro
        "odpt.Railway:TokyoMetro.Ginza": "G",
        "odpt.Railway:TokyoMetro.Marunouchi": "M",
        "odpt.Railway:TokyoMetro.MarunouchiBranch": "Mb",
        "odpt.Railway:TokyoMetro.Hibiya": "H",
        "odpt.Railway:TokyoMetro.Tozai": "T",
        "odpt.Railway:TokyoMetro.Chiyoda": "C",
        "odpt.Railway:TokyoMetro.Yurakucho": "Y",
        "odpt.Railway:TokyoMetro.Hanzomon": "Z",
        "odpt.Railway:TokyoMetro.Namboku": "N",
        "odpt.Railway:TokyoMetro.Fukutoshin": "F",
        // Toei
        "odpt.Railway:Toei.Asakusa": "A",
        "odpt.Railway:Toei.Mita": "I",
        "odpt.Railway:Toei.Shinjuku": "S",
        "odpt.Railway:Toei.Oedo": "E",
        "odpt.Railway:Toei.NipporiToneri": "NT",
        "odpt.Railway:Toei.Toden": "SA",
    ]

    /// Returns the line name for the user's current language
    public var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        switch lang {
        case "en": return nameEn.isEmpty ? name : nameEn
        case "ko": return nameKo.isEmpty ? name : nameKo
        case "zh":
            let script = Locale.current.language.script?.identifier ?? ""
            if script == "Hant" {
                return nameZhHant.isEmpty ? name : nameZhHant
            }
            return nameZhHans.isEmpty ? name : nameZhHans
        default: return name
        }
    }
}

// MARK: - Timetable Entry

public struct TimetableEntry: Identifiable, Codable {
    public let id: String
    public let stationId: String
    public let arrivalTime: String?   // "HH:mm" — may be >24:00
    public let departureTime: String? // "HH:mm"

    public init(id: String, stationId: String, arrivalTime: String?, departureTime: String?) {
        self.id = id
        self.stationId = stationId
        self.arrivalTime = arrivalTime
        self.departureTime = departureTime
    }

    /// Parse a Japanese rail time string (supports 25:30 etc.)
    public func arrivalSeconds() -> Int? {
        guard let t = arrivalTime else { return nil }
        return Self.parseRailTime(t)
    }

    public func departureSeconds() -> Int? {
        guard let t = departureTime else { return nil }
        return Self.parseRailTime(t)
    }

    /// Parses "HH:mm" where HH can exceed 23 (Japanese rail convention).
    /// Returns seconds since midnight of the service day.
    public static func parseRailTime(_ timeStr: String) -> Int? {
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return nil }
        return h * 3600 + m * 60
    }
}

// MARK: - Train Service

public struct TrainService: Identifiable, Codable {
    public let id: String              // Train number / service ID
    public let lineId: String
    public let trainType: TrainType
    public let direction: Direction
    public let timetable: [TimetableEntry]
    public let destinationStationId: String

    public init(id: String, lineId: String, trainType: TrainType, direction: Direction, timetable: [TimetableEntry], destinationStationId: String) {
        self.id = id
        self.lineId = lineId
        self.trainType = trainType
        self.direction = direction
        self.timetable = timetable
        self.destinationStationId = destinationStationId
    }

    public enum TrainType: String, Codable {
        case local = "Local"
        case rapid = "Rapid"
        case express = "Express"
        case limitedExpress = "LimitedExpress"
        case commuterRapid = "CommuterRapid"
        case specialRapid = "SpecialRapid"

        public var displayName: String { rawValue }
        public var displayNameJa: String {
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

    public enum Direction: String, Codable {
        case inbound = "Inbound"
        case outbound = "Outbound"
    }
}

// MARK: - Station Departure

public struct StationDeparture: Identifiable, Codable {
    public let id: String
    public let departureTime: String       // "HH:mm"
    public let trainType: TrainService.TrainType
    public let destinationName: String     // Localized destination name
    public let destinationNameEn: String
    public let trainNumber: String
    public let isLast: Bool

    public init(id: String, departureTime: String, trainType: TrainService.TrainType, destinationName: String, destinationNameEn: String, trainNumber: String, isLast: Bool) {
        self.id = id
        self.departureTime = departureTime
        self.trainType = trainType
        self.destinationName = destinationName
        self.destinationNameEn = destinationNameEn
        self.trainNumber = trainNumber
        self.isLast = isLast
    }

    public var localizedDestination: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        switch lang {
        case "en": return destinationNameEn.isEmpty ? destinationName : destinationNameEn
        default: return destinationName
        }
    }
}

// MARK: - Station Timetable

public struct StationTimetableData: Codable {
    public let stationId: String
    public let railDirection: String
    public let railDirectionName: String
    public let railDirectionNameEn: String
    public let departures: [StationDeparture]

    public init(stationId: String, railDirection: String, railDirectionName: String, railDirectionNameEn: String, departures: [StationDeparture]) {
        self.stationId = stationId
        self.railDirection = railDirection
        self.railDirectionName = railDirectionName
        self.railDirectionNameEn = railDirectionNameEn
        self.departures = departures
    }

    public var localizedDirectionName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        switch lang {
        case "en": return railDirectionNameEn.isEmpty ? railDirectionName : railDirectionNameEn
        default: return railDirectionName
        }
    }
}

// MARK: - Delay Info

public struct DelayInfo: Codable {
    public let lineId: String
    public let delayMinutes: Int
    public let cause: String?
    public let updatedAt: Date

    public init(lineId: String, delayMinutes: Int, cause: String?, updatedAt: Date) {
        self.lineId = lineId
        self.delayMinutes = delayMinutes
        self.cause = cause
        self.updatedAt = updatedAt
    }

    public var isDelayed: Bool { delayMinutes > 0 }
}

// MARK: - Journey

public struct Journey: Identifiable, Codable {
    public let id: UUID
    public let service: TrainService
    public let line: TrainLine
    public let boardingStationId: String
    public let alightingStationId: String
    public let startedAt: Date

    public init(id: UUID, service: TrainService, line: TrainLine, boardingStationId: String, alightingStationId: String, startedAt: Date) {
        self.id = id
        self.service = service
        self.line = line
        self.boardingStationId = boardingStationId
        self.alightingStationId = alightingStationId
        self.startedAt = startedAt
    }

    /// Subset of stations the user travels through
    public var journeyStations: [Station] {
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
    public var journeyTimetable: [TimetableEntry] {
        let stationIds = Set(journeyStations.map(\.id))
        return service.timetable.filter { stationIds.contains($0.stationId) }
    }
}

// MARK: - Position State

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

// MARK: - Color Extension

public extension Color {
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
