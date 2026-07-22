import SwiftUI

// MARK: - LCD Fonts

/// Faces for the JR / Tokyo Metro LCD simulations. The real displays pair
/// 新ゴ with Frutiger; the closest open stand-ins are BIZ UDPGothic
/// (Morisawa's own free UD gothic) and Hind (Frutiger-adjacent humanist).
enum LCDFont {
    static func gothic(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(gothicName(for: weight), fixedSize: size)
    }

    static func gothicName(for weight: Font.Weight) -> String {
        switch weight {
        case .medium, .semibold, .bold, .heavy, .black: return "BIZUDPGothic-Bold"
        default: return "BIZUDPGothic-Regular"
        }
    }

    static func latin(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(latinName(for: weight), fixedSize: size)
    }

    static func latinName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: return "Hind-Bold"
        case .semibold: return "Hind-SemiBold"
        case .medium: return "Hind-Medium"
        case .light, .thin, .ultraLight: return "Hind-Light"
        default: return "Hind-Regular"
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
            .font(LCDFont.latin(size: fontSize, weight: .bold))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: height, alignment: textAnchor)
            .rotationEffect(.degrees(90))
            .frame(width: width, height: height)
    }
}
