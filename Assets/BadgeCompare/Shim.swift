import SwiftUI
import AppKit

// Backbone stand-ins, so the harness can compile the real badge views verbatim.

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        if hex.count == 6 {
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        } else {
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }

    /// Stands in for `UIColor(self).getRed(...)`; identical for the sRGB
    /// components these badges are built from.
    var rgbComponents: (CGFloat, CGFloat, CGFloat) {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .black
        return (ns.redComponent, ns.greenComponent, ns.blueComponent)
    }
}

public enum BadgeStyle: String, Codable, CaseIterable, Sendable, Hashable, Identifiable {
    case rounded, ring, filled, square
    public var id: String { rawValue }
}
