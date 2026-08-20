import Foundation
import SwiftUI

/// From StaticData/Lines/<Folder>/Badge.json.
public struct LineBadgeConfig: Decodable {
    public var symbol: String
    public var style: String
    /// Overrides for the style's colour slots, e.g. {"letter": "#595757"}.
    public var colors: [String: String]?
    public var stationStyleOverrides: [String: String]?

    public func stationStyle(forPrefix prefix: String) -> String {
        stationStyleOverrides?[prefix] ?? style
    }
}

// MARK: - Style specification, from StaticData/BadgeStyles/<style>.json

/// `$name` a slot from the style's `colors` block, `lineColor` the line's own
/// colour, `#RRGGBB` a literal.
public enum ColorToken {
    static func literal(_ raw: String, line: Color) -> Color {
        raw == "lineColor" ? line : Color(hex: raw)
    }

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

public struct BadgeLayer: Decodable {
    var shape: String   // rect | roundedRect | circle | hexagon | sakura | seasideWave | serifI | minatomiraiWave
    var radius: CGFloat?        // absolute pt
    var radiusRatio: CGFloat?   // × badge side
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

public struct RuleSpec: Decodable {
    var color: String
    var widthRatio: CGFloat?
    var width: CGFloat?
    var heightRatio: CGFloat?
    var height: CGFloat?
}

/// The single-symbol plate. Sizes are points at a 32pt reference, scaled by
/// `f = dimension / 32`.
public struct LineFace: Decodable {
    var layers: [BadgeLayer]?
    var overlays: [BadgeLayer]?
    var literal: String?
    var family: String?
    var size: CGFloat?
    var sizeMulti: CGFloat?   // when the symbol is >1 character
    var weight: String?
    var width: String?
    var color: String?
    var insetH: CGFloat?
    var nudgeBase: CGFloat?
    var nudgeBaseMulti: CGFloat?
    var offsetY: CGFloat?
    var kerning: Bool?
    var minimumScaleFactor: CGFloat?
    /// For symbols too wide for the plate's aperture.
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
    /// Bespoke vector art (西武's train logo).
    var renderer: String?
}

public struct StationRow: Decodable {
    var kind: String   // prefix | number | rule
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

/// The prefix-over-number plate. Sizes are ratios of the badge side.
public struct StationFace: Decodable {
    var layers: [BadgeLayer]?
    var overlays: [BadgeLayer]?
    var clip: BadgeLayer?
    var spacing: CGFloat?
    var spacingRatio: CGFloat?
    var color: String?
    var minimumScaleFactor: CGFloat?
    /// For prefixes too wide for the plate's aperture.
    var prefixSizes: [String: CGFloat]?
    var rows: [StationRow]?
    var solo: StationRow?
    var renderer: String?
}

public struct BadgeStyleSpec: Decodable {
    public var id: String
    public var nameJa: String?
    public var nameEn: String?
    /// Named colour slots and their defaults. Referenced from any colour field
    /// as "$slot", and overridable per line in Badge.json.
    var colors: [String: String]?
    var line: LineFace
    var station: StationFace?
}
