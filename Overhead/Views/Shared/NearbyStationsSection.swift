import SwiftUI
import CoreLocation
import Backbone

// MARK: - Nearby Stations Section

/// Home-screen 付近の駅 rail: one card per nearby station, each line a row
/// showing the next scheduled departure. Tapping a row flips its direction.
/// Every state except denied keeps the same height so content below never jumps.
struct NearbyStationsSection: View {
    @ObservedObject var viewModel: JourneyViewModel
    @StateObject private var provider = NearbyStationsProvider()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.serviceStatusPresenter) private var serviceStatusPresenter
    @AppStorage("journey.walkingSpeed") private var walkingSpeedRaw = WalkingSpeed.normal.rawValue

    /// Remembered flip per "stationName|lineId", persisted across launches.
    @State private var directionChoices: [String: String] =
        (UserDefaults.standard.dictionary(forKey: Self.directionChoicesKey) as? [String: String]) ?? [:]
    /// Full per-direction timetables per hit id, computed off the main thread.
    @State private var timetablesByHit: [String: [StationTimetableData]] = [:]
    @State private var timetableTarget: NearbyTimetableTarget?

    private static let directionChoicesKey = "nearby.directionChoices"
    /// All cards share one height (3 visible rows); longer lists scroll inside it.
    private static let cardHeight: CGFloat = 182
    /// Header (~22) + 8 gap + card, exactly — any slack here reads as
    /// uneven spacing against the root VStack's 24pt section gaps.
    private static let sectionHeight: CGFloat = 212

    var body: some View {
        Group {
            switch provider.authorizationStatus {
            case .denied, .restricted:
                deniedRow
            case .notDetermined:
                fixedFrame { promptCard }
            default:
                fixedFrame { authorizedContent }
            }
        }
        .task(id: viewModel.availableLines.count) {
            guard !viewModel.availableLines.isEmpty else { return }
            refreshUnlessJourneyActive()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, !viewModel.availableLines.isEmpty else { return }
            refreshUnlessJourneyActive()
        }
        .task(id: provider.nearestGroups.map(\.id).joined(separator: "|")) {
            await recomputeTimetables()
        }
        .sheet(item: $timetableTarget) { target in
            NavigationStack {
                StationTimetableView(
                    station: target.hit.station,
                    line: target.hit.line,
                    preferredDirectionId: target.directionId,
                    viewModel: viewModel
                )
            }
        }
    }

    private func refreshUnlessJourneyActive() {
        // Mid-journey the rail would reshuffle under the user; let it go stale.
        guard viewModel.activeJourney == nil else { return }
        provider.refreshIfNeeded(lines: viewModel.availableLines)
    }

    /// Fixed-height frame shared by every state except denied.
    private func fixedFrame(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            content()
        }
        .frame(height: Self.sectionHeight, alignment: .top)
    }

    // MARK: - Header

    private var header: some View {
        SectionHeader(title: provider.isReducedAccuracy ? "Nearby.TitleApprox" : "Nearby.Title") {
            switch provider.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                // Always present once authorized; dimmed while locating.
                SectionAction(
                    icon: "arrow.clockwise",
                    label: "Button.Refresh",
                    enabled: !provider.isLocating
                ) {
                    provider.refreshIfNeeded(lines: viewModel.availableLines, force: true)
                }
            default:
                EmptyView()
            }
        }
    }

    // MARK: - States

    @ViewBuilder private var authorizedContent: some View {
        if !provider.nearestGroups.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(provider.nearestGroups) { group in
                        stationCard(group)
                    }
                }
            }
            .scrollClipDisabled()
        } else if provider.isLocating {
            loadingCard
        } else if provider.fixFailed {
            fixFailedCard
        } else if provider.lastUpdated != nil {
            outOfAreaCard
        } else {
            // Fix not attempted yet (lines still loading).
            Color.clear
        }
    }

    private var deniedRow: some View {
        HStack(spacing: 6) {
            Text("Nearby.Denied")
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link("Nearby.Settings", destination: url)
                    .font(.system(size: 12.5, weight: .semibold))
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nearby.Prompt.Title")
                .font(.system(size: 14.5, weight: .semibold))
            Text("Nearby.Prompt.Body")
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
            Button {
                provider.requestPermission(lines: viewModel.availableLines)
            } label: {
                Text("Nearby.Prompt.Button")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.tint))
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(17)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var loadingCard: some View {
        // The header's 測位中… gives way to the label here, so it isn't doubled.
        ProgressView("Nearby.Locating")
            .controlSize(.large)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var fixFailedCard: some View {
        unavailableCard(title: "Nearby.FixFailed.Title", icon: "location.slash")
    }

    private var outOfAreaCard: some View {
        unavailableCard(title: "Nearby.OutOfArea.Title", icon: "mappin.slash")
    }

    /// Compact empty-state card, centered vertically; no inner scrolling.
    private func unavailableCard(title: LocalizedStringKey, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.bottom, 5)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Station card

    private func stationCard(_ group: NearbyStationGroup) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.station.localizedName)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                if !provider.isReducedAccuracy {
                    walkLabel(meters: group.distanceMeters)
                }
            }
            // Every line is reachable by scrolling within the fixed card height.
            ScrollView(.vertical, showsIndicators: false) {
                TimelineView(.everyMinute) { context in
                    VStack(spacing: 0) {
                        ForEach(Array(group.hits.enumerated()), id: \.element.id) { index, hit in
                            if index > 0 { Divider() }
                            lineRow(group: group, hit: hit, at: context.date)
                        }
                    }
                }
            }
            // Rows clip at the bare card edge mid-scroll, but the end of the
            // list keeps breathing room when scrolled all the way down.
            .contentMargins(.bottom, 10, for: .scrollContent)
            .scrollDisabled(group.hits.count <= 3)
        }
        // No bottom inset: the row list runs to the card edge so scrolling
        // content emerges from under the rounded corner.
        .padding(EdgeInsets(top: 13, leading: 13, bottom: 0, trailing: 13))
        .frame(width: 196, height: Self.cardHeight, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func walkLabel(meters: Double) -> some View {
        let speed = WalkingSpeed(rawValue: walkingSpeedRaw) ?? .normal
        return Group {
            if let pace = speed.paceMetersPerMinute {
                // Straight-line distance with the estimator's 1.4 circuity factor.
                Text("Nearby.Walk \(max(1, Int((meters * 1.4 / pace).rounded(.up))))")
            } else {
                Text(verbatim: meters < 1000
                    ? String(format: "%.0fm", meters)
                    : String(format: "%.1fkm", meters / 1000))
            }
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }

    // MARK: - Line row

    private func lineRow(group: NearbyStationGroup, hit: StationSearchHit, at date: Date) -> some View {
        let timetables = timetablesByHit[hit.id] ?? []
        let choiceKey = "\(group.name)|\(hit.line.id)"
        let current = currentTimetable(timetables, choiceKey: choiceKey)
        let next = current.flatMap { nextDeparture(in: $0, at: date) }

        return Button {
            flip(choiceKey: choiceKey, timetables: timetables)
        } label: {
            HStack(spacing: 9) {
                if !hit.line.lineSymbol.isEmpty {
                    LineSymbolBadge(symbol: hit.line.lineSymbol, color: hit.line.color, dimension: 26)
                } else {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(hit.line.color)
                        .frame(width: 5, height: 20)
                        .frame(width: 26, height: 26)
                }
                if let next {
                    Text(next.departureTime)
                        .font(.system(size: 14.5, weight: .semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Spacer(minLength: 4)
                    Text(next.localizedDestination)
                        .font(.system(size: 14.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .contentTransition(.opacity)
                } else if current != nil {
                    Text("StationTimetable.NoMoreTrains")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                } else {
                    // Timetable still computing.
                    Text(verbatim: "--:--")
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                    Spacer(minLength: 4)
                }
            }
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                timetableTarget = NearbyTimetableTarget(hit: hit, directionId: currentDirectionId(timetables, choiceKey: choiceKey))
            } label: {
                Label("Nearby.OpenTimetable", systemImage: "calendar")
            }
            Button {
                serviceStatusPresenter?.activate(
                    lineId: hit.line.id,
                    delayInfo: viewModel.delayCheckInfo(for: hit.line.id)
                )
            } label: {
                Label("StationTimetable.ServiceStatus", systemImage: "info.circle")
            }
        }
    }

    // MARK: - Direction flip

    private func currentTimetable(_ timetables: [StationTimetableData], choiceKey: String) -> StationTimetableData? {
        guard !timetables.isEmpty else { return nil }
        if let chosen = directionChoices[choiceKey],
           let match = timetables.first(where: { $0.railDirection == chosen }) {
            return match
        }
        return timetables.first
    }

    private func currentDirectionId(_ timetables: [StationTimetableData], choiceKey: String) -> String? {
        currentTimetable(timetables, choiceKey: choiceKey)?.railDirection
    }

    private func flip(choiceKey: String, timetables: [StationTimetableData]) {
        guard timetables.count > 1 else { return }
        let currentId = currentDirectionId(timetables, choiceKey: choiceKey)
        let index = timetables.firstIndex { $0.railDirection == currentId } ?? 0
        let nextId = timetables[(index + 1) % timetables.count].railDirection
        withAnimation(.smooth(duration: 0.28)) {
            directionChoices[choiceKey] = nextId
        }
        UserDefaults.standard.set(directionChoices, forKey: Self.directionChoicesKey)
    }

    private func nextDeparture(in timetable: StationTimetableData, at date: Date) -> StationDeparture? {
        let nowMinutes = Self.railNowMinutes(at: date)
        return timetable.departures.first { departure in
            guard let secs = TimetableEntry.parseRailTime(departure.departureTime) else { return false }
            return secs / 60 >= nowMinutes
        }
    }

    /// Before 03:00 the clock reads as 24+ so post-midnight departures compare correctly.
    private static func railNowMinutes(at date: Date) -> Int {
        let tz = TimeZone(identifier: "Asia/Tokyo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let comps = cal.dateComponents([.hour, .minute], from: date)
        var nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        if nowMinutes < 180 {
            nowMinutes += 1440
        }
        return nowMinutes
    }

    // MARK: - Timetable computation

    private func recomputeTimetables() async {
        // Plain values captured on the main actor before hopping off it.
        let targets = provider.nearestGroups.flatMap { group in
            group.hits.map { (id: $0.id, lineId: $0.line.id, stationId: $0.station.id) }
        }
        guard !targets.isEmpty else { return }
        let computed = await Task.detached(priority: .userInitiated) { () -> [String: [StationTimetableData]] in
            var result: [String: [StationTimetableData]] = [:]
            let calendar = ScheduleCalendar.current()
            for target in targets {
                guard let staticLine = StaticTrainData.line(withId: target.lineId) else { continue }
                result[target.id] = StaticTimetableGenerator.stationTimetables(
                    for: staticLine,
                    stationId: target.stationId,
                    calendar: calendar
                )
            }
            return result
        }.value
        timetablesByHit = computed
    }
}

// MARK: - Timetable sheet target

private struct NearbyTimetableTarget: Identifiable {
    let hit: StationSearchHit
    let directionId: String?
    var id: String { hit.id }
}
