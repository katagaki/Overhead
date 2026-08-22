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
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(BadgeStyles.all, id: \.id) { spec in
                    styleCell(spec)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("CustomLine.Badge.Style")
        .navigationBarTitleDisplayMode(.inline)
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

                Text(BadgeStyles.displayName(spec.id))
                    .font(.caption2)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
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
