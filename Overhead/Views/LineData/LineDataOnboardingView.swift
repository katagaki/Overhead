import SwiftUI
import Backbone

// MARK: - First-run line download

/// Offers the base network — JR East and the Tokyo subways — so a new install
/// is usable in one tap, with everything else a browse away.
struct LineDataOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = LineDataModel()
    @AppStorage("lineData.onboarded") private var onboarded = false

    private var baseLines: [CatalogLine] {
        Catalog.current.lines.filter { LineDataModel.baseOperators.contains($0.operatorId) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LineData.Onboarding.Title")
                            .font(.largeTitle.bold())
                        Text("LineData.Onboarding.Body")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(LineDataModel.baseOperators, id: \.self) { operatorId in
                        operatorCard(operatorId)
                    }

                    NavigationLink {
                        LineDataManagerView()
                    } label: {
                        Label("LineData.Onboarding.BrowseAll", systemImage: "list.bullet")
                    }
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) { actions }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(model.isWorking)
        .onAppear { model.selectBaseSet() }
    }

    @ViewBuilder
    private func operatorCard(_ operatorId: String) -> some View {
        let lines = model.lines(for: operatorId)
        let selected = lines.allSatisfy { model.selection.contains($0.id) }

        Button {
            model.toggleOperator(operatorId)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : .secondary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 6) {
                    Text(OperatorSections.title(for: operatorId))
                        .font(.headline)
                    Text("\(lines.count) 路線 · " +
                         LineDataModel.formatted(bytes: lines.reduce(0) { $0 + $1.bytes }))
                        .font(.caption).foregroundStyle(.secondary)
                    badgeStrip(lines)
                }
                Spacer()
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    /// One badge per distinct symbol: JR East has a dozen lines sharing the
    /// plain JR mark, and ten copies of it says nothing.
    private func distinctBadges(_ lines: [CatalogLine]) -> [CatalogLine] {
        var seen = Set<String>()
        return lines.filter { seen.insert("\($0.symbol)|\($0.colorHex)").inserted }
    }

    @ViewBuilder
    private func badgeStrip(_ lines: [CatalogLine]) -> some View {
        let shown = distinctBadges(lines)
        HStack(spacing: 4) {
            ForEach(shown.prefix(10)) { line in
                LineSymbolBadge(symbol: line.symbol, color: Color(hex: line.colorHex),
                                dimension: 22, styleOverride: line.badgeStyle)
            }
            if shown.count > 10 {
                Text("+\(shown.count - 10)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await model.install()
                    onboarded = true
                    dismiss()
                }
            } label: {
                HStack {
                    if model.isWorking { ProgressView().tint(.white) }
                    Text("LineData.Onboarding.Download")
                    if !model.selection.isEmpty {
                        Text(LineDataModel.formatted(bytes: model.selectedBytes))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.selection.isEmpty || model.isWorking)

            Button("LineData.Onboarding.Later") {
                onboarded = true
                dismiss()
            }
            .disabled(model.isWorking)
        }
        .padding()
        .background(.regularMaterial)
    }
}
