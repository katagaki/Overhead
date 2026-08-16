import SwiftUI
import Backbone

// MARK: - Line Grid

/// 2-up grid of line cells, as the home catalog used to draw them.
struct LineGrid: View {
    let lines: [TrainLine]
    let onSelect: (TrainLine) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(stride(from: 0, to: lines.count, by: 2)), id: \.self) { start in
                HStack(alignment: .top, spacing: 10) {
                    cellButton(lines[start])
                    if start + 1 < lines.count {
                        cellButton(lines[start + 1])
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func cellButton(_ line: TrainLine) -> some View {
        Button {
            onSelect(line)
        } label: {
            LineGridCell(line: line)
        }
        .buttonStyle(.plain)
    }
}

struct LineGridCell: View {
    let line: TrainLine

    var body: some View {
        HStack(spacing: 10) {
            LineLeadingBadge(line: line, dimension: 38)

            HorizontallyFittedText(
                text: line.localizedName,
                font: .system(size: 12, weight: .semibold),
                alignment: .leading
            )
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .contentShape(Rectangle())
    }
}

/// The line's plate, or its colour as a stripe when the line has no numbering.
struct LineLeadingBadge: View {
    let line: TrainLine
    var dimension: CGFloat = 38

    @ViewBuilder var body: some View {
        if !line.lineSymbol.isEmpty {
            LineSymbolBadge(
                symbol: line.lineSymbol,
                color: line.color,
                dimension: dimension,
                styleOverride: line.badgeStyle
            )
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(line.color)
                .frame(width: 7, height: dimension * 0.74)
                .frame(width: dimension, height: dimension)
        }
    }
}
