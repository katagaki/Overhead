import SwiftUI

// MARK: - Station Number Badge
/// Renders station number badges matching the real Tokyo rail signage:
/// - JR East: Rounded rectangle with colored outline, white inner, colored text
/// - Tokyo Metro: Circle with colored outline, white inner, colored text
/// - Toei: Circle (same style as Metro)

struct StationNumberBadge: View {
    let code: String
    let color: Color
    var opacity: Double = 1.0
    var size: BadgeSize = .regular

    enum BadgeSize {
        case compact  // For list rows
        case regular  // For journey view station labels
    }

    /// Parse "JC05" → ("JC", "05"), "G01" → ("G", "01"), "M08" → ("M", "08")
    private var parsed: (prefix: String, number: String) {
        let letters = code.prefix(while: \.isLetter)
        let digits = code.drop(while: \.isLetter)
        return (String(letters), String(digits))
    }

    /// JR station codes start with "J" (JC, JY, JK, JB, JA, JE, JH, etc.)
    private var isJR: Bool {
        parsed.prefix.hasPrefix("J")
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

        if isJR {
            jrBadge(prefix: prefix, number: number)
        } else {
            metroBadge(prefix: prefix, number: number)
        }
    }

    // MARK: - JR Style: Rounded Rectangle

    @ViewBuilder
    private func jrBadge(prefix: String, number: String) -> some View {
        let w = badgeDimension
        let h = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("HelveticaNeue-Bold", size: prefixFontSize))
                .frame(maxWidth: .infinity)
                .padding(.top, 2)

            Rectangle()
                .fill(color.opacity(opacity * 0.4))
                .frame(height: 0.5)
                .padding(.horizontal, 3)

            Text(number)
                .font(.custom("HelveticaNeue-Bold", size: numberFontSize))
                .frame(maxWidth: .infinity)
                .padding(.bottom, 2)
        }
        .foregroundColor(Color.black.opacity(opacity))
        .frame(width: w, height: h)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(color.opacity(opacity), lineWidth: 3)
        )
    }

    // MARK: - Metro / Toei Style: Circle

    @ViewBuilder
    private func metroBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: -1) {
            Text(prefix)
                .font(.system(size: prefixFontSize, weight: .heavy, design: .default))
                .padding(.top, 1)

            Text(number)
                .font(.system(size: numberFontSize, weight: .black, design: .default))
                .padding(.bottom, 1)
        }
        .foregroundColor(Color.black.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(color.opacity(opacity), lineWidth: 3)
        )
    }
}
