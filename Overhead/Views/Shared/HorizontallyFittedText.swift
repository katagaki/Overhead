import SwiftUI

// MARK: - Horizontally Fitted Text

/// A single-line label that squashes glyphs horizontally (preserving cap
/// height) when the text is wider than its container.
struct HorizontallyFittedText: View {
    let text: String
    let font: Font
    var alignment: Alignment = .center

    @State private var naturalWidth: CGFloat = 0

    /// Squash toward the aligned edge so compressed text stays pinned to it.
    private var scaleAnchor: UnitPoint {
        if alignment.horizontal == .leading { return .leading }
        if alignment.horizontal == .trailing { return .trailing }
        return .center
    }

    var body: some View {
        // Hidden copy reserves the intrinsic height.
        Text(text)
            .font(font)
            .lineLimit(1)
            .hidden()
            .overlay {
                GeometryReader { geo in
                    let scale = naturalWidth > geo.size.width && naturalWidth > 0
                        ? geo.size.width / naturalWidth
                        : 1
                    Text(text)
                        .font(font)
                        .lineLimit(1)
                        .fixedSize()
                        .scaleEffect(x: scale, y: 1, anchor: scaleAnchor)
                        .frame(width: geo.size.width, height: geo.size.height,
                               alignment: alignment)
                }
            }
            .background {
                // Off-screen copy measures the natural width.
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .fixedSize()
                    .hidden()
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: FittedTextWidthKey.self,
                                               value: proxy.size.width)
                    })
            }
            .onPreferenceChange(FittedTextWidthKey.self) { naturalWidth = $0 }
    }
}

private struct FittedTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
