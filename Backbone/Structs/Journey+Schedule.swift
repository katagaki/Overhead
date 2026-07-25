import Foundation

public extension Journey {

    /// Scheduled time per station (arrival else departure); skipped stations carry the previous time.
    var scheduledStationTimes: [Date] {
        let timetable = journeyTimetable
        var times: [Date] = []
        var last: Date?
        for station in journeyStations {
            if let entry = timetable.first(where: { $0.stationId == station.id }),
               let secs = entry.arrivalSeconds() ?? entry.departureSeconds() {
                last = Journey.railDate(secs)
            }
            times.append(last ?? Date())
        }
        return times
    }

    /// Scheduled departure and arrival dates from the journey's timetable.
    var scheduledTimes: (departure: Date?, arrival: Date?) {
        let timetable = journeyTimetable
        let depSec = timetable.first.flatMap { $0.departureSeconds() ?? $0.arrivalSeconds() }
        let arrSec = timetable.last.flatMap { $0.arrivalSeconds() ?? $0.departureSeconds() }
        return (depSec.map(Journey.railDate), arrSec.map(Journey.railDate))
    }

    /// Today's JST date for a rail-time offset; 24:00+ rolls into tomorrow.
    static func railDate(_ seconds: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = seconds / 3600
        comps.minute = (seconds % 3600) / 60
        comps.second = seconds % 60
        if comps.hour! >= 24 {
            comps.hour! -= 24
            if let d = cal.date(from: comps) {
                return cal.date(byAdding: .day, value: 1, to: d) ?? d
            }
        }
        return cal.date(from: comps) ?? Date()
    }
}
