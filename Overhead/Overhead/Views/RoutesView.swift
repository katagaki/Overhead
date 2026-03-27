import SwiftUI

// MARK: - Routes View
/// Lets users configure and launch predefined quick routes (Home, Work, School).

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
        if let route, let line = findLine(id: route.lineId),
           let from = line.stations.first(where: { $0.id == route.fromStationId }),
           let to = line.stations.first(where: { $0.id == route.toStationId }) {
            // Configured route — show details + start button
            Section {
                Button {
                    startRoute(route)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: label.iconName)
                            .font(.system(size: 22))
                            .foregroundColor(line.color)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey(label.localizationKey))
                                .font(.system(size: 17, weight: .semibold))

                            Text(line.localizedName)
                                .font(.system(size: 13))
                                .foregroundColor(line.color)

                            HStack(spacing: 4) {
                                StationNumberBadge(code: from.stationCode, color: line.color, size: .regular)
                                Text(from.localizedName)
                                    .font(.system(size: 13))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                StationNumberBadge(code: to.stationCode, color: line.color, size: .regular)
                                Text(to.localizedName)
                                    .font(.system(size: 13))
                            }
                        }

                        Spacer()

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(line.color)
                    }
                    .padding(.vertical, 4)
                }
                .foregroundColor(.primary)

                NavigationLink {
                    RouteEditorView(
                        label: label,
                        existingRoute: route,
                        availableLines: availableLines,
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
            // Unconfigured — show setup link
            Section {
                NavigationLink {
                    RouteEditorView(
                        label: label,
                        existingRoute: nil,
                        availableLines: availableLines,
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

    // MARK: - Actions

    private func startRoute(_ route: QuickRoute) {
        guard let line = findLine(id: route.lineId),
              let from = line.stations.first(where: { $0.id == route.fromStationId }),
              let to = line.stations.first(where: { $0.id == route.toStationId }) else { return }

        if viewModel.isDemoMode {
            viewModel.startDemoJourney(line: line, from: from, to: to)
        } else {
            Task {
                await viewModel.startJourney(line: line, from: from, to: to)
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
    let onSave: (QuickRoute) -> Void

    @State private var selectedLine: TrainLine?
    @State private var fromStation: Station?
    @State private var toStation: Station?
    @Environment(\.dismiss) private var dismiss

    /// The effective line: explicitly selected, or auto-detected from the From station
    private var effectiveLine: TrainLine? {
        if let selectedLine { return selectedLine }
        guard let from = fromStation else { return nil }
        return availableLines.first(where: { $0.stations.contains(where: { $0.id == from.id }) })
    }

    var body: some View {
        Form {
            // Line selection (optional — auto-detected from station)
            Section("Route.Section.Line") {
                Picker(selection: $selectedLine) {
                    Text("Picker.AllLines").tag(nil as TrainLine?)
                    ForEach(availableLines) { line in
                        Text(line.localizedName).tag(line as TrainLine?)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if let line = effectiveLine {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(line.color)
                                .frame(width: 4, height: 20)
                        }
                        Text("Route.Section.Line")
                    }
                }
                .onChange(of: selectedLine) { _, newLine in
                    // Reset stations when line changes if they don't belong to the new line
                    if let newLine {
                        if let from = fromStation, !newLine.stations.contains(where: { $0.id == from.id }) {
                            fromStation = nil
                        }
                        if let to = toStation, !newLine.stations.contains(where: { $0.id == to.id }) {
                            toStation = nil
                        }
                    }
                }
            }

            // From station
            Section("Section.BoardingStation") {
                Picker(selection: $fromStation) {
                    Text("Picker.SelectStation").tag(nil as Station?)
                    if let line = selectedLine {
                        // Show only the selected line's stations
                        ForEach(line.stations) { station in
                            stationPickerLabel(station: station, line: line).tag(station as Station?)
                        }
                    } else {
                        // Show all stations grouped by line
                        ForEach(availableLines) { line in
                            Section(line.localizedName) {
                                ForEach(line.stations) { station in
                                    stationPickerLabel(station: station, line: line).tag(station as Station?)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(effectiveLine?.color ?? .secondary)
                        Text("Section.BoardingStation")
                    }
                }
            }

            // To station (shown once we know which line)
            if let line = effectiveLine {
                Section("Section.AlightingStation") {
                    Picker(selection: $toStation) {
                        Text("Picker.SelectStation").tag(nil as Station?)
                        ForEach(line.stations) { station in
                            stationPickerLabel(station: station, line: line).tag(station as Station?)
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

            // Save button
            if let line = effectiveLine,
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
            if let existing = existingRoute {
                selectedLine = availableLines.first(where: { $0.id == existing.lineId })
                fromStation = selectedLine?.stations.first(where: { $0.id == existing.fromStationId })
                toStation = selectedLine?.stations.first(where: { $0.id == existing.toStationId })
            }
        }
    }

    @ViewBuilder
    private func stationPickerLabel(station: Station, line: TrainLine) -> some View {
        if station.stationCode.isEmpty {
            Text(station.localizedName)
        } else {
            Text("\(station.stationCode) \(station.localizedName)")
        }
    }
}
