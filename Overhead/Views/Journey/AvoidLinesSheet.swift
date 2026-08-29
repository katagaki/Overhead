import SwiftUI
import Backbone

/// Sheet for the 路線を避ける customization: tick the lines the route search must not use.
/// Browsing, searching and the row plates follow `SearchSheet`, minus stations.
struct AvoidLinesSheet: View {
    let lines: [TrainLine]
    @Binding var avoidedLineIds: Set<String>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var scope: Scope = .operators
    @FocusState private var searchFocused: Bool

    /// The sheet has no stations, so 検索's four scopes collapse to two.
    private enum Scope: String, CaseIterable, Identifiable {
        case operators
        case lines

        var id: String { rawValue }

        var title: String {
            switch self {
            case .operators: return String(localized: "Search.Scope.Operators")
            case .lines: return String(localized: "Search.Scope.Lines")
            }
        }
    }

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var matchedLines: [TrainLine] {
        CatalogSearch.lines(in: lines, query: query)
    }

    private var matchedOperators: [OperatorSearchHit] {
        CatalogSearch.operators(in: lines, query: query)
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
            .navigationTitle("Setup.AvoidLines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Setup.AvoidLines.Clear") {
                        avoidedLineIds = []
                    }
                    .disabled(avoidedLineIds.isEmpty)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Scope

    private var scopePicker: some View {
        Picker("Setup.AvoidLines", selection: $scope) {
            ForEach(Scope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        // Rows scroll under the inset; without the glass they read through it.
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    // MARK: - Content

    @ViewBuilder
    private var browseContent: some View {
        switch scope {
        case .operators:
            Section("Search.Section.Operators") {
                ForEach(matchedOperators) { hit in
                    operatorRow(hit)
                }
            }
        case .lines:
            ForEach(OperatorSections.sections(for: lines), id: \.operatorId) { section in
                Section {
                    ForEach(section.lines) { line in
                        lineRow(line, showsOperator: false)
                    }
                } header: {
                    sectionHeader(title: section.title, lines: section.lines)
                }
            }
        }
    }

    @ViewBuilder
    private var resultsContent: some View {
        switch scope {
        case .operators:
            let hits = matchedOperators
            if hits.isEmpty {
                hintRow("Search.NoResults")
            } else {
                Section("Search.Section.Operators") {
                    ForEach(hits) { hit in
                        operatorRow(hit)
                    }
                }
            }
        case .lines:
            let matched = matchedLines
            if matched.isEmpty {
                hintRow("Search.NoResults")
            } else {
                Section("Search.Section.Lines") {
                    ForEach(matched) { line in
                        lineRow(line, showsOperator: true)
                    }
                }
            }
        }
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

    // MARK: - Rows

    @ViewBuilder
    private func sectionHeader(title: String, lines: [TrainLine]) -> some View {
        let ids = Set(lines.map(\.id))
        let allAvoided = ids.isSubset(of: avoidedLineIds)

        HStack {
            Text(title)

            Spacer()

            Button(allAvoided ? "Setup.AvoidLines.Clear" : "Setup.AvoidLines.SelectAll") {
                if allAvoided {
                    avoidedLineIds.subtract(ids)
                } else {
                    avoidedLineIds.formUnion(ids)
                }
            }
            .font(.system(size: 13))
            .buttonStyle(.borderless)
            .textCase(nil)
        }
    }

    /// Whole-operator toggle: ticking it avoids every line the operator runs.
    private func operatorRow(_ hit: OperatorSearchHit) -> some View {
        let ids = Set(hit.lines.map(\.id))
        let avoidedCount = ids.intersection(avoidedLineIds).count

        return Button {
            if avoidedCount == ids.count {
                avoidedLineIds.subtract(ids)
            } else {
                avoidedLineIds.formUnion(ids)
            }
        } label: {
            HStack(spacing: 10) {
                OperatorIcon(
                    operatorId: hit.operatorId,
                    fallbackColor: OperatorSections.brandColor(for: hit.operatorId, lines: hit.lines)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(hit.title)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Search.LineCount \(hit.lines.count)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: selectionSymbol(avoided: avoidedCount, total: ids.count))
                    .foregroundColor(avoidedCount == 0 ? Color(.tertiaryLabel) : .accentColor)
            }
            .contentShape(Rectangle())
        }
        .foregroundColor(.primary)
    }

    private func selectionSymbol(avoided: Int, total: Int) -> String {
        if avoided == 0 { return "circle" }
        return avoided == total ? "checkmark.circle.fill" : "minus.circle.fill"
    }

    private func lineRow(_ line: TrainLine, showsOperator: Bool) -> some View {
        let avoided = avoidedLineIds.contains(line.id)

        return Button {
            if avoided {
                avoidedLineIds.remove(line.id)
            } else {
                avoidedLineIds.insert(line.id)
            }
        } label: {
            HStack(spacing: 10) {
                LineLeadingBadge(line: line, dimension: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(line.localizedName)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                    if showsOperator {
                        Text(OperatorSections.title(for: line.operatorId))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: avoided ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(avoided ? .accentColor : Color(.tertiaryLabel))
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
