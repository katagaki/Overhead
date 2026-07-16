import SwiftUI
import Backbone

/// Sheet for the 路線を避ける customization: tick the lines the route search must not use.
struct AvoidLinesSheet: View {
    let lines: [TrainLine]
    @Binding var avoidedLineIds: Set<String>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredLines: [TrainLine] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return lines }
        let lowered = query.lowercased()
        return lines.filter {
            $0.name.contains(query)
                || $0.localizedName.lowercased().contains(lowered)
                || $0.nameEn.lowercased().contains(lowered)
                || $0.lineSymbol.lowercased() == lowered
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(OperatorSections.sections(for: filteredLines), id: \.operatorId) { section in
                    Section {
                        ForEach(section.lines) { line in
                            lineRow(line)
                        }
                    } header: {
                        sectionHeader(title: section.title, lines: section.lines)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
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
                    if #available(iOS 26.0, *) {
                        Button(role: .close) {
                            dismiss()
                        }
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .tint(.secondary)
                        .accessibilityLabel("Button.Close")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

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

    @ViewBuilder
    private func lineRow(_ line: TrainLine) -> some View {
        Button {
            if avoidedLineIds.contains(line.id) {
                avoidedLineIds.remove(line.id)
            } else {
                avoidedLineIds.insert(line.id)
            }
        } label: {
            HStack(spacing: 12) {
                if !line.lineSymbol.isEmpty {
                    LineSymbolBadge(
                        symbol: line.lineSymbol,
                        color: line.color,
                        dimension: 30
                    )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(line.color)
                        .frame(width: 30, height: 30)
                }

                Text(line.localizedName)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                if avoidedLineIds.contains(line.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
    }
}
