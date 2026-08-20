import SwiftUI
import Backbone

// MARK: - Line Symbol Badge

struct LineSymbolBadge: View {
    let symbol: String
    let color: Color
    var dimension: CGFloat = 32
    /// Style id, set by user-created lines whose symbols match no operator.
    var styleOverride: String? = nil
    /// Skips symbol resolution and picks up per-line colour overrides.
    var lineId: String? = nil

    var body: some View {
        let resolved = BadgeResolution(symbol: symbol, color: color,
                                       styleOverride: styleOverride, lineId: lineId)
        if let spec = BadgeStyles.spec(resolved.styleId) {
            LineBadge(symbol: symbol, color: color, dimension: dimension,
                      spec: spec, overrides: resolved.overrides)
        }
    }
}

// MARK: - Style resolution

/// Picks a style: an explicit override, then the line's Badge.json entry,
/// then the symbol index. Anything unresolved falls back to the JR plate.
struct BadgeResolution {
    let styleId: String
    let overrides: [String: String]?

    init(symbol: String, color: Color, styleOverride: String?, lineId: String?) {
        if let styleOverride {
            styleId = styleOverride
            overrides = nil
        } else if let lineId, let config = BadgeStyles.config(lineId: lineId) {
            styleId = config.style
            overrides = config.colors
        } else {
            styleId = BadgeStyles.styleId(symbol: symbol, colorHex: color.hexString)
            overrides = nil
        }
    }

    /// Station plates dispatch on the station's own code prefix, so a stop
    /// carrying another operator's code keeps that operator's plate.
    init(code: String, color: Color, styleOverride: String?, lineId: String?) {
        let prefix = String(code.prefix(while: \.isLetter))
        if let styleOverride {
            styleId = styleOverride
            overrides = nil
        } else if let lineId, let config = BadgeStyles.config(lineId: lineId) {
            styleId = config.stationStyle(forPrefix: prefix)
            overrides = config.colors
        } else {
            styleId = BadgeStyles.styleId(symbol: prefix, colorHex: color.hexString)
            overrides = nil
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let badges: [(symbol: String, color: Color)] = [
        ("JY", Color(hex: "#9ACD32")), ("M", Color(hex: "#E60012")),
        ("NT", Color(hex: "#CD7DAD")), ("KS", Color(hex: "#1155CC")),
        ("TS", Color(hex: "#00559F")), ("SI", Color(hex: "#F5A200")),
        ("TY", Color(hex: "#DA0442")), ("OH", Color(hex: "#0086D1")),
        ("MM", Color(hex: "#004098")), ("KK", Color(hex: "#00BFFF")),
        ("KO", Color(hex: "#DD0077")), ("SO", Color(hex: "#35519D")),
        ("R", Color(hex: "#222D65")), ("TT", Color(hex: "#F08300")),
        ("B", Color(hex: "#3577BC")), ("G", Color(hex: "#40CC40")),
    ]

    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
        ForEach(badges, id: \.symbol) { badge in
            VStack(spacing: 4) {
                LineSymbolBadge(symbol: badge.symbol, color: badge.color)
                Text(badge.symbol).font(.system(size: 9)).foregroundColor(.secondary)
            }
        }
    }
    .padding()
    .frame(width: 260)
}
