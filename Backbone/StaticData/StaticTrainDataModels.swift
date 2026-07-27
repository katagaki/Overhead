import Foundation

// MARK: - Static Train Data Models

// MARK: - Schedule Calendar

public enum ScheduleCalendar: String, Codable, CaseIterable, Sendable {
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

// MARK: - Exact Run

public struct ExactRun: Codable, Hashable {
    public let departure: String          // "HH:mm" at the run's origin, may exceed 24:00
    public let terminusStationId: String? // nil = runs to the direction's terminus
    public let startsHere: Bool           // 当駅始発 at the run's origin
    public let continuesBeyond: Bool
    public let trainType: TrainService.TrainType?
    public let stopIndices: [Int]?

    public init(_ departure: String, terminusStationId: String? = nil,
                startsHere: Bool = true, continuesBeyond: Bool = false,
                trainType: TrainService.TrainType? = nil,
                stopIndices: [Int]? = nil) {
        self.departure = departure
        self.terminusStationId = terminusStationId
        self.startsHere = startsHere
        self.continuesBeyond = continuesBeyond
        self.trainType = trainType
        self.stopIndices = stopIndices
    }
}

// MARK: - Service Pattern

public struct ServicePattern: Codable, Hashable {
    public let firstDeparture: String  // "HH:mm" at the origin of the direction
    public let lastDeparture: String   // "HH:mm", may exceed 24:00
    public let bands: [HeadwayBand]    // ordered by time
    public let trainType: TrainService.TrainType
    public let exactRuns: [ExactRun]?

    init(first: String, last: String, bands: [HeadwayBand],
         trainType: TrainService.TrainType = .local, exactRuns: [ExactRun]? = nil) {
        self.firstDeparture = first
        self.lastDeparture = last
        self.bands = bands
        self.trainType = trainType
        self.exactRuns = exactRuns
    }
}

// MARK: - Intermediate Origin (当駅始発)

public struct IntermediateOrigin: Codable, Hashable {
    public let stationId: String
    public let weekdayDepartures: [String]
    public let saturdayHolidayDepartures: [String]
    public let weekdayRuns: [ExactRun]?
    public let saturdayHolidayRuns: [ExactRun]?

    public init(stationId: String, weekday: [String], saturdayHoliday: [String]) {
        self.stationId = stationId
        self.weekdayDepartures = weekday
        self.saturdayHolidayDepartures = saturdayHoliday
        self.weekdayRuns = nil
        self.saturdayHolidayRuns = nil
    }

    public init(stationId: String, weekdayRuns: [ExactRun], saturdayHolidayRuns: [ExactRun]) {
        self.stationId = stationId
        self.weekdayDepartures = []
        self.saturdayHolidayDepartures = []
        self.weekdayRuns = weekdayRuns
        self.saturdayHolidayRuns = saturdayHolidayRuns
    }

    public func departures(for calendar: ScheduleCalendar) -> [String] {
        calendar == .weekday ? weekdayDepartures : saturdayHolidayDepartures
    }

    public func runs(for calendar: ScheduleCalendar) -> [ExactRun]? {
        calendar == .weekday ? weekdayRuns : saturdayHolidayRuns
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
    public let intermediateOrigins: [IntermediateOrigin]
    public let expressWeekdayRuns: [ExactRun]
    public let expressSaturdayHolidayRuns: [ExactRun]

    public init(
        id: String, nameJa: String, nameEn: String, isAscending: Bool,
        weekday: ServicePattern, saturdayHoliday: ServicePattern,
        intermediateOrigins: [IntermediateOrigin] = [],
        expressWeekdayRuns: [ExactRun] = [],
        expressSaturdayHolidayRuns: [ExactRun] = []
    ) {
        self.id = id
        self.nameJa = nameJa
        self.nameEn = nameEn
        self.isAscending = isAscending
        self.weekday = weekday
        self.saturdayHoliday = saturdayHoliday
        self.intermediateOrigins = intermediateOrigins
        self.expressWeekdayRuns = expressWeekdayRuns
        self.expressSaturdayHolidayRuns = expressSaturdayHolidayRuns
    }

    public func pattern(for calendar: ScheduleCalendar) -> ServicePattern {
        calendar == .weekday ? weekday : saturdayHoliday
    }

    public func expressRuns(for calendar: ScheduleCalendar) -> [ExactRun] {
        calendar == .weekday ? expressWeekdayRuns : expressSaturdayHolidayRuns
    }
}

// MARK: - Through Service

/// A through-running connection (直通運転) past a junction station.
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
    // Set when the connecting line is bundled in the app; nil for external operators
    public var connectingLineId: String? = nil

    public var localizedLineName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "ja" ? lineNameJa : lineNameEn
    }

    public var localizedToward: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "ja" ? towardJa : towardEn
    }
}

// MARK: - Timetable Run

public struct TimetableRun: Hashable, Sendable, Codable {
    public let calendar: ScheduleCalendar
    public let ascending: Bool
    public let startIndex: Int
    public let stops: [Int]
    public let startsHere: Bool
    public let type: TrainService.TrainType
    public let terminates: Bool
    // Off-line terminus for through-runs (行き先 as riders see it, e.g. 我孫子).
    public var throughDestJa: String? = nil
    public var throughDestEn: String? = nil
    public init(_ calendar: ScheduleCalendar, _ ascending: Bool, _ startIndex: Int,
                _ startsHere: Bool, _ type: TrainService.TrainType, _ stops: [Int],
                terminates: Bool = true, throughDestJa: String? = nil, throughDestEn: String? = nil) {
        self.calendar = calendar; self.ascending = ascending; self.startIndex = startIndex
        self.startsHere = startsHere; self.type = type; self.stops = stops
        self.terminates = terminates
        self.throughDestJa = throughDestJa; self.throughDestEn = throughDestEn
    }
}

// MARK: - Static Train Line

public struct StaticTrainLine: Codable, Hashable {
    public let id: String          // e.g. "Railway:JR-East.Yamanote"
    public let nameJa: String
    public let nameEn: String
    public let operatorId: String  // e.g. "Operator:JR-East"
    public let colorHex: String
    public let stations: [Station]
    public let hopTimesMinutes: [Double] // count == stations.count - 1
    public var upHopTimesMinutes: [Double]? = nil
    public var exactStationTimes: [String: [Int]]? = nil
    public var timetableRuns: [TimetableRun]? = nil
    public var isLoop: Bool = false
    public let directions: [StaticLineDirection]
    public let delayInfo: DelayCheckInfo
    public var throughServices: [ThroughService] = [] // 直通運転
    public var stopPatterns: [TrainService.TrainType: Set<Int>] = [:]

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

    // One JSON resource per operator; see LineStore and StaticData/Lines/.
    private static let lineResources = [
        "JREastLine", "TokyoMetroLine", "ToeiLine", "KeiseiLine", "TobuLine",
        "OdakyuLine", "TokyuLine", "TokyuOimachiLine", "TokyuIkegamiLine",
        "TokyuTamagawaLine", "TokyuSetagayaLine", "TokyuShinYokohamaLine",
        "KodomonokuniLine", "KeikyuLine", "KeioLine", "KeioInokashiraLine",
        "SeibuLine", "SotetsuLine", "SotetsuIzuminoLine", "SotetsuShinYokohamaLine",
        "MinatomiraiLine", "SaitamaRapidLine", "RinkaiLine", "TsukubaExpressLine",
        "TamaMonorailLine", "YokohamaBlueLine", "YokohamaGreenLine",
    ]

    static let allLines: [StaticTrainLine] = lineResources.flatMap { LineStore.lines($0) }

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

    // MARK: Through Services (直通運転)

    /// Stations reachable beyond a junction via a through service onto a bundled line.
    public struct ThroughDestinationGroup {
        public let service: ThroughService
        public let connectingLine: StaticTrainLine
        /// Stations past the junction on the connecting line, in travel order.
        public let stations: [Station]
        /// Whether through trains traverse `connectingLine` in array order.
        public let connectingAscending: Bool
    }

    public static func throughDestinations(
        fromLineId lineId: String,
        boardingStationId: String? = nil
    ) -> [ThroughDestinationGroup] {
        guard let line = linesById[lineId] else { return [] }
        var groups: [ThroughDestinationGroup] = []
        for service in line.throughServices {
            if let boardingStationId {
                guard let fromIdx = line.stations.firstIndex(where: { $0.id == boardingStationId }),
                      let jIdx = line.stations.firstIndex(where: { $0.id == service.junctionStationId })
                else { continue }
                switch service.end {
                case .ascending: guard fromIdx <= jIdx else { continue }
                case .descending: guard fromIdx >= jIdx else { continue }
                }
            }
            guard let group = destinationGroup(for: service, on: line) else { continue }
            groups.append(group)
            groups.append(contentsOf: chainedGroups(after: group))
        }
        return groups
    }

    private static func chainedGroups(after group: ThroughDestinationGroup) -> [ThroughDestinationGroup] {
        let line2 = group.connectingLine
        var result: [ThroughDestinationGroup] = []
        for onward in line2.throughServices {
            guard (onward.end == .ascending) == group.connectingAscending,
                  group.stations.contains(where: { $0.id == onward.junctionStationId }),
                  let g2 = destinationGroup(for: onward, on: line2)
            else { continue }
            let combined = ThroughService(
                junctionStationId: group.service.junctionStationId,
                end: group.service.end,
                lineNameJa: "\(group.service.lineNameJa)・\(onward.lineNameJa)",
                lineNameEn: "\(group.service.lineNameEn) & \(onward.lineNameEn)",
                towardJa: onward.towardJa,
                towardEn: onward.towardEn,
                connectingLineId: onward.connectingLineId
            )
            result.append(ThroughDestinationGroup(
                service: combined,
                connectingLine: g2.connectingLine,
                stations: g2.stations,
                connectingAscending: g2.connectingAscending
            ))
        }
        return result
    }

    private static func destinationGroup(
        for service: ThroughService,
        on line: StaticTrainLine
    ) -> ThroughDestinationGroup? {
        guard let targetId = service.connectingLineId,
              let target = linesById[targetId],
              let junction = line.stations.first(where: { $0.id == service.junctionStationId }),
              let jIdx = target.stations.firstIndex(where: { $0.name == junction.name })
        else { return nil }

        let ascending: Bool
        if let reciprocal = target.throughServices.first(where: { ts in
            target.stations.first(where: { $0.id == ts.junctionStationId })?.name == junction.name
        }) {
            ascending = reciprocal.end == .descending
        } else if jIdx == 0 {
            ascending = true
        } else if jIdx == target.stations.count - 1 {
            ascending = false
        } else {
            return nil
        }

        let beyond = ascending
            ? Array(target.stations[(jIdx + 1)...])
            : Array(target.stations[..<jIdx].reversed())
        guard !beyond.isEmpty else { return nil }
        return ThroughDestinationGroup(
            service: service, connectingLine: target,
            stations: beyond, connectingAscending: ascending
        )
    }

    // MARK: Direct Route Search

    public struct DirectRouteOption: Identifiable {
        /// Line to generate services from (composite when the route runs through a junction).
        public let staticLine: StaticTrainLine
        /// The line the passenger boards on (used for color, symbol, and display).
        public let boardingLine: StaticTrainLine
        public let fromStation: Station
        public let toStation: Station
        public let isThrough: Bool

        public var id: String { "\(staticLine.id)|\(fromStation.id)|\(toStation.id)" }
    }

    public static func directRoutes(
        fromStationName: String,
        toStationName: String,
        avoidingLineIds: Set<String> = []
    ) -> [DirectRouteOption] {
        guard fromStationName != toStationName else { return [] }
        func isAvoided(_ lineId: String) -> Bool {
            guard !avoidingLineIds.isEmpty else { return false }
            return lineId.split(separator: "+").contains { avoidingLineIds.contains(String($0)) }
        }
        var options: [DirectRouteOption] = []
        for line in allLines {
            guard !isAvoided(line.id),
                  let from = line.stations.first(where: { $0.name == fromStationName }) else { continue }

            if let to = line.stations.first(where: { $0.name == toStationName }) {
                if let resolved = resolveJourneyLine(
                    lineId: line.id, fromStationId: from.id, toStationId: to.id
                ) {
                    options.append(DirectRouteOption(
                        staticLine: resolved.staticLine,
                        boardingLine: line,
                        fromStation: from,
                        toStation: to,
                        isThrough: false
                    ))
                }
                continue
            }

            for group in throughDestinations(fromLineId: line.id, boardingStationId: from.id) {
                guard let to = group.stations.first(where: { $0.name == toStationName }),
                      let resolved = resolveJourneyLine(
                          lineId: line.id, fromStationId: from.id, toStationId: to.id
                      ),
                      !isAvoided(resolved.staticLine.id)
                else { continue }
                options.append(DirectRouteOption(
                    staticLine: resolved.staticLine,
                    boardingLine: line,
                    fromStation: from,
                    toStation: to,
                    isThrough: true
                ))
            }
        }
        return options
    }

    // MARK: Transfer Route Planning (乗り換え)

    public struct TransferLeg {
        public let staticLine: StaticTrainLine
        public let fromStation: Station
        public let toStation: Station
    }

    /// Time assumed for walking between platforms when changing trains.
    public static let transferBufferMinutes: Double = 5

    public static func estimatedRide(
        on line: StaticTrainLine,
        fromStationId: String,
        toStationId: String
    ) -> (stations: [Station], minutes: Double)? {
        let stations = line.stations
        guard let fromIdx = stations.firstIndex(where: { $0.id == fromStationId }),
              let toIdx = stations.firstIndex(where: { $0.id == toStationId }),
              fromIdx != toIdx
        else { return nil }

        let hops = line.hopTimesMinutes
        let range = min(fromIdx, toIdx)..<max(fromIdx, toIdx)
        let directMinutes = hops[range].reduce(0, +)
        let directPath: [Station] = fromIdx < toIdx
            ? Array(stations[fromIdx...toIdx])
            : Array(stations[toIdx...fromIdx].reversed())

        guard line.isLoop, hops.count == stations.count - 1, stations.count > 2 else {
            return (directPath, directMinutes)
        }

        let total = hops.reduce(0, +)
        let seamHop = total / Double(hops.count)
        let wrapMinutes = total + seamHop - directMinutes
        guard wrapMinutes < directMinutes else { return (directPath, directMinutes) }

        let count = stations.count
        let step = fromIdx < toIdx ? -1 : 1
        var path = [stations[fromIdx]]
        var idx = fromIdx
        while idx != toIdx {
            idx = ((idx + step) % count + count) % count
            path.append(stations[idx])
        }
        return (path, wrapMinutes)
    }

    public static func planTransferRoute(
        throughStationNames names: [String],
        maxTransfers: Int = 2,
        transferMinutes: Double = transferBufferMinutes,
        avoidingLineIds: Set<String> = []
    ) -> [TransferLeg]? {
        guard names.count >= 2 else { return nil }
        var plan: [TransferLeg] = []
        for (from, to) in zip(names, names.dropFirst()) {
            guard from != to,
                  var segment = planTransferRoute(
                      fromStationName: from,
                      toStationName: to,
                      maxTransfers: maxTransfers,
                      transferMinutes: transferMinutes,
                      avoidingLineIds: avoidingLineIds
                  )
            else { return nil }

            if let last = plan.last, let first = segment.first,
               last.staticLine.id == first.staticLine.id,
               last.toStation.id == first.fromStation.id,
               continuesSameDirection(last, first) {
                plan.removeLast()
                segment[0] = TransferLeg(
                    staticLine: first.staticLine,
                    fromStation: last.fromStation,
                    toStation: first.toStation
                )
            }
            plan.append(contentsOf: segment)
        }
        return plan.isEmpty ? nil : plan
    }

    private static func continuesSameDirection(_ first: TransferLeg, _ second: TransferLeg) -> Bool {
        let stations = first.staticLine.stations
        guard let aFrom = stations.firstIndex(where: { $0.id == first.fromStation.id }),
              let aTo = stations.firstIndex(where: { $0.id == first.toStation.id }),
              let bFrom = stations.firstIndex(where: { $0.id == second.fromStation.id }),
              let bTo = stations.firstIndex(where: { $0.id == second.toStation.id })
        else { return false }
        return (aTo > aFrom) == (bTo > bFrom)
    }

    public static func planTransferRoute(
        fromStationName: String,
        toStationName: String,
        maxTransfers: Int = 2,
        transferMinutes: Double = transferBufferMinutes,
        avoidingLineIds: Set<String> = []
    ) -> [TransferLeg]? {
        guard fromStationName != toStationName else { return nil }
        let lines = avoidingLineIds.isEmpty
            ? allLines
            : allLines.filter { !avoidingLineIds.contains($0.id) }
        let transferPenalty = transferMinutes + 3  // walk + expected wait

        // Node = (line index, station index on that line)
        struct Node: Hashable {
            let line: Int
            let idx: Int
        }
        struct Entry {
            var cost: Double
            var transfers: Int
            var parent: Node?
        }

        // Stations grouped by name for transfer edges and start/goal lookup
        var nodesByName: [String: [Node]] = [:]
        for (li, line) in lines.enumerated() {
            for (si, station) in line.stations.enumerated() {
                nodesByName[station.name, default: []].append(Node(line: li, idx: si))
            }
        }
        guard let startNodes = nodesByName[fromStationName],
              nodesByName[toStationName] != nil
        else { return nil }

        var best: [Node: Entry] = [:]
        // Simple priority queue: linear extract-min is fine at this scale
        var frontier: [(cost: Double, node: Node)] = []
        for node in startNodes {
            best[node] = Entry(cost: 0, transfers: 0, parent: nil)
            frontier.append((0, node))
        }

        var goal: Node?
        while !frontier.isEmpty {
            var minIdx = 0
            for i in 1..<frontier.count where frontier[i].cost < frontier[minIdx].cost {
                minIdx = i
            }
            let (cost, node) = frontier.remove(at: minIdx)
            guard let entry = best[node], entry.cost == cost else { continue }

            let line = lines[node.line]
            let station = line.stations[node.idx]
            if station.name == toStationName {
                goal = node
                break
            }

            func relax(_ next: Node, cost nextCost: Double, transfers: Int) {
                if let existing = best[next], existing.cost <= nextCost { return }
                best[next] = Entry(cost: nextCost, transfers: transfers, parent: node)
                frontier.append((nextCost, next))
            }

            // Ride to adjacent stations on the same line
            if node.idx > 0 {
                relax(Node(line: node.line, idx: node.idx - 1),
                      cost: cost + line.hopTimesMinutes[node.idx - 1],
                      transfers: entry.transfers)
            }
            if node.idx < line.stations.count - 1 {
                relax(Node(line: node.line, idx: node.idx + 1),
                      cost: cost + line.hopTimesMinutes[node.idx],
                      transfers: entry.transfers)
            }

            // Change to other lines at this station
            if entry.transfers < maxTransfers, let siblings = nodesByName[station.name] {
                for sibling in siblings where sibling.line != node.line {
                    relax(sibling, cost: cost + transferPenalty, transfers: entry.transfers + 1)
                }
            }
        }

        guard var cursor = goal else { return nil }

        // Walk parents back to the start, then compress into per-line legs
        var path: [Node] = [cursor]
        while let parent = best[cursor]?.parent {
            path.append(parent)
            cursor = parent
        }
        path.reverse()

        var legs: [TransferLeg] = []
        var legStart = path[0]
        for i in 1..<path.count {
            let prev = path[i - 1]
            let node = path[i]
            if node.line != prev.line {
                if legStart.idx != prev.idx {
                    legs.append(TransferLeg(
                        staticLine: lines[legStart.line],
                        fromStation: lines[legStart.line].stations[legStart.idx],
                        toStation: lines[prev.line].stations[prev.idx]
                    ))
                }
                legStart = node
            }
        }
        let last = path[path.count - 1]
        if legStart.idx != last.idx {
            legs.append(TransferLeg(
                staticLine: lines[legStart.line],
                fromStation: lines[legStart.line].stations[legStart.idx],
                toStation: lines[last.line].stations[last.idx]
            ))
        }
        return legs.isEmpty ? nil : legs
    }

    public struct ResolvedJourneyLine {
        public let staticLine: StaticTrainLine
        public let isThrough: Bool
        public let throughService: ThroughService?
    }

    public static func resolveJourneyLine(
        lineId: String,
        fromStationId: String,
        toStationId: String
    ) -> ResolvedJourneyLine? {
        guard let line = linesById[lineId],
              let fromIdx = line.stations.firstIndex(where: { $0.id == fromStationId })
        else { return nil }

        if line.stations.contains(where: { $0.id == toStationId }) {
            return ResolvedJourneyLine(staticLine: line, isThrough: false, throughService: nil)
        }

        for service in line.throughServices {
            guard let jIdx = line.stations.firstIndex(where: { $0.id == service.junctionStationId })
            else { continue }
            switch service.end {
            case .ascending: guard fromIdx <= jIdx else { continue }
            case .descending: guard fromIdx >= jIdx else { continue }
            }
            guard let group = destinationGroup(for: service, on: line) else { continue }

            if group.stations.contains(where: { $0.id == toStationId }) {
                guard let composite = compositeLine(origin: line, group: group) else { continue }
                return ResolvedJourneyLine(staticLine: composite, isThrough: true, throughService: service)
            }

            // Two-junction chain onto a third line
            let line2 = group.connectingLine
            for onward in line2.throughServices {
                guard (onward.end == .ascending) == group.connectingAscending,
                      group.stations.contains(where: { $0.id == onward.junctionStationId }),
                      let g2 = destinationGroup(for: onward, on: line2),
                      g2.stations.contains(where: { $0.id == toStationId }),
                      let first = compositeLine(origin: line, group: group)
                else { continue }

                let onwardForComposite = ThroughService(
                    junctionStationId: onward.junctionStationId,
                    end: .ascending,
                    lineNameJa: onward.lineNameJa,
                    lineNameEn: onward.lineNameEn,
                    towardJa: onward.towardJa,
                    towardEn: onward.towardEn,
                    connectingLineId: onward.connectingLineId
                )
                let secondGroup = ThroughDestinationGroup(
                    service: onwardForComposite,
                    connectingLine: g2.connectingLine,
                    stations: g2.stations,
                    connectingAscending: g2.connectingAscending
                )
                guard let composite = compositeLine(origin: first, group: secondGroup) else { continue }
                return ResolvedJourneyLine(staticLine: composite, isThrough: true, throughService: service)
            }
        }
        return nil
    }

    private static func compositeLine(
        origin: StaticTrainLine,
        group: ThroughDestinationGroup
    ) -> StaticTrainLine? {
        let service = group.service
        guard let jIdx = origin.stations.firstIndex(where: { $0.id == service.junctionStationId })
        else { return nil }
        let originAscending = service.end == .ascending

        let originStations: [Station]
        let originHops: [Double]
        if originAscending {
            originStations = Array(origin.stations[...jIdx])
            originHops = Array(origin.hopTimesMinutes[..<jIdx])
        } else {
            let hops = origin.upHopTimesMinutes ?? origin.hopTimesMinutes
            originStations = Array(origin.stations[jIdx...].reversed())
            originHops = Array(hops[jIdx...].reversed())
        }

        let target = group.connectingLine
        guard let junctionName = originStations.last?.name,
              let tIdx = target.stations.firstIndex(where: { $0.name == junctionName }),
              let firstBeyond = group.stations.first,
              let bIdx = target.stations.firstIndex(where: { $0.id == firstBeyond.id })
        else { return nil }

        let targetHops: [Double] = bIdx > tIdx
            ? Array(target.hopTimesMinutes[tIdx...])
            : Array((target.upHopTimesMinutes ?? target.hopTimesMinutes)[..<tIdx].reversed())

        let stations = originStations + group.stations
        let hops = originHops + targetHops
        guard hops.count == stations.count - 1 else { return nil }

        let basis = origin.directions.first(where: { $0.isAscending == originAscending })
            ?? origin.directions[0]

        let junctionOffset = originHops.reduce(0, +)
        let junctionTargetId = target.stations[tIdx].id
        let connectingDirection = target.directions.first {
            $0.isAscending == group.connectingAscending
        }
        let connectingOriginatesAtJunction = group.connectingAscending
            ? tIdx == 0
            : tIdx == target.stations.count - 1
        let junctionIsOriginTerminus = originAscending
            ? jIdx == origin.stations.count - 1
            : jIdx == 0

        func rebasedRuns(_ runs: [ExactRun]) -> [ExactRun] {
            runs.compactMap { run in
                guard run.continuesBeyond, run.terminusStationId == service.junctionStationId
                else { return nil }
                return ExactRun(run.departure, terminusStationId: nil, startsHere: run.startsHere)
            }
        }
        func rebasedPattern(_ pattern: ServicePattern) -> ServicePattern {
            guard !junctionIsOriginTerminus, let runs = pattern.exactRuns else { return pattern }
            return ServicePattern(
                first: pattern.firstDeparture, last: pattern.lastDeparture,
                bands: [], trainType: pattern.trainType, exactRuns: rebasedRuns(runs)
            )
        }
        func rebasedOrigin(_ io: IntermediateOrigin) -> IntermediateOrigin {
            guard !junctionIsOriginTerminus,
                  io.weekdayRuns != nil || io.saturdayHolidayRuns != nil
            else { return io }
            return IntermediateOrigin(
                stationId: io.stationId,
                weekdayRuns: rebasedRuns(io.weekdayRuns ?? []),
                saturdayHolidayRuns: rebasedRuns(io.saturdayHolidayRuns ?? [])
            )
        }

        let weekday: ServicePattern
        let saturdayHoliday: ServicePattern
        let intermediateOrigins: [IntermediateOrigin]
        if let connecting = connectingDirection, connectingOriginatesAtJunction,
           let throughWeekday = junctionRunPattern(
               runs: connecting.weekday.exactRuns,
               trainType: connecting.weekday.trainType, minusMinutes: junctionOffset),
           let throughHoliday = junctionRunPattern(
               runs: connecting.saturdayHoliday.exactRuns,
               trainType: connecting.saturdayHoliday.trainType, minusMinutes: junctionOffset) {
            weekday = throughWeekday
            saturdayHoliday = throughHoliday
            intermediateOrigins = connecting.intermediateOrigins
        } else if let connecting = connectingDirection,
                  let junctionIO = connecting.intermediateOrigins.first(where: { $0.stationId == junctionTargetId }),
                  let throughWeekday = junctionRunPattern(
                      runs: junctionIO.weekdayRuns,
                      trainType: connecting.weekday.trainType, minusMinutes: junctionOffset),
                  let throughHoliday = junctionRunPattern(
                      runs: junctionIO.saturdayHolidayRuns,
                      trainType: connecting.saturdayHoliday.trainType, minusMinutes: junctionOffset) {
            weekday = throughWeekday
            saturdayHoliday = throughHoliday
            intermediateOrigins = connecting.intermediateOrigins.filter { $0.stationId != junctionTargetId }
        } else {
            weekday = rebasedPattern(basis.weekday)
            saturdayHoliday = rebasedPattern(basis.saturdayHoliday)
            intermediateOrigins = basis.intermediateOrigins.map(rebasedOrigin)
        }

        let direction = StaticLineDirection(
            id: "static.RailDirection:Composite.\(origin.id).\(target.id)",
            nameJa: service.towardJa,
            nameEn: service.towardEn,
            isAscending: true,
            weekday: weekday,
            saturdayHoliday: saturdayHoliday,
            intermediateOrigins: intermediateOrigins
        )

        return StaticTrainLine(
            id: "\(origin.id)+\(target.id)",
            nameJa: "\(origin.nameJa)〜\(target.nameJa)",
            nameEn: "\(origin.nameEn) – \(target.nameEn)",
            operatorId: origin.operatorId,
            colorHex: origin.colorHex,
            stations: stations,
            hopTimesMinutes: hops,
            directions: [direction],
            delayInfo: origin.delayInfo
        )
    }

    private static func junctionRunPattern(
        runs: [ExactRun]?,
        trainType: TrainService.TrainType,
        minusMinutes offset: Double
    ) -> ServicePattern? {
        guard let runs else { return nil }
        let shift = Int(offset.rounded())
        let shifted: [ExactRun] = runs.compactMap { run in
            guard !run.startsHere,
                  let depSec = TimetableEntry.parseRailTime(run.departure)
            else { return nil }
            let minutes = max(0, depSec / 60 - shift)
            return ExactRun(
                String(format: "%02d:%02d", minutes / 60, minutes % 60),
                terminusStationId: run.terminusStationId,
                startsHere: false,
                continuesBeyond: run.continuesBeyond
            )
        }
        return ServicePattern(
            first: shifted.first?.departure ?? "",
            last: shifted.last?.departure ?? "",
            bands: [],
            trainType: trainType,
            exactRuns: shifted
        )
    }
}

// MARK: - Static Timetable Generator

public enum StaticTimetableGenerator {

    // MARK: Train Services

    public static func services(for line: StaticTrainLine, calendar: ScheduleCalendar) -> [TrainService] {
        if let runs = line.timetableRuns {
            return timetableServices(line: line, runs: runs.filter { $0.calendar == calendar })
        }
        return line.directions.flatMap { services(for: line, direction: $0, calendar: calendar) }
    }

    private static func timetableServices(line: StaticTrainLine, runs: [TimetableRun]) -> [TrainService] {
        let n = line.stations.count
        func absIndex(_ start: Int, _ k: Int, ascending: Bool) -> Int? {
            let raw = start + (ascending ? k : -k)
            if line.isLoop { return ((raw % n) + n) % n }
            return (raw >= 0 && raw < n) ? raw : nil
        }
        return runs.compactMap { run in
            guard let first = run.stops.first else { return nil }
            let lastIdx = run.stops.count - 1
            guard let destAbs = absIndex(run.startIndex, lastIdx, ascending: run.ascending) else { return nil }
            let serviceId = "\(line.id).\(run.ascending ? "A" : "D").tt.\(run.startIndex).\(timeString(first))"
            let entries = run.stops.indices.compactMap { k -> TimetableEntry? in
                let m = run.stops[k]
                guard m >= 0 else { return nil }   // train passes this station
                guard let abs = absIndex(run.startIndex, k, ascending: run.ascending) else { return nil }
                let time = timeString(m)
                return TimetableEntry(
                    id: "\(serviceId)_\(k)",
                    stationId: line.stations[abs].id,
                    arrivalTime: k == 0 ? nil : time,
                    departureTime: (k == lastIdx && run.terminates) ? nil : time
                )
            }
            guard entries.count >= 2 else { return nil }
            return TrainService(
                id: serviceId,
                lineId: line.id,
                trainType: run.type,
                direction: run.ascending ? .outbound : .inbound,
                timetable: entries,
                destinationStationId: line.stations[destAbs].id,
                originatesAtStart: run.startsHere,
                throughDestinationName: run.throughDestJa,
                throughDestinationNameEn: run.throughDestEn
            )
        }
    }

    private static func services(
        for line: StaticTrainLine,
        direction: StaticLineDirection,
        calendar: ScheduleCalendar
    ) -> [TrainService] {
        let stations = orderedStations(line: line, direction: direction)
        let hopTimes = (direction.isAscending ? nil : line.upHopTimesMinutes) ?? line.hopTimesMinutes
        let offsets = cumulativeMinutes(hopTimes: hopTimes, ascending: direction.isAscending)
        guard stations.count == offsets.count, let destination = stations.last else { return [] }

        let pattern = direction.pattern(for: calendar)
        var result: [TrainService]
        if let exact = pattern.exactRuns {
            result = exactRunServices(
                line: line, direction: direction,
                stations: stations, offsets: offsets,
                startIndex: 0, runs: exact,
                trainType: pattern.trainType, tag: "full", calendar: calendar
            )
        } else {
            result = runServices(
                line: line, direction: direction,
                stations: stations, offsets: offsets, destination: destination,
                startIndex: 0, originMinutes: departureMinutes(for: pattern),
                trainType: pattern.trainType, tag: "full"
            )
        }
        for (n, io) in direction.intermediateOrigins.enumerated() {
            guard let startIdx = stations.firstIndex(where: { $0.id == io.stationId }),
                  startIdx > 0, startIdx < stations.count - 1 else { continue }
            if let ioRuns = io.runs(for: calendar) {
                result += exactRunServices(
                    line: line, direction: direction,
                    stations: stations, offsets: offsets,
                    startIndex: startIdx, runs: ioRuns,
                    trainType: pattern.trainType, tag: "org\(n)", calendar: calendar
                )
            } else {
                let originMinutes = io.departures(for: calendar)
                    .compactMap { parseMinutes($0) }
                    .sorted()
                result += runServices(
                    line: line, direction: direction,
                    stations: stations, offsets: offsets, destination: destination,
                    startIndex: startIdx, originMinutes: originMinutes,
                    trainType: pattern.trainType, tag: "org\(n)"
                )
            }
        }
        let expressRuns = direction.expressRuns(for: calendar)
        if !expressRuns.isEmpty {
            result += exactRunServices(
                line: line, direction: direction,
                stations: stations, offsets: offsets,
                startIndex: 0, runs: expressRuns,
                trainType: pattern.trainType, tag: "exp", calendar: calendar
            )
        }
        return result
    }

    private static func exactRunServices(
        line: StaticTrainLine,
        direction: StaticLineDirection,
        stations: [Station],
        offsets: [Double],
        startIndex: Int,
        runs: [ExactRun],
        trainType: TrainService.TrainType,
        tag: String,
        calendar: ScheduleCalendar
    ) -> [TrainService] {
        let baseOffset = offsets[startIndex]
        return runs.compactMap { run in
            guard let origin = parseMinutes(run.departure) else { return nil }
            let exactKey = "\(calendar.rawValue)|\(direction.isAscending ? "A" : "D")|\(stations[startIndex].id)|\(run.departure)"
            let exactTimes = line.exactStationTimes?[exactKey]
            let endIndex: Int
            if let exactTimes {
                endIndex = min(startIndex + exactTimes.count - 1, stations.count - 1)
            } else if let terminusId = run.terminusStationId {
                guard let idx = stations.firstIndex(where: { $0.id == terminusId }),
                      idx > startIndex else { return nil }
                endIndex = idx
            } else {
                endIndex = stations.count - 1
            }
            // stopIndices / stopPatterns are ABSOLUTE indices into line.stations;
            // stations/i here are direction-ordered, so map to absolute before testing.
            let effectiveType = run.trainType ?? trainType
            let stopSet = run.stopIndices.map(Set.init) ?? line.stopPatterns[effectiveType]
            let n = stations.count
            let serviceId = "\(line.id).\(direction.id).\(tag).\(timeString(origin))"
            let entries = (startIndex...endIndex).compactMap { i -> TimetableEntry? in
                let absI = direction.isAscending ? i : (n - 1 - i)
                if let exactTimes {
                    let m = exactTimes[i - startIndex]
                    guard m >= 0 else { return nil }
                    let time = timeString(m)
                    return TimetableEntry(
                        id: "\(serviceId)_\(i)",
                        stationId: stations[i].id,
                        arrivalTime: i == startIndex ? nil : time,
                        departureTime: i == endIndex ? nil : time
                    )
                }
                if let stopSet, i != startIndex, i != endIndex, !stopSet.contains(absI) {
                    return nil  // express passes through this station
                }
                let time = timeString(origin + Int((offsets[i] - baseOffset).rounded()))
                return TimetableEntry(
                    id: "\(serviceId)_\(i)",
                    stationId: stations[i].id,
                    arrivalTime: i == startIndex ? nil : time,
                    departureTime: i == endIndex ? nil : time
                )
            }
            return TrainService(
                id: serviceId,
                lineId: line.id,
                trainType: effectiveType,
                direction: direction.isAscending ? .outbound : .inbound,
                timetable: entries,
                destinationStationId: stations[endIndex].id,
                originatesAtStart: run.startsHere
            )
        }
    }

    private static func runServices(
        line: StaticTrainLine,
        direction: StaticLineDirection,
        stations: [Station],
        offsets: [Double],
        destination: Station,
        startIndex: Int,
        originMinutes: [Int],
        trainType: TrainService.TrainType,
        tag: String
    ) -> [TrainService] {
        let baseOffset = offsets[startIndex]
        return originMinutes.map { origin in
            let serviceId = "\(line.id).\(direction.id).\(tag).\(timeString(origin))"
            let entries = (startIndex..<stations.count).map { i -> TimetableEntry in
                let time = timeString(origin + Int((offsets[i] - baseOffset).rounded()))
                return TimetableEntry(
                    id: "\(serviceId)_\(i)",
                    stationId: stations[i].id,
                    arrivalTime: i == startIndex ? nil : time,
                    departureTime: i == stations.count - 1 ? nil : time
                )
            }
            return TrainService(
                id: serviceId,
                lineId: line.id,
                trainType: trainType,
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
            let stations = orderedStations(line: line, direction: direction)
            guard stations.contains(where: { $0.id == stationId }),
                  stations.last?.id != stationId,  // no departures toward a direction from its terminus
                  let destination = stations.last
            else { return nil }

            struct Row { let time: String; let type: TrainService.TrainType; let originatesHere: Bool; let destJa: String; let destEn: String }
            let stationsById = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
            let directionServices = line.timetableRuns != nil
                ? services(for: line, calendar: calendar).filter { ($0.direction == .outbound) == direction.isAscending }
                : services(for: line, direction: direction, calendar: calendar)
            var byMinute: [Int: Row] = [:]
            for service in directionServices {
                guard let idx = service.timetable.firstIndex(where: { $0.stationId == stationId }),
                      let time = service.timetable[idx].departureTime,
                      let secs = TimetableEntry.parseRailTime(time)
                else { continue }
                let minute = secs / 60
                let originatesHere = idx == 0 && service.originatesAtStart
                if let existing = byMinute[minute], existing.originatesHere || !originatesHere { continue }
                let dest = stationsById[service.destinationStationId] ?? destination
                byMinute[minute] = Row(
                    time: time, type: service.trainType, originatesHere: originatesHere,
                    destJa: service.throughDestinationName ?? dest.name,
                    destEn: service.throughDestinationNameEn ?? dest.nameEn
                )
            }
            guard let lastMinute = byMinute.keys.max() else { return nil }

            let departures = byMinute.keys.sorted().enumerated().map { (i, minute) -> StationDeparture in
                let row = byMinute[minute]!
                return StationDeparture(
                    id: "\(line.id).\(direction.id).\(stationId)_\(i)",
                    departureTime: row.time,
                    trainType: row.type,
                    destinationName: row.destJa,
                    destinationNameEn: row.destEn,
                    trainNumber: "",
                    isFirst: row.originatesHere,  // 当駅始発
                    isLast: minute == lastMinute
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
