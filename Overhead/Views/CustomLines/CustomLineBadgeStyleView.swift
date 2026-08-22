import SwiftUI
import Backbone

// MARK: - Badge Style Picker

/// Every operator plate the app can draw, previewed with this line's own
/// symbol and colour.
struct CustomLineBadgeStyleView: View {
    @Binding var line: CustomLine

    private let columns = [GridItem(.adaptive(minimum: 112), spacing: 12)]

    private var symbol: String { line.symbol.isEmpty ? "＋" : line.symbol }
    private var code: String { line.stationCode(at: 0) }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12, pinnedViews: .sectionHeaders) {
                ForEach(BadgeStyles.grouped, id: \.category) { group in
                    Section {
                        ForEach(group.styles, id: \.id) { spec in
                            styleCell(spec)
                        }
                    } header: {
                        sectionHeader(group.category)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("CustomLine.Badge.Style")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionHeader(_ category: BadgeStyleCategory) -> some View {
        Text(LocalizedStringKey(category.titleKey))
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
    }

    private func squashedLine(_ text: String, isSelected: Bool) -> some View {
        HorizontallySquashed {
            Text(text)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        }
    }

    /// "JR東日本（駅ナンバリングなし）" -> the name, then the bracket on its own line.
    private static func split(_ name: String) -> (head: String, bracketed: String?) {
        guard let open = name.firstIndex(where: { $0 == "（" || $0 == "(" }),
              let last = name.last, last == "）" || last == ")"
        else { return (name, nil) }
        let head = name[name.startIndex..<open].trimmingCharacters(in: .whitespaces)
        return (head.isEmpty ? name : head, String(name[open...]))
    }

    @ViewBuilder
    private func styleCell(_ spec: BadgeStyleSpec) -> some View {
        let isSelected = line.styleId == spec.id

        Button {
            line.setStyleId(spec.id)
        } label: {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    LineSymbolBadge(symbol: symbol, color: line.color,
                                    dimension: 34, styleOverride: spec.id)
                    StationNumberBadge(code: code, color: line.color,
                                       size: .compact, styleOverride: spec.id)
                }
                .frame(height: 36)

                let name = Self.split(BadgeStyles.displayName(spec.id))
                VStack(spacing: 1) {
                    squashedLine(name.head, isSelected: isSelected)
                    // Always drawn, so a bracketless name reserves the same height.
                    squashedLine(name.bracketed ?? " ", isSelected: isSelected)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(BadgeStyles.displayName(spec.id))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
