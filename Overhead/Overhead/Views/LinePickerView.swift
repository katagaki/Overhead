import SwiftUI

// MARK: - Line & Station Picker

struct LinePickerView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var selectedLine: TrainLine?
    @State private var boardingStation: Station?
    @State private var alightingStation: Station?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading.Lines")
                } else if viewModel.availableLines.isEmpty {
                    emptyState
                } else {
                    lineList
                }
            }
            .navigationTitle("NavigationTitle.LineSelection")
            .task {
                if viewModel.availableLines.isEmpty {
                    await viewModel.loadLines()
                }
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
            Text("Error.ConfigureAPIKey")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Button("Button.Retry") {
                Task { await viewModel.loadLines() }
            }
        }
    }

    private var lineList: some View {
        List {
            ForEach(viewModel.availableLines) { line in
                NavigationLink {
                    StationPickerView(
                        line: line,
                        viewModel: viewModel
                    )
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(line.color)
                            .frame(width: 6, height: 36)

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
        }
    }
}

// MARK: - Station Picker

struct StationPickerView: View {
    let line: TrainLine
    @ObservedObject var viewModel: JourneyViewModel
    @State private var boardingStation: Station?
    @State private var alightingStation: Station?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Section.BoardingStation") {
                ForEach(line.stations) { station in
                    Button {
                        boardingStation = station
                    } label: {
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
                            if boardingStation?.id == station.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(line.color)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }

            Section("Section.AlightingStation") {
                ForEach(line.stations) { station in
                    Button {
                        alightingStation = station
                    } label: {
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
                            if alightingStation?.id == station.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(line.color)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }

            if let boarding = boardingStation, let alighting = alightingStation,
               boarding.id != alighting.id {
                Section {
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
        }
        .navigationTitle(line.localizedName)
    }
}
