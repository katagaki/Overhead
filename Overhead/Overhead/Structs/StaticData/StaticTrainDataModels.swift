import Foundation

// MARK: - Static Train Data Models
//
// Bundled train line data sourced from publicly available information
// (operator websites, published timetables and route maps), so the app
// works without relying on the unreliable transit API.
//
// Timetables are encoded as service patterns (first/last train plus
// time-of-day headway bands) per direction and per calendar, from which
// a full day of departures is generated for every station on the line.

// MARK: - Schedule Calendar

enum ScheduleCalendar: String, Codable, CaseIterable {
    case weekday = "Weekday"
    case saturdayHoliday = "SaturdayHoliday"

    /// The calendar in effect right now in Japan.
    static func current(at date: Date = Date()) -> ScheduleCalendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let weekday = cal.component(.weekday, from: date)
        // 1 = Sunday, 7 = Saturday
        return (weekday == 1 || weekday == 7) ? .saturdayHoliday : .weekday
    }
}

// MARK: - Delay Check Info

/// Where and how to check for delays on a line.
struct DelayCheckInfo: Codable, Hashable {
    /// Official service status page (Japanese)
    let statusPageURL: String
    /// Official service status page (English)
    let statusPageURLEn: String
    /// Official service information account on X (formerly Twitter), if any
    let xAccount: String?
    /// How to check for delays, in Japanese
    let checkMethodJa: String
    /// How to check for delays, in English
    let checkMethodEn: String

    var localizedCheckMethod: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "ja" ? checkMethodJa : checkMethodEn
    }

    var localizedStatusPageURL: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "ja" ? statusPageURL : statusPageURLEn
    }
}

// MARK: - Headway Band

/// A period of the day with a constant interval between trains.
/// Applies from `from` until the next band starts (or the last train).
struct HeadwayBand: Codable, Hashable {
    let from: String          // "HH:mm"
    let headwayMinutes: Double
}

// MARK: - Service Pattern

/// Describes a full day of service in one direction for one calendar.
struct ServicePattern: Codable, Hashable {
    let firstDeparture: String  // "HH:mm" at the origin of the direction
    let lastDeparture: String   // "HH:mm", may exceed 24:00
    let bands: [HeadwayBand]    // ordered by time
    let trainType: TrainService.TrainType

    init(first: String, last: String, bands: [HeadwayBand], trainType: TrainService.TrainType = .local) {
        self.firstDeparture = first
        self.lastDeparture = last
        self.bands = bands
        self.trainType = trainType
    }
}

// MARK: - Line Direction

struct StaticLineDirection: Codable, Hashable {
    let id: String        // e.g. "static.RailDirection:TokyoMetro.Ginza.Asakusa"
    let nameJa: String    // e.g. "浅草方面"
    let nameEn: String    // e.g. "For Asakusa"
    /// true: trains run through `stations` in array order; false: reversed
    let isAscending: Bool
    let weekday: ServicePattern
    let saturdayHoliday: ServicePattern

    func pattern(for calendar: ScheduleCalendar) -> ServicePattern {
        calendar == .weekday ? weekday : saturdayHoliday
    }
}

// MARK: - Through Service

/// A through-running connection (直通運転): trains that continue past a
/// junction station onto another line's or operator's tracks.
struct ThroughService: Codable, Hashable {

    /// Which travel direction of this line the through service extends.
    enum LineEnd: String, Codable {
        /// Trains travelling in stations-array order continue on
        case ascending
        /// Trains travelling in reverse array order continue on
        case descending
    }

    /// Station on this line where trains leave for the connecting line
    let junctionStationId: String
    let end: LineEnd
    let lineNameJa: String   // e.g. "東急東横線"
    let lineNameEn: String   // e.g. "Tokyu Toyoko Line"
    let towardJa: String     // e.g. "元町・中華街方面"
    let towardEn: String     // e.g. "for Motomachi-Chukagai"

    var localizedLineName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "ja" ? lineNameJa : lineNameEn
    }

    var localizedToward: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "ja" ? towardJa : towardEn
    }
}

// MARK: - Static Train Line

struct StaticTrainLine {
    let id: String          // ODPT-compatible, e.g. "odpt.Railway:JR-East.Yamanote"
    let nameJa: String
    let nameEn: String
    let operatorId: String  // e.g. "odpt.Operator:JR-East"
    let colorHex: String
    let stations: [Station]
    /// Run time in minutes between adjacent stations; count == stations.count - 1
    let hopTimesMinutes: [Double]
    let directions: [StaticLineDirection]
    let delayInfo: DelayCheckInfo
    /// Through-running connections onto other lines (直通運転)
    var throughServices: [ThroughService] = []

    /// Converts to the app-facing TrainLine model.
    var trainLine: TrainLine {
        TrainLine(
            id: id,
            name: nameJa,
            nameEn: nameEn,
            operatorId: operatorId,
            stations: stations,
            colorHex: colorHex
        )
    }
}

// MARK: - Static Train Data Store

enum StaticTrainData {

    static let allLines: [StaticTrainLine] =
        JREastLineData.lines
        + TokyoMetroLineData.lines
        + ToeiLineData.lines
        + KeiseiLineData.lines
        + TobuLineData.lines

    private static let linesById: [String: StaticTrainLine] = Dictionary(
        allLines.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    private static let linesByStationId: [String: StaticTrainLine] = {
        var map: [String: StaticTrainLine] = [:]
        for line in allLines {
            for station in line.stations where map[station.id] == nil {
                map[station.id] = line
            }
        }
        return map
    }()

    static func line(withId id: String) -> StaticTrainLine? {
        linesById[id]
    }

    static func line(containingStationId stationId: String) -> StaticTrainLine? {
        linesByStationId[stationId]
    }

    static func delayCheckInfo(forLineId lineId: String) -> DelayCheckInfo? {
        linesById[lineId]?.delayInfo
    }

    /// App-facing line list, sorted the same way the network path sorted them.
    static func trainLines(includeJR: Bool) -> [TrainLine] {
        allLines
            .filter { includeJR || $0.operatorId != "odpt.Operator:JR-East" }
            .map(\.trainLine)
            .sorted {
                if $0.operatorId != $1.operatorId {
                    return $0.operatorId < $1.operatorId
                }
                return $0.nameEn < $1.nameEn
            }
    }

    /// Direction ID → localized names, for the view model's direction lookup.
    static var railDirections: [String: (ja: String, en: String)] {
        var map: [String: (ja: String, en: String)] = [:]
        for line in allLines {
            for direction in line.directions {
                map[direction.id] = (ja: direction.nameJa, en: direction.nameEn)
            }
        }
        return map
    }
}

// MARK: - Static Timetable Generator

/// Generates full-day timetables (per train and per station) from the
/// encoded service patterns.
enum StaticTimetableGenerator {

    // MARK: Train Services

    /// All train services for a line on the given calendar (both directions).
    static func services(for line: StaticTrainLine, calendar: ScheduleCalendar) -> [TrainService] {
        line.directions.flatMap { services(for: line, direction: $0, calendar: calendar) }
    }

    private static func services(
        for line: StaticTrainLine,
        direction: StaticLineDirection,
        calendar: ScheduleCalendar
    ) -> [TrainService] {
        let pattern = direction.pattern(for: calendar)
        let stations = orderedStations(line: line, direction: direction)
        let offsets = cumulativeMinutes(hopTimes: line.hopTimesMinutes, ascending: direction.isAscending)
        guard stations.count == offsets.count, let destination = stations.last else { return [] }

        return departureMinutes(for: pattern).map { origin in
            let serviceId = "\(line.id).\(direction.id).\(calendar.rawValue).\(timeString(origin))"
            let entries = stations.enumerated().map { (i, station) -> TimetableEntry in
                let time = timeString(origin + Int(offsets[i].rounded()))
                return TimetableEntry(
                    id: "\(serviceId)_\(i)",
                    stationId: station.id,
                    arrivalTime: i == 0 ? nil : time,
                    departureTime: i == stations.count - 1 ? nil : time
                )
            }
            return TrainService(
                id: serviceId,
                lineId: line.id,
                trainType: pattern.trainType,
                direction: direction.isAscending ? .outbound : .inbound,
                timetable: entries,
                destinationStationId: destination.id
            )
        }
    }

    // MARK: Station Timetables

    /// Full-day departures from one station, grouped by direction.
    static func stationTimetables(
        for line: StaticTrainLine,
        stationId: String,
        calendar: ScheduleCalendar
    ) -> [StationTimetableData] {
        line.directions.compactMap { direction in
            let pattern = direction.pattern(for: calendar)
            let stations = orderedStations(line: line, direction: direction)
            let offsets = cumulativeMinutes(hopTimes: line.hopTimesMinutes, ascending: direction.isAscending)
            guard let index = stations.firstIndex(where: { $0.id == stationId }),
                  index < stations.count - 1,  // no departures toward a direction from its terminus
                  let destination = stations.last
            else { return nil }

            let offset = Int(offsets[index].rounded())
            let origins = departureMinutes(for: pattern)
            let departures = origins.enumerated().map { (i, origin) -> StationDeparture in
                StationDeparture(
                    id: "\(line.id).\(direction.id).\(stationId)_\(i)",
                    departureTime: timeString(origin + offset),
                    trainType: pattern.trainType,
                    destinationName: destination.name,
                    destinationNameEn: destination.nameEn,
                    trainNumber: "",
                    isLast: i == origins.count - 1
                )
            }

            return StationTimetableData(
                stationId: stationId,
                railDirection: direction.id,
                railDirectionName: direction.nameJa,
                railDirectionNameEn: direction.nameEn,
                departures: departures
            )
        }
    }

    // MARK: Helpers

    private static func orderedStations(line: StaticTrainLine, direction: StaticLineDirection) -> [Station] {
        direction.isAscending ? line.stations : Array(line.stations.reversed())
    }

    /// Cumulative travel time from the direction's origin to each station.
    private static func cumulativeMinutes(hopTimes: [Double], ascending: Bool) -> [Double] {
        let hops = ascending ? hopTimes : Array(hopTimes.reversed())
        var result: [Double] = [0]
        result.reserveCapacity(hops.count + 1)
        for hop in hops {
            result.append((result.last ?? 0) + hop)
        }
        return result
    }

    /// All origin departure times (minutes since midnight) for a pattern.
    private static func departureMinutes(for pattern: ServicePattern) -> [Int] {
        guard let first = parseMinutes(pattern.firstDeparture),
              let last = parseMinutes(pattern.lastDeparture),
              first <= last, !pattern.bands.isEmpty
        else { return [] }

        var times: [Int] = []
        var t = Double(first)
        while Int(t.rounded()) < last {
            let rounded = Int(t.rounded())
            if times.last != rounded {
                times.append(rounded)
            }
            t += headway(at: t, in: pattern.bands)
        }
        if times.last != last {
            times.append(last)
        }
        return times
    }

    private static func headway(at minutes: Double, in bands: [HeadwayBand]) -> Double {
        var current = bands[0].headwayMinutes
        for band in bands {
            guard let from = parseMinutes(band.from) else { continue }
            if Double(from) <= minutes {
                current = band.headwayMinutes
            } else {
                break
            }
        }
        return max(current, 0.5)
    }

    /// Parses "HH:mm" (hours may exceed 24) into minutes since midnight.
    private static func parseMinutes(_ time: String) -> Int? {
        guard let seconds = TimetableEntry.parseRailTime(time) else { return nil }
        return seconds / 60
    }

    /// Formats minutes since midnight as "HH:mm" (Japanese rail convention, may exceed 24:00).
    private static func timeString(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}
