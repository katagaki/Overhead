import Foundation
import SwiftUI

/// Styles from `StaticData/BadgeStyles/<id>.json`, and each line's assignment
/// from `StaticData/Lines/<Folder>/Badge.json`.
public enum BadgeStyles {

    private static let tablesLock = NSLock()
    private static var cachedSpecs: [String: BadgeStyleSpec]?
    private static var cachedConfigs: [String: LineBadgeConfig]?
    private static var cachedIndex: (bySymbol: [String: String], bySymbolColor: [String: String])?

    /// Built outside the lock. `NSLock` is not recursive, and these tables
    /// reach through each other — the index reads the configs — so holding it
    /// across a build deadlocks the thread that is drawing a badge.
    private static var specs: [String: BadgeStyleSpec] {
        tablesLock.lock()
        if let cachedSpecs { tablesLock.unlock(); return cachedSpecs }
        tablesLock.unlock()
        let built = buildSpecs()
        tablesLock.lock(); cachedSpecs = built; tablesLock.unlock()
        return built
    }

    /// Call when the underlying data changes.
    public static func invalidate() {
        tablesLock.lock()
        cachedSpecs = nil; cachedConfigs = nil; cachedIndex = nil
        tablesLock.unlock()
    }

    private static func buildSpecs() -> [String: BadgeStyleSpec] {
        var out: [String: BadgeStyleSpec] = [:]
        for data in LineDataStore.badgeStyleData() {
            guard let spec = try? JSONDecoder().decode(BadgeStyleSpec.self, from: data)
            else { continue }
            out[spec.id] = spec
        }
        return out
    }

    private static var configs: [String: LineBadgeConfig] {
        tablesLock.lock()
        if let cachedConfigs { tablesLock.unlock(); return cachedConfigs }
        tablesLock.unlock()
        let built = buildConfigs()
        tablesLock.lock(); cachedConfigs = built; tablesLock.unlock()
        return built
    }

    private static func buildConfigs() -> [String: LineBadgeConfig] {
        var out: [String: LineBadgeConfig] = [:]
        for line in Catalog.current.lines {
            guard let data = LineDataStore.data(folder: line.folder, file: "Badge.json"),
                  let file = try? JSONDecoder().decode(BadgeFile.self, from: data)
            else { continue }
            out.merge(file.lines) { a, _ in a }
        }
        return out
    }

    private struct BadgeFile: Decodable { let lines: [String: LineBadgeConfig] }

    /// Symbol -> style, plus symbol+colour for the prefixes two operators share
    /// ("G" is Ginza and Yokohama Green; "SR" is Saitama Railway and Shibayama).
    private static var index: (bySymbol: [String: String], bySymbolColor: [String: String]) {
        tablesLock.lock()
        if let cachedIndex { tablesLock.unlock(); return cachedIndex }
        tablesLock.unlock()
        let built = buildIndex()
        tablesLock.lock(); cachedIndex = built; tablesLock.unlock()
        return built
    }

    private static func buildIndex() -> (bySymbol: [String: String], bySymbolColor: [String: String]) {
        var bySymbol: [String: String] = [:]
        var bySymbolColor: [String: String] = [:]
        var ambiguous: Set<String> = []
        for (lineId, config) in configs {
            guard !config.symbol.isEmpty else { continue }
            if let existing = bySymbol[config.symbol], existing != config.style {
                ambiguous.insert(config.symbol)
            }
            bySymbol[config.symbol] = config.style
            if let hex = Catalog.line(id: lineId)?.colorHex {
                bySymbolColor["\(config.symbol)|\(hex.uppercased())"] = config.style
            }
        }
        for symbol in ambiguous { bySymbol.removeValue(forKey: symbol) }
        return (bySymbol, bySymbolColor)
    }

    /// Anything unrecognised falls back to the JR plate.
    public static let fallbackStyleId = "jr"

    public static func spec(_ id: String) -> BadgeStyleSpec? {
        specs[id] ?? specs[fallbackStyleId]
    }

    /// Ordered by display name, for pickers.
    public static var all: [BadgeStyleSpec] {
        specs.values.sorted { ($0.nameJa ?? $0.id) < ($1.nameJa ?? $1.id) }
    }

    public static func displayName(_ id: String) -> String {
        guard let spec = specs[id] else { return id }
        let ja = Locale.current.language.languageCode?.identifier != "en"
        return (ja ? spec.nameJa : spec.nameEn) ?? spec.nameEn ?? spec.nameJa ?? spec.id
    }

    public static func config(lineId: String) -> LineBadgeConfig? { configs[lineId] }

    /// Style for a badge drawn without a line in hand, resolved from the data
    /// index rather than from the symbol's spelling.
    public static func styleId(symbol: String, colorHex: String) -> String {
        if let s = index.bySymbolColor["\(symbol)|\(colorHex.uppercased())"] { return s }
        if let s = index.bySymbol[symbol] { return s }
        return "metro"
    }

    /// The plate's outer silhouette, for callers drawing their own outline
    /// around it — a ring at the wrong radius reads as a second badge.
    public static func stationOutline(styleId: String,
                                      side: CGFloat) -> (isCircle: Bool, cornerRadiusRatio: CGFloat) {
        let fallback: CGFloat = 6.0 / 28.0
        guard let face = spec(styleId)?.station else { return (false, fallback) }
        guard let layer = face.clip ?? face.layers?.first else { return (false, fallback) }
        if layer.shape == "circle" { return (true, 0.5) }
        if let ratio = layer.radiusRatio { return (false, ratio) }
        if let radius = layer.radius, side > 0 { return (false, radius / side) }
        return (false, fallback)
    }

    public static func styleId(for style: BadgeStyle) -> String {
        switch style {
        case .rounded: return "jr"
        case .ring:    return "metro"
        case .filled:  return "tokyu"
        case .square:  return "square"
        }
    }
}
