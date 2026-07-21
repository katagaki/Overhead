import SwiftUI

// MARK: - LCD Gothic Font

/// Gothic face for the JR / Tokyo Metro LCD simulations' Japanese text.
enum LCDFont {
    static func gothic(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(gothicName(for: weight), fixedSize: size)
    }

    static func gothicName(for weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy: return "ZenKakuGothicNew-Black"
        case .bold, .semibold: return "ZenKakuGothicNew-Bold"
        case .medium: return "ZenKakuGothicNew-Medium"
        default: return "ZenKakuGothicNew-Regular"
        }
    }
}

// MARK: - Rotated English Station Name

/// English station name for the LCD stop progressions: rotated 90° clockwise
/// so it reads sideways, anchored to the band edge like the vertical kanji.
struct RotatedEnglishStationName: View {
    let name: String
    let fontSize: CGFloat
    let width: CGFloat
    let height: CGFloat
    var color: Color = .black
    /// `.trailing` ends the text at the band below (Joban family);
    /// `.leading` starts it at the band above (Metro).
    var textAnchor: Alignment = .trailing

    var body: some View {
        Text(name)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: height, alignment: textAnchor)
            .rotationEffect(.degrees(90))
            .frame(width: width, height: height)
    }
}
