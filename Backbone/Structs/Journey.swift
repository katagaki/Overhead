import Foundation

public struct Journey: Identifiable, Codable {
    public let id: UUID
    public let service: TrainService
    public let line: TrainLine
    public let boardingStationId: String
    public let alightingStationId: String
    public let startedAt: Date
    /// Stations where the passenger changes trains (乗り換え) on a multi-leg
    /// itinerary. Empty for single-ride and through (直通) journeys.
    public let transferStationIds: [String]

    public init(id: UUID, service: TrainService, line: TrainLine, boardingStationId: String, alightingStationId: String, startedAt: Date, transferStationIds: [String] = []) {
        self.id = id
        self.service = service
        self.line = line
        self.boardingStationId = boardingStationId
        self.alightingStationId = alightingStationId
        self.startedAt = startedAt
        self.transferStationIds = transferStationIds
    }

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

    public var journeyTimetable: [TimetableEntry] {
        let stationIds = Set(journeyStations.map(\.id))
        return service.timetable.filter { stationIds.contains($0.stationId) }
    }
}
