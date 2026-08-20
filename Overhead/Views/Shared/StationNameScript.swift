import SwiftUI
import Backbone

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
    var alignment: Alignment
    @ViewBuilder var content: () -> Content
    @State private var naturalSize: CGSize = .zero

    init(maxWidth: CGFloat? = nil, alignment: Alignment = .center,
         @ViewBuilder content: @escaping () -> Content) {
        self.maxWidth = maxWidth
        self.alignment = alignment
        self.content = content
    }

    private var anchor: UnitPoint { alignment == .leading ? .leading : .center }

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
                .scaleEffect(x: scale, y: 1, anchor: anchor)
                .frame(width: footprint, height: naturalSize.height == 0 ? nil : naturalSize.height,
                       alignment: alignment)
        } else {
            GeometryReader { geo in
                let scale = naturalSize.width > geo.size.width && naturalSize.width > 0
                    ? geo.size.width / naturalSize.width : 1
                content()
                    .fixedSize()
                    .scaleEffect(x: scale, y: 1, anchor: anchor)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: alignment)
            }
            .frame(height: naturalSize.height)
        }
    }
}

/// Transfer-line row in the LCD stop columns: kanji/katakana pairs split
/// into two squashed lines, badge centered on the first.
struct LCDTransferLineName: View {
    let name: String
    let fontSize: CGFloat
    var symbol: String = ""
    var badgeColor: Color = .clear
    var badgeStyleId: String? = nil
    var kerning: CGFloat = 0
    var color: Color = .black

    private var rowHeight: CGFloat { fontSize + 1.5 }

    var body: some View {
        HStack(alignment: .top, spacing: 1.5) {
            if !symbol.isEmpty {
                LineSymbolBadge(symbol: symbol, color: badgeColor, dimension: 7,
                                styleOverride: badgeStyleId)
                    .frame(height: rowHeight)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(name.scriptSegments.enumerated()), id: \.offset) { _, segment in
                    HorizontallySquashed(alignment: .leading) {
                        Text(segment)
                            .font(LCDFont.gothic(size: fontSize, weight: .bold))
                            .kerning(kerning)
                            .foregroundColor(color)
                            .lineLimit(1)
                    }
                    .frame(height: rowHeight)
                }
            }
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
    /// The JR/Metro LCDs set their Japanese text in the bundled gothic.
    var gothic: Bool = false
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
                    .font(gothic ? LCDFont.gothic(size: size, weight: weight)
                                 : .system(size: size, weight: weight))
                    .foregroundColor(color)
                    .fixedSize()
            }
        }
    }
}

// MARK: - Latin headline that fills its slot

/// Romaji headline that grows to fill the space it is given and squashes
/// horizontally once the name outruns the width. The height budget is inflated
/// by `lineBoxSlack` because the Latin line box runs well past the glyphs.
struct FillingLatinName: View {
    let name: String
    let baseSize: CGFloat
    var weight: Font.Weight = .bold
    var color: Color = .white
    /// Ceiling on the grow factor, so short names stay sane.
    var maxGrowth: CGFloat = 1.3

    private static let lineBoxSlack: CGFloat = 1.32

    @State private var natural: CGSize = .zero

    private var text: some View {
        Text(name)
            .font(LCDFont.latin(size: baseSize, weight: weight))
            .foregroundColor(color)
            .lineLimit(1)
    }

    var body: some View {
        GeometryReader { geo in
            let sy = natural.height > 0
                ? min(geo.size.height * Self.lineBoxSlack / natural.height, maxGrowth)
                : 1
            let sx = natural.width > 0
                ? min(geo.size.width / natural.width, sy)
                : sy
            text
                .fixedSize()
                .scaleEffect(x: sx, y: sy, anchor: .center)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(
            text
                .fixedSize()
                .hidden()
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: SquashedSizeKey.self, value: proxy.size)
                })
        )
        .onPreferenceChange(SquashedSizeKey.self) { natural = $0 }
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
    /// The JR/Metro LCDs set their Japanese text in the bundled gothic.
    var gothic: Bool = false

    /// Glyphs that rotate 90° in vertical writing (chōonpu, wave/long dashes).
    private static let rotatedGlyphs: Set<Character> = ["ー", "ｰ", "〜", "～", "−", "－", "-"]

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
                            .font(gothic ? LCDFont.gothic(size: fontSize, weight: weight)
                                         : .system(size: fontSize, weight: weight))
                            .rotationEffect(Self.rotatedGlyphs.contains(chars[j]) ? .degrees(90) : .zero)
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
