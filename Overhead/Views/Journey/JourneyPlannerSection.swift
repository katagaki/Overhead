import SwiftUI
import Backbone

// MARK: - Journey Planner Section (乗換案内-style)

/// Top section of the home screen. The user picks a departure and arrival
/// station, optional midpoints (経由), a departure time and walking speed,
/// then chooses one of the candidate trains — including itineraries with
/// transfers (乗り換え) when no single train covers the trip.
struct JourneyPlannerSection: View {
    @ObservedObject var viewModel: JourneyViewModel

    @State private var fromSelection: StationSearchHit?
    @State private var toSelection: StationSearchHit?
    @State private var viaSelections: [StationSearchHit] = []
    @State private var pickerTarget: PickerTarget?

    @State private var departureMode: DepartureMode = .now
    @State private var departureDate = Date()
    @AppStorage("journey.walkingSpeed") private var walkingSpeedRaw = WalkingSpeed.normal.rawValue
    @AppStorage("journey.setup.stations") private var storedStationsJSON = ""

    @State private var candidates: [TrainCandidate] = []
    @State private var hasSearched = false
    @State private var isSearching = false
    @State private var searchError: LocalizedStringKey?
    @StateObject private var walkingEstimator = WalkingTimeEstimator()

    private static let maxViaCount = 3

    private struct StoredStation: Codable {
        var lineId: String
        var stationId: String
    }

    private struct StoredSetup: Codable {
        var from: StoredStation?
        var vias: [StoredStation]
        var to: StoredStation?
    }

    enum DepartureMode: Hashable {
        case now
        case scheduled
    }

    enum PickerTarget: Identifiable {
        case from
        case to
        case via(Int)
        case addVia

        var id: String {
            switch self {
            case .from: return "from"
            case .to: return "to"
            case .via(let index): return "via\(index)"
            case .addVia: return "addVia"
            }
        }
    }

    private var walkingSpeed: WalkingSpeed {
        WalkingSpeed(rawValue: walkingSpeedRaw) ?? .normal
    }

    private var effectiveDeparture: Date {
        departureMode == .now ? Date() : departureDate
    }

    // MARK: - Content

    var body: some View {
        VStack(spacing: 20) {
            stationCard

            departureTimeSection

            walkingSpeedSection

            searchButton

            if let searchError {
                noticeRow(icon: "exclamationmark.circle", text: searchError)
            }

            if hasSearched {
                candidateList
            }
        }
        .task {
            await viewModel.loadLines()
            restoreSelections()
        }
        .sheet(item: $pickerTarget) { target in
            stationPickerSheet { hit in
                switch target {
                case .from:
                    fromSelection = hit
                case .to:
                    toSelection = hit
                case .via(let index):
                    if viaSelections.indices.contains(index) {
                        viaSelections[index] = hit
                    }
                case .addVia:
                    viaSelections.append(hit)
                }
                persistSelections()
                invalidateResults()
            }
        }
    }

    private func stationPickerSheet(onSelect: @escaping (StationSearchHit) -> Void) -> some View {
        NavigationStack {
            StationSearchSelectionView(
                lines: viewModel.availableLines,
                showsCloseButton: true,
                mergesStations: true,
                onSelect: onSelect
            )
        }
    }

    // MARK: - Station Card

    private var stationCard: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                stationField(label: "Setup.From", selection: fromSelection) {
                    pickerTarget = .from
                }

                ForEach(Array(viaSelections.enumerated()), id: \.offset) { index, via in
                    fieldDivider
                    viaField(index: index, selection: via)
                }

                fieldDivider

                stationField(label: "Setup.To", selection: toSelection) {
                    pickerTarget = .to
                }
            }

            VStack(spacing: 10) {
                Button {
                    swapStations()
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(fromSelection != nil || toSelection != nil ? .accentColor : .secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Setup.Swap")
                .disabled(fromSelection == nil && toSelection == nil)

                Button {
                    pickerTarget = .addVia
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(viaSelections.count < Self.maxViaCount ? .accentColor : .secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Setup.AddVia")
                .disabled(viaSelections.count >= Self.maxViaCount)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    @ViewBuilder
    private func viaField(index: Int, selection: StationSearchHit) -> some View {
        HStack(spacing: 10) {
            Button {
                pickerTarget = .via(index)
            } label: {
                HStack(spacing: 10) {
                    Text("Setup.Via")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 22)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(selection.station.localizedName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                viaSelections.remove(at: index)
                persistSelections()
                invalidateResults()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Setup.RemoveVia")
        }
    }

    @ViewBuilder
    private func stationField(
        label: LocalizedStringKey,
        selection: StationSearchHit?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 22)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                if let selection {
                    Text(selection.station.localizedName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                } else {
                    Text("Setup.SelectStation")
                        .font(.system(size: 16))
                        .foregroundColor(Color(.tertiaryLabel))
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var fieldDivider: some View {
        HStack(spacing: 10) {
            // Small connector aligned under the labels
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 2.5, height: 2.5)
                }
            }
            .frame(width: 44)

            VStack { Divider() }
        }
        .frame(height: 10)
    }

    // MARK: - Departure Time Section

    private var departureTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Setup.DepartureTime")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 10) {
                Picker("Setup.DepartureTime", selection: $departureMode) {
                    Text("Setup.DepartNow").tag(DepartureMode.now)
                    Text("Setup.DepartAt").tag(DepartureMode.scheduled)
                }
                .pickerStyle(.segmented)
                .onChange(of: departureMode) { _, _ in
                    if departureMode == .scheduled {
                        departureDate = max(departureDate, Date())
                    }
                    invalidateResults()
                }

                if departureMode == .scheduled {
                    DatePicker(
                        "Setup.DepartureTime",
                        selection: $departureDate,
                        in: Date()...Date().addingTimeInterval(7 * 86400),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .environment(\.timeZone, TimeZone(identifier: "Asia/Tokyo")!)
                    .font(.system(size: 14))
                    .onChange(of: departureDate) { _, _ in
                        invalidateResults()
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    // MARK: - Walking Speed Section

    private var walkingSpeedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Setup.WalkingSpeed")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            Picker("Setup.WalkingSpeed", selection: Binding(
                get: { walkingSpeed },
                set: { walkingSpeedRaw = $0.rawValue }
            )) {
                ForEach(WalkingSpeed.allCases) { speed in
                    Text(speed.label).tag(speed)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: walkingSpeedRaw) { _, _ in
                invalidateResults()
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    // MARK: - Search Button

    @ViewBuilder
    private var searchButton: some View {
        let label = HStack(spacing: 6) {
            if isSearching {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
            }
            Text(hasSearched ? "Setup.SearchAgain" : "Setup.SearchTrains")
                .font(.system(size: 16, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)

        if #available(iOS 26.0, *) {
            Button {
                search()
            } label: {
                label
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .disabled(!canSearch || isSearching)
        } else {
            Button {
                search()
            } label: {
                label
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(!canSearch || isSearching)
        }
    }

    /// Station names along the journey: from, midpoints, to.
    private var waypointNames: [String]? {
        guard let from = fromSelection, let to = toSelection else { return nil }
        return [from.station.name] + viaSelections.map(\.station.name) + [to.station.name]
    }

    private var canSearch: Bool {
        guard let names = waypointNames else { return false }
        return zip(names, names.dropFirst()).allSatisfy { $0 != $1 }
    }

    // MARK: - Candidate List

    @ViewBuilder
    private var candidateList: some View {
        if candidates.isEmpty {
            noticeRow(icon: "tram", text: "Setup.NoTrains")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Setup.Candidates")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)

                VStack(spacing: 0) {
                    ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                        candidateRow(candidate)
                        if index < candidates.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private func candidateRow(_ candidate: TrainCandidate) -> some View {
        let waitMinutes = minutesUntilDeparture(candidate)

        Button {
            viewModel.startJourney(candidate: candidate)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(displayTime(candidate.departureTime))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .fixedSize()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(displayTime(candidate.arrivalTime))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .fixedSize()

                        Spacer()

                        if let waitMinutes {
                            Text(waitMinutes == 0
                                 ? "Candidate.DepartsNow"
                                 : "Candidate.DepartsIn \(waitMinutes)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(waitMinutes <= 3 ? .red : .green)
                        }
                    }

                    HStack(spacing: 8) {
                        Text("Candidate.Duration \(candidate.durationMinutes)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        if candidate.transferCount > 0 {
                            Text("Candidate.Transfers \(candidate.transferCount)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                    }
                }

                if candidate.legs.count == 1, let leg = candidate.legs.first {
                    singleLegSummary(candidate: candidate, leg: leg)
                } else {
                    transferSummary(candidate)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func singleLegSummary(candidate: TrainCandidate, leg: CandidateLeg) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(leg.line.color)
                .frame(width: 4, height: 16)

            Text(leg.line.localizedName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(leg.line.color)
                .lineLimit(1)

            Text(leg.service.trainType.displayNameJa)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(leg.line.color)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            if let destination = destinationName(of: candidate) {
                Text("Candidate.For \(destination)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if candidate.isThrough {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
    }

    /// Per-leg breakdown for itineraries with transfers, e.g.
    /// 山手線 東京 10:02 → 神田 10:04 [乗換]
    @ViewBuilder
    private func transferSummary(_ candidate: TrainCandidate) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(candidate.legs.enumerated()), id: \.offset) { index, leg in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(leg.line.color)
                        .frame(width: 4, height: 14)

                    Text(leg.line.localizedName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(leg.line.color)
                        .lineLimit(1)
                        .layoutPriority(1)

                    Text(leg.fromStation.localizedName)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Text(displayTime(leg.departureTime))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .fixedSize()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(leg.toStation.localizedName)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Text(displayTime(leg.arrivalTime))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .fixedSize()

                    if index < candidate.legs.count - 1 {
                        Text("Candidate.TransferBadge")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 0)

                    if index == 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
        }
    }

    private func destinationName(of candidate: TrainCandidate) -> String? {
        candidate.journeyLine.stations
            .first(where: { $0.id == candidate.journeyService.destinationStationId })?
            .localizedName
    }

    /// Minutes from now until departure — only shown for near-term departures today.
    private func minutesUntilDeparture(_ candidate: TrainCandidate) -> Int? {
        let interval = candidate.departureDate(reference: effectiveDeparture).timeIntervalSinceNow
        guard interval > -60 else { return nil }
        let minutes = Int(interval / 60)
        guard minutes < 100 else { return nil }
        return max(0, minutes)
    }

    /// Renders rail times past 24:00 as clock times (24:15 → 0:15).
    private func displayTime(_ railTime: String) -> String {
        guard let sec = TimetableEntry.parseRailTime(railTime), sec >= 24 * 3600 else {
            return railTime
        }
        let s = sec - 24 * 3600
        return String(format: "%d:%02d", s / 3600, (s % 3600) / 60)
    }

    @ViewBuilder
    private func noticeRow(icon: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(.system(size: 14))
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // MARK: - Actions

    private func swapStations() {
        let from = fromSelection
        fromSelection = toSelection
        toSelection = from
        viaSelections.reverse()
        persistSelections()
        invalidateResults()
    }

    private func invalidateResults() {
        candidates = []
        hasSearched = false
        searchError = nil
    }

    private func search() {
        guard let names = waypointNames, !isSearching else { return }
        searchError = nil
        isSearching = true

        Task {
            // When leaving now, trains departing before the user can walk to
            // the station are excluded outright.
            var departure = effectiveDeparture
            if departureMode == .now,
               walkingSpeed != .none,
               let station = fromSelection?.station,
               let walkSeconds = await walkingEstimator.walkingSeconds(to: station) {
                departure = departure.addingTimeInterval(walkSeconds * walkingSpeed.paceMultiplier)
            }

            candidates = viewModel.searchTrainCandidates(
                stationNames: names,
                departure: departure,
                transferMinutes: walkingSpeed.transferMinutes
            )
            hasSearched = true
            isSearching = false

            if candidates.isEmpty && !viewModel.routeExists(through: names) {
                hasSearched = false
                searchError = "Setup.NoRoute"
            }
        }
    }

    // MARK: - Selection Persistence

    private func persistSelections() {
        let setup = StoredSetup(
            from: fromSelection.map { StoredStation(lineId: $0.line.id, stationId: $0.station.id) },
            vias: viaSelections.map { StoredStation(lineId: $0.line.id, stationId: $0.station.id) },
            to: toSelection.map { StoredStation(lineId: $0.line.id, stationId: $0.station.id) }
        )
        guard let data = try? JSONEncoder().encode(setup),
              let json = String(data: data, encoding: .utf8)
        else { return }
        storedStationsJSON = json
    }

    private func restoreSelections() {
        guard fromSelection == nil, toSelection == nil, viaSelections.isEmpty,
              let data = storedStationsJSON.data(using: .utf8),
              let setup = try? JSONDecoder().decode(StoredSetup.self, from: data)
        else { return }
        fromSelection = hit(for: setup.from)
        viaSelections = setup.vias.compactMap { hit(for: $0) }
        toSelection = hit(for: setup.to)
    }

    private func hit(for stored: StoredStation?) -> StationSearchHit? {
        guard let stored,
              let line = viewModel.availableLines.first(where: { $0.id == stored.lineId }),
              let station = line.stations.first(where: { $0.id == stored.stationId })
        else { return nil }
        return StationSearchHit(line: line, station: station)
    }
}
