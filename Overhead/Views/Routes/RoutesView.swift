import SwiftUI
import Backbone

// MARK: - Favorites Section (旅程)

struct FavoritesSection: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var places: [SavedPlace] = []
    @State private var editorTarget: EditorTarget?

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

                Button {
                    editorTarget = .new
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                }
                .accessibilityLabel("Button.AddPlace")
            }
            .padding(.leading, 4)
            .padding(.trailing, 4)

            if places.isEmpty {
                emptyState
            } else {
                placesList
            }
        }
        .task {
            await viewModel.loadLines()
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

    // MARK: - List

    private var placesList: some View {
        VStack(spacing: 0) {
            ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                if let resolved = resolve(place) {
                    placeRow(place: place, resolved: resolved)
                } else {
                    brokenPlaceRow(place: place)
                }
                if index < places.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    @ViewBuilder
    private func placeRow(
        place: SavedPlace,
        resolved: ResolvedPlace
    ) -> some View {
        HStack(spacing: 12) {
            Button {
                editorTarget = .edit(place)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: place.kind.iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(resolved.line.color)
                        .clipShape(RoundedRectangle(cornerRadius: 9))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(displayName(of: place))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: 5) {
                            Text(resolved.from.localizedName)
                            ForEach(resolved.vias, id: \.id) { via in
                                routeArrow(mode: .transfer)
                                Text(via.localizedName)
                            }
                            routeArrow(mode: resolved.mode)
                            Text(resolved.to.localizedName)

                            if resolved.mode == .transfer && resolved.vias.isEmpty {
                                Text("Label.Transfer")
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Capsule())
                            }
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                        Text(resolved.line.localizedName)
                            .font(.system(size: 12))
                            .foregroundColor(resolved.line.color)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                Task {
                    await start(place, resolved: resolved)
                }
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(resolved.line.color, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Button.StartJourney")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contextMenu {
            deleteButton(for: place)
        }
    }

    private func routeArrow(mode: RouteMode) -> some View {
        Image(systemName: mode == .through ? "arrow.triangle.branch" : "arrow.right")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
    }

    @ViewBuilder
    private func brokenPlaceRow(place: SavedPlace) -> some View {
        HStack(spacing: 14) {
            Image(systemName: place.kind.iconName)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName(of: place))
                    .font(.system(size: 16, weight: .semibold))
                Text("Place.Unresolvable")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contextMenu {
            deleteButton(for: place)
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

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Place.EmptyTitle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                Text("Place.EmptyDescription")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
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

        if place.ignoreTimetable {
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
            departure: Date(),
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

    private func upsert(_ place: SavedPlace) {
        if let idx = places.firstIndex(where: { $0.id == place.id }) {
            places[idx] = place
        } else {
            places.append(place)
        }
        SavedPlaceStore.save(places)
    }
}
