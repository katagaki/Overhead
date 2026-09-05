import SwiftUI
import Backbone

// MARK: - Journey Planner Section (乗換案内-style)

struct JourneyPlannerSection: View {
    @ObservedObject var viewModel: JourneyViewModel

    @State private var fromSelection: StationSearchHit?
    @State private var toSelection: StationSearchHit?
    @State private var viaSelections: [StationSearchHit] = []

    @State private var timeMode: TimeMode = .now
    @State private var pinnedDate = Date()
    @AppStorage("journey.walkingSpeed") private var walkingSpeedRaw = WalkingSpeed.normal.rawValue
    @AppStorage("journey.preferOriginating") private var preferOriginating = false
    @AppStorage("journey.avoidedLines") private var avoidedLinesJSON = ""
    @AppStorage(JourneyMode.storageKey) private var journeyMode = JourneyMode.hybrid
    @AppStorage("journey.setup.stations") private var storedStationsJSON = ""
    @State private var showAvoidLinesSheet = false
    @State private var showTimeSettingsSheet = false
    @State private var savedPlaces: [SavedPlace] = []

    @State private var candidates: [TrainCandidate] = []
    @State private var hasSearched = false
    @State private var isSearching = false
    @State private var searchError: LocalizedStringKey?
    @State private var searchWalkMinutes: Int?
    @StateObject private var walkingEstimator = WalkingTimeEstimator()

    private struct StoredStation: Codable {
        var lineId: String
        var stationId: String
    }

    private struct StoredSetup: Codable {
        var from: StoredStation?
        var vias: [StoredStation]
        var to: StoredStation?
    }

    enum TimeMode: Hashable {
        case now
        case departAt
        case arriveBy
    }

    private var walkingSpeed: WalkingSpeed {
        WalkingSpeed(rawValue: walkingSpeedRaw) ?? .normal
    }

    private var ignoreTimetable: Bool { journeyMode.ignoresTimetable }

    private var avoidedLineIds: Set<String> {
        guard let data = avoidedLinesJSON.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return Set(ids)
    }

    private var avoidedLineIdsBinding: Binding<Set<String>> {
        Binding(
            get: { avoidedLineIds },
            set: { newValue in
                let ids = newValue.sorted()
                avoidedLinesJSON = (try? JSONEncoder().encode(ids))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? ""
                invalidateResults()
            }
        )
    }

    private var anchorDate: Date {
        timeMode == .now ? Date() : pinnedDate
    }

    private var searchAnchor: JourneyViewModel.TimeAnchor {
        timeMode == .arriveBy ? .arrival(anchorDate) : .departure(anchorDate)
    }

    // MARK: - Content

    var body: some View {
        VStack(spacing: 20) {
            // Card and its buttons read as one control; keep them tight.
            VStack(spacing: 12) {
                plannerCard

                HStack(spacing: 10) {
                    searchButton
                    favoriteButton
                }
            }

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
        .onAppear { savedPlaces = SavedPlaceStore.load() }
        .onReceive(NotificationCenter.default.publisher(for: SavedPlaceStore.didChangeNotification)) { _ in
            savedPlaces = SavedPlaceStore.load()
        }
        .onReceive(viewModel.$plannerFromRequest) { hit in
            guard let hit else { return }
            viewModel.plannerFromRequest = nil
            withAnimation(.smooth(duration: 0.35)) {
                fromSelection = hit
            }
            persistSelections()
            invalidateResults()
        }
#if DEBUG
        .onReceive(ScreenshotStaging.shared.$plannerCommand) { command in
            guard let command else { return }
            ScreenshotStaging.shared.plannerCommand = nil
            Task { await stage(command) }
        }
#endif
    }

    // MARK: - Planner Card

    private var plannerCard: some View {
        RouteSetupCard(
            lines: viewModel.availableLines,
            fromSelection: $fromSelection,
            viaSelections: $viaSelections,
            toSelection: $toSelection,
            walkingSpeedRaw: $walkingSpeedRaw,
            preferOriginating: $preferOriginating,
            avoidedLineIds: avoidedLineIdsBinding,
            onStationsChanged: {
                persistSelections()
                invalidateResults()
            },
            leadingItems: AnyView(departureTimeItem)
        )
        .sheet(isPresented: $showTimeSettingsSheet) {
            TimeSettingsSheet(
                timeMode: $timeMode,
                pinnedDate: $pinnedDate
            )
        }
        // Staging-only surface: the interactive item lives in RouteSetupCard.
        .sheet(isPresented: $showAvoidLinesSheet) {
            AvoidLinesSheet(
                lines: viewModel.availableLines,
                avoidedLineIds: avoidedLineIdsBinding
            )
        }
        .onChange(of: walkingSpeedRaw) { _, _ in
            invalidateResults()
        }
        .onChange(of: preferOriginating) { _, _ in
            invalidateResults()
        }
        .onChange(of: journeyMode) { _, _ in
            invalidateResults()
        }
        .onChange(of: timeMode) { _, _ in
            invalidateResults()
        }
        .onChange(of: pinnedDate) { _, _ in
            invalidateResults()
        }
    }

    private var departureTimeItem: some View {
        Button {
            showTimeSettingsSheet = true
        } label: {
            CustomizationItem(
                icon: "clock",
                label: "Setup.TimeSettings",
                active: timeMode != .now
            )
        }
        .buttonStyle(.plain)
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
        
        Button {
            search()
        } label: {
            label
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .disabled(!canSearch || isSearching)
    }

    // MARK: - Favorite Button

    private var favoriteButton: some View {
        let isSaved = savedPlaceForSetup != nil
        return Button {
            toggleFavorite()
        } label: {
            Image(systemName: isSaved ? "star.fill" : "star")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 24)
                .padding(.vertical, 8)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .disabled(!canSearch)
        .accessibilityLabel(isSaved ? "Button.RemoveFromFavorites" : "Button.AddToFavorites")
        .sensoryFeedback(.success, trigger: savedPlaceForSetup?.id)
    }

    /// The favorite whose route matches what's in the planner right now, if any.
    private var savedPlaceForSetup: SavedPlace? {
        guard let from = fromSelection, let to = toSelection else { return nil }
        let vias = viaSelections.map(\.station.id)
        return savedPlaces.first {
            $0.fromStationId == from.station.id
                && $0.toStationId == to.station.id
                && $0.viaStationIds == vias
        }
    }

    /// Saves the planner's current route as-is, or unsaves it if it's already there.
    private func toggleFavorite() {
        guard let from = fromSelection, let to = toSelection else { return }
        var places = SavedPlaceStore.load()

        if let existing = savedPlaceForSetup {
            places.removeAll { $0.id == existing.id }
        } else {
            places.append(SavedPlace(
                id: UUID(),
                kind: .custom,
                customName: to.station.localizedName,
                lineId: from.line.id,
                fromStationId: from.station.id,
                toStationId: to.station.id,
                viaStationIds: viaSelections.map(\.station.id),
                walkingSpeedRaw: walkingSpeedRaw,
                preferOriginating: preferOriginating,
                avoidedLineIds: avoidedLineIds.sorted()
            ))
        }

        withAnimation {
            SavedPlaceStore.save(places)
            savedPlaces = places
        }
    }

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
            noticeRow(
                icon: "exclamationmark.circle",
                text: timeMode == .arriveBy ? "Setup.NoTrainsByArrival" : "Setup.NoTrains"
            )
        } else {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: ignoreTimetable ? "Setup.Routes" : "Setup.Candidates")

                if let walkMinutes = searchWalkMinutes,
                   let fromName = fromSelection?.station.localizedName {
                    noticeRow(icon: "figure.walk", text: "Setup.WalkEstimate \(fromName) \(walkMinutes)")
                }

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
                if candidate.hasSchedule {
                    scheduledCandidateHeader(candidate, waitMinutes: waitMinutes)
                } else {
                    untimedCandidateHeader(candidate)
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
    private func untimedCandidateHeader(_ candidate: TrainCandidate) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Candidate.EstimatedDuration \(candidate.durationMinutes)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .lineLimit(1)
                .fixedSize()

            if candidate.transferCount > 0 {
                Text("Candidate.Transfers \(candidate.transferCount)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func scheduledCandidateHeader(_ candidate: TrainCandidate, waitMinutes: Int?) -> some View {
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
                        .foregroundColor(waitMinutes <= (searchWalkMinutes ?? 0) + 3 ? .red : .green)
                }
            }

            HStack(spacing: 8) {
                Text("Candidate.Duration \(candidate.durationMinutes)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                if candidate.startsAtBoarding {
                    originatingBadge
                }

                if candidate.legs.count == 1,
                   let platform = boardingPlatform(for: candidate.legs.first) {
                    Text("Candidate.Platform \(platform)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }

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
    }

    /// 始発 — you board where the train starts, so there is a seat waiting.
    private var originatingBadge: some View {
        Text("Candidate.Originating")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func singleLegSummary(candidate: TrainCandidate, leg: CandidateLeg) -> some View {
        HStack(spacing: 6) {
            LineLeadingBadge(line: leg.line, dimension: 18)

            Text(leg.line.localizedName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(leg.line.color)
                .lineLimit(1)

            if candidate.hasSchedule {
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

    @ViewBuilder
    private func transferSummary(_ candidate: TrainCandidate) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(candidate.legs.enumerated()), id: \.offset) { index, leg in
                HStack(spacing: 5) {
                    LineLeadingBadge(line: leg.line, dimension: 16)

                    Text(leg.line.localizedName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(leg.line.color)
                        .lineLimit(1)
                        .layoutPriority(1)

                    Text(leg.fromStation.localizedName)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    if let platform = boardingPlatform(for: leg) {
                        Text("Candidate.Platform \(platform)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                            .fixedSize()
                    }
                    if candidate.hasSchedule {
                        Text(displayTime(leg.departureTime))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .fixedSize()
                    }

                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(leg.toStation.localizedName)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    if candidate.hasSchedule {
                        Text(displayTime(leg.arrivalTime))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .fixedSize()
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

    private func minutesUntilDeparture(_ candidate: TrainCandidate) -> Int? {
        let interval = candidate.departureDate(reference: anchorDate).timeIntervalSinceNow
        guard interval > -60 else { return nil }
        let minutes = Int(interval / 60)
        guard minutes < 100 else { return nil }
        return max(0, minutes)
    }

    /// 番線 the first leg boards at. Absent for most stations, and for every
    /// station where the platform depends on which train turns up.
    private func boardingPlatform(for leg: CandidateLeg?) -> String? {
        guard let leg,
              let line = StaticTrainData.line(containingStationId: leg.fromStation.id),
              let index = leg.service.timetable.firstIndex(where: { $0.stationId == leg.fromStation.id }),
              index + 1 < leg.service.timetable.count
        else { return nil }
        return line.boardingPlatform(atStationId: leg.fromStation.id,
                                     nextStationId: leg.service.timetable[index + 1].stationId,
                                     departure: leg.service.timetable[index].departureTime,
                                     calendar: .current(at: anchorDate))
    }

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

    private func invalidateResults() {
        candidates = []
        hasSearched = false
        searchError = nil
        searchWalkMinutes = nil
    }

    private func search() {
        guard let names = waypointNames, !isSearching else { return }
        searchError = nil
        isSearching = true

        Task {
            let avoided = avoidedLineIds

            if ignoreTimetable {
                searchWalkMinutes = nil
                candidates = viewModel.searchRouteOptions(
                    stationNames: names,
                    transferMinutes: walkingSpeed.transferMinutes,
                    avoidingLineIds: avoided
                )
                hasSearched = true
                isSearching = false
                if candidates.isEmpty {
                    hasSearched = false
                    searchError = "Setup.NoRoute"
                }
                return
            }

            var anchor = searchAnchor
            var walkMinutes: Int?
            // 到着時刻 keeps its anchor, but trains you can't reach are out too.
            var earliestDeparture: Date? = timeMode == .arriveBy ? Date() : nil
            if timeMode != .departAt,
               let station = fromSelection?.station,
               let walkSeconds = await walkingEstimator.walkingSeconds(to: station, speed: walkingSpeed),
               walkSeconds <= 120 * 60 {
                walkMinutes = max(1, Int((walkSeconds / 60).rounded(.up)))
                if timeMode == .arriveBy {
                    earliestDeparture = Date().addingTimeInterval(walkSeconds)
                } else {
                    anchor = .departure(anchorDate.addingTimeInterval(walkSeconds))
                }
            }
            searchWalkMinutes = walkMinutes

            candidates = viewModel.searchTrainCandidates(
                stationNames: names,
                anchor: anchor,
                transferMinutes: walkingSpeed.transferMinutes,
                avoidingLineIds: avoided,
                notDepartingBefore: earliestDeparture,
                preferringOriginating: preferOriginating
            )
            hasSearched = true
            isSearching = false

            if candidates.isEmpty && !viewModel.routeExists(through: names, avoidingLineIds: avoided) {
                hasSearched = false
                searchError = "Setup.NoRoute"
            }
        }
    }

#if DEBUG
    // MARK: - Screenshot Harness

    private func stage(_ command: ScreenshotStaging.PlannerCommand) async {
        await viewModel.loadLines()
        guard let line = viewModel.availableLines.first(where: { $0.id == "Railway:JR-East.JobanRapid" }),
              let from = line.stations.first(where: { $0.id == "Station:JR-East.JobanRapid.Tokyo" }),
              let to = line.stations.first(where: { $0.id == "Station:JR-East.JobanRapid.Toride" })
        else { return }
        fromSelection = StationSearchHit(line: line, station: from)
        toSelection = StationSearchHit(line: line, station: to)
        viaSelections = []
        switch command {
        case .search:
            search()
        case .avoid:
            avoidedLineIdsBinding.wrappedValue = [
                "Railway:JR-East.JobanLocal",
                "Railway:TokyoMetro.Chiyoda"
            ]
            try? await Task.sleep(for: .seconds(1))
            showAvoidLinesSheet = true
        case .departure:
            timeMode = .departAt
            try? await Task.sleep(for: .seconds(1))
            showTimeSettingsSheet = true
        case .arrival:
            timeMode = .arriveBy
            pinnedDate = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
            try? await Task.sleep(for: .seconds(1))
            search()
        }
    }
#endif

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
