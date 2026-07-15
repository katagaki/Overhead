import Foundation
import Backbone

// MARK: - Custom Journey Builder
//
// Turns a CustomLine ride (boarding → alighting) into a Backbone `TrainService`
// so the existing JourneyView / position engine / Live Activity can run it
// unchanged. Scheduled lines generate clock times from their headway pattern;
// scheduleless lines produce a timeless service (GPS or manual position).

enum CustomJourneyBuilder {

    /// The stations from `fromId` to `toId` in travel order, plus the hop
    /// minutes between each consecutive pair, or nil if the ids aren't on the line.
    private static func travelPlan(
        line: CustomLine, fromId: String, toId: String
    ) -> (stations: [Station], hops: [Double])? {
        let stations = line.backboneStations()
        guard let fromIdx = stations.firstIndex(where: { $0.id == fromId }),
              let toIdx = stations.firstIndex(where: { $0.id == toId }),
              fromIdx != toIdx else { return nil }

        if fromIdx < toIdx {
            let slice = Array(stations[fromIdx...toIdx])
            let hops = Array(line.hopMinutes[fromIdx..<toIdx])
            return (slice, hops)
        } else {
            let slice = Array(stations[toIdx...fromIdx].reversed())
            // Descending: traverse the same gaps in reverse order.
            let hops = Array(line.hopMinutes[toIdx..<fromIdx].reversed())
            return (slice, hops)
        }
    }

    /// A ride with clock times, boarding at the next headway departure ≥ now.
    /// Returns nil when the line has no schedule for the current calendar.
    static func scheduledService(
        line: CustomLine, fromId: String, toId: String, at date: Date = Date()
    ) -> TrainService? {
        guard let timetable = line.timetable,
              let plan = travelPlan(line: line, fromId: fromId, toId: toId)
        else { return nil }

        let calendar = ScheduleCalendar.current(at: date)
        let pattern = timetable.pattern(for: calendar)
        guard let first = parseMinutes(pattern.firstDeparture),
              let last = parseMinutes(pattern.lastDeparture),
              pattern.headwayMinutes > 0
        else { return nil }

        let nowMin = jstMinutes(from: date)
        var departure = first
        if nowMin > first {
            let steps = Int(ceil(Double(nowMin - first) / Double(pattern.headwayMinutes)))
            departure = min(first + steps * pattern.headwayMinutes, last)
        }

        // Cumulative offsets (minutes) from the boarding station.
        var offsets: [Int] = [0]
        var running = 0.0
        for hop in plan.hops {
            running += hop
            offsets.append(Int(running.rounded()))
        }

        let serviceId = "custom.\(line.id).\(fromId).\(toId).\(departure)"
        let entries = plan.stations.enumerated().map { index, station in
            let minute = departure + offsets[index]
            let time = railTimeString(minute)
            return TimetableEntry(
                id: "\(serviceId)_\(index)",
                stationId: station.id,
                arrivalTime: index == 0 ? nil : time,
                departureTime: index == plan.stations.count - 1 ? nil : time
            )
        }

        return TrainService(
            id: serviceId,
            lineId: line.id,
            trainType: .local,
            direction: .outbound,
            timetable: entries,
            destinationStationId: toId
        )
    }

    /// A timeless ride (no clock times) — position comes from GPS or manual
    /// station flipping.
    static func untimedService(line: CustomLine, fromId: String, toId: String) -> TrainService? {
        guard let plan = travelPlan(line: line, fromId: fromId, toId: toId) else { return nil }
        let serviceId = "custom.untimed.\(line.id).\(fromId).\(toId)"
        let entries = plan.stations.enumerated().map { index, station in
            TimetableEntry(
                id: "\(serviceId)_\(index)",
                stationId: station.id,
                arrivalTime: nil,
                departureTime: nil
            )
        }
        return TrainService(
            id: serviceId,
            lineId: line.id,
            trainType: .local,
            direction: .outbound,
            timetable: entries,
            destinationStationId: toId
        )
    }

    // MARK: Helpers

    private static func parseMinutes(_ hhmm: String) -> Int? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }

    private static func railTimeString(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    private static func jstMinutes(from date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let comps = cal.dateComponents([.hour, .minute], from: date)
        let raw = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        // Trains published as 24:00+ belong to the previous service day.
        return raw < 4 * 60 ? raw + 24 * 60 : raw
    }
}
