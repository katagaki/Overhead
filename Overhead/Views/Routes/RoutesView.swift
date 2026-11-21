import SwiftUI
import Backbone

// MARK: - Favorites Section (旅程)

struct FavoritesSection: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var places: [SavedPlace] = []
    @ObservedObject private var installer = LineDataInstaller.shared
    @State private var editorTarget: EditorTarget?
    /// Upcoming departures from each favorite's origin, as rail seconds.
    @State private var departuresByPlace: [UUID: [Int]] = [:]

    /// Measured rail width; cards are sized from it, not from a fixed constant.
    @State private var railWidth: CGFloat = 0
    @Namespace private var editorZoom

    /// Matches the 12pt vertical gap down to the planner card.
    private static let cardSpacing: CGFloat = 12
    /// A half-card peeks at the trailing edge to say the rail scrolls.
    private static let visibleCards: CGFloat = 2.3
    private static let cardHeight: CGFloat = 92
    private static let sectionHeight: CGFloat = 92
    private static let cardShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    /// Keeps the add tiles reading as placeholders next to the glass cards.
    private var dashedOutline: some View {
        Self.cardShape.strokeBorder(
            Color(.systemGray4),
            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
        )
    }

    /// 2.3 cards and the 2 gaps between them, whatever the screen is.
    private var cardWidth: CGFloat {
        guard railWidth > 0 else { return 176 }
        return ((railWidth - Self.cardSpacing * 2) / Self.visibleCards).rounded()
    }

    private enum EditorTarget: Identifiable {
        case new
        case edit(SavedPlace)

        var id: String {
            switch self {
            case .new: return "new"
            case .edit(let place): return place.id.uuidString
            }
        }
    }

    private typealias RouteMode = FavoriteDeparture.RouteMode
    private typealias ResolvedPlace = FavoriteDeparture.Resolved

    var body: some View {
        rail
            .frame(height: Self.sectionHeight, alignment: .top)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { railWidth = $0 }
            // Trim the 24pt section gap down to the planner's tighter rhythm.
            .padding(.bottom, -12)
        .task {
            await viewModel.loadLines()
        }
        .task(id: placesSignature) {
            await recomputeDepartures()
        }
        .onAppear {
            places = SavedPlaceStore.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: SavedPlaceStore.didChangeNotification)) { _ in
            places = SavedPlaceStore.load()
        }
#if DEBUG
        .onReceive(ScreenshotStaging.shared.$placeEditorCommand) { command in
            guard let command else { return }
            ScreenshotStaging.shared.placeEditorCommand = nil
            switch command {
            case .new:
                editorTarget = .new
            case .editFirst:
                if let place = places.first { editorTarget = .edit(place) }
            }
        }
#endif
        .sheet(item: $editorTarget) { target in
            NavigationStack {
                PlaceEditorView(
                    existingPlace: {
                        if case .edit(let place) = target { return place }
                        return nil
                    }(),
                    availableLines: viewModel.availableLines,
                    onSave: { upsert($0) }
                )
            }
            .navigationTransition(.zoom(sourceID: target.id, in: editorZoom))
        }
    }

    // MARK: - Rail

    @ViewBuilder private var rail: some View {
        if places.isEmpty {
            emptyCard
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    HStack(alignment: .top, spacing: Self.cardSpacing) {
                        ForEach(places) { place in
                            if let resolved = resolve(place) {
                                placeCard(place: place, resolved: resolved, at: context.date)
                            } else if !SavedPlaceLineData.missingLines(for: place).isEmpty {
                                missingDataCard(place: place)
                            } else {
                                brokenPlaceCard(place: place)
                            }
                        }
                        addTile
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    private func placeCard(
        place: SavedPlace,
        resolved: ResolvedPlace,
        at date: Date
    ) -> some View {
        Button {
            Task { await FavoriteDeparture.start(place, resolved: resolved, viewModel: viewModel) }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Image(systemName: place.kind.iconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 7))
                    Text(displayName(of: place))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                }

                routeLine(resolved)

                Spacer(minLength: 0)

                countdownLabel(for: place, at: date)
            }
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 11, trailing: 12))
            .frame(width: cardWidth, height: Self.cardHeight, alignment: .topLeading)
            .glassEffect(.regular.interactive(), in: Self.cardShape)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: EditorTarget.edit(place).id, in: editorZoom)
        .accessibilityLabel("Button.StartJourney")
        .contextMenu {
            editButton(for: place)
            deleteButton(for: place)
        }
    }

    @ViewBuilder
    private func routeLine(_ resolved: ResolvedPlace) -> some View {
        let names = [resolved.from.localizedName]
            + resolved.vias.map(\.localizedName)
            + [resolved.to.localizedName]
        HStack(spacing: 4) {
            if names.count > 2 && names.joined().count > 9 {
                Text(resolved.from.localizedName)
                routeArrow(mode: resolved.mode)
                Text(resolved.to.localizedName)
            } else {
                Text(resolved.from.localizedName)
                ForEach(resolved.vias, id: \.id) { via in
                    routeArrow(mode: .transfer)
                    Text(via.localizedName)
                }
                routeArrow(mode: resolved.mode)
                Text(resolved.to.localizedName)
            }
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }

    private func routeArrow(mode: RouteMode) -> some View {
        Image(systemName: mode == .through ? "arrow.triangle.branch" : "arrow.right")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.tertiary)
    }

    /// Time to the next departure: m:ss inside 10 minutes, あとX分 beyond it.
    @ViewBuilder
    private func countdownLabel(for place: SavedPlace, at date: Date) -> some View {
        let departures = departuresByPlace[place.id]
        if let departures {
            let now = Self.railNowSeconds(at: date)
            if let next = departures.first(where: { $0 >= now }) {
                let remaining = next - now
                Group {
                    if remaining < 10 * 60 {
                        Text(verbatim: String(format: "%d:%02d", remaining / 60, remaining % 60))
                    } else {
                        Text("Candidate.DepartsIn \(remaining / 60)")
                    }
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(remaining <= 3 * 60 ? Color.red : Color.accentColor)
                .contentTransition(.numericText(countsDown: true))
                .animation(.default, value: remaining)
            } else {
                Text("Favorites.NoMoreTrains")
                    .font(.system(size: 14.5))
                    .foregroundStyle(.secondary)
            }
        } else {
            Text(verbatim: "--:--")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }

    /// The favourite is fine — its line data just is not on the device.
    private func missingDataCard(place: SavedPlace) -> some View {
        let missing = SavedPlaceLineData.missingLines(for: place)
        let downloading = installer.isDownloading

        return Button {
            Task { try? await installer.sync() }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Image(systemName: place.kind.iconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color(.systemGray3), in: RoundedRectangle(cornerRadius: 7))
                    Text(displayName(of: place))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                }
                HStack(spacing: 5) {
                    ForEach(missing.prefix(3)) { line in
                        LineSymbolBadge(symbol: line.symbol, color: Color(hex: line.colorHex),
                                        dimension: 18, styleOverride: line.badgeStyle,
                                        lineId: line.id)
                    }
                    if missing.count > 3 {
                        Text("+\(missing.count - 3)")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                HStack(spacing: 5) {
                    if downloading {
                        ProgressView().controlSize(.mini)
                        Text("Place.Downloading")
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                        Text(LineDataModel.formatted(bytes: installer.pendingBytes))
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.accentColor)
            }
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 11, trailing: 12))
            .frame(width: cardWidth, height: Self.cardHeight, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(downloading)
        .glassEffect(.regular, in: Self.cardShape)
        .contextMenu {
            deleteButton(for: place)
        }
        .accessibilityLabel(Text("Place.NeedsDownload"))
    }

    private func brokenPlaceCard(place: SavedPlace) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Image(systemName: place.kind.iconName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color(.systemGray3), in: RoundedRectangle(cornerRadius: 7))
                Text(displayName(of: place))
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            Text("Place.Unresolvable")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 11, trailing: 12))
        .frame(width: cardWidth, height: Self.cardHeight, alignment: .topLeading)
        .glassEffect(.regular, in: Self.cardShape)
        .matchedTransitionSource(id: EditorTarget.edit(place).id, in: editorZoom)
        .contextMenu {
            deleteButton(for: place)
        }
    }

    private var addTile: some View {
        Button {
            editorTarget = .new
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: cardWidth, height: Self.cardHeight)
                .background(dashedOutline)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: EditorTarget.new.id, in: editorZoom)
        .accessibilityLabel("Button.AddPlace")
    }

    /// Full-width add tile shown when nothing is saved.
    private var emptyCard: some View {
        Button {
            editorTarget = .new
        } label: {
            VStack(spacing: 4) {
                Label("Place.EmptyTitle", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Place.EmptyDescription")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: Self.cardHeight)
            .background(dashedOutline)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: EditorTarget.new.id, in: editorZoom)
        .accessibilityLabel("Button.AddPlace")
    }

    private func editButton(for place: SavedPlace) -> some View {
        Button {
            editorTarget = .edit(place)
        } label: {
            Label("Button.EditPlace", systemImage: "pencil")
        }
    }

    private func deleteButton(for place: SavedPlace) -> some View {
        Button(role: .destructive) {
            places.removeAll { $0.id == place.id }
            SavedPlaceStore.save(places)
        } label: {
            Label("Button.DeletePlace", systemImage: "trash")
        }
    }

    // MARK: - Helpers

    private func displayName(of place: SavedPlace) -> String {
        if !place.customName.isEmpty {
            return place.customName
        }
        return String(localized: String.LocalizationValue(place.kind.localizationKey))
    }

    private func resolve(_ place: SavedPlace) -> ResolvedPlace? {
        FavoriteDeparture.resolve(place, lines: viewModel.availableLines)
    }

    // MARK: - Departure computation

    private var placesSignature: String {
        places.map { "\($0.id)|\($0.lineId)|\($0.fromStationId)|\($0.toStationId)" }
            .joined(separator: ",")
    }

    private func recomputeDepartures() async {
        // Plain values captured on the main actor before hopping off it.
        let targets = places.map { place in
            (id: place.id,
             lineId: place.lineId,
             fromId: place.fromStationId,
             toId: place.toStationId,
             towardId: place.viaStationIds.first ?? place.toStationId,
             isOneRide: place.viaStationIds.isEmpty)
        }
        guard !targets.isEmpty else {
            departuresByPlace = [:]
            return
        }
        departuresByPlace = await Task.detached(priority: .userInitiated) { () -> [UUID: [Int]] in
            var result: [UUID: [Int]] = [:]
            let calendar = ScheduleCalendar.current()
            for target in targets {
                if target.isOneRide,
                   let departures = Self.departuresReaching(
                       lineId: target.lineId, fromId: target.fromId, toId: target.toId, calendar: calendar
                   ) {
                    result[target.id] = departures
                    continue
                }
                guard let line = StaticTrainData.line(withId: target.lineId),
                      let timetable = Self.timetable(
                          line: line,
                          fromId: target.fromId,
                          towardId: target.towardId,
                          calendar: calendar
                      )
                else { continue }
                result[target.id] = timetable.departures
                    .compactMap { TimetableEntry.parseRailTime($0.departureTime) }
                    .sorted()
            }
            return result
        }.value
    }

    /// Only trains that reach the favorite's destination, matching what tapping it can start.
    nonisolated private static func departuresReaching(
        lineId: String,
        fromId: String,
        toId: String,
        calendar: ScheduleCalendar
    ) -> [Int]? {
        guard let resolved = StaticTrainData.resolveJourneyLine(
            lineId: lineId, fromStationId: fromId, toStationId: toId
        ) else { return nil }
        return StaticTimetableGenerator.services(for: resolved.staticLine, calendar: calendar)
            .compactMap { service -> Int? in
                let stationIds = service.timetable.map(\.stationId)
                guard let fromIndex = stationIds.firstIndex(of: fromId),
                      let toIndex = stationIds.firstIndex(of: toId),
                      fromIndex < toIndex
                else { return nil }
                return service.timetable[fromIndex].departureSeconds()
            }
            .sorted()
    }

    nonisolated private static func timetable(
        line: StaticTrainLine,
        fromId: String,
        towardId: String,
        calendar: ScheduleCalendar
    ) -> StationTimetableData? {
        let timetables = StaticTimetableGenerator.stationTimetables(
            forLineId: line.id, stationId: fromId, calendar: calendar
        )
        guard !timetables.isEmpty else { return nil }

        var ascending: Bool?
        if let fromIndex = line.stations.firstIndex(where: { $0.id == fromId }) {
            if let towardIndex = line.stations.firstIndex(where: { $0.id == towardId }) {
                ascending = towardIndex > fromIndex
            } else {
                for group in StaticTrainData.throughDestinations(
                    fromLineId: line.id, boardingStationId: fromId
                ) where group.stations.contains(where: { $0.id == towardId }) {
                    ascending = group.service.end == .ascending
                    break
                }
            }
        }

        if let ascending,
           let direction = line.directions.first(where: { $0.isAscending == ascending }) {
            return timetables.first { $0.railDirection == direction.id }
        }
        return timetables.count == 1 ? timetables.first : nil
    }

    private static func railNowSeconds(at date: Date) -> Int {
        ServiceDay.railSeconds(at: RailClock.adjusted(date))
    }

    private func upsert(_ place: SavedPlace) {
        if let idx = places.firstIndex(where: { $0.id == place.id }) {
            places[idx] = place
        } else {
            places.append(place)
        }
        SavedPlaceStore.save(places)
    }
}
