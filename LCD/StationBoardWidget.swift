import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 発車標 Widgets

nonisolated enum LED {
    static let board = Color(hex: "#0C0E11")
    static let local = Color(hex: "#C8CCD2")
    static let amber = Color(hex: "#FFB000")
    static let white = Color(hex: "#F4F6F2")
    static let green = Color(hex: "#3BD16F")
    static let label = Color.white.opacity(0.52)
    static let rule = Color.white.opacity(0.10)
}

nonisolated extension BoardTier {
    var color: Color {
        switch self {
        case .local: return LED.local
        case .rapid: return .red
        case .express: return .orange
        case .limited: return .purple
        }
    }
}

nonisolated extension BoardDeparture {
    func minutesUntil(nowRailMinutes: Int) -> Int? {
        guard let minutes = railMinutes else { return nil }
        return minutes - nowRailMinutes
    }
}

// MARK: - Entities

struct BoardStationEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "駅")
    static let defaultQuery = BoardStationQuery()

    let id: String  // station name

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
}

struct BoardStationQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [BoardStationEntity] {
        identifiers.map { BoardStationEntity(id: $0) }
    }

    func suggestedEntities() async throws -> [BoardStationEntity] {
        (BoardSnapshotStore.load()?.stations ?? []).map { BoardStationEntity(id: $0.name) }
    }

    func defaultResult() async -> BoardStationEntity? {
        (try? await suggestedEntities())?.first
    }
}

struct BoardLineEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "路線")
    static let defaultQuery = BoardLineQuery()

    let id: String  // "station|lineId"
    let title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    var stationName: String { id.components(separatedBy: "|").first ?? "" }
    var lineId: String { id.components(separatedBy: "|").last ?? "" }

    static func all(stationName: String?) -> [BoardLineEntity] {
        guard let snapshot = BoardSnapshotStore.load() else { return [] }
        let stations = stationName.map { name in
            snapshot.stations.filter { $0.name == name }
        } ?? snapshot.stations
        return stations.flatMap { station in
            station.lines.map { line in
                BoardLineEntity(id: "\(station.name)|\(line.lineId)", title: line.name)
            }
        }
    }
}

struct BoardLineQuery: EntityQuery {
    @IntentParameterDependency<LineBoardIntent>(\.$station)
    var configuration

    private var selectedStation: String? {
        configuration?.station.id
    }

    func entities(for identifiers: [String]) async throws -> [BoardLineEntity] {
        let all = BoardLineEntity.all(stationName: nil)
        return identifiers.compactMap { id in all.first { $0.id == id } }
    }

    func suggestedEntities() async throws -> [BoardLineEntity] {
        BoardLineEntity.all(stationName: selectedStation)
    }

    func defaultResult() async -> BoardLineEntity? {
        BoardLineEntity.all(stationName: selectedStation).first
    }
}

struct BoardDirectionEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "方面")
    static let defaultQuery = BoardDirectionQuery()

    let id: String  // "station|lineId|directionId"
    let title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    var lineKey: String {
        id.components(separatedBy: "|").dropLast().joined(separator: "|")
    }
    var directionId: String { id.components(separatedBy: "|").last ?? "" }

    static func all(lineKey: String?) -> [BoardDirectionEntity] {
        guard let snapshot = BoardSnapshotStore.load() else { return [] }
        let parts = lineKey?.components(separatedBy: "|")
        return snapshot.stations.flatMap { station in
            station.lines.flatMap { line -> [BoardDirectionEntity] in
                if let parts, parts.count == 2,
                   parts[0] != station.name || parts[1] != line.lineId {
                    return []
                }
                return line.directions.map { direction in
                    BoardDirectionEntity(
                        id: "\(station.name)|\(line.lineId)|\(direction.directionId)",
                        title: direction.name
                    )
                }
            }
        }
    }
}

struct BoardDirectionQuery: EntityQuery {
    @IntentParameterDependency<LineBoardIntent>(\.$station, \.$line)
    var configuration

    private var selectedLineKey: String? {
        guard let configuration else { return nil }
        let line = configuration.line
        guard line.stationName == configuration.station.id else { return nil }
        return line.id
    }

    func entities(for identifiers: [String]) async throws -> [BoardDirectionEntity] {
        let all = BoardDirectionEntity.all(lineKey: nil)
        return identifiers.compactMap { id in all.first { $0.id == id } }
    }

    func suggestedEntities() async throws -> [BoardDirectionEntity] {
        BoardDirectionEntity.all(lineKey: selectedLineKey)
    }

    func defaultResult() async -> BoardDirectionEntity? {
        BoardDirectionEntity.all(lineKey: selectedLineKey).first
    }
}

// MARK: - Intents

struct StationBoardIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "駅の発車標"
    static let description = IntentDescription("選んだ駅の発車案内を表示します。")

    @Parameter(title: "駅")
    var station: BoardStationEntity?
}

struct LineBoardIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "一路線の発車案内"
    static let description = IntentDescription("選んだ駅・路線・方面の発車案内を表示します。")

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$station
            \.$line
            \.$direction
        }
    }

    @Parameter(title: "駅")
    var station: BoardStationEntity?

    @Parameter(title: "路線")
    var line: BoardLineEntity?

    @Parameter(title: "方面")
    var direction: BoardDirectionEntity?

    var selection: (station: String?, lineId: String?, directionId: String?) {
        let stationName = station?.id
        let line = line.flatMap { entity -> BoardLineEntity? in
            guard let stationName else { return entity }
            return entity.stationName == stationName ? entity : nil
        }
        let direction = direction.flatMap { entity -> BoardDirectionEntity? in
            guard let line else { return nil }
            return entity.lineKey == line.id ? entity : nil
        }
        return (stationName, line?.lineId, direction?.directionId)
    }
}

// MARK: - Timeline

struct BoardEntry: TimelineEntry {
    let date: Date
    let snapshot: StationBoardSnapshot?
    let stationName: String?
    let lineId: String?
    let directionId: String?

    init(
        date: Date,
        snapshot: StationBoardSnapshot?,
        stationName: String? = nil,
        lineId: String? = nil,
        directionId: String? = nil
    ) {
        self.date = date
        self.snapshot = snapshot
        self.stationName = stationName
        self.lineId = lineId
        self.directionId = directionId
    }
}

nonisolated func boardTimeline(
    snapshot base: StationBoardSnapshot?,
    stationName: String?,
    lineId: String? = nil,
    directionId: String? = nil
) -> Timeline<BoardEntry> {
    let snapshot = (base?.railDay == BoardSnapshotStore.railDay()) ? base : nil
    let now = Date()
    let start = Date(timeIntervalSince1970: (now.timeIntervalSince1970 / 60).rounded(.down) * 60)
    let entries = (0..<60).map { offset in
        BoardEntry(
            date: start.addingTimeInterval(TimeInterval(offset * 60)),
            snapshot: snapshot,
            stationName: stationName,
            lineId: lineId,
            directionId: directionId
        )
    }
    return Timeline(entries: entries, policy: .atEnd)
}

struct StationBoardProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BoardEntry {
        BoardEntry(date: Date(), snapshot: .sample)
    }

    func snapshot(for configuration: StationBoardIntent, in context: Context) async -> BoardEntry {
        let stored = BoardSnapshotStore.load() ?? (context.isPreview ? .sample : nil)
        return BoardEntry(
            date: Date(), snapshot: stored,
            stationName: configuration.station?.id
        )
    }

    func timeline(for configuration: StationBoardIntent, in context: Context) async -> Timeline<BoardEntry> {
        boardTimeline(
            snapshot: BoardSnapshotStore.load(),
            stationName: configuration.station?.id
        )
    }
}

struct LineBoardProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BoardEntry {
        BoardEntry(date: Date(), snapshot: .sample)
    }

    func snapshot(for configuration: LineBoardIntent, in context: Context) async -> BoardEntry {
        let stored = BoardSnapshotStore.load() ?? (context.isPreview ? .sample : nil)
        let selection = configuration.selection
        return BoardEntry(
            date: Date(), snapshot: stored,
            stationName: selection.station,
            lineId: selection.lineId,
            directionId: selection.directionId
        )
    }

    func timeline(for configuration: LineBoardIntent, in context: Context) async -> Timeline<BoardEntry> {
        let selection = configuration.selection
        return boardTimeline(
            snapshot: BoardSnapshotStore.load(),
            stationName: selection.station,
            lineId: selection.lineId,
            directionId: selection.directionId
        )
    }
}

// MARK: - Row Model

nonisolated struct BoardRowItem: Identifiable {
    let line: BoardLine
    let directionId: String
    let departure: BoardDeparture
    let minutesLeft: Int
    var id: String { "\(line.lineId)|\(directionId)|\(departure.time)" }
}

/// Upcoming departures across lines, in time order.
nonisolated func mergedRows(
    lines: [(BoardLine, BoardDirection)],
    nowRailMinutes: Int,
    limit: Int
) -> [BoardRowItem] {
    lines.flatMap { line, direction in
        direction.departures.compactMap { dep -> BoardRowItem? in
            guard let left = dep.minutesUntil(nowRailMinutes: nowRailMinutes), left >= 0 else { return nil }
            return BoardRowItem(line: line, directionId: direction.directionId, departure: dep, minutesLeft: left)
        }
    }
    .sorted { $0.minutesLeft < $1.minutesLeft }
    .prefix(limit)
    .map { $0 }
}

// MARK: - Board Views

nonisolated enum BoardCol {
    static let time: CGFloat = 41
    static let type: CGFloat = 42
    static let badge: CGFloat = 20
}

struct BoardColumnHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("時刻").frame(width: BoardCol.time, alignment: .trailing)
            Text("種別").frame(width: BoardCol.type, alignment: .leading)
            Color.clear.frame(width: BoardCol.badge, height: 1)
            Text("行先")
            Spacer(minLength: 4)
        }
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(LED.label)
        .padding(.vertical, 3)
    }
}

struct BoardRowView: View {
    let item: BoardRowItem

    private var typeColor: Color { item.departure.tier.color }

    var body: some View {
        HStack(spacing: 8) {
            Text(item.departure.time)
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .foregroundStyle(LED.amber)
                .frame(width: BoardCol.time, alignment: .trailing)
            Text(item.departure.typeName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(typeColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: BoardCol.type, alignment: .leading)
            destinationBadge
            Text(item.departure.destName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LED.white)
                .lineLimit(1)
            Spacer(minLength: 4)
            if item.departure.isOrigin {
                Text("当駅始発")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LED.green)
            }
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private var destinationBadge: some View {
        if item.departure.destCode.isEmpty {
            Color.clear.frame(width: BoardCol.badge, height: 1)
        } else {
            LCDStationNumberBadge(
                code: item.departure.destCode,
                color: Color(hex: item.line.colorHex),
                dimension: BoardCol.badge
            )
        }
    }
}

struct BoardRule: View {
    var body: some View {
        LED.rule.frame(maxWidth: .infinity).frame(height: 1)
    }
}

struct BoardEmptyView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "tram.fill")
                .font(.system(size: 18))
                .foregroundStyle(LED.label)
            Text("アプリを開いて更新")
                .font(.system(size: 11))
                .foregroundStyle(LED.label)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Station Board (systemMedium / systemLarge)

struct StationBoardView: View {
    let entry: BoardEntry
    @Environment(\.widgetFamily) private var family

    private var station: BoardStation? {
        guard let snapshot = entry.snapshot else { return nil }
        if let name = entry.stationName {
            return snapshot.stations.first { $0.name == name } ?? snapshot.stations.first
        }
        return snapshot.stations.first
    }

    var body: some View {
        Group {
            if let station {
                board(for: station)
            } else {
                BoardEmptyView()
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(LED.board, for: .widget)
    }

    private func board(for station: BoardStation) -> some View {
        let now = BoardSnapshotStore.railNowMinutes(at: entry.date)
        let primary = station.lines.compactMap { line in
            line.directions.first(where: \.isPrimary).map { (line, $0) }
        }
        let all = station.lines.flatMap { line in
            line.directions.map { (line, $0) }
        }
        let large = family == .systemLarge

        let shown = large ? all : primary

        return VStack(alignment: .leading, spacing: 0) {
            if large {
                VStack(spacing: 3) {
                    badges(for: shown, dimension: 24)
                    Text(station.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LED.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)
            } else {
                        HStack(spacing: 6) {
                    badges(for: shown, dimension: 18)
                    Text(station.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LED.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }

            BoardColumnHeader()
            BoardRule()
            rows(mergedRows(
                lines: large ? all : primary,
                nowRailMinutes: now,
                limit: large ? 8 : 4
            ))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func badges(for shown: [(BoardLine, BoardDirection)], dimension: CGFloat) -> some View {
        var seen: [BoardLine] = []
        for (line, _) in shown where !seen.contains(where: { $0.lineId == line.lineId }) {
            seen.append(line)
        }
        return HStack(spacing: 3) {
            ForEach(seen.prefix(6), id: \.lineId) { line in
                LCDStationNumberBadge(
                    code: line.stationCode,
                    color: Color(hex: line.colorHex),
                    dimension: dimension
                )
            }
        }
    }

    @ViewBuilder
    private func rows(_ items: [BoardRowItem]) -> some View {
        if items.isEmpty {
            Text("本日の運行は終了しました")
                .font(.system(size: 11))
                .foregroundStyle(LED.label)
                .padding(.vertical, 8)
        } else {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 { BoardRule() }
                BoardRowView(item: item)
            }
        }
    }
}

// MARK: - Line Board (systemSmall + accessories)

struct LineBoardView: View {
    let entry: BoardEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var contentMargins

    private var target: (station: BoardStation, line: BoardLine, direction: BoardDirection)? {
        guard let snapshot = entry.snapshot else { return nil }
        let station = entry.stationName
            .flatMap { name in snapshot.stations.first { $0.name == name } }
            ?? snapshot.stations.first
        guard let station else { return nil }

        let line = entry.lineId
            .flatMap { id in station.lines.first { $0.lineId == id } }
            ?? station.lines.first
        guard let line else { return nil }

        let direction = entry.directionId
            .flatMap { id in line.directions.first { $0.directionId == id } }
            ?? line.directions.first(where: \.isPrimary)
            ?? line.directions.first
        guard let direction else { return nil }

        return (station, line, direction)
    }

    private var upcoming: [BoardDeparture] {
        guard let target else { return [] }
        let now = BoardSnapshotStore.railNowMinutes(at: entry.date)
        return target.direction.departures.filter {
            ($0.minutesUntil(nowRailMinutes: now) ?? -1) >= 0
        }
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            inline
        case .accessoryRectangular:
            rectangular
                .containerBackground(.clear, for: .widget)
        case .accessoryCircular:
            circular
                .containerBackground(.clear, for: .widget)
        default:
            small
                .padding(contentMargins - 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .containerBackground(LED.board, for: .widget)
        }
    }

    // MARK: systemSmall

    private var small: some View {
        let deps = Array(upcoming.prefix(4))

        return Group {
            if let target, !deps.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(spacing: 2) {
                        LCDStationNumberBadge(
                            code: target.line.stationCode,
                            color: Color(hex: target.line.colorHex),
                            dimension: 24
                        )
                        Text(target.station.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LED.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            Text(deps.allSatisfy(\.isOrigin)
                             ? "\(target.direction.name) · 当駅始発"
                             : target.direction.name)
                            .font(.system(size: 10))
                            .foregroundStyle(LED.label)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 6)

                    VStack(spacing: 0) {
                        ForEach(Array(deps.enumerated()), id: \.offset) { index, dep in
                            if index > 0 { BoardRule() }
                            smallRow(dep, line: target.line)
                                .opacity(index == 0 ? 1 : 0.55)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                BoardEmptyView()
            }
        }
    }

    private func smallRow(_ dep: BoardDeparture, line: BoardLine) -> some View {
        HStack(spacing: 4) {
            Text(dep.time)
                .font(.system(size: 11, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .foregroundStyle(LED.amber)
                .frame(width: 33, alignment: .trailing)
            Text(dep.typeName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(dep.tier.color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 31, alignment: .leading)
            if !dep.destCode.isEmpty {
                LCDStationNumberBadge(
                    code: dep.destCode,
                    color: Color(hex: line.colorHex),
                    dimension: 14
                )
            }
            SquashedText(
                text: dep.destName,
                font: .system(size: 11, weight: .medium),
                color: LED.white
            )
        }
        .padding(.vertical, 2)
    }

    private var inline: some View {
        let now = BoardSnapshotStore.railNowMinutes(at: entry.date)
        return Group {
            if let target, let first = upcoming.first,
               let left = first.minutesUntil(nowRailMinutes: now) {
                Label(
                    "\(target.line.name) \(boundFor(first.destName)) \(left)分",
                    systemImage: "tram.fill"
                )
            } else {
                Label("発車情報なし", systemImage: "tram.fill")
            }
        }
    }

    private var rectangular: some View {
        let now = BoardSnapshotStore.railNowMinutes(at: entry.date)
        return Group {
            if let target, let first = upcoming.first,
               let left = first.minutesUntil(nowRailMinutes: now) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        LCDStationNumberBadge(
                            code: target.line.stationCode,
                            color: Color(hex: target.line.colorHex),
                            dimension: 17
                        )
                        .widgetAccentable()
                        SquashedText(
                            text: boundFor(first.destName),
                            font: .system(size: 11, weight: .medium),
                            color: .primary
                        )
                        Text(first.typeName)
                            .font(.system(size: 11, weight: .semibold))
                            .opacity(0.8)
                            .layoutPriority(1)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        countdownLine(left, unit: "分", size: 24, unitSize: 12)
                            .widgetAccentable()
                        Text("\(first.time)発")
                            .font(.system(size: 11, weight: .medium))
                            .monospacedDigit()
                            .opacity(0.7)
                        Spacer(minLength: 0)
                    }
                }
            } else {
                Label("発車情報なし", systemImage: "tram.fill")
                    .font(.system(size: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var circular: some View {
        let now = BoardSnapshotStore.railNowMinutes(at: entry.date)
        return Group {
            if let target, let first = upcoming.first,
               let left = first.minutesUntil(nowRailMinutes: now) {
                Gauge(value: ringFraction(first: first, now: now)) {
                    Text(target.line.stationCode)
                } currentValueLabel: {
                    Text("\(left)")
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                }
                .gaugeStyle(.accessoryCircular)
            } else {
                Image(systemName: "tram.fill")
            }
        }
    }

    /// 立川行 / for Tachikawa
    private func boundFor(_ destination: String) -> String {
        String(format: String(localized: "Board.Bound"), destination)
    }

    private func countdownLine(_ left: Int, unit: String, size: CGFloat, unitSize: CGFloat) -> Text {
        let number = Text("\(left)").font(.system(size: size, weight: .bold)).monospacedDigit()
        let suffix = Text(unit).font(.system(size: unitSize, weight: .semibold))
        return Text("\(number)\(suffix)")
    }

    private func ringFraction(first: BoardDeparture, now: Int) -> Double {
        guard let target, let depMinutes = first.railMinutes else { return 0 }
        let index = target.direction.departures.firstIndex { $0.time == first.time } ?? 0
        let previous = index > 0 ? target.direction.departures[index - 1].railMinutes : nil
        let span = max(1, depMinutes - (previous ?? (depMinutes - 15)))
        let left = max(0, depMinutes - now)
        return min(1, Double(left) / Double(span))
    }
}

// MARK: - Widgets

struct StationBoardWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "StationBoard",
            intent: StationBoardIntent.self,
            provider: StationBoardProvider()
        ) { entry in
            StationBoardView(entry: entry)
        }
        .configurationDisplayName("駅の発車標")
        .description("お気に入りの駅の発車案内を表示します。")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct LineBoardWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "LineBoard",
            intent: LineBoardIntent.self,
            provider: LineBoardProvider()
        ) { entry in
            LineBoardView(entry: entry)
        }
        .configurationDisplayName("一路線の発車案内")
        .description("選んだ駅・路線・方面の次の発車を表示します。")
        .supportedFamilies([.systemSmall, .accessoryInline, .accessoryRectangular, .accessoryCircular])
        .contentMarginsDisabled()
    }
}

// MARK: - Gallery Sample

nonisolated extension StationBoardSnapshot {
    /// Gallery placeholder; 中野's real lines give the badge column both plate shapes.
    static let sample = StationBoardSnapshot(
        railDay: BoardSnapshotStore.railDay(),
        stations: [
            BoardStation(name: "中野", lines: [
                BoardLine(
                    lineId: "Railway:TokyoMetro.Tozai", name: "東西線",
                    colorHex: "#00A7DB", stationCode: "T01",
                    directions: [BoardDirection(
                        directionId: "east", name: "西船橋方面", isPrimary: true,
                        departures: tozaiDeps
                    )]
                ),
                BoardLine(
                    lineId: "Railway:JR-East.ChuoRapid", name: "中央線快速",
                    colorHex: "#F15A22", stationCode: "JC06",
                    directions: [BoardDirection(
                        directionId: "east", name: "東京方面", isPrimary: true,
                        departures: chuoRapidDeps
                    )]
                ),
                BoardLine(
                    lineId: "Railway:JR-East.ChuoSobuLocal", name: "中央・総武線各駅停車",
                    colorHex: "#FFD400", stationCode: "JB07",
                    directions: [BoardDirection(
                        directionId: "east", name: "千葉方面", isPrimary: true,
                        departures: chuoSobuDeps
                    )]
                ),
            ]),
        ],
        places: []
    )

    private static func sampleTime(_ offset: Int) -> String {
        let m = BoardSnapshotStore.railNowMinutes() + offset
        return "\(m / 60):" + String(format: "%02d", m % 60)
    }

    private static var chuoRapidDeps: [BoardDeparture] {
        [
            BoardDeparture(time: sampleTime(6), typeName: "快速", tier: .rapid, destName: "東京", destCode: "JC01", isOrigin: false),
            BoardDeparture(time: sampleTime(13), typeName: "通勤特快", tier: .rapid, destName: "東京", destCode: "JC01", isOrigin: false),
        ]
    }

    private static var chuoSobuDeps: [BoardDeparture] {
        [
            BoardDeparture(time: sampleTime(4), typeName: "各停", tier: .local, destName: "津田沼", destCode: "JB33", isOrigin: false),
            BoardDeparture(time: sampleTime(11), typeName: "各停", tier: .local, destName: "千葉", destCode: "JB39", isOrigin: false),
        ]
    }

    private static var tozaiDeps: [BoardDeparture] {
        let now = BoardSnapshotStore.railNowMinutes()
        func t(_ offset: Int) -> String {
            let m = now + offset
            return "\(m / 60):" + String(format: "%02d", m % 60)
        }
        return [
            BoardDeparture(time: t(3), typeName: "快速", tier: .rapid, destName: "西船橋", destCode: "T23", isOrigin: true),
            BoardDeparture(time: t(9), typeName: "各停", tier: .local, destName: "東陽町", destCode: "T14", isOrigin: true),
            BoardDeparture(time: t(16), typeName: "快速", tier: .rapid, destName: "西船橋", destCode: "T23", isOrigin: true),
        ]
    }
}

// MARK: - Horizontal Squashing

/// Squashes rather than truncates; ported since the extension can't import the app's.
struct SquashedText: View {
    let text: String
    let font: Font
    let color: Color
    @State private var natural: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let scale = natural.width > geo.size.width && natural.width > 0
                ? geo.size.width / natural.width : 1
            label
                .fixedSize()
                .scaleEffect(x: scale, y: 1, anchor: .leading)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
        }
        .frame(height: natural.height == 0 ? nil : natural.height)
        .background(
            label
                .fixedSize()
                .hidden()
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: SquashSizeKey.self, value: proxy.size)
                })
        )
        .onPreferenceChange(SquashSizeKey.self) { natural = $0 }
    }

    private var label: some View {
        Text(text).font(font).foregroundStyle(color).lineLimit(1)
    }
}

private struct SquashSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        value = CGSize(width: max(value.width, next.width),
                       height: max(value.height, next.height))
    }
}

nonisolated func - (insets: EdgeInsets, inset: CGFloat) -> EdgeInsets {
    EdgeInsets(
        top: max(0, insets.top - inset),
        leading: max(0, insets.leading - inset),
        bottom: max(0, insets.bottom - inset),
        trailing: max(0, insets.trailing - inset)
    )
}
