import SwiftUI

// MARK: - LCD Fonts

/// Faces for the JR / Tokyo Metro LCD simulations. The real displays set
/// Japanese in 新ゴ — BIZ UDPGothic is Morisawa's own free UD stand-in — and
/// romaji in Helvetica.
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
        case .medium, .semibold, .bold, .heavy, .black: return "Helvetica-Bold"
        case .light, .thin, .ultraLight: return "Helvetica-Light"
        default: return "Helvetica"
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

// MARK: - Angled English Station Name

/// English station name climbing to the right at a shallow angle, the way the
/// E235 strip sets romaji: the name starts at its column's band edge and runs
/// up across its neighbours.
struct AngledEnglishStationName: View {
    let name: String
    let fontSize: CGFloat
    let width: CGFloat
    let height: CGFloat
    var color: Color = .black
    /// Travel direction; the climb mirrors with it.
    var mirrored = false

    private static let degrees: CGFloat = 58

    var body: some View {
        // Longest run that still fits the slot's height once rotated.
        let run = (height - 3) / sin(Self.degrees * .pi / 180)
        Text(name)
            .font(LCDFont.latin(size: fontSize, weight: .medium))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: run, alignment: mirrored ? .trailing : .leading)
            .rotationEffect(
                .degrees(mirrored ? Self.degrees : -Self.degrees),
                anchor: mirrored ? .bottomTrailing : .bottomLeading
            )
            .frame(width: width, height: height,
                   alignment: mirrored ? .bottomTrailing : .bottomLeading)
            // The column's own edge is half a slot off from the code centered
            // under it; start the climb just left of that code instead.
            .offset(x: mirrored ? -startInset : startInset)
    }

    private var startInset: CGFloat {
        max(0, width / 2 - 4)
    }
}
