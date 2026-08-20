import SwiftUI
import Backbone

// MARK: - Station Number Badge

struct StationNumberBadge: View {
    let code: String
    let color: Color
    var opacity: Double = 1.0
    var size: BadgeSize = .regular
    var stationName: String? = nil
    /// Style id, set by user-created lines whose codes match no operator.
    var styleOverride: String? = nil
    /// Set when the caller knows which line this is.
    var lineId: String? = nil

    enum BadgeSize {
        case compact  // For list rows
        case regular  // For journey view station labels

        var side: CGFloat {
            switch self {
            case .compact: return 32
            case .regular: return 28
            }
        }
    }

    var body: some View {
        let resolved = BadgeResolution(code: code, color: color,
                                       styleOverride: styleOverride, lineId: lineId)
        if let spec = BadgeStyles.spec(resolved.styleId) {
            StationBadge(code: code, color: color, opacity: opacity, side: size.side,
                         spec: spec, overrides: resolved.overrides)
        }
    }

    /// An outline at the wrong radius reads as a second, mismatched badge.
    static func cornerRadiusRatio(code: String, color: Color,
                                  styleOverride: String? = nil,
                                  lineId: String? = nil,
                                  size: BadgeSize = .regular) -> CGFloat {
        let resolved = BadgeResolution(code: code, color: color,
                                       styleOverride: styleOverride, lineId: lineId)
        return BadgeStyles.stationOutline(styleId: resolved.styleId, side: size.side)
            .cornerRadiusRatio
    }

    static func rendersAsCircle(code: String, color: Color,
                                styleOverride: String? = nil,
                                lineId: String? = nil,
                                size: BadgeSize = .regular) -> Bool {
        let resolved = BadgeResolution(code: code, color: color,
                                       styleOverride: styleOverride, lineId: lineId)
        return BadgeStyles.stationOutline(styleId: resolved.styleId, side: size.side).isCircle
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let badges: [(code: String, color: Color, station: String)] = [
        ("Z02", Color(hex: "#8F76D6"), "表参道"),
        ("JL19", Color(hex: "#00BB85"), "綾瀬"),
        ("TS01", Color(hex: "#00559F"), "浅草"),
        ("SI01", Color(hex: "#F5A200"), "池袋"),
        ("MG01", Color(hex: "#009CD2"), "目黒"),
        ("MM04", Color(hex: "#004098"), "みなとみらい"),
        ("KK01", Color(hex: "#00BFFF"), "泉岳寺"),
        ("KO01", Color(hex: "#DD0077"), "新宿"),
        ("SO01", Color(hex: "#35519D"), "横浜"),
        ("OH05", Color(hex: "#0086D1"), "代々木上原"),
        ("KS55", Color(hex: "#1155CC"), "千葉中央"),
        ("NT01", Color(hex: "#CD7DAD"), "日暮里"),
        ("R04", Color(hex: "#222D65"), "東京テレポート"),
        ("TT12", Color(hex: "#F08300"), "立川北"),
        ("B25", Color(hex: "#3577BC"), "新横浜"),
        ("G05", Color(hex: "#4BA672"), "センター北"),
    ]

    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
        ForEach(badges, id: \.code) { badge in
            VStack(spacing: 4) {
                StationNumberBadge(code: badge.code, color: badge.color,
                                   opacity: 1.0, size: .regular, stationName: badge.station)
                Text(badge.station).font(.system(size: 9)).foregroundColor(.secondary)
            }
        }
    }
    .padding()
    .frame(width: 300)
}
