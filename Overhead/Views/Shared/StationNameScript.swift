import SwiftUI

// MARK: - Kanji ↔ Katakana Splitting

/// Splits a station name into two parts only when it's a clean kanji/katakana
/// pair whose katakana half is a real word (> 3 chars): 高輪ゲートウェイ →
/// ["高輪", "ゲートウェイ"], トリニティ学門前 → ["トリニティ", "学門前"].
/// Anything else — single-script names, three-part names, or a lone connector
/// kana like the ノ in 新御茶ノ水 — returns `[name]` unsplit.
enum StationNameScript {
    private enum Kind { case kanji, katakana }

    private static func kind(of scalar: Unicode.Scalar) -> Kind? {
        switch scalar.value {
        case 0x4E00...0x9FFF, 0x3400...0x4DBF, 0xF900...0xFAFF, 0x3005:
            return .kanji
        case 0x30A0...0x30FF, 0x31F0...0x31FF, 0xFF66...0xFF9D:
            return .katakana
        default:
            return nil
        }
    }

    private static func kind(of character: Character) -> Kind? {
        for scalar in character.unicodeScalars where kind(of: scalar) != nil {
            return kind(of: scalar)
        }
        return nil
    }

    static func segments(of name: String) -> [String] {
        var segments: [String] = []
        var kinds: [Kind?] = []
        var current = ""
        var currentKind: Kind?
        for character in name {
            let k = kind(of: character)
            if let k, let cur = currentKind, k != cur {
                segments.append(current)
                kinds.append(cur)
                current = String(character)
                currentKind = k
            } else {
                current.append(character)
                if currentKind == nil { currentKind = k }
            }
        }
        if !current.isEmpty {
            segments.append(current)
            kinds.append(currentKind)
        }
        guard segments.count == 2,
              let katakana = zip(segments, kinds).first(where: { $0.1 == .katakana })?.0,
              katakana.count > 3 else {
            return [name]
        }
        return segments
    }
}

extension String {
    /// The name split at kanji/katakana boundaries (see `StationNameScript`).
    var scriptSegments: [String] { StationNameScript.segments(of: self) }
}

// MARK: - Horizontal: squash to fit one line (no wrap)

/// Compresses its content horizontally (preserving height) so a long name
/// stays on one line at full glyph height rather than shrinking or wrapping —
/// the real Yamanote/Metro in-car look.
///
/// With `maxWidth == nil` it fills the width its parent gives it (use inside a
/// `.frame(maxWidth: .infinity)` slot). With an explicit `maxWidth` it stays
/// its natural width until that limit, then squashes — for names sitting in a
/// content-sized, centered header next to a badge.
struct HorizontallySquashed<Content: View>: View {
    var maxWidth: CGFloat?
    @ViewBuilder var content: () -> Content
    @State private var naturalSize: CGSize = .zero

    init(maxWidth: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.maxWidth = maxWidth
        self.content = content
    }

    var body: some View {
        core
            .background(
                content()
                    .fixedSize()
                    .hidden()
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: SquashedSizeKey.self, value: proxy.size)
                    })
            )
            .onPreferenceChange(SquashedSizeKey.self) { naturalSize = $0 }
    }

    @ViewBuilder private var core: some View {
        if let maxWidth {
            let scale = naturalSize.width > maxWidth && naturalSize.width > 0
                ? maxWidth / naturalSize.width : 1
            let footprint = naturalSize.width == 0 ? maxWidth : min(naturalSize.width, maxWidth)
            content()
                .fixedSize()
                .scaleEffect(x: scale, y: 1, anchor: .center)
                .frame(width: footprint, height: naturalSize.height == 0 ? nil : naturalSize.height)
        } else {
            GeometryReader { geo in
                let scale = naturalSize.width > geo.size.width && naturalSize.width > 0
                    ? geo.size.width / naturalSize.width : 1
                content()
                    .fixedSize()
                    .scaleEffect(x: scale, y: 1, anchor: .center)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            }
            .frame(height: naturalSize.height)
        }
    }
}

/// Characters spread across the available width; when their packed width
/// exceeds it, the row squashes horizontally to fit (the E235 name box).
struct SpreadSquashName: View {
    let chars: [Character]
    let size: CGFloat
    var weight: Font.Weight = .heavy
    var color: Color = .black
    @State private var packedWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let scale = packedWidth > geo.size.width && packedWidth > 0
                ? geo.size.width / packedWidth : 1
            row(spread: true)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                .scaleEffect(x: scale, y: 1, anchor: .center)
        }
        .frame(height: size * 1.3)
        .background(
            row(spread: false)
                .fixedSize()
                .hidden()
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: SquashedSizeKey.self, value: proxy.size)
                })
        )
        .onPreferenceChange(SquashedSizeKey.self) { packedWidth = $0.width }
    }

    private func row(spread: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(chars.indices, id: \.self) { i in
                if spread && i > 0 { Spacer(minLength: 0) }
                Text(String(chars[i]))
                    .font(.system(size: size, weight: weight))
                    .foregroundColor(color)
                    .fixedSize()
            }
        }
    }
}

private struct SquashedSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        value = CGSize(width: max(value.width, next.width),
                       height: max(value.height, next.height))
    }
}

// MARK: - Vertical: parallel columns, shorter part spaced out

/// A vertically-set station name. Mixed-script names split into parallel
/// columns (高輪 | ゲートウェイ); the shorter column is spaced out to span the
/// taller one's height, and the whole name squashes to fit `availableHeight`.
struct VerticalStationName: View {
    let name: String
    let fontSize: CGFloat
    var weight: Font.Weight = .bold
    let charBox: CGFloat
    let availableHeight: CGFloat
    var color: Color = .primary
    /// `.top` for Metro/Millennium, `.bottom` for the Joban family.
    var columnAnchor: VerticalAlignment = .top
    /// Distribute a single column's characters across the full area (Metro
    /// justifies first/last chars; the Joban family packs them).
    var justifiedSingle: Bool = false
    var columnSpacing: CGFloat = 1

    var body: some View {
        let segments = name.scriptSegments
        let maxCount = segments.map(\.count).max() ?? 1
        let natural = charBox * CGFloat(max(maxCount, 1))
        let justify = justifiedSingle || segments.count > 1
        // Justified single names fill the whole area; split names size to the
        // tallest column so both columns share a height.
        let target = (justifiedSingle && segments.count == 1)
            ? max(availableHeight, natural) : natural
        let scaleY = min(1, availableHeight / natural)
        let anchor: UnitPoint = columnAnchor == .bottom ? .bottom : .top
        let frameAlign: Alignment = columnAnchor == .bottom ? .bottom : .top
        // Japanese vertical writing reads columns right-to-left, so the first
        // part sits in the rightmost column.
        let columns = Array(segments.reversed())

        HStack(alignment: columnAnchor, spacing: columnSpacing) {
            ForEach(columns.indices, id: \.self) { i in
                let chars = Array(columns[i])
                VStack(spacing: 0) {
                    ForEach(chars.indices, id: \.self) { j in
                        if justify && j > 0 { Spacer(minLength: 0) }
                        Text(String(chars[j]))
                            .font(.system(size: fontSize, weight: weight))
                            .frame(height: charBox)
                    }
                }
                .frame(height: target, alignment: frameAlign)
            }
        }
        .scaleEffect(x: 1, y: scaleY, anchor: anchor)
        .foregroundColor(color)
    }
}
