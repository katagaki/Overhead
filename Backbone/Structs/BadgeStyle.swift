import Foundation

/// Badge shape for a user-created line's station numbers. Built-in lines infer
/// their shape from the station-code prefix; custom codes have no operator to
/// match, so they carry the choice explicitly.
public enum BadgeStyle: String, Codable, CaseIterable, Sendable, Hashable, Identifiable {
    case rounded   // JR-style: color frame, white core, black code
    case ring      // Metro-style: color ring, white core
    case filled    // Tokyu-style: solid color, white code
    case square    // thin color border, sharp corners

    public var id: String { rawValue }

    public var labelJa: String {
        switch self {
        case .rounded: return "角丸"
        case .ring: return "リング"
        case .filled: return "塗り"
        case .square: return "スクエア"
        }
    }
}
