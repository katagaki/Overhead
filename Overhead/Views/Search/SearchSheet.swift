import SwiftUI
import Backbone

// MARK: - Search Sheet

/// One query over operators, lines and stations. Selecting a result hands the
/// destination back and closes; the caller pushes it onto the root stack.
struct SearchSheet: View {
    let lines: [TrainLine]
    let onSelect: (SearchDestination) -> Void

    @State private var searchText = ""
    @State private var scope: SearchScope
    @FocusState private var searchFocused: Bool
    @Environment(\.dismiss) private var dismiss

    /// How many of each kind the combined scope shows before もっと見る.
    private static let previewLimit = 5

    init(lines: [TrainLine], initialScope: SearchScope = .all, onSelect: @escaping (SearchDestination) -> Void) {
        self.lines = lines
        self.onSelect = onSelect
        _scope = State(initialValue: initialScope)
    }

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var operatorHits: [OperatorSearchHit] {
        CatalogSearch.operators(in: lines, query: query)
    }

    private var lineHits: [TrainLine] {
        CatalogSearch.lines(in: lines, query: query)
    }

    private var stationHits: [StationSearchHit] {
        StationSearch.search(lines: lines, query: query)
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    browseContent
                } else {
                    resultsContent
                }
            }
            .listStyle(.grouped)
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .safeAreaInset(edge: .top, spacing: 0) {
                scopePicker
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                searchBar
            }
            .navigationTitle("Search.Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            searchFocused = true
#if DEBUG
            if let debugQuery = UserDefaults.standard.string(forKey: "debugSearchQuery") {
                searchText = debugQuery
            }
#endif
        }
    }

    // MARK: - Scope

    private var scopePicker: some View {
        Picker("Search.Title", selection: $scope) {
            ForEach(SearchScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        GlassEffectContainer {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.primary)

                TextField("Search.Prompt", text: $searchText)
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                    .submitLabel(.search)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .accessibilityLabel("Button.Close")
                }
            }
            .font(.system(size: 17))
            .padding(.horizontal, 16)
            .frame(height: 48)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .padding(10)
    }

    // MARK: - Idle Content

    @ViewBuilder
    private var browseContent: some View {
        switch scope {
        case .all, .operators:
            Section("Search.Section.Operators") {
                ForEach(operatorHits) { hit in
                    operatorRow(hit)
                }
            }
        case .lines:
            ForEach(operatorHits) { hit in
                Section(hit.title) {
                    ForEach(hit.lines) { line in
                        lineRow(line)
                    }
                }
            }
        case .stations:
            hintRow("Search.Hint.Stations")
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsContent: some View {
        let operators = operatorHits
        let matchedLines = lineHits
        let stations = stationHits

        if operators.isEmpty, matchedLines.isEmpty, stations.isEmpty {
            hintRow("Search.NoResults")
        } else {
            if scope == .all || scope == .operators, !operators.isEmpty {
                Section("Search.Section.Operators") {
                    ForEach(limited(operators)) { hit in
                        operatorRow(hit)
                    }
                    moreRow(count: operators.count, scope: .operators)
                }
            }
            if scope == .all || scope == .lines, !matchedLines.isEmpty {
                Section("Search.Section.Lines") {
                    ForEach(limited(matchedLines)) { line in
                        lineRow(line)
                    }
                    moreRow(count: matchedLines.count, scope: .lines)
                }
            }
            if scope == .all || scope == .stations, !stations.isEmpty {
                Section("Search.Section.Stations") {
                    ForEach(limited(stations)) { hit in
                        stationRow(hit)
                    }
                    moreRow(count: stations.count, scope: .stations)
                }
            }
        }
    }

    private func limited<Element>(_ items: [Element]) -> [Element] {
        scope == .all ? Array(items.prefix(Self.previewLimit)) : items
    }

    @ViewBuilder
    private func moreRow(count: Int, scope target: SearchScope) -> some View {
        if scope == .all, count > Self.previewLimit {
            Button {
                scope = target
            } label: {
                HStack {
                    Text("Search.ShowAll")
                    Spacer()
                    Text("Search.MoreCount \(count - Self.previewLimit)")
                        .foregroundColor(.secondary)
                }
                .font(.system(size: 15, weight: .medium))
            }
        }
    }

    // MARK: - Rows

    private func operatorRow(_ hit: OperatorSearchHit) -> some View {
        selectionRow(.operatorLines(hit.operatorId)) {
            HStack(spacing: 10) {
                operatorBadges(hit.lines)
                VStack(alignment: .leading, spacing: 2) {
                    Text(hit.title)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Search.LineCount \(hit.lines.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    /// Up to three of the operator's line colours, as a stack of chips.
    private func operatorBadges(_ lines: [TrainLine]) -> some View {
        HStack(spacing: 3) {
            ForEach(lines.prefix(3)) { line in
                RoundedRectangle(cornerRadius: 3)
                    .fill(line.color)
                    .frame(width: 5, height: 30)
            }
        }
        .frame(width: 30, alignment: .leading)
    }

    private func lineRow(_ line: TrainLine) -> some View {
        selectionRow(.line(line.id)) {
            HStack(spacing: 10) {
                LineLeadingBadge(line: line, dimension: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.localizedName)
                        .font(.system(size: 16, weight: .semibold))
                    Text(OperatorSections.title(for: line.operatorId))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func stationRow(_ hit: StationSearchHit) -> some View {
        selectionRow(.station(lineId: hit.line.id, stationId: hit.station.id)) {
            StationSearchRow(hit: hit)
        }
    }

    private func selectionRow(
        _ destination: SearchDestination,
        @ViewBuilder label: () -> some View
    ) -> some View {
        Button {
            onSelect(destination)
            dismiss()
        } label: {
            HStack {
                label()
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .contentShape(Rectangle())
        }
        .foregroundColor(.primary)
    }

    private func hintRow(_ text: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
            Text(text)
        }
        .foregroundColor(.secondary)
    }
}
