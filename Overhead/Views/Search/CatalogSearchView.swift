import SwiftUI
import Backbone
import EnhancedNavigation

/// The catalog search surface, including its results and keyboard-aware field.
struct CatalogSearchView: View {
    let lines: [TrainLine]
    @Binding var searchText: String
    @Binding var scope: SearchScope
    let dismiss: () -> Void
    let onOpen: (SearchDestination) -> Void
    let onRoute: (_ from: StationSearchHit, _ to: StationSearchHit) -> Void

    @FocusState private var isFieldFocused: Bool
    @State private var results = Results.empty
    @State private var pendingRouteDestination: StationSearchHit?
    @State private var isKeyboardUp = false
    @StateObject private var nearbyProvider = NearbyStationsProvider()

    private static let previewLimit = 6
    private static let scopeLimit = 100
    private static let fieldHeight = TabBottomBarMetrics.itemHeight

    private struct Results {
        var operators: [OperatorSearchHit] = []
        var lines: [TrainLine] = []
        var stations: [StationSearchHit] = []

        static let empty = Results()
    }

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasResultsForSelectedScope: Bool {
        switch scope {
        case .all:
            !results.operators.isEmpty || !results.lines.isEmpty || !results.stations.isEmpty
        case .operators:
            !results.operators.isEmpty
        case .lines:
            !results.lines.isEmpty
        case .stations:
            !results.stations.isEmpty
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            resultsList
                .ignoresSafeArea(.container, edges: .bottom)
                .background {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea([.container, .keyboard])
                }
            searchField
        }
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.safeAreaInsets.bottom > DisplayMetrics.safeAreaInsets.bottom + 1
        } action: { isUp in
            isKeyboardUp = isUp
        }
        .task {
            try? await Task.sleep(for: .milliseconds(80))
            isFieldFocused = true
        }
    }

    private var resultsList: some View {
        List {
            Section {
                Picker("Search.Title", selection: $scope) {
                    ForEach(SearchScope.allCases) { item in
                        Label(item.title, systemImage: item.icon).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            if query.isEmpty {
                browseContent
            } else {
                resultsContent
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, fieldClearance, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .task(id: "\(query)|\(lines.count)") { await runSearch() }
        .task(id: lines.count) {
            nearbyProvider.refreshIfNeeded(lines: lines)
        }
        .onChange(of: nearbyProvider.nearestStations.map(\.id)) { _, _ in
            completePendingRouteIfPossible()
        }
    }

    /// The list runs under the home indicator, so it clears the field and
    /// whatever lies beneath it.
    private var fieldClearance: CGFloat {
        let below = isKeyboardUp
            ? 8
            : DisplayMetrics.safeAreaInsets.bottom - TabBottomBarMetrics.safeAreaOverhang
        return Self.fieldHeight + TabBottomBarMetrics.topInset + below
    }

    private var searchField: some View {
        GlassEffectContainer(spacing: TabBottomBarMetrics.itemSpacing) {
            HStack(spacing: TabBottomBarMetrics.itemSpacing) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search.Prompt", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($isFieldFocused)
                        .onSubmit { isFieldFocused = false }
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Button.Close")
                    }
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: Self.fieldHeight)
                .glassEffect(.regular.interactive(), in: .capsule)

                Button {
                    isFieldFocused = false
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: Self.fieldHeight, height: Self.fieldHeight)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("Button.Close")
            }
        }
        // Where the omnibox sits, so the field opens in place.
        .padding(.horizontal, TabBottomBarMetrics.horizontalInset)
        .padding(.bottom, isKeyboardUp ? 8 : -TabBottomBarMetrics.safeAreaOverhang)
    }

    @MainActor
    private func runSearch() async {
        let text = query
        guard !text.isEmpty else {
            results = .empty
            return
        }
        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled else { return }
        let source = lines
        let computed = await Task.detached(priority: .userInitiated) {
            Results(
                operators: CatalogSearch.operators(in: source, query: text),
                lines: CatalogSearch.lines(in: source, query: text),
                stations: StationSearch.search(lines: source, query: text)
            )
        }.value
        guard !Task.isCancelled else { return }
        results = computed
    }

    @ViewBuilder
    private var browseContent: some View {
        switch scope {
        case .stations:
            hintRow("Search.Hint.Stations")
        case .lines:
            Section("Search.Section.Lines") {
                ForEach(lines) { lineRow($0) }
            }
            .listRowBackground(Color.clear)
        case .all, .operators:
            Section("Search.Section.Operators") {
                ForEach(CatalogSearch.operators(in: lines, query: "")) { hit in
                    operatorRow(hit)
                }
            }
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var resultsContent: some View {
        if !hasResultsForSelectedScope {
            hintRow("Search.NoResults")
        } else {
            if scope == .all || scope == .operators, !results.operators.isEmpty {
                Section("Search.Section.Operators") {
                    ForEach(limited(results.operators)) { operatorRow($0) }
                    moreRow(results.operators.count, scope: .operators)
                }
                .listRowBackground(Color.clear)
            }
            if scope == .all || scope == .lines, !results.lines.isEmpty {
                Section("Search.Section.Lines") {
                    ForEach(limited(results.lines)) { lineRow($0) }
                    moreRow(results.lines.count, scope: .lines)
                }
                .listRowBackground(Color.clear)
            }
            if scope == .all || scope == .stations, !results.stations.isEmpty {
                Section("Search.Section.Stations") {
                    ForEach(limited(results.stations)) { stationRow($0) }
                    moreRow(results.stations.count, scope: .stations)
                }
                .listRowBackground(Color.clear)
            }
        }
    }

    private func limited<Element>(_ values: [Element]) -> [Element] {
        Array(values.prefix(scope == .all ? Self.previewLimit : Self.scopeLimit))
    }

    @ViewBuilder
    private func moreRow(_ count: Int, scope target: SearchScope) -> some View {
        if scope == .all, count > Self.previewLimit {
            Button {
                scope = target
            } label: {
                HStack {
                    Text("Search.ShowAll")
                    Spacer()
                    Text("Search.MoreCount \(count - Self.previewLimit)")
                        .foregroundStyle(.secondary)
                }
            }
        } else if count > Self.scopeLimit {
            Text("Search.MoreCount \(count - Self.scopeLimit)")
                .foregroundStyle(.secondary)
        }
    }

    private func operatorRow(_ hit: OperatorSearchHit) -> some View {
        Button {
            onOpen(.operatorLines(hit.operatorId))
        } label: {
            HStack(spacing: 10) {
                OperatorIcon(
                    operatorId: hit.operatorId,
                    fallbackColor: OperatorSections.brandColor(for: hit.operatorId, lines: hit.lines)
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(hit.title).font(.system(size: 16, weight: .semibold))
                    Text("Search.LineCount \(hit.lines.count)")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
    }

    private func lineRow(_ line: TrainLine) -> some View {
        Button {
            onOpen(.line(line.id))
        } label: {
            HStack(spacing: 10) {
                LineLeadingBadge(line: line, dimension: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.localizedName).font(.system(size: 16, weight: .semibold))
                    Text(OperatorSections.title(for: line.operatorId))
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
    }

    private func stationRow(_ hit: StationSearchHit) -> some View {
        Menu {
            Button {
                route(to: hit)
            } label: {
                Label("Search.RouteFromNearest", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
            }
            Button {
                onOpen(.station(lineId: hit.line.id, stationId: hit.station.id))
            } label: {
                Label("Nearby.OpenTimetable", systemImage: "calendar")
            }
            Divider()
            Button {
                onOpen(.line(hit.line.id))
            } label: {
                Label(hit.line.localizedName, systemImage: "tram.fill")
            }
            Button {
                onOpen(.operatorLines(hit.line.operatorId))
            } label: {
                Label(OperatorSections.title(for: hit.line.operatorId), systemImage: "building.2")
            }
        } label: {
            HStack {
                StationSearchRow(hit: hit)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .foregroundStyle(.primary)
    }

    private func route(to destination: StationSearchHit) {
        if let origin = nearbyProvider.nearestStations.first?.hit {
            onRoute(origin, destination)
        } else {
            pendingRouteDestination = destination
            nearbyProvider.requestPermission(lines: lines)
        }
    }

    private func completePendingRouteIfPossible() {
        guard let destination = pendingRouteDestination,
              let origin = nearbyProvider.nearestStations.first?.hit else { return }
        pendingRouteDestination = nil
        onRoute(origin, destination)
    }

    private func hintRow(_ title: LocalizedStringKey) -> some View {
        Label(title, systemImage: "magnifyingglass")
            .foregroundStyle(.secondary)
            .listRowBackground(Color.clear)
    }
}
