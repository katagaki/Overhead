import SwiftUI
import Backbone

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
