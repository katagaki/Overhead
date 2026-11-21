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
                last = railDate(secs)
            }
            times.append(last ?? RailClock.now)
        }
        return times
    }

    /// Scheduled departure and arrival dates from the journey's timetable.
    var scheduledTimes: (departure: Date?, arrival: Date?) {
        let timetable = journeyTimetable
        let depSec = timetable.first.flatMap { $0.departureSeconds() ?? $0.arrivalSeconds() }
        let arrSec = timetable.last.flatMap { $0.arrivalSeconds() ?? $0.departureSeconds() }
        return (depSec.map(railDate), arrSec.map(railDate))
    }

    func railDate(_ seconds: Int) -> Date {
        serviceDay.date(atRailSeconds: seconds)
    }

    func railSeconds(at date: Date) -> Int {
        serviceDay.railSeconds(at: date)
    }
}
