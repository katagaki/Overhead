import SwiftUI
import Backbone

// MARK: - Places View (場所)

/// Saved places: any number of labelled routes (自宅・職場・学校・カスタム),
/// each startable with one tap.
struct PlacesView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var places: [SavedPlace] = []

    var body: some View {
        NavigationStack {
            Group {
                if places.isEmpty {
                    emptyState
                } else {
                    placesList
                }
            }
            .navigationTitle("NavigationTitle.Places")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        PlaceEditorView(
                            existingPlace: nil,
                            availableLines: viewModel.availableLines,
                            onSave: { upsert($0) }
                        )
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Button.AddPlace")
                }
            }
            .task {
                await viewModel.loadLines()
            }
            .onAppear { places = SavedPlaceStore.load() }
        }
    }

    // MARK: - List

    private var placesList: some View {
        List {
            ForEach(places) { place in
                if let resolved = resolve(place) {
                    placeRow(place: place, resolved: resolved)
                } else {
                    brokenPlaceRow(place: place)
                }
            }
            .onDelete { offsets in
                places.remove(atOffsets: offsets)
                SavedPlaceStore.save(places)
            }
        }
    }

    @ViewBuilder
    private func placeRow(
        place: SavedPlace,
        resolved: (line: TrainLine, from: Station, to: Station, isThrough: Bool)
    ) -> some View {
        NavigationLink {
            PlaceEditorView(
                existingPlace: place,
                availableLines: viewModel.availableLines,
                onSave: { upsert($0) }
            )
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

                    HStack(spacing: 5) {
                        Text(resolved.from.localizedName)
                        Image(systemName: resolved.isThrough ? "arrow.triangle.branch" : "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Text(resolved.to.localizedName)
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

                Button {
                    Task {
                        await viewModel.startJourney(
                            line: resolved.line,
                            from: resolved.from,
                            to: resolved.to
                        )
                    }
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(resolved.line.color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Button.StartJourney")
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func brokenPlaceRow(place: SavedPlace) -> some View {
        HStack(spacing: 14) {
            Image(systemName: place.kind.iconName)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName(of: place))
                    .font(.system(size: 16, weight: .semibold))
                Text("Place.Unresolvable")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Place.EmptyTitle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            Text("Place.EmptyDescription")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Helpers

    private func displayName(of place: SavedPlace) -> String {
        if !place.customName.isEmpty {
            return place.customName
        }
        return String(localized: String.LocalizationValue(place.kind.localizationKey))
    }

    /// Resolves a place's stations. The alighting station may live on a
    /// connecting line reached via a through service (直通) past a junction.
    private func resolve(_ place: SavedPlace) -> (line: TrainLine, from: Station, to: Station, isThrough: Bool)? {
        guard let line = viewModel.availableLines.first(where: { $0.id == place.lineId }),
              let from = line.stations.first(where: { $0.id == place.fromStationId })
        else { return nil }

        if let to = line.stations.first(where: { $0.id == place.toStationId }) {
            return (line, from, to, false)
        }

        for group in StaticTrainData.throughDestinations(fromLineId: line.id, boardingStationId: from.id) {
            if let to = group.stations.first(where: { $0.id == place.toStationId }) {
                return (line, from, to, true)
            }
        }
        return nil
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

// MARK: - Place Editor View

struct PlaceEditorView: View {
    let existingPlace: SavedPlace?
    let availableLines: [TrainLine]
    let onSave: (SavedPlace) -> Void

    @State private var kind: SavedPlace.Kind = .home
    @State private var customName: String = ""
    @State private var line: TrainLine?
    @State private var fromStation: Station?
    @State private var toStation: Station?
    @Environment(\.dismiss) private var dismiss

    // Through-service (直通) destinations reachable from the boarding station.
    private var throughGroups: [StaticTrainData.ThroughDestinationGroup] {
        guard let line else { return [] }
        return StaticTrainData.throughDestinations(
            fromLineId: line.id,
            boardingStationId: fromStation?.id
        )
    }

    var body: some View {
        Form {
            Section("Place.Kind") {
                Picker("Place.Kind", selection: $kind) {
                    ForEach(SavedPlace.Kind.allCases, id: \.self) { kind in
                        Label(
                            LocalizedStringKey(kind.localizationKey),
                            systemImage: kind.iconName
                        ).tag(kind)
                    }
                }
                .pickerStyle(.menu)
                // Keep the menu's symbols monochrome instead of line-color tinted
                .tint(.primary)

                TextField("Place.NamePlaceholder", text: $customName)
            }

            Section("Section.BoardingStation") {
                NavigationLink {
                    StationSearchSelectionView(lines: availableLines) { hit in
                        if hit.line.id != line?.id {
                            toStation = nil
                        }
                        line = hit.line
                        fromStation = hit.station
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(line?.color ?? .secondary)
                        if let from = fromStation, let line {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(from.localizedName)
                                Text(line.localizedName)
                                    .font(.system(size: 12))
                                    .foregroundColor(line.color)
                            }
                        } else {
                            Text("StationSearch.Prompt")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if let line, fromStation != nil {
                Section("Section.AlightingStation") {
                    Picker(selection: $toStation) {
                        Text("Picker.SelectStation").tag(nil as Station?)
                        Section(line.localizedName) {
                            ForEach(line.stations) { station in
                                stationPickerLabel(station: station).tag(station as Station?)
                            }
                        }
                        ForEach(throughGroups, id: \.service) { group in
                            Section {
                                ForEach(group.stations) { station in
                                    stationPickerLabel(station: station).tag(station as Station?)
                                }
                            } header: {
                                Text("Picker.ThroughSection \(group.service.localizedLineName)")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(line.color)
                            Text("Section.AlightingStation")
                        }
                    }
                }
            }

            if canSave {
                Section {
                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Button.SavePlace")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(line?.color ?? Color.accentColor)
                }
            }
        }
        .navigationTitle(existingPlace == nil ? "Place.NewTitle" : "Place.EditTitle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard line == nil, let existing = existingPlace else { return }
            kind = existing.kind
            customName = existing.customName
            let savedLine = availableLines.first(where: { $0.id == existing.lineId })
            line = savedLine
            fromStation = savedLine?.stations.first(where: { $0.id == existing.fromStationId })
            toStation = savedLine?.stations.first(where: { $0.id == existing.toStationId })
                ?? throughStation(withId: existing.toStationId)
        }
    }

    private var canSave: Bool {
        guard let from = fromStation, let to = toStation, line != nil else { return false }
        if kind == .custom && customName.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        return from.id != to.id
    }

    private func save() {
        guard let line, let from = fromStation, let to = toStation else { return }
        let place = SavedPlace(
            id: existingPlace?.id ?? UUID(),
            kind: kind,
            customName: customName.trimmingCharacters(in: .whitespaces),
            lineId: line.id,
            fromStationId: from.id,
            toStationId: to.id
        )
        onSave(place)
        dismiss()
    }

    private func throughStation(withId id: String) -> Station? {
        for group in throughGroups {
            if let station = group.stations.first(where: { $0.id == id }) {
                return station
            }
        }
        return nil
    }

    @ViewBuilder
    private func stationPickerLabel(station: Station) -> some View {
        if station.stationCode.isEmpty {
            Text(station.localizedName)
        } else {
            Text("\(station.stationCode) \(station.localizedName)")
        }
    }
}

// MARK: - Station Search Selection

/// Searchable list of every bundled station; calls `onSelect` and dismisses.
/// Shows the nearest stations on top when location access is granted.
struct StationSearchSelectionView: View {
    let lines: [TrainLine]
    /// Whether to show a close button (for sheet presentation). When pushed
    /// onto an existing navigation stack, the back button suffices.
    var showsCloseButton: Bool = false
    let onSelect: (StationSearchHit) -> Void

    @State private var searchText = ""
    @StateObject private var nearbyProvider = NearbyStationsProvider()
    @Environment(\.dismiss) private var dismiss

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        List {
            if trimmedQuery.isEmpty {
                if !nearbyProvider.nearestStations.isEmpty {
                    Section("StationSearch.Nearby") {
                        ForEach(nearbyProvider.nearestStations) { nearby in
                            nearbyRow(nearby)
                        }
                    }
                }

                ForEach(lines) { line in
                    Section(line.localizedName) {
                        ForEach(line.stations) { station in
                            selectionRow(hit: StationSearchHit(line: line, station: station))
                        }
                    }
                }
            } else {
                let results = StationSearch.search(lines: lines, query: trimmedQuery)
                if results.isEmpty {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("StationSearch.NoResults")
                    }
                    .foregroundColor(.secondary)
                } else {
                    ForEach(results) { hit in
                        selectionRow(hit: hit)
                    }
                }
            }
        }
        .listStyle(.grouped)
        .searchable(text: $searchText, prompt: Text("StationSearch.Prompt"))
        .navigationTitle("ViewTitle.Stations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26.0, *) {
                        // System close role: standard neutral glyph, ignores tint
                        Button(role: .close) {
                            dismiss()
                        }
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .tint(.secondary)
                        .accessibilityLabel("Button.Close")
                    }
                }
            }
        }
        .onAppear {
            nearbyProvider.refresh(lines: lines)
        }
    }

    private func selectionRow(hit: StationSearchHit) -> some View {
        Button {
            onSelect(hit)
            dismiss()
        } label: {
            StationSearchRow(hit: hit)
        }
        .foregroundColor(.primary)
    }

    private func nearbyRow(_ nearby: NearbyStation) -> some View {
        Button {
            onSelect(nearby.hit)
            dismiss()
        } label: {
            HStack {
                StationSearchRow(hit: nearby.hit)
                Spacer()
                Text(nearby.formattedDistance)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
    }
}
