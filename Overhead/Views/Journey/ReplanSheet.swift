import SwiftUI
import Backbone

// MARK: - Replan Sheet

/// Mid-journey course change: pick a stop you can still get off at, then take a
/// different train or a different destination from there.
struct ReplanSheet: View {
    @ObservedObject var viewModel: JourneyViewModel
    /// Stop the rider tapped on the route strip; falls back to the next one.
    var initialAnchorIndex: Int?
    var initialMode: Mode = .train

    @AppStorage("journey.walkingSpeed") private var walkingSpeedRaw = WalkingSpeed.normal.rawValue
    @Environment(\.dismiss) private var dismiss

    @State private var anchorIndex: Int?
    @State private var mode: Mode = .train
    @State private var candidates: [TrainCandidate] = []
    @State private var isSearching = false
    @State private var selection: Selection?
    @State private var searchingStation = false
    /// Set when the destination tab searched for a station off the current route.
    @State private var offRouteDestination: Station?

    enum Mode: Hashable {
        case train
        case destination
    }

    private enum Selection: Equatable {
        case candidate(String)
        case stop(Int)
    }

    private var anchors: [JourneyViewModel.ReplanAnchor] { viewModel.replanAnchors }

    private var anchor: JourneyViewModel.ReplanAnchor? {
        guard let anchorIndex else { return anchors.first }
        return anchors.first { $0.stationIndex == anchorIndex } ?? anchors.first
    }

    private var walkingSpeed: WalkingSpeed {
        WalkingSpeed(rawValue: walkingSpeedRaw) ?? .normal
    }

    private var destination: Station? {
        viewModel.activeJourney?.journeyStations.last
    }

    /// Searches match on the Japanese name; only the label is localized.
    private var destinationName: String? { destination?.name }

    /// The arrival the change is measured against.
    private var currentArrival: Date? {
        viewModel.positionState?.estimatedArrival
    }

    var body: some View {
        NavigationStack {
            Group {
                if anchors.isEmpty {
                    unavailableState
                } else {
                    content
                }
            }
            .navigationTitle("Replan.Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $searchingStation) {
                StationSearchSelectionView(
                    lines: viewModel.availableLines,
                    mergesStations: true
                ) { hit in
                    searchingStation = false
                    offRouteDestination = hit.station
                    selection = nil
                    search(destination: hit.station.name)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            anchorIndex = initialAnchorIndex ?? anchors.first?.stationIndex
            mode = initialMode
            searchIfNeeded()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        List {
            Section {
                anchorRow
            } header: {
                Text("Replan.Anchor.Header")
            }

            Section {
                Picker("Replan.Title", selection: $mode) {
                    Text("Replan.Mode.Train").tag(Mode.train)
                    Text("Replan.Mode.Destination").tag(Mode.destination)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }

            switch mode {
            case .train: trainSection
            case .destination: destinationSection
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            if let applyAction {
                confirmBar(applyAction)
            }
        }
        .onChange(of: mode) { _, _ in
            selection = nil
            offRouteDestination = nil
            searchIfNeeded()
        }
        .onChange(of: anchorIndex) { _, _ in
            selection = nil
            searchIfNeeded()
        }
    }

    // MARK: - Anchor Picker

    @ViewBuilder
    private var anchorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(anchors) { candidate in
                    let isSelected = candidate.stationIndex == anchor?.stationIndex
                    Button {
                        anchorIndex = candidate.stationIndex
                    } label: {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(candidate.station.localizedName)
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(1)
                            Group {
                                if candidate.stationIndex == anchors.first?.stationIndex {
                                    Text("Replan.NextStop")
                                } else {
                                    Text(verbatim: timeString(candidate.time))
                                }
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.accentColor.opacity(0.18) : Color(.tertiarySystemFill))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    // MARK: - Alternative Trains

    @ViewBuilder
    private var trainSection: some View {
        Section {
            if isSearching {
                HStack {
                    ProgressView()
                    Text("Replan.Searching")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            } else if candidates.isEmpty {
                Text("Replan.NoAlternatives")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(candidates) { candidate in
                    candidateRow(candidate)
                }
            }
        } header: {
            if let anchor, let destination {
                Text("Replan.Trains.Header \(anchor.station.localizedName) \(destination.localizedName)")
            }
        }
    }

    @ViewBuilder
    private func candidateRow(_ candidate: TrainCandidate) -> some View {
        let isSelected = selection == .candidate(candidate.id)
        Button {
            selection = .candidate(candidate.id)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("\(displayTime(candidate.departureTime)) → \(displayTime(candidate.arrivalTime))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        deltaPill(for: candidate.arrivalDate())
                    }

                    HStack(spacing: 6) {
                        if let leg = candidate.legs.first {
                            Text(leg.service.trainType.displayNameJa)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(leg.line.color)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Group {
                            Text("Candidate.Duration \(candidate.durationMinutes)")
                            if candidate.transferCount > 0 {
                                Text("Candidate.Transfers \(candidate.transferCount)")
                            }
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 4)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Change Destination

    @ViewBuilder
    private var destinationSection: some View {
        if let anchor {
            let onward = viewModel.onwardStops(from: anchor)

            if !onward.isEmpty {
                Section {
                    ForEach(onward) { stop in
                        stopRow(stop)
                    }
                } header: {
                    Text("Replan.Onward.Header")
                } footer: {
                    Text("Replan.Onward.Footer")
                }
            }

            Section {
                Button {
                    searchingStation = true
                } label: {
                    Label("Replan.SearchOtherStation", systemImage: "magnifyingglass")
                }

                if let offRouteDestination {
                    if isSearching {
                        HStack {
                            ProgressView()
                            Text("Replan.Searching")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    } else if candidates.isEmpty {
                        Text("Replan.NoRoute \(offRouteDestination.localizedName)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(candidates) { candidate in
                            candidateRow(candidate)
                        }
                    }
                }
            } header: {
                if let offRouteDestination {
                    Text(verbatim: offRouteDestination.localizedName)
                }
            }
        }
    }

    @ViewBuilder
    private func stopRow(_ stop: JourneyViewModel.ReplanAnchor) -> some View {
        let isSelected = selection == .stop(stop.stationIndex)
        Button {
            selection = .stop(stop.stationIndex)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(stop.station.localizedName)
                            .font(.system(size: 16, weight: .semibold))
                        deltaPill(for: stop.time)
                    }
                    Text(verbatim: timeString(stop.time))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 4)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirm Bar

    /// Nil until something is picked; the row already shows its time and delta.
    private var applyAction: (() -> Void)? {
        guard let anchor, let selection else { return nil }
        switch selection {
        case .candidate(let id):
            guard let candidate = candidates.first(where: { $0.id == id }) else { return nil }
            return { viewModel.replan(from: anchor, to: candidate) }
        case .stop(let index):
            guard let stop = viewModel.onwardStops(from: anchor).first(where: { $0.stationIndex == index })
            else { return nil }
            return { viewModel.changeDestination(to: stop) }
        }
    }

    @ViewBuilder
    private func confirmBar(_ apply: @escaping () -> Void) -> some View {
        Button {
            apply()
            dismiss()
        } label: {
            Text("Replan.Apply")
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var unavailableState: some View {
        ContentUnavailableView {
            Label("Replan.Unavailable.Title", systemImage: "arrow.triangle.branch")
        } description: {
            Text("Replan.Unavailable.Description")
        }
    }

    // MARK: - Search

    private func searchIfNeeded() {
        switch mode {
        case .train:
            guard let destinationName else { return }
            search(destination: destinationName)
        case .destination:
            if let offRouteDestination {
                search(destination: offRouteDestination.name)
            } else {
                candidates = []
            }
        }
    }

    private func search(destination: String) {
        guard let anchor else { return }
        isSearching = true
        // Sync and main-actor bound; yield so the spinner lands first.
        Task {
            await Task.yield()
            candidates = viewModel.replanCandidates(
                from: anchor,
                to: destination,
                transferMinutes: walkingSpeed.transferMinutes
            )
            isSearching = false
        }
    }

    // MARK: - Formatting

    private func deltaMinutes(to arrival: Date) -> Int {
        guard let currentArrival else { return 0 }
        return Int((arrival.timeIntervalSince(currentArrival) / 60).rounded())
    }

    @ViewBuilder
    private func deltaPill(for arrival: Date) -> some View {
        let delta = deltaMinutes(to: arrival)
        Group {
            if delta > 0 {
                Text("Replan.Delta.Later \(delta)")
            } else if delta < 0 {
                Text("Replan.Delta.Earlier \(-delta)")
            } else {
                Text("Replan.Delta.Same")
            }
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(deltaColor(delta))
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(deltaColor(delta).opacity(0.15), in: Capsule())
    }

    private func deltaColor(_ minutes: Int) -> Color {
        minutes == 0 ? .secondary : (minutes > 0 ? .red : .green)
    }

    /// Rail times can read 24:xx; show them on a 24-hour clock as-is.
    private func displayTime(_ railTime: String) -> String {
        guard let secs = TimetableEntry.parseRailTime(railTime) else { return railTime }
        let normalized = secs % (24 * 3600)
        return String(format: "%02d:%02d", normalized / 3600, (normalized % 3600) / 60)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
}
