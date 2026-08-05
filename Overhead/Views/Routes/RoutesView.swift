import SwiftUI
import Backbone

// MARK: - Favorites Section (旅程)

struct FavoritesSection: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var places: [SavedPlace] = []
    @State private var editorTarget: EditorTarget?
    /// Upcoming departures from each favorite's origin, as rail seconds.
    @State private var departuresByPlace: [UUID: [Int]] = [:]

    private static let cardWidth: CGFloat = 176
    private static let cardHeight: CGFloat = 92
    private static let sectionHeight: CGFloat = 122

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

    /// How the saved pair is rideable: one train, 直通, or with transfers.
    private enum RouteMode {
        case direct
        case through
        case transfer
    }

    private typealias ResolvedPlace = (line: TrainLine, from: Station, to: Station, vias: [Station], mode: RouteMode)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Section.Favorites")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            rail
        }
        .frame(height: Self.sectionHeight, alignment: .top)
        .task {
            await viewModel.loadLines()
        }
        .task(id: placesSignature) {
            await recomputeDepartures()
        }
        .onAppear { places = SavedPlaceStore.load() }
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
        }
    }

    // MARK: - Rail

    private var rail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(alignment: .top, spacing: 10) {
                    ForEach(places) { place in
                        if let resolved = resolve(place) {
                            placeCard(place: place, resolved: resolved, at: context.date)
                        } else {
                            brokenPlaceCard(place: place)
                        }
                    }
                    addTile
                    if places.isEmpty {
                        emptyHint
                    }
                }
            }
        }
        .scrollClipDisabled()
    }

    private func placeCard(
        place: SavedPlace,
        resolved: ResolvedPlace,
        at date: Date
    ) -> some View {
        Button {
            Task { await start(place, resolved: resolved) }
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
            .frame(width: Self.cardWidth, height: Self.cardHeight, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
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
        .frame(width: Self.cardWidth, height: Self.cardHeight, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                .frame(width: 56, height: Self.cardHeight)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            Color(.systemGray4),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Button.AddPlace")
    }

    private var emptyHint: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Place.EmptyTitle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Place.EmptyDescription")
                .font(.system(size: 11.5))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 240, height: Self.cardHeight, alignment: .leading)
        .padding(.leading, 6)
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
        guard let line = viewModel.availableLines.first(where: { $0.id == place.lineId }),
              let from = line.stations.first(where: { $0.id == place.fromStationId })
        else { return nil }

        let vias = place.viaStationIds.compactMap(station(withId:))
        guard vias.count == place.viaStationIds.count else { return nil }

        if let to = line.stations.first(where: { $0.id == place.toStationId }) {
            return (line, from, to, vias, vias.isEmpty ? .direct : .transfer)
        }

        for group in StaticTrainData.throughDestinations(fromLineId: line.id, boardingStationId: from.id) {
            if let to = group.stations.first(where: { $0.id == place.toStationId }) {
                return (line, from, to, vias, vias.isEmpty ? .through : .transfer)
            }
        }

        if let to = station(withId: place.toStationId) {
            return (line, from, to, vias, .transfer)
        }
        return nil
    }

    private func station(withId id: String) -> Station? {
        for line in viewModel.availableLines {
            if let station = line.stations.first(where: { $0.id == id }) {
                return station
            }
        }
        return nil
    }

    private func start(_ place: SavedPlace, resolved: ResolvedPlace) async {
        let names = [resolved.from.name] + resolved.vias.map(\.name) + [resolved.to.name]
        let avoided = Set(place.avoidedLineIds)
        let transferMinutes = place.walkingSpeed.transferMinutes

        if place.ignoreTimetable || JourneyMode.current.ignoresTimetable {
            startCandidate(viewModel.searchRouteOptions(
                stationNames: names,
                transferMinutes: transferMinutes,
                avoidingLineIds: avoided
            ).first)
            return
        }

        if resolved.mode != .transfer {
            await viewModel.startJourney(
                line: resolved.line,
                from: resolved.from,
                to: resolved.to
            )
            return
        }

        startCandidate(viewModel.searchTrainCandidates(
            stationNames: names,
            anchor: .departure(Date()),
            transferMinutes: transferMinutes,
            avoidingLineIds: avoided
        ).first ?? viewModel.searchRouteOptions(
            stationNames: names,
            transferMinutes: transferMinutes,
            avoidingLineIds: avoided
        ).first)
    }

    private func startCandidate(_ candidate: TrainCandidate?) {
        if let candidate {
            viewModel.startJourney(candidate: candidate)
        } else {
            viewModel.errorMessage = String(localized: "Setup.NoRoute")
        }
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
             towardId: place.viaStationIds.first ?? place.toStationId)
        }
        guard !targets.isEmpty else {
            departuresByPlace = [:]
            return
        }
        departuresByPlace = await Task.detached(priority: .userInitiated) { () -> [UUID: [Int]] in
            var result: [UUID: [Int]] = [:]
            let calendar = ScheduleCalendar.current()
            for target in targets {
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

    private static func timetable(
        line: StaticTrainLine,
        fromId: String,
        towardId: String,
        calendar: ScheduleCalendar
    ) -> StationTimetableData? {
        let timetables = StaticTimetableGenerator.stationTimetables(
            for: line, stationId: fromId, calendar: calendar
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

    /// Before 03:00 the clock reads as 24+ so post-midnight departures compare correctly.
    private static func railNowSeconds(at date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        let seconds = (parts.hour ?? 0) * 3600 + (parts.minute ?? 0) * 60 + (parts.second ?? 0)
        return seconds < 3 * 3600 ? seconds + 24 * 3600 : seconds
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
