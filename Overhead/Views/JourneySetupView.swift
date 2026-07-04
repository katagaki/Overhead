import SwiftUI
import Backbone

// MARK: - Journey Setup View

/// Shown on the Journey tab when no journey is active. Lets the user pick
/// boarding and alighting stations and start a journey without leaving the tab.
struct JourneySetupView: View {
    @ObservedObject var viewModel: JourneyViewModel

    @State private var line: TrainLine?
    @State private var fromStation: Station?
    @State private var toStation: Station?

    private var availableLines: [TrainLine] {
        if viewModel.isDemoMode {
            return DemoDataProvider.demoLines
        }
        return viewModel.availableLines
    }

    // Through-service (直通) destinations continuing past a junction onto
    // bundled connecting lines, reachable from the current boarding station.
    private var throughGroups: [StaticTrainData.ThroughDestinationGroup] {
        guard !viewModel.isDemoMode, let line else { return [] }
        return StaticTrainData.throughDestinations(
            fromLineId: line.id,
            boardingStationId: fromStation?.id
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && availableLines.isEmpty {
                    ProgressView("Loading.Lines")
                } else {
                    setupForm
                }
            }
            .navigationTitle("Tab.Journey")
            .task {
                await viewModel.loadLines()
            }
        }
    }

    // MARK: - Form

    private var setupForm: some View {
        Form {
            Section {
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

                if let line, fromStation != nil {
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
                    .onChange(of: fromStation) { _, newBoarding in
                        // Drop an alighting station that is no longer reachable
                        // (e.g. a through destination past a junction behind us).
                        guard let alighting = toStation,
                              !line.stations.contains(where: { $0.id == alighting.id })
                        else { return }
                        let stillReachable = throughGroupsContain(alighting, line: line, boarding: newBoarding)
                        if !stillReachable {
                            toStation = nil
                        }
                    }
                }
            } header: {
                Text("Section.BoardingStation")
            } footer: {
                if fromStation == nil {
                    Text("Onboarding.Description")
                }
            }

            if let line,
               let from = fromStation,
               let to = toStation,
               from.id != to.id {
                Section {
                    if isThroughDestination(to, line: line) {
                        Label("Picker.ThroughJourneyNote", systemImage: "arrow.triangle.branch")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Button {
                        startJourney(line: line, from: from, to: to)
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isStartingJourney {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Button.StartJourney")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isStartingJourney)
                    .foregroundColor(.white)
                    .listRowBackground(line.color)
                } footer: {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func startJourney(line: TrainLine, from: Station, to: Station) {
        if viewModel.isDemoMode {
            viewModel.startDemoJourney(line: line, from: from, to: to)
        } else {
            Task {
                await viewModel.startJourney(line: line, from: from, to: to)
            }
        }
    }

    // MARK: - Through Helpers

    private func isThroughDestination(_ station: Station, line: TrainLine) -> Bool {
        !line.stations.contains(where: { $0.id == station.id })
    }

    private func throughGroupsContain(_ station: Station, line: TrainLine, boarding: Station?) -> Bool {
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
}
