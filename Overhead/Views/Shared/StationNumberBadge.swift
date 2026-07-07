import SwiftUI
import Backbone

// MARK: - Station Number Badge
/// Renders station number badges matching the real signage of each operator:
/// - JR East / Tobu: rounded square with a line-color frame, white inner,
///   prefix stacked over number in black (e.g. JY01, TS01)
/// - Tokyo Metro / Toei / Keisei: circle with a line-color ring, white inner,
///   prefix stacked over number in black (e.g. G01, A01, KS01)
/// - Odakyu: split rounded square — line-color top band with white prefix,
///   white bottom with black number (e.g. OH01)

struct StationNumberBadge: View {
    let code: String
    let color: Color
    var opacity: Double = 1.0
    var size: BadgeSize = .regular
    /// Japanese station name (currently unused; kept for future variants).
    var stationName: String? = nil

    enum BadgeSize {
        case compact  // For list rows
        case regular  // For journey view station labels
    }

    private static let squarePrefixes: Set<String> = [
        // Tobu
        "TS", "TI", "TN", "TD", "TJ",
    ]
    private static let splitPrefixes: Set<String> = [
        // Odakyu
        "OH", "OE", "OT",
    ]

    private var parsed: (prefix: String, number: String) {
        let letters = code.prefix(while: \.isLetter)
        let digits = code.drop(while: \.isLetter)
        return (String(letters), String(digits))
    }

    private var badgeDimension: CGFloat {
        switch size {
        case .compact: return 32
        case .regular: return 28
        }
    }

    private var prefixFontSize: CGFloat {
        switch size {
        case .compact: return 9
        case .regular: return 8
        }
    }

    private var numberFontSize: CGFloat {
        switch size {
        case .compact: return 12
        case .regular: return 10
        }
    }

    var body: some View {
        let (prefix, number) = parsed

        // JR station codes start with "J" (JC, JY, JK, JB, etc.)
        if prefix.hasPrefix("J") || Self.squarePrefixes.contains(prefix) {
            squareBadge(prefix: prefix, number: number)
        } else if Self.splitPrefixes.contains(prefix) {
            splitBadge(prefix: prefix, number: number)
        } else {
            circleBadge(prefix: prefix, number: number)
        }
    }

    // MARK: - JR East / Tobu: Rounded Square Frame

    @ViewBuilder
    private func squareBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension
        // Sized so the letters and digits fill the white core like the real
        // JR East signage (Hind's cap height is only 0.678em, hence the
        // generous point sizes relative to the badge).
        let prefixSize = d * 0.58
        let numberSize = d * 0.79

        // Hind's line box is ~1.6x the point size (Devanagari metrics), so cap
        // each line to a tight frame and shift glyphs down to optical center
        // (caps sit 0.085em above the box center).
        VStack(spacing: 1) {
            Text(prefix)
                .font(.custom("Hind-Bold", size: prefixSize))
                .offset(y: prefixSize * 0.24)
                .frame(maxWidth: .infinity)
                .frame(height: prefixSize * 0.75)

            Text(number)
                .font(.custom("Hind-Bold", size: numberSize))
                .offset(y: numberSize * -0.06)
                .frame(maxWidth: .infinity)
                .frame(height: numberSize * 0.75)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Color.black.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(color.opacity(opacity), lineWidth: 3)
        )
    }

    // MARK: - Metro / Toei / Keisei: Circle Ring

    /// Matches the official Tokyo Metro station numbering: colored ring
    /// (~13% of diameter), white core, Futura letter over number in black.
    @ViewBuilder
    private func circleBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Futura-Bold", size: d * 0.38))
                .frame(height: d * 0.42)
                .offset(y: 1.10)

            Text(number)
                .font(.custom("Futura-Bold", size: d * 0.38))
                .frame(height: d * 0.42)
                .offset(y: -1.90)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Color.black.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(color.opacity(opacity), lineWidth: d * 0.13)
        )
    }

    // MARK: - Odakyu: Split Rounded Square

    @ViewBuilder
    private func splitBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Hind-Bold", size: prefixFontSize))
                .offset(y: prefixFontSize * 0.085)
                .foregroundColor(Color.white.opacity(opacity))
                .frame(maxWidth: .infinity)
                .frame(height: d * 0.42)
                .background(color.opacity(opacity))

            Text(number)
                .font(.custom("Hind-Bold", size: numberFontSize))
                .offset(y: numberFontSize * 0.085)
                .foregroundColor(Color.black.opacity(opacity))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
        }
        .frame(width: d, height: d)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(color.opacity(opacity), lineWidth: 2)
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    StationNumberBadge(
        code: "Z02",
        color: .indigo,
        opacity: 1.0,
        size: .regular,
        stationName: "表参道"
    )
}

#Preview(traits: .sizeThatFitsLayout) {
    StationNumberBadge(
        code: "JL19",
        color: .gray,
        opacity: 1.0,
        size: .regular,
        stationName: "綾瀬"
    )
}
