import Foundation

// MARK: - Static Train Data Models

// MARK: - Schedule Calendar

public enum ScheduleCalendar: String, Codable, CaseIterable {
    case weekday = "Weekday"
    case saturdayHoliday = "SaturdayHoliday"

    public static func current(at date: Date = Date()) -> ScheduleCalendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let weekday = cal.component(.weekday, from: date)
        // 1 = Sunday, 7 = Saturday
        return (weekday == 1 || weekday == 7) ? .saturdayHoliday : .weekday
    }
}

// MARK: - Delay Check Info

public struct DelayCheckInfo: Codable, Hashable {
    public let statusPageURL: String
    public let statusPageURLEn: String
    public let xAccount: String?
    public let checkMethodJa: String
    public let checkMethodEn: String

    public var localizedCheckMethod: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "ja" ? checkMethodJa : checkMethodEn
    }

    public var localizedStatusPageURL: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "ja" ? statusPageURL : statusPageURLEn
    }
}

// MARK: - Headway Band

public struct HeadwayBand: Codable, Hashable {
    public let from: String          // "HH:mm"
    public let headwayMinutes: Double
}

// MARK: - Service Pattern

public struct ServicePattern: Codable, Hashable {
    public let firstDeparture: String  // "HH:mm" at the origin of the direction
    public let lastDeparture: String   // "HH:mm", may exceed 24:00
    public let bands: [HeadwayBand]    // ordered by time
    public let trainType: TrainService.TrainType

    init(first: String, last: String, bands: [HeadwayBand], trainType: TrainService.TrainType = .local) {
        self.firstDeparture = first
        self.lastDeparture = last
        self.bands = bands
        self.trainType = trainType
    }
}

// MARK: - Line Direction

public struct StaticLineDirection: Codable, Hashable {
    public let id: String        // e.g. "static.RailDirection:TokyoMetro.Ginza.Asakusa"
    public let nameJa: String    // e.g. "浅草方面"
    public let nameEn: String    // e.g. "For Asakusa"
    public let isAscending: Bool // true: trains run through `stations` in array order; false: reversed
    public let weekday: ServicePattern
    public let saturdayHoliday: ServicePattern

    public func pattern(for calendar: ScheduleCalendar) -> ServicePattern {
        calendar == .weekday ? weekday : saturdayHoliday
    }
}

// MARK: - Through Service

/// A through-running connection (直通運転): trains that continue past a
/// junction station onto another line's or operator's tracks.
public struct ThroughService: Codable, Hashable {

    public enum LineEnd: String, Codable {
        case ascending  // trains travelling in stations-array order continue on
        case descending // trains travelling in reverse array order continue on
    }

    public let junctionStationId: String
    public let end: LineEnd
    public let lineNameJa: String   // e.g. "東急東横線"
    public let lineNameEn: String   // e.g. "Tokyu Toyoko Line"
    public let towardJa: String     // e.g. "元町・中華街方面"
    public let towardEn: String     // e.g. "for Motomachi-Chukagai"

    public var localizedLineName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "ja" ? lineNameJa : lineNameEn
    }

    public var localizedToward: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "ja" ? towardJa : towardEn
    }
}

// MARK: - Static Train Line

public struct StaticTrainLine {
    public let id: String          // ODPT-compatible, e.g. "odpt.Railway:JR-East.Yamanote"
    public let nameJa: String
    public let nameEn: String
    public let operatorId: String  // e.g. "odpt.Operator:JR-East"
    public let colorHex: String
    public let stations: [Station]
    public let hopTimesMinutes: [Double] // count == stations.count - 1
    public let directions: [StaticLineDirection]
    public let delayInfo: DelayCheckInfo
    public var throughServices: [ThroughService] = [] // 直通運転

    public var trainLine: TrainLine {
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

public enum StaticTrainData {

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

    public static func line(withId id: String) -> StaticTrainLine? {
        linesById[id]
    }

    public static func line(containingStationId stationId: String) -> StaticTrainLine? {
        linesByStationId[stationId]
    }

    public static func delayCheckInfo(forLineId lineId: String) -> DelayCheckInfo? {
        linesById[lineId]?.delayInfo
    }

    public static func trainLines() -> [TrainLine] {
        allLines
            .map(\.trainLine)
            .sorted {
                if $0.operatorId != $1.operatorId {
                    return $0.operatorId < $1.operatorId
                }
                return $0.nameEn < $1.nameEn
            }
    }

    public static var railDirections: [String: (ja: String, en: String)] {
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

public enum StaticTimetableGenerator {

    // MARK: Train Services

    public static func services(for line: StaticTrainLine, calendar: ScheduleCalendar) -> [TrainService] {
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

    public static func stationTimetables(
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

    private static func cumulativeMinutes(hopTimes: [Double], ascending: Bool) -> [Double] {
        let hops = ascending ? hopTimes : Array(hopTimes.reversed())
        var result: [Double] = [0]
        result.reserveCapacity(hops.count + 1)
        for hop in hops {
            result.append((result.last ?? 0) + hop)
        }
        return result
    }

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
