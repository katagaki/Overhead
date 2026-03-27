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
                            .foregroundColor(.blue)
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

    var body: some View {
        Form {
            // Line selection
            Section("Route.Section.Line") {
                ForEach(availableLines) { line in
                    Button {
                        selectedLine = line
                        // Reset stations when line changes
                        if fromStation != nil && !line.stations.contains(where: { $0.id == fromStation?.id }) {
                            fromStation = nil
                        }
                        if toStation != nil && !line.stations.contains(where: { $0.id == toStation?.id }) {
                            toStation = nil
                        }
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(line.color)
                                .frame(width: 6, height: 28)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(line.localizedName)
                                    .font(.system(size: 15, weight: .medium))
                                Text(line.nameEn)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedLine?.id == line.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(line.color)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }

            if let line = selectedLine {
                // From station
                Section("Section.BoardingStation") {
                    ForEach(line.stations) { station in
                        Button {
                            fromStation = station
                        } label: {
                            HStack {
                                if !station.stationCode.isEmpty {
                                    StationNumberBadge(code: station.stationCode, color: line.color, size: .compact)
                                }
                                VStack(alignment: .leading) {
                                    Text(station.localizedName)
                                    Text(station.nameEn)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if fromStation?.id == station.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(line.color)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                // To station
                Section("Section.AlightingStation") {
                    ForEach(line.stations) { station in
                        Button {
                            toStation = station
                        } label: {
                            HStack {
                                if !station.stationCode.isEmpty {
                                    StationNumberBadge(code: station.stationCode, color: line.color, size: .compact)
                                }
                                VStack(alignment: .leading) {
                                    Text(station.localizedName)
                                    Text(station.nameEn)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if toStation?.id == station.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(line.color)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }

            // Save button
            if let line = selectedLine,
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
                    .listRowBackground(selectedLine?.color ?? .blue)
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
}
