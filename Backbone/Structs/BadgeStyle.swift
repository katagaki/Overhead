import Foundation

/// Legacy four-shape choice for user-created lines. Superseded by badge style
/// ids; kept so lines saved before the change still decode.
public enum BadgeStyle: String, Codable, CaseIterable, Sendable, Hashable, Identifiable {
    case rounded, ring, filled, square

    public var id: String { rawValue }

    public var styleId: String {
        switch self {
        case .rounded: return "jr"
        case .ring:    return "metro"
        case .filled:  return "tokyu"
        case .square:  return "square"
        }
    }
}
