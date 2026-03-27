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
                    ProgressView("Loading lines...")
                } else if viewModel.availableLines.isEmpty {
                    emptyState
                } else {
                    lineList
                }
            }
            .navigationTitle("\u{8DEF}\u{7DDA}\u{9078}\u{629E}")
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
            Text("No lines available")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Configure your ODPT API key in Settings")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Button("Retry") {
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
                            Text(line.name)
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
            Section("\u{4E57}\u{8ECA}\u{99C5} / Boarding Station") {
                ForEach(line.stations) { station in
                    Button {
                        boardingStation = station
                    } label: {
                        HStack {
                            if !station.stationCode.isEmpty {
                                Text(station.stationCode)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(line.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            VStack(alignment: .leading) {
                                Text(station.name)
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

            Section("\u{964D}\u{8ECA}\u{99C5} / Alighting Station") {
                ForEach(line.stations) { station in
                    Button {
                        alightingStation = station
                    } label: {
                        HStack {
                            if !station.stationCode.isEmpty {
                                Text(station.stationCode)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(line.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            VStack(alignment: .leading) {
                                Text(station.name)
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
                        Task {
                            await viewModel.startJourney(
                                line: line,
                                from: boarding,
                                to: alighting
                            )
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("\u{65C5}\u{7A0B}\u{3092}\u{958B}\u{59CB} / Start Journey")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(line.color)
                }
            }
        }
        .navigationTitle(line.name)
    }
}
