import SwiftUI
import Backbone

// MARK: - Station Search Selection

struct StationSearchSelectionView: View {
    let lines: [TrainLine]
    /// For sheet presentation; a pushed nav stack uses the back button instead.
    var showsCloseButton: Bool = false
    /// Merges same-named stations into one row with every line's badge.
    var mergesStations: Bool = false
    let onSelect: (StationSearchHit) -> Void

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @StateObject private var nearbyProvider = NearbyStationsProvider()
    @Environment(\.dismiss) private var dismiss

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
