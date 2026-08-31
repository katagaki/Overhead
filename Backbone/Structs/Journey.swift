import Foundation

public struct Journey: Identifiable, Codable {
    public let id: UUID
    public let service: TrainService
    public let line: TrainLine
    public let boardingStationId: String
    public let alightingStationId: String
    public let startedAt: Date
    /// Transfer (乗り換え) stations on a multi-leg itinerary.
    public let transferStationIds: [String]
    /// False when the timetable was ignored — position comes from GPS/manual flipping.
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

    /// 行き先 as riders see it — an off-line through destination wins over the
    /// on-line terminus — in every language the data carries.
    public var destinationNames: LocalizedText {
        service.throughDestination ?? destinationStation?.names ?? LocalizedText(ja: "")
    }

    public var destinationNameJa: String { destinationNames.ja }

    public var destinationNameEn: String {
        let names = destinationNames
        return names.en.isEmpty ? names.ja : names.en
    }

    public var destinationStation: Station? {
        line.stations.first { $0.id == service.destinationStationId } ?? journeyStations.last
    }

    public var journeyStations: [Station] {
        guard let startIdx = line.stations.firstIndex(where: { $0.id == boardingStationId }),
              let endIdx = line.stations.firstIndex(where: { $0.id == alightingStationId }) else {
            return []
        }

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
        if let from = service.timetable.firstIndex(where: { $0.stationId == boardingStationId }),
           let to = service.timetable[from...].firstIndex(where: { $0.stationId == alightingStationId }) {
            return Array(service.timetable[from...to].filter { stationIds.contains($0.stationId) })
        }
        return service.timetable.filter { stationIds.contains($0.stationId) }
    }
}
