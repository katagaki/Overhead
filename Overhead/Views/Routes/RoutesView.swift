import SwiftUI
import Backbone

// MARK: - Favorites Section (場所)

/// Home-screen section for saved places: any number of labelled routes
/// (自宅・職場・学校・カスタム), each startable with one tap. Rendered as a
/// custom card so it sits inline in the home scroll view.
struct FavoritesSection: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var places: [SavedPlace] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Section.Favorites")
                    .font(.body)
                    .foregroundColor(.secondary)

                Spacer()

                NavigationLink {
                    PlaceEditorView(
                        existingPlace: nil,
                        availableLines: viewModel.availableLines,
                        onSave: { upsert($0) }
                    )
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
        resolved: (line: TrainLine, from: Station, to: Station, isThrough: Bool)
    ) -> some View {
        HStack(spacing: 12) {
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
                            .foregroundColor(.primary)

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
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contextMenu {
            deleteButton(for: place)
        }
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
    /// Shows the same physical station as a single row with every line's
    /// badge. Use only when the caller doesn't need a specific boarding line.
    var mergesStations: Bool = false
    let onSelect: (StationSearchHit) -> Void

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @StateObject private var nearbyProvider = NearbyStationsProvider()
    @Environment(\.dismiss) private var dismiss

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Every hit for each Japanese station name, across all lines.
    private var hitsByName: [String: [StationSearchHit]] {
        var result: [String: [StationSearchHit]] = [:]
        for line in lines {
            for station in line.stations {
                result[station.name, default: []].append(StationSearchHit(line: line, station: station))
            }
        }
        return result
    }

    var body: some View {
        List {
            if trimmedQuery.isEmpty {
                emptyQueryContent
            } else {
                searchResultsContent
            }
        }
        .listStyle(.grouped)
        .searchable(text: $searchText, prompt: Text("StationSearch.Prompt"))
        .searchFocused($searchFocused)
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
            searchFocused = true
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private var emptyQueryContent: some View {
        let allHits = mergesStations ? hitsByName : [:]

        if !nearbyProvider.nearestStations.isEmpty {
            Section("StationSearch.Nearby") {
                ForEach(nearbyProvider.nearestStations) { nearby in
                    nearbyRow(nearby, allHits: allHits)
                }
            }
        }

        ForEach(lines) { line in
            Section(line.localizedName) {
                ForEach(line.stations) { station in
                    let hit = StationSearchHit(line: line, station: station)
                    if mergesStations {
                        mergedRow(
                            primary: hit,
                            hits: allHits[station.name] ?? [hit]
                        )
                    } else {
                        selectionRow(hit: hit)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        let results = StationSearch.search(lines: lines, query: trimmedQuery)
        if results.isEmpty {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("StationSearch.NoResults")
            }
            .foregroundColor(.secondary)
        } else if mergesStations {
            let merged = mergeByStationName(results)
            ForEach(merged, id: \.primary.id) { group in
                mergedRow(primary: group.primary, hits: group.hits)
            }
        } else {
            ForEach(results) { hit in
                selectionRow(hit: hit)
            }
        }
    }

    /// Groups ranked search results by station name, preserving rank order.
    private func mergeByStationName(
        _ results: [StationSearchHit]
    ) -> [(primary: StationSearchHit, hits: [StationSearchHit])] {
        var order: [String] = []
        var grouped: [String: [StationSearchHit]] = [:]
        for hit in results {
            if grouped[hit.station.name] == nil {
                order.append(hit.station.name)
            }
            grouped[hit.station.name, default: []].append(hit)
        }
        return order.compactMap { name in
            guard let hits = grouped[name], let primary = hits.first else { return nil }
            return (primary, hits)
        }
    }

    // MARK: - Rows

    private func selectionRow(hit: StationSearchHit) -> some View {
        Button {
            onSelect(hit)
            dismiss()
        } label: {
            StationSearchRow(hit: hit)
        }
        .foregroundColor(.primary)
    }

    private func mergedRow(
        primary: StationSearchHit,
        hits: [StationSearchHit],
        subtitle: String? = nil
    ) -> some View {
        Button {
            onSelect(primary)
            dismiss()
        } label: {
            MergedStationRow(primary: primary, hits: hits, subtitle: subtitle)
        }
        .foregroundColor(.primary)
    }

    @ViewBuilder
    private func nearbyRow(_ nearby: NearbyStation, allHits: [String: [StationSearchHit]] = [:]) -> some View {
        if mergesStations {
            mergedRow(
                primary: nearby.hit,
                hits: allHits[nearby.hit.station.name] ?? [nearby.hit],
                subtitle: nearby.formattedDistance
            )
        } else {
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
}

// MARK: - Merged Station Row

/// One row per physical station: name on the left edge, the badge of every
/// line serving it on the right edge.
struct MergedStationRow: View {
    let primary: StationSearchHit
    let hits: [StationSearchHit]
    /// Secondary text under the name (e.g. distance for nearby rows).
    var subtitle: String? = nil

    private static let maxBadges = 4

    /// Numbered lines first, in station-code order, like station signage.
    private var orderedHits: [StationSearchHit] {
        hits.sorted {
            switch ($0.station.stationCode.isEmpty, $1.station.stationCode.isEmpty) {
            case (false, true): return true
            case (true, false): return false
            default: return $0.station.stationCode < $1.station.stationCode
            }
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(primary.station.localizedName)
                    .font(.system(size: 16, weight: .semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                } else if primary.station.nameEn != primary.station.localizedName {
                    Text(primary.station.nameEn)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                let ordered = orderedHits
                ForEach(ordered.prefix(Self.maxBadges)) { hit in
                    badge(for: hit)
                }
                if ordered.count > Self.maxBadges {
                    Text(verbatim: "+\(ordered.count - Self.maxBadges)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func badge(for hit: StationSearchHit) -> some View {
        if !hit.station.stationCode.isEmpty {
            StationNumberBadge(
                code: hit.station.stationCode,
                color: hit.line.color,
                size: .compact,
                stationName: hit.station.name
            )
        } else if !hit.line.lineSymbol.isEmpty {
            LineSymbolBadge(
                symbol: hit.line.lineSymbol,
                color: hit.line.color
            )
        } else {
            RoundedRectangle(cornerRadius: 3)
                .fill(hit.line.color)
                .frame(width: 8, height: 32)
        }
    }
}
