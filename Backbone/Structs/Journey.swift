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
    /// False for journeys planned while ignoring the timetable — the service's
    /// entries carry no times, so position comes from GPS or manual flipping.
    public let hasSchedule: Bool

    public init(id: UUID, service: TrainService, line: TrainLine, boardingStationId: String, alightingStationId: String, startedAt: Date, transferStationIds: [String] = [], hasSchedule: Bool = true) {
        self.id = id
        self.service = service
        self.line = line
        self.boardingStationId = boardingStationId
        self.alightingStationId = alightingStationId
        self.startedAt = startedAt
        self.transferStationIds = transferStationIds
        self.hasSchedule = hasSchedule
    }

    public var journeyStations: [Station] {
        guard let startIdx = line.stations.firstIndex(where: { $0.id == boardingStationId }),
              let endIdx = line.stations.firstIndex(where: { $0.id == alightingStationId }) else {
            return []
        }

        // Follow the service's travel direction — on a loop line the plain
        // array slice can chart the wrong way around (東京→品川 via 神田
        // while the train runs via 有楽町), so walk from the boarding
        // station toward the service's next stop, wrapping at the ends.
        let stops = service.timetable
        if let svcFrom = stops.firstIndex(where: { $0.stationId == boardingStationId }),
           svcFrom + 1 < stops.count,
           let nextIdx = line.stations.firstIndex(where: { $0.id == stops[svcFrom + 1].stationId }),
           nextIdx != startIdx {
            let count = line.stations.count
            let ascending = (nextIdx - startIdx + count) % count
                <= (startIdx - nextIdx + count) % count
            let step = ascending ? 1 : -1
            var path = [line.stations[startIdx]]
            var idx = startIdx
            for _ in 0..<count {
                idx = ((idx + step) % count + count) % count
                path.append(line.stations[idx])
                if idx == endIdx { return path }
            }
        }

        if startIdx <= endIdx {
            return Array(line.stations[startIdx...endIdx])
        } else {
            return Array(line.stations[endIdx...startIdx].reversed())
        }
    }

    public var journeyTimetable: [TimetableEntry] {
        let stationIds = Set(journeyStations.map(\.id))
        // Slice the run between boarding and alighting so a loop service
        // that visited a path station before boarding can't leak that
        // earlier entry.
        if let from = service.timetable.firstIndex(where: { $0.stationId == boardingStationId }),
           let to = service.timetable[from...].firstIndex(where: { $0.stationId == alightingStationId }) {
            return Array(service.timetable[from...to].filter { stationIds.contains($0.stationId) })
        }
        return service.timetable.filter { stationIds.contains($0.stationId) }
    }
}
