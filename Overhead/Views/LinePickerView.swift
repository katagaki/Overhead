import SwiftUI
import Backbone

// MARK: - Station Search

struct StationSearchHit: Identifiable {
    let line: TrainLine
    let station: Station

    var id: String { "\(line.id)|\(station.id)" }
}

enum StationSearch {

    /// Searches every station on every line by localized name, Japanese name,
    /// English name, or station code.
    static func search(lines: [TrainLine], query: String) -> [StationSearchHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lowered = trimmed.lowercased()

        var hits: [StationSearchHit] = []
        for line in lines {
            for station in line.stations {
                if station.name.contains(trimmed)
                    || station.nameEn.lowercased().contains(lowered)
                    || station.localizedName.lowercased().contains(lowered)
                    || (!station.stationCode.isEmpty && station.stationCode.lowercased().hasPrefix(lowered)) {
                    hits.append(StationSearchHit(line: line, station: station))
                }
            }
        }

        func rank(_ hit: StationSearchHit) -> Int {
            if hit.station.name == trimmed || hit.station.nameEn.lowercased() == lowered {
                return 0
            }
            if hit.station.name.hasPrefix(trimmed) || hit.station.nameEn.lowercased().hasPrefix(lowered) {
                return 1
            }
            return 2
        }

        return hits.sorted {
            let l = rank($0), r = rank($1)
            if l != r { return l < r }
            if $0.station.name != $1.station.name { return $0.station.name < $1.station.name }
            return $0.line.nameEn < $1.line.nameEn
        }
    }
}

struct StationSearchRow: View {
    let hit: StationSearchHit

    var body: some View {
        HStack(spacing: 10) {
            if !hit.station.stationCode.isEmpty {
                StationNumberBadge(
                    code: hit.station.stationCode,
                    color: hit.line.color,
                    size: .compact
                )
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(hit.line.color)
                    .frame(width: 4, height: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(hit.station.localizedName)
                    .font(.system(size: 16, weight: .semibold))
                Text(hit.line.localizedName)
                    .font(.system(size: 12))
                    .foregroundColor(hit.line.color)
            }
        }
    }
}

// MARK: - Station Picker (search all stations)

struct LinePickerView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading.Lines")
                } else if viewModel.availableLines.isEmpty {
                    emptyState
                } else {
                    stationSearchList
                }
            }
            .navigationTitle("ViewTitle.Stations")
            .task {
                await viewModel.loadLines()
            }
            .refreshable {
                await viewModel.forceRefreshLines()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Error.NoLinesAvailable")
                .font(.headline)
                .foregroundColor(.secondary)
            Button("Button.Retry") {
                Task { await viewModel.loadLines() }
            }
        }
    }

    // MARK: - Search / Browse

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private var stationSearchList: some View {
        List {
            if trimmedQuery.isEmpty {
                browseByLineSections
            } else {
                searchResultsSection
            }
        }
        .listStyle(.grouped)
        .searchable(text: $searchText, prompt: Text("StationSearch.Prompt"))
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        let results = StationSearch.search(lines: viewModel.availableLines, query: trimmedQuery)
        if results.isEmpty {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("StationSearch.NoResults")
            }
            .foregroundColor(.secondary)
        } else {
            ForEach(results) { hit in
                NavigationLink {
                    StationPickerView(
                        line: hit.line,
                        viewModel: viewModel,
                        initialBoardingStation: hit.station
                    )
                } label: {
                    StationSearchRow(hit: hit)
                }
            }
        }
    }

    @ViewBuilder
    private var browseByLineSections: some View {
        let grouped = Dictionary(grouping: viewModel.availableLines) { $0.operatorId }
        let sectionOrder = [
            "odpt.Operator:JR-East",
            "odpt.Operator:TokyoMetro",
            "odpt.Operator:Toei",
            "odpt.Operator:Keisei",
            "odpt.Operator:Tobu",
            "odpt.Operator:Odakyu"
        ]
        let sectionTitles: [String: String] = [
            "odpt.Operator:JR-East": "JR",
            "odpt.Operator:TokyoMetro": "東京メトロ",
            "odpt.Operator:Toei": "都営",
            "odpt.Operator:Keisei": "京成",
            "odpt.Operator:Tobu": "東武",
            "odpt.Operator:Odakyu": "小田急"
        ]

        ForEach(sectionOrder, id: \.self) { operatorId in
            if let lines = grouped[operatorId] {
                Section(sectionTitles[operatorId] ?? operatorId) {
                    ForEach(lines) { line in
                        NavigationLink {
                            StationPickerView(
                                line: line,
                                viewModel: viewModel
                            )
                        } label: {
                            lineRow(line: line)
                        }
                    }
                }
            }
        }
    }

    private func lineRow(line: TrainLine) -> some View {
        HStack(spacing: 12) {
            if !line.lineSymbol.isEmpty {
                LineSymbolBadge(
                    symbol: line.lineSymbol,
                    color: line.color
                )
            } else {
                // Placeholder to keep text aligned with badged rows
                RoundedRectangle(cornerRadius: 5)
                    .fill(line.color)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(line.localizedName)
                    .font(.system(size: 16, weight: .semibold))
                Text(line.nameEn)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Station Picker

struct StationPickerView: View {
    let line: TrainLine
    @ObservedObject var viewModel: JourneyViewModel
    var initialBoardingStation: Station? = nil
    @State private var boardingStation: Station?
    @State private var alightingStation: Station?
    @Environment(\.dismiss) private var dismiss

    // Through-service (直通) destinations continuing past a junction onto
    // bundled connecting lines, reachable from the current boarding station.
    private var throughGroups: [StaticTrainData.ThroughDestinationGroup] {
        guard !viewModel.isDemoMode else { return [] }
        return StaticTrainData.throughDestinations(
            fromLineId: line.id,
            boardingStationId: boardingStation?.id
        )
    }

    var body: some View {
        Form {
            Section {
                Picker(selection: $boardingStation) {
                    Text("Picker.SelectStation").tag(nil as Station?)
                    ForEach(line.stations) { station in
                        stationPickerLabel(station: station).tag(station as Station?)
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(line.color)
                        Text("Section.BoardingStation")
                    }
                }

                Picker(selection: $alightingStation) {
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
                .onChange(of: boardingStation) { _, newBoarding in
                    // Drop an alighting station that is no longer reachable
                    // (e.g. a through destination past a junction behind us).
                    guard let alighting = alightingStation,
                          !line.stations.contains(where: { $0.id == alighting.id })
                    else { return }
                    let stillReachable = throughGroupsContain(alighting, boarding: newBoarding)
                    if !stillReachable {
                        alightingStation = nil
                    }
                }
            }

            if let boarding = boardingStation, let alighting = alightingStation,
               boarding.id != alighting.id {
                Section {
                    if isThroughDestination(alighting) {
                        Label("Picker.ThroughJourneyNote", systemImage: "arrow.triangle.branch")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Button {
                        if viewModel.isDemoMode {
                            viewModel.startDemoJourney(
                                line: line,
                                from: boarding,
                                to: alighting
                            )
                            dismiss()
                        } else {
                            Task {
                                await viewModel.startJourney(
                                    line: line,
                                    from: boarding,
                                    to: alighting
                                )
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Button.StartJourney")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(line.color)
                }
            }

            Section("Section.Stations") {
                ForEach(line.stations) { station in
                    NavigationLink {
                        StationTimetableView(station: station, line: line, viewModel: viewModel)
                    } label: {
                        stationRow(station: station)
                    }
                }
            }
        }
        .navigationTitle(line.localizedName)
        .onAppear {
            if boardingStation == nil, let initial = initialBoardingStation {
                boardingStation = initial
            }
        }
    }

    // MARK: - Through Helpers

    private func isThroughDestination(_ station: Station) -> Bool {
        !line.stations.contains(where: { $0.id == station.id })
    }

    private func throughGroupsContain(_ station: Station, boarding: Station?) -> Bool {
        guard !viewModel.isDemoMode else { return false }
        return StaticTrainData.throughDestinations(
            fromLineId: line.id,
            boardingStationId: boarding?.id
        ).contains { group in
            group.stations.contains(where: { $0.id == station.id })
        }
    }

    // MARK: - Picker Label

    @ViewBuilder
    private func stationPickerLabel(station: Station) -> some View {
        if station.stationCode.isEmpty {
            Text(station.localizedName)
        } else {
            Text("\(station.stationCode) \(station.localizedName)")
        }
    }

    // MARK: - Station Row

    @ViewBuilder
    private func stationRow(station: Station) -> some View {
        HStack {
            if !station.stationCode.isEmpty {
                StationNumberBadge(
                    code: station.stationCode,
                    color: line.color,
                    size: .compact
                )
            }
            VStack(alignment: .leading) {
                Text(station.localizedName)
                Text(station.nameEn)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}
