import SwiftUI

/// Per-line badge assignment, from StaticData/Lines/<Folder>/Badge.json
struct LineBadgeConfig: Decodable {
    var symbol: String
    var style: String
    /// Per-line overrides for the style's named colour slots, e.g.
    /// {"letter": "#595757"}. Values are a hex literal or "lineColor".
    var colors: [String: String]?
    var stationStyleOverrides: [String: String]?

    /// Style to draw a station plate with, given that station's code prefix.
    func stationStyle(forPrefix prefix: String) -> String {
        stationStyleOverrides?[prefix] ?? style
    }
}

// MARK: - Badge style specification, loaded from StaticData/BadgeStyles/<style>.json

/// A colour reference inside a style file:
///   "$name"      a named slot, defaulted in the style's `colors` block and
///                overridable per line via Badge.json
///   "lineColor"  the line's own colour
///   "#RRGGBB"    a literal
enum ColorToken {
    static func literal(_ raw: String, line: Color) -> Color {
        raw == "lineColor" ? line : Color(hex: raw)
    }

    /// Style defaults, with the line's overrides applied on top.
    static func palette(_ spec: BadgeStyleSpec, overrides: [String: String]?,
                        line: Color) -> [String: Color] {
        var out: [String: Color] = [:]
        for (slot, value) in spec.colors ?? [:] { out[slot] = literal(value, line: line) }
        for (slot, value) in overrides ?? [:] { out[slot] = literal(value, line: line) }
        return out
    }

    static func resolve(_ raw: String?, line: Color, palette: [String: Color]) -> Color? {
        guard let raw else { return nil }
        if raw.hasPrefix("$") { return palette[String(raw.dropFirst())] }
        return literal(raw, line: line)
    }
}

struct BadgeLayer: Decodable {
    var shape: String                 // rect | roundedRect | circle | hexagon | sakura | seasideWave | serifI | minatomiraiWave
    var radius: CGFloat?              // absolute pt
    var radiusRatio: CGFloat?         // × badge side
    var continuous: Bool?
    var fill: String?
    var stroke: String?
    var lineWidth: CGFloat?
    var lineWidthRatio: CGFloat?
    var inset: CGFloat?
    var insetRatio: CGFloat?
    var clipCircle: Bool?
    var heightRatio: CGFloat?
    var offsetYRatio: CGFloat?
    var alignTop: Bool?
}

struct RuleSpec: Decodable {
    var color: String
    var widthRatio: CGFloat?
    var width: CGFloat?
    var heightRatio: CGFloat?
    var height: CGFloat?
}

/// The single-symbol plate (line badge). Sizes are in points at a 32pt
/// reference and scaled by `f = dimension / 32`, matching the current views.
struct LineFace: Decodable {
    var layers: [BadgeLayer]?
    var overlays: [BadgeLayer]?
    var literal: String?
    var family: String?
    var size: CGFloat?
    var sizeMulti: CGFloat?           // used when the symbol is >1 character
    var weight: String?
    var width: String?
    var color: String?
    var insetH: CGFloat?
    var nudgeBase: CGFloat?
    var nudgeBaseMulti: CGFloat?
    var offsetY: CGFloat?
    var kerning: Bool?
    var minimumScaleFactor: CGFloat?
    /// Per-symbol size overrides, for symbols too wide for the plate's aperture.
    var glyphSize: [String: CGFloat]?
    var glyphOffsetX: [String: CGFloat]?
    var glyphOffsetY: [String: CGFloat]?
    var rule: RuleSpec?
    var stackSpacing: CGFloat?
    // A drawn glyph instead of text (三田線's barred I).
    var glyphShape: String?
    var glyphFill: String?
    var glyphWidth: CGFloat?
    var glyphHeight: CGFloat?
    /// Escape hatch for plates that are bespoke vector art (西武's train logo).
    var renderer: String?
}

struct StationRow: Decodable {
    var kind: String                  // prefix | number | rule
    var family: String?
    var sizeRatio: CGFloat?
    var weight: String?
    var width: String?
    var bold: Bool?
    var color: String?
    var background: String?
    var heightRatio: CGFloat?
    var maxHeightRatio: CGFloat?
    var expandHeight: Bool?
    var offsetYRatio: CGFloat?
    var offsetY: CGFloat?
    var widthRatio: CGFloat?
    var fullWidth: Bool?
    var kerningRatio: CGFloat?
    var stripLeadingZeros: Bool?
    var glyphShape: String?
    var glyphFill: String?
    var glyphWidthRatio: CGFloat?
    var glyphHeightRatio: CGFloat?
    var rule: RuleSpec?
}

/// The prefix-over-number plate (station badge). Sizes are ratios of the badge
/// side, which is 32pt compact / 28pt regular.
struct StationFace: Decodable {
    var layers: [BadgeLayer]?
    var overlays: [BadgeLayer]?
    var clip: BadgeLayer?
    var spacing: CGFloat?
    var spacingRatio: CGFloat?
    var color: String?
    var minimumScaleFactor: CGFloat?
    /// Per-prefix size overrides (ratio of the badge side) for code
    /// prefixes too wide for the plate's aperture.
    var prefixSizes: [String: CGFloat]?
    var rows: [StationRow]?
    var solo: StationRow?
    var renderer: String?
}

struct BadgeStyleSpec: Decodable {
    var id: String
    var nameJa: String?
    var nameEn: String?
    /// Named colour slots and their defaults. Referenced from any colour field
    /// as "$slot", and overridable per line in Badge.json.
    var colors: [String: String]?
    var line: LineFace
    var station: StationFace?
}

// MARK: - Registry

final class BadgeStyleRegistry {
    private(set) var styles: [String: BadgeStyleSpec] = [:]

    init(directory: String) {
        let fm = FileManager.default
        for file in ((try? fm.contentsOfDirectory(atPath: directory)) ?? []).sorted()
        where file.hasSuffix(".json") {
            let url = URL(fileURLWithPath: "\(directory)/\(file)")
            do {
                let spec = try JSONDecoder().decode(BadgeStyleSpec.self, from: Data(contentsOf: url))
                styles[spec.id] = spec
            } catch {
                FileHandle.standardError.write("BadgeStyles: \(file) failed to decode: \(error)\n"
                    .data(using: .utf8)!)
            }
        }
    }

    /// Unknown styles fall back to the ringed circle, so data naming a style an
    /// older build doesn't have still renders something sane.
    func spec(_ id: String) -> BadgeStyleSpec? { styles[id] ?? styles["metro"] }
}

// MARK: - Shared helpers

extension View {
    @ViewBuilder
    func applyFontWidth(_ width: String?) -> some View {
        switch width {
        case "condensed": self.fontWidth(.condensed)
        case "expanded":  self.fontWidth(.expanded)
        case "standard":  self.fontWidth(.standard)
        default:          self
        }
    }
}

func swiftUIWeight(_ name: String?) -> Font.Weight? {
    switch name {
    case "black": return .black
    case "bold": return .bold
    case "semibold": return .semibold
    case "medium": return .medium
    case "regular": return .regular
    case "light": return .light
    default: return nil
    }
}

/// One badge layer's outline. Insettable so `strokeBorder` behaves exactly as
/// it does on the SwiftUI primitives these styles were transcribed from.
struct BadgePath: Shape, InsettableShape {
    var shape: String
    var radius: CGFloat = 0
    var continuous: Bool = false
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        switch shape {
        case "circle":          return Circle().path(in: r)
        case "rect":            return Rectangle().path(in: r)
        case "hexagon":         return FlatTopHexagon().path(in: r)
        case "sakura":          return SakuraBlossom().path(in: r)
        case "seasideWave":     return SeasideWave().path(in: r)
        case "serifI":          return SerifI().path(in: r)
        case "minatomiraiWave": return MinatomiraiWave().path(in: r)
        default:
            return RoundedRectangle(cornerRadius: max(0, radius - insetAmount),
                                    style: continuous ? .continuous : .circular).path(in: r)
        }
    }

    func inset(by amount: CGFloat) -> BadgePath {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

func badgeShape(_ layer: BadgeLayer, side: CGFloat) -> BadgePath {
    BadgePath(shape: layer.shape,
              radius: layer.radius ?? (layer.radiusRatio.map { $0 * side } ?? 0),
              continuous: layer.continuous ?? false)
}
