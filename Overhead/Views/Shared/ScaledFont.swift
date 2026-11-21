import SwiftUI

extension Font.TextStyle {
    /// The text style whose default size is closest to `size`, to scale a fixed size along with.
    static func nearest(to size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<11.5: return .caption2
        case ..<12.5: return .caption
        case ..<14: return .footnote
        case ..<15.5: return .subheadline
        case ..<16.5: return .callout
        case ..<19.5: return .body
        case ..<21: return .title3
        case ..<25: return .title2
        case ..<31: return .title
        default: return .largeTitle
        }
    }
}

/// A system font that keeps `size` at the default text size and follows Dynamic Type from there.
private struct ScaledSystemFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, relativeTo style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    func scaledFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo style: Font.TextStyle? = nil
    ) -> some View {
        modifier(ScaledSystemFont(size: size, weight: weight, design: design,
                                  relativeTo: style ?? .nearest(to: size)))
    }
}

/// Lays children out in rows, wrapping to the next row when one is full.
struct FlowLayout: Layout {
    var spacing: CGFloat = 2
    var lineSpacing: CGFloat = 2
    var centersRows = false

    private func rows(_ subviews: Subviews, width: CGFloat) -> [[(index: Int, size: CGSize)]] {
        var rows: [[(index: Int, size: CGSize)]] = [[]]
        var x: CGFloat = 0
        for (index, view) in subviews.enumerated() {
            let ideal = view.sizeThatFits(.unspecified)
            let size = ideal.width > width
                ? view.sizeThatFits(ProposedViewSize(width: width, height: nil))
                : ideal
            if x > 0, x + size.width > width {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append((index, size))
            x += size.width + spacing
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = rows(subviews, width: width)
        var height: CGFloat = 0
        var widest: CGFloat = 0
        for (n, row) in rows.enumerated() {
            height += (row.map(\.size.height).max() ?? 0) + (n > 0 ? lineSpacing : 0)
            let rowWidth = row.map(\.size.width).reduce(0, +) + spacing * CGFloat(max(row.count - 1, 0))
            widest = max(widest, rowWidth)
        }
        return CGSize(width: proposal.width ?? widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(subviews, width: bounds.width) {
            let rowHeight = row.map(\.size.height).max() ?? 0
            var x = bounds.minX
            for item in row {
                let offset = centersRows ? (rowHeight - item.size.height) / 2 : 0
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + offset),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += rowHeight + lineSpacing
        }
    }
}

/// A plain row up to the default text size; above it, wraps onto more rows once the row no longer fits.
struct WrappingRow<Content: View>: View {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 4
    @ViewBuilder var content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize <= .large {
            HStack(spacing: spacing) { content }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: spacing) { content }
                FlowLayout(spacing: spacing, lineSpacing: lineSpacing, centersRows: true) { content }
            }
        }
    }
}
