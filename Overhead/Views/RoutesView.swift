import SwiftUI
import Backbone

// MARK: - Routes View

struct RoutesView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var routes: [QuickRoute] = []
    @State private var editingRoute: QuickRoute.RouteLabel?

    private let storageKey = "savedQuickRoutes"

    var body: some View {
        NavigationStack {
            List {
                ForEach(QuickRoute.RouteLabel.allCases, id: \.self) { label in
                    let route = routes.first(where: { $0.label == label })
                    routeRow(label: label, route: route)
                }
            }
            .navigationTitle("NavigationTitle.Routes")
            .onAppear { loadRoutes() }
        }
    }

    // MARK: - Route Row

    @ViewBuilder
    private func routeRow(label: QuickRoute.RouteLabel, route: QuickRoute?) -> some View {
        if let route, let resolved = resolveRoute(route) {
            Section {
                Button {
                    startRoute(route)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: label.iconName)
                            .font(.system(size: 22))
                            .foregroundColor(resolved.line.color)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey(label.localizationKey))
                                .font(.system(size: 17, weight: .semibold))

                            Text(resolved.line.localizedName)
                                .font(.system(size: 13))
                                .foregroundColor(resolved.line.color)

                            HStack(spacing: 4) {
                                StationNumberBadge(code: resolved.from.stationCode, color: resolved.line.color, size: .regular)
                                Text(resolved.from.localizedName)
                                    .font(.system(size: 13))
                                Image(systemName: resolved.isThrough ? "arrow.triangle.branch" : "arrow.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                StationNumberBadge(code: resolved.to.stationCode, color: resolved.line.color, size: .regular)
                                Text(resolved.to.localizedName)
                                    .font(.system(size: 13))
                            }
                        }

                        Spacer()

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(resolved.line.color)
                    }
                    .padding(.vertical, 4)
                }
                .foregroundColor(.primary)

                NavigationLink {
                    RouteEditorView(
                        label: label,
                        existingRoute: route,
                        availableLines: availableLines,
                        includeThroughDestinations: !viewModel.isDemoMode,
                        onSave: { updated in
                            saveRoute(updated)
                        }
                    )
                } label: {
                    Label("Button.EditRoute", systemImage: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Button(role: .destructive) {
                    deleteRoute(label: label)
                } label: {
                    Label("Button.DeleteRoute", systemImage: "trash")
                        .font(.system(size: 14))
                }
            }
        } else {
            Section {
                NavigationLink {
                    RouteEditorView(
                        label: label,
                        existingRoute: nil,
                        availableLines: availableLines,
                        includeThroughDestinations: !viewModel.isDemoMode,
                        onSave: { newRoute in
                            saveRoute(newRoute)
                        }
                    )
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: label.iconName)
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(label.localizationKey))
                                .font(.system(size: 17, weight: .semibold))

                            Text("Route.NotConfigured")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "plus.circle")
                            .font(.system(size: 22))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Available Lines

    private var availableLines: [TrainLine] {
        if viewModel.isDemoMode {
            return DemoDataProvider.demoLines
        }
        return viewModel.availableLines
    }

    private func findLine(id: String) -> TrainLine? {
        availableLines.first(where: { $0.id == id })
    }

    /// Resolves a saved route's stations. The alighting station may live on a
    /// connecting line reached via a through service (直通) past a junction.
    private func resolveRoute(_ route: QuickRoute) -> (line: TrainLine, from: Station, to: Station, isThrough: Bool)? {
        guard let line = findLine(id: route.lineId),
              let from = line.stations.first(where: { $0.id == route.fromStationId })
        else { return nil }

        if let to = line.stations.first(where: { $0.id == route.toStationId }) {
            return (line, from, to, false)
        }

        guard !viewModel.isDemoMode else { return nil }
        for group in StaticTrainData.throughDestinations(fromLineId: line.id, boardingStationId: from.id) {
            if let to = group.stations.first(where: { $0.id == route.toStationId }) {
                return (line, from, to, true)
            }
        }
        return nil
    }

    // MARK: - Actions

    private func startRoute(_ route: QuickRoute) {
        guard let resolved = resolveRoute(route) else { return }

        if viewModel.isDemoMode {
            viewModel.startDemoJourney(line: resolved.line, from: resolved.from, to: resolved.to)
        } else {
            Task {
                await viewModel.startJourney(line: resolved.line, from: resolved.from, to: resolved.to)
            }
        }
    }

    // MARK: - Persistence

    private func loadRoutes() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([QuickRoute].self, from: data) else { return }
        routes = decoded
    }

    private func saveRoute(_ route: QuickRoute) {
        if let idx = routes.firstIndex(where: { $0.label == route.label }) {
            routes[idx] = route
        } else {
            routes.append(route)
        }
        persist()
    }

    private func deleteRoute(label: QuickRoute.RouteLabel) {
        routes.removeAll(where: { $0.label == label })
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(routes) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - Route Editor View

struct RouteEditorView: View {
    let label: QuickRoute.RouteLabel
    let existingRoute: QuickRoute?
    let availableLines: [TrainLine]
    var includeThroughDestinations: Bool = true
    let onSave: (QuickRoute) -> Void

    @State private var line: TrainLine?
    @State private var fromStation: Station?
    @State private var toStation: Station?
    @Environment(\.dismiss) private var dismiss

    // Through-service (直通) destinations reachable from the boarding station.
    private var throughGroups: [StaticTrainData.ThroughDestinationGroup] {
        guard includeThroughDestinations, let line else { return [] }
        return StaticTrainData.throughDestinations(
            fromLineId: line.id,
            boardingStationId: fromStation?.id
        )
    }

    var body: some View {
        Form {
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

            if let line,
               let from = fromStation,
               let to = toStation,
               from.id != to.id {
                Section {
                    Button {
                        let route = QuickRoute(
                            id: existingRoute?.id ?? UUID(),
                            label: label,
                            lineId: line.id,
                            fromStationId: from.id,
                            toStationId: to.id
                        )
                        onSave(route)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Button.SaveRoute")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(line.color)
                }
            }
        }
        .navigationTitle(LocalizedStringKey(label.localizationKey))
        .onAppear {
            guard line == nil, let existing = existingRoute else { return }
            let savedLine = availableLines.first(where: { $0.id == existing.lineId })
            line = savedLine
            fromStation = savedLine?.stations.first(where: { $0.id == existing.fromStationId })
            toStation = savedLine?.stations.first(where: { $0.id == existing.toStationId })
                ?? throughStation(withId: existing.toStationId)
        }
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
struct StationSearchSelectionView: View {
    let lines: [TrainLine]
    let onSelect: (StationSearchHit) -> Void

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        List {
            if trimmedQuery.isEmpty {
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
}
