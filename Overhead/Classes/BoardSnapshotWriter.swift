import Foundation
import Backbone
import WidgetKit

/// Flattens today's departures for the favorite origins into the App Group.
/// All timetable work happens here; the extension only renders.
nonisolated enum BoardSnapshotWriter {

    private static let directionChoicesKey = "nearby.directionChoices"

    /// How far ahead the snapshot covers when the app stays closed.
    private static let coveredDays = 7

    @MainActor
    static func refresh() {
        Task { await rebuild() }
    }

    @MainActor
    static func rebuild() async {
        let places = SavedPlaceStore.load()
        let titles = Dictionary(uniqueKeysWithValues: places.map { place in
            (place.id, place.customName.isEmpty
                ? String(localized: String.LocalizationValue(place.kind.localizationKey))
                : place.customName)
        })
        await Task.detached(priority: .utility) {
            let snapshot = build(places: places, titles: titles)
            #if DEBUG
            NSLog("[OverheadBoard] snapshot %@ later days %@ alternate %@",
                  snapshot.railDay,
                  (snapshot.laterDays ?? [:]).sorted { $0.key < $1.key }
                      .map { "\($0.key)=\($0.value.rawValue)" }.joined(separator: ","),
                  snapshot.alternateStations == nil ? "no" : "yes")
            #endif
            guard BoardSnapshotStore.save(snapshot) else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }.value
    }

    private static func build(places: [SavedPlace], titles: [UUID: String]) -> StationBoardSnapshot {
        let lines = StaticTrainData.trainLines().filter { !$0.id.hasPrefix("Custom:") }
        // The widget reads the system clock, so the snapshot does too.
        let now = Date()
        let calendar = ScheduleCalendar.current(at: now)
        let choices = (UserDefaults.standard.dictionary(forKey: directionChoicesKey)
            as? [String: String]) ?? [:]

        var stationNames: [String] = []
        for place in places {
            guard let line = lines.first(where: { $0.id == place.lineId }),
                  let station = line.stations.first(where: { $0.id == place.fromStationId })
            else { continue }
            if !stationNames.contains(station.name) {
                stationNames.append(station.name)
            }
        }

        let stations = stationNames.compactMap { name in
            boardStation(named: name, lines: lines, calendar: calendar, choices: choices)
        }

        // Tomorrow's board is the only one worth a second copy; later days reuse whichever matches.
        let nextCalendar = ScheduleCalendar.current(at: now.addingTimeInterval(86400))
        let alternateCalendar = nextCalendar == calendar ? nil : nextCalendar
        let boardLineIds = Set(stations.flatMap { $0.lines.map(\.lineId) })
        let firstRevisionDay = boardLineIds
            .flatMap { StaticTrainData.upcomingRevisions(forLineId: $0, on: now) }
            .compactMap(\.validFromDayKey)
            .min()
        var laterDays: [String: BoardDayKind] = [:]
        for offset in 1...coveredDays {
            let date = now.addingTimeInterval(TimeInterval(offset) * 86400)
            let day = BoardSnapshotStore.railDay(for: date)
            if let firstRevisionDay, let key = Int(day), key >= firstRevisionDay { break }
            let dayCalendar = ScheduleCalendar.current(at: date)
            if dayCalendar == calendar {
                laterDays[day] = .same
            } else if dayCalendar == alternateCalendar {
                laterDays[day] = .alternate
            } else {
                break
            }
        }
        let alternateStations = alternateCalendar.flatMap { alternate in
            laterDays.values.contains(.alternate)
                ? stationNames.compactMap { name in
                    boardStation(named: name, lines: lines, calendar: alternate, choices: choices)
                }
                : nil
        }

        return StationBoardSnapshot(
            railDay: BoardSnapshotStore.railDay(for: now),
            stations: stations,
            places: places.compactMap { boardPlace($0, lines: lines, titles: titles) },
            laterDays: laterDays.isEmpty ? nil : laterDays,
            alternateStations: alternateStations
        )
    }

    private static func boardStation(
        named name: String,
        lines: [TrainLine],
        calendar: ScheduleCalendar,
        choices: [String: String]
    ) -> BoardStation? {
        var boardLines: [BoardLine] = []
        var displayName = name
        for line in lines {
            guard let station = line.stations.first(where: { $0.name == name }),
                  let staticLine = StaticTrainData.line(withId: line.id) else { continue }
            let timetables = StaticTimetableGenerator.stationTimetables(
                forLineId: staticLine.id, stationId: station.id, calendar: calendar
            )
            guard !timetables.isEmpty else { continue }
            displayName = station.localizedName

            let chosenId = choices["\(name)|\(line.id)"]
            let directions = timetables.enumerated().map { index, timetable in
                let ascending = staticLine.directions
                    .first(where: { $0.id == timetable.railDirection })?.isAscending
                return BoardDirection(
                    directionId: timetable.railDirection,
                    name: timetable.localizedDirectionName,
                    isPrimary: chosenId.map { $0 == timetable.railDirection } ?? (index == 0),
                    departures: timetable.departures.map {
                        boardDeparture($0, line: line, staticLine: staticLine,
                                       stationId: station.id, ascending: ascending,
                                       calendar: calendar)
                    }
                )
            }
            boardLines.append(BoardLine(
                lineId: line.id,
                name: line.localizedName,
                colorHex: line.colorHex,
                stationCode: station.stationCode,
                directions: directions
            ))
        }
        guard !boardLines.isEmpty else { return nil }
        return BoardStation(name: name, displayName: displayName, lines: boardLines)
    }

    private static func boardDeparture(
        _ departure: StationDeparture,
        line: TrainLine,
        staticLine: StaticTrainLine,
        stationId: String,
        ascending: Bool?,
        calendar: ScheduleCalendar
    ) -> BoardDeparture {
        BoardDeparture(
            time: departure.departureTime,
            typeName: departure.trainType.localizedDisplayName,
            tier: tier(of: departure.trainType),
            destName: departure.localizedDestination,
            // Looked up by the Japanese name; only that one matches the station list.
            destCode: destinationCode(named: departure.destinationName, line: line),
            isOrigin: departure.isFirst,
            platform: ascending.flatMap {
                staticLine.platform(atStationId: stationId, ascending: $0,
                                    departure: departure.departureTime, calendar: calendar)
            }
        )
    }

    private static func tier(of type: TrainService.TrainType) -> BoardTier {
        switch type {
        case .local:
            return .local
        case .rapid, .sectionRapid, .commuterRapid, .specialRapid:
            return .rapid
        case .semiExpress, .sectionSemiExpress, .commuterSemiExpress,
             .express, .sectionExpress, .rapidExpress, .commuterExpress:
            return .express
        case .liner, .rapidLimitedExpress, .limitedExpress, .commuterLimitedExpress:
            return .limited
        @unknown default:
            return .local
        }
    }

    private static func destinationCode(named name: String, line: TrainLine) -> String {
        line.stations.first(where: { $0.name == name })?.stationCode ?? ""
    }

    private static func boardPlace(_ place: SavedPlace, lines: [TrainLine], titles: [UUID: String]) -> BoardPlace? {
        guard let line = lines.first(where: { $0.id == place.lineId }) else { return nil }
        let dest = lines.lazy
            .compactMap { $0.stations.first(where: { $0.id == place.toStationId }) }
            .first
        guard let dest else { return nil }
        let title = titles[place.id] ?? place.customName
        return BoardPlace(
            id: place.id,
            title: title,
            destName: dest.localizedName,
            destCode: dest.stationCode,
            colorHex: StaticTrainData.line(containingStationId: dest.id)?.colorHex ?? line.colorHex
        )
    }
}
