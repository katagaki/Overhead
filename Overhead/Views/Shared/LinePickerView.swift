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
            let l = rank($0)
            let r = rank($1)
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
                    size: .compact,
                    stationName: hit.station.name
                )
            } else if !hit.line.lineSymbol.isEmpty {
                // Stations without a number (beyond the numbered section)
                // still get the line's symbol so rows stay aligned
                LineSymbolBadge(
                    symbol: hit.line.lineSymbol,
                    color: hit.line.color
                )
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(hit.line.color)
                    .frame(width: 4, height: 32)
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
        ScrollView {
            if trimmedQuery.isEmpty {
                browseByLineGrid
            } else {
                searchResultsList
            }
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: Text("StationSearch.Prompt"))
    }

    @ViewBuilder
    private var searchResultsList: some View {
        let results = StationSearch.search(lines: viewModel.availableLines, query: trimmedQuery)
        if results.isEmpty {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("StationSearch.NoResults")
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(results) { hit in
                    NavigationLink {
                        StationTimetableView(
                            station: hit.station,
                            line: hit.line,
                            viewModel: viewModel
                        )
                    } label: {
                        HStack {
                            StationSearchRow(hit: hit)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
    }

    private var browseByLineGrid: some View {
        let grouped = Dictionary(grouping: viewModel.availableLines) { $0.operatorId }
        let knownOrder = [
            "Operator:JR-East",
            "Operator:TokyoMetro",
            "Operator:Toei",
            "Operator:Keisei",
            "Operator:Tobu",
            "Operator:Odakyu",
            "Operator:Tokyu",
            "Operator:Keikyu",
            "Operator:Keio",
            "Operator:Seibu",
            "Operator:Sotetsu",
            "Operator:Minatomirai",
            "Operator:SaitamaRailway"
        ]
        // Operators missing from knownOrder still get a section at the end
        // instead of silently disappearing from the browser
        let sectionOrder = knownOrder.filter { grouped[$0] != nil }
            + grouped.keys.filter { !knownOrder.contains($0) }.sorted()
        let sectionTitles: [String: String] = [
            "Operator:JR-East": "JR",
            "Operator:TokyoMetro": "東京メトロ",
            "Operator:Toei": "都営",
            "Operator:Keisei": "京成",
            "Operator:Tobu": "東武",
            "Operator:Odakyu": "小田急",
            "Operator:Tokyu": "東急",
            "Operator:Keikyu": "京急",
            "Operator:Keio": "京王",
            "Operator:Seibu": "西武",
            "Operator:Sotetsu": "相鉄",
            "Operator:Minatomirai": "みなとみらい線",
            "Operator:SaitamaRailway": "埼玉高速鉄道"
        ]
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

        return LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(sectionOrder, id: \.self) { operatorId in
                if let lines = grouped[operatorId] {
                    // Symbol order (JA, JB, JC… / A, C, E…); symbol-less lines last
                    let sorted = lines.sorted {
                        switch ($0.lineSymbol.isEmpty, $1.lineSymbol.isEmpty) {
                        case (false, false):
                            return $0.lineSymbol == $1.lineSymbol
                                ? $0.localizedName < $1.localizedName
                                : $0.lineSymbol < $1.lineSymbol
                        case (false, true): return true
                        case (true, false): return false
                        case (true, true): return $0.localizedName < $1.localizedName
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(sectionTitles[operatorId] ?? operatorId)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(sorted) { line in
                                NavigationLink {
                                    StationPickerView(
                                        line: line,
                                        viewModel: viewModel
                                    )
                                } label: {
                                    lineCell(line: line)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func lineCell(line: TrainLine) -> some View {
        VStack(spacing: 8) {
            if !line.lineSymbol.isEmpty {
                LineSymbolBadge(
                    symbol: line.lineSymbol,
                    color: line.color,
                    dimension: 44
                )
            } else {
                RoundedRectangle(cornerRadius: 7)
                    .fill(line.color)
                    .frame(width: 44, height: 44)
            }

            // Fixed two-line text area so every cell is the same height and
            // single-line names sit at the same position as wrapped ones
            Text(line.localizedName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: 32, alignment: .top)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .contentShape(Rectangle())
    }
}

// MARK: - Station Picker

struct StationPickerView: View {
    let line: TrainLine
    @ObservedObject var viewModel: JourneyViewModel

    var body: some View {
        Form {
            if let delayInfo = viewModel.delayCheckInfo(for: line.id) {
                ServiceStatusSection(delayInfo: delayInfo)
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
    }

    // MARK: - Station Row

    @ViewBuilder
    private func stationRow(station: Station) -> some View {
        HStack {
            if !station.stationCode.isEmpty {
                StationNumberBadge(
                    code: station.stationCode,
                    color: line.color,
                    size: .compact,
                    stationName: station.name
                )
            } else if !line.lineSymbol.isEmpty {
                LineSymbolBadge(
                    symbol: line.lineSymbol,
                    color: line.color
                )
            }
            VStack(alignment: .leading) {
                Text(station.localizedName)
                Text(station.nameEn)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}
