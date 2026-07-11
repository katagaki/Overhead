import SwiftUI
import Backbone
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// True when green clearly dominates red in the line color. Used to tell
    /// the Yokohama Municipal Green Line (#4BA672) apart from Tokyo Metro Ginza
    /// (orange), which share the "G" station-code prefix — the line color is
    /// the only discriminator available in both the app and the Live Activity.
    var isGreenDominant: Bool {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return g > r + 0.2
        #else
        return false
        #endif
    }
}

// MARK: - Line Symbol Badge
/// Renders line symbol badges matching each operator's official signage:
/// - JR East (J..): rounded square, thick color frame, sharp-cornered white core,
///   black Helvetica-style letters (signage uses Frutiger; Hind is the bundled substitute)
/// - Tokyo Metro / Toei subway: circle with color ring (~16% of diameter),
///   near-black letter (signage uses Futura)
/// - Keisei (KS): circle with thinner blue ring, line-color letters in
///   regular Helvetica (not bold)
/// - Tobu (TS/TI/TN/TD/TJ): rounded square, rounder corners than JR,
///   color stroke with rounded white core
/// - Odakyu (OH/OE/OT): very-round squircle, line-color ring and letters
/// - Nippori-Toneri Liner (NT): rounded square with pink outer + green inner border
/// - Tokyu (TY/DT/MG/…): FILLED rounded square in the line color with white
///   letters
/// - Minatomirai (MM): FILLED rounded square, white Helvetica letters
/// - Keikyu (KK): white circle with a thin light-blue ring and BLUE letters
///   (signage is blue regardless of the red line color)
/// - Keio (KO/IN): white circle with a thick line-color ring and line-color
///   letters (the official KO logo)
/// - Seibu (SI/SS/…): the official train-front logo — line-color train body
///   with a white face bearing the letters, two white lights, splayed legs
/// - Sotetsu (SO): filled navy rounded square, white letters over an orange rule
/// (Shapes verified against station signage photos, 2026-07)

struct LineSymbolBadge: View {
    let symbol: String
    let color: Color
    /// Badge side length; all internal metrics scale proportionally.
    var dimension: CGFloat = 32

    private static let tobuSymbols: Set<String> = ["TS", "TI", "TN", "TD", "TJ"]
    private static let odakyuSymbols: Set<String> = ["OH", "OE", "OT"]
    // Tsukuba Express (TX) signage uses the same filled-square style as Tokyu.
    private static let tokyuStyleSymbols: Set<String> = ["TY", "DT", "MG", "OM", "IK", "SG", "TM", "KD", "TX"]
    private static let seibuSymbols: Set<String> = ["SI", "SS", "SK", "ST", "SW", "SY"]
    private static let keioSymbols: Set<String> = ["KO", "IN"]
    private static let metroLetterColor = Color(hex: "#232021")
    private static let nipporiToneriGreen = Color(hex: "#69B444")
    private static let keikyuRingBlue = Color(hex: "#00A7E1")
    private static let keikyuLetterBlue = Color(hex: "#1E50A2")
    private static let seibuLetterColor = Color(hex: "#414D66")
    private static let sotetsuOrange = Color(hex: "#EE7B01")
    private static let rinkaiLightBlue = Color(hex: "#96C7C1")
    // Tama Monorail signage numbers are green even though the line/route is
    // drawn orange, so the TT badge uses a fixed green, not the line color.
    private static let tamaGreen = Color(hex: "#3C605F")

    /// Scale factor relative to the 32pt reference design.
    private var f: CGFloat { dimension / 32 }

    var body: some View {
        switch symbol {
        case "NT":
            nipporiToneriBadge
        case "KS":
            keiseiBadge
        case "KK":
            keikyuBadge
        case "SO":
            sotetsuBadge
        case "MM":
            minatomiraiBadge
        case "R":
            rinkaiBadge
        case "TT":
            tamaBadge
        case "B":
            yokohamaBadge
        case "G" where color.isGreenDominant:
            // Yokohama Municipal Green Line shares "G" with Tokyo Metro Ginza;
            // the green line color is what tells them apart (Ginza is orange).
            yokohamaBadge
        case _ where Self.keioSymbols.contains(symbol):
            keioBadge
        case _ where Self.tokyuStyleSymbols.contains(symbol):
            tokyuBadge
        case _ where Self.seibuSymbols.contains(symbol):
            seibuBadge
        case _ where Self.odakyuSymbols.contains(symbol):
            odakyuBadge
        case _ where Self.tobuSymbols.contains(symbol):
            tobuBadge
        case _ where symbol.hasPrefix("J"):
            jrBadge
        default:
            metroBadge
        }
    }

    // MARK: - JR East: rounded square, sharp-cornered white core

    private var jrBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: (symbol.count > 1 ? 18.5 : 20) * f),
                   color: .black, inset: 4 * f,
                   nudge: (symbol.count > 1 ? 16.5 : 20) * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 4 * f)
                        .fill(color)
                    Rectangle()
                        .fill(Color.white)
                        .padding(3.5 * f)
                }
            }
    }

    // MARK: - Tobu: rounder square, rounded white core

    private var tobuBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: 18.5 * f), color: .black, inset: 4.5 * f,
                   nudge: 15 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 7 * f))
            .overlay(
                RoundedRectangle(cornerRadius: 7 * f)
                    .strokeBorder(color, lineWidth: 3.5 * f)
            )
    }

    // MARK: - Rinkai: filled navy circle inside a light blue outer ring

    /// Matches TWR Rinkai signage (user photo 2026-07-10): white letter on a
    /// filled navy circle, a thin white separator ring, and a pale blue outer
    /// ring (~11% of the diameter).
    private var rinkaiBadge: some View {
        symbolText(.custom("Helvetica-Bold", fixedSize: 13 * f), color: .white, inset: 5.5 * f)
            .frame(width: dimension, height: dimension)
            .background {
                ZStack {
                    Circle()
                        .fill(Self.rinkaiLightBlue)
                    Circle()
                        .fill(Color.white)
                        .padding(3.5 * f)
                    Circle()
                        .fill(color)
                        .padding(4.5 * f)
                }
            }
    }

    // MARK: - Tama Monorail: JR-style rounded square in green

    /// Same rounded-square shape as JR East but rendered in the Tama Monorail
    /// green (its route line is orange, but the station numbering is green).
    private var tamaBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: (symbol.count > 1 ? 18.5 : 20) * f),
                   color: Self.tamaGreen, inset: 4 * f,
                   nudge: (symbol.count > 1 ? 16.5 : 20) * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 4 * f)
                        .fill(Self.tamaGreen)
                    Rectangle()
                        .fill(Color.white)
                        .padding(3.5 * f)
                }
            }
    }

    // MARK: - Yokohama Municipal: filled line-color circle, white letter

    private var yokohamaBadge: some View {
        symbolText(.custom("Helvetica-Bold", fixedSize: 16 * f), color: .white, inset: 5 * f)
            .frame(width: dimension, height: dimension)
            .background(color, in: Circle())
    }

    // MARK: - Keisei: blue ring, line-color bold condensed letters

    /// The LINE badge's KS is bold and condensed (user 2026-07-10) — unlike
    /// the STATION number badge, which keeps regular Helvetica. Both are
    /// circles. SF's .fontWidth(.condensed) approximates the narrow face.
    private var keiseiBadge: some View {
        symbolText(.system(size: 17 * f, weight: .bold).width(.condensed),
                   color: color, inset: 4.5 * f)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: Circle())
            .overlay(
                // Thicker than before, but deliberately lighter than the
                // Metro ring (6.2 * f)
                Circle()
                    .strokeBorder(color, lineWidth: 4.2 * f)
            )
    }

    // MARK: - Nippori-Toneri Liner: pink outer + green inner border

    private var nipporiToneriBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: 13.5 * f), color: .black, inset: 6 * f,
                   nudge: 13.5 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 5 * f))
            .overlay(
                RoundedRectangle(cornerRadius: 5 * f)
                    .strokeBorder(color, lineWidth: 2.4 * f)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2.4 * f)
                    .strokeBorder(Self.nipporiToneriGreen, lineWidth: 1.4 * f)
                    .padding(3.8 * f)
            )
    }

    // MARK: - Tokyu / Minatomirai: filled rounded square, white letters

    private var tokyuBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: 18.5 * f), color: .white, inset: 4.5 * f,
                   nudge: 15 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background(color, in: RoundedRectangle(cornerRadius: 8 * f))
    }

    // MARK: - Odakyu: very-round squircle, line-color ring and letters

    private var odakyuBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: 14 * f), color: color, inset: 4.5 * f,
                   nudge: 14 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: RoundedRectangle(cornerRadius: dimension * 0.45, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: dimension * 0.45, style: .continuous)
                    .strokeBorder(color, lineWidth: 3 * f)
            )
    }

    // MARK: - Keikyu: white circle, thin light-blue ring, blue letters

    private var keikyuBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: 17 * f), color: Self.keikyuLetterBlue, inset: 4.5 * f,
                   nudge: 14 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(Self.keikyuRingBlue, lineWidth: 3 * f)
            )
    }

    // MARK: - Keio: white circle, thick ring, line-color letters (KO logo)

    private var keioBadge: some View {
        symbolText(.custom("Hind-Semibold", fixedSize: 17 * f), color: color, inset: 5 * f,
                   nudge: 13 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(color, lineWidth: 2 * f)
            )
    }

    // MARK: - Minatomirai: filled rounded square, white Helvetica letters

    private var minatomiraiBadge: some View {
        symbolText(.custom("Helvetica-Bold", fixedSize: 14.5 * f), color: .white, inset: 4.5 * f)
            .frame(width: dimension, height: dimension)
            .background(color, in: RoundedRectangle(cornerRadius: 5 * f))
    }

    // MARK: - Seibu: train-front logo (body + face + lights + legs)

    private var seibuBadge: some View {
        ZStack {
            SeibuTrainLegs()
                .fill(color)

            UnevenRoundedRectangle(
                topLeadingRadius: 0.20 * dimension,
                bottomLeadingRadius: 0.07 * dimension,
                bottomTrailingRadius: 0.07 * dimension,
                topTrailingRadius: 0.20 * dimension,
                style: .continuous
            )
            .fill(color)
            .frame(width: 0.82 * dimension, height: 0.78 * dimension)
            .offset(y: -0.11 * dimension)

            UnevenRoundedRectangle(
                topLeadingRadius: 0.10 * dimension,
                bottomLeadingRadius: 0.30 * dimension,
                bottomTrailingRadius: 0.30 * dimension,
                topTrailingRadius: 0.10 * dimension,
                style: .continuous
            )
                .fill(Color.white)
                .frame(width: 0.60 * dimension, height: 0.48 * dimension)
                .offset(y: -0.16 * dimension)

            Text(symbol)
                .font(.custom("Hind-Bold", fixedSize: 0.40 * dimension))
                .kerning(symbol.count > 1 ? -0.5 * f : 0)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.black)
                .frame(width: 0.56 * dimension)
                .offset(y: -0.20 * dimension + 0.30 * dimension * 0.085)

            ForEach([-1.0, 1.0], id: \.self) { side in
                Circle()
                    .fill(Color.white)
                    .frame(width: 0.11 * dimension, height: 0.11 * dimension)
                    .offset(x: side * 0.20 * dimension, y: 0.14 * dimension)
            }
        }
        .frame(width: dimension, height: dimension)
    }

    // MARK: - Sotetsu: filled navy square, white letters over orange rule

    private var sotetsuBadge: some View {
        // Sotetsu signage uses a flat, wide face; expanded-width SF is the
        // closest system substitute (no Hind nudge/kerning needed).
        VStack(spacing: 2 * f) {
            Text(symbol)
                .font(.system(size: 11.5 * f, weight: .bold))
                .fontWidth(.expanded)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.white)
                .padding(.horizontal, 3 * f)
            Rectangle()
                .fill(Self.sotetsuOrange)
                .frame(width: 18 * f, height: max(1, 1.8 * f))
        }
        .frame(width: dimension, height: dimension)
        .background(color, in: RoundedRectangle(cornerRadius: 6.5 * f))
    }

    // MARK: - Tokyo Metro / Toei: thick color ring

    private var metroBadge: some View {
        symbolText(.custom("Futura-Bold", fixedSize: (symbol.count > 1 ? 11 : 15) * f),
                   color: Self.metroLetterColor, inset: 7 * f)
            // Futura-Bold's "C" has uneven side bearings — nudge to optical center
            .offset(x: symbol == "C" ? -0.75 * f : 0)
            // Futura-Bold's "M" sits low in its line box; lift it so it stays
            // optically centered inside the thick ring
            .offset(y: symbol == "M" ? -0.8 * f : 0)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(color, lineWidth: 6.2 * f)
            )
    }

    // MARK: - Shared Text

    /// `nudge` shifts the glyph down to optical center — Hind's Devanagari-
    /// scale metrics leave Latin caps sitting 0.085em above the box center.
    private func symbolText(_ font: Font, color: Color, inset: CGFloat, nudge: CGFloat = 0) -> some View {
        Text(symbol)
            .font(font)
            .kerning(symbol.count > 1 ? -0.5 * f : 0)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(color)
            .offset(y: nudge)
            .padding(.horizontal, inset)
    }
}

// MARK: - Seibu Train Legs

/// The two splayed legs (rails) under the Seibu train-front logo. Drawn in
/// unit space; the top ends tuck behind the train body.
struct SeibuTrainLegs: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: 0.40 * w, y: 0.60 * h))
        p.addLine(to: CGPoint(x: 0.53 * w, y: 0.60 * h))
        p.addLine(to: CGPoint(x: 0.27 * w, y: 1.00 * h))
        p.addLine(to: CGPoint(x: 0.10 * w, y: 1.00 * h))
        p.closeSubpath()
        p.move(to: CGPoint(x: 0.60 * w, y: 0.60 * h))
        p.addLine(to: CGPoint(x: 0.47 * w, y: 0.60 * h))
        p.addLine(to: CGPoint(x: 0.73 * w, y: 1.00 * h))
        p.addLine(to: CGPoint(x: 0.90 * w, y: 1.00 * h))
        p.closeSubpath()
        return p
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let badges: [(symbol: String, color: Color)] = [
        ("JY", .green),   // JR square frame
        ("M", .red),      // Tokyo Metro ring circle
        ("NT", .pink),    // Nippori-Toneri double border
        ("KS", .blue),    // Keisei Helvetica circle
        ("TS", .blue),    // Tobu rounder square
        ("SI", .orange),  // Seibu train logo
        ("TY", .red),     // Tokyu filled square
        ("OH", .blue),    // Odakyu squircle
        ("MM", .blue),    // Minatomirai filled square
        ("KK", .pink),    // Keikyu blue-ring circle
        ("KO", .pink),    // Keio logo circle
        ("SO", .indigo),  // Sotetsu orange rule
        ("R", Color(hex: "#222D65")),   // Rinkai navy circle, light-blue ring
        ("TT", Color(hex: "#F08300")),  // Tama Monorail green JR-style square
        ("B", Color(hex: "#3577BC")),   // Yokohama Blue filled circle
        ("G", Color(hex: "#40CC40")),   // Yokohama Green filled circle
    ]

    VStack(spacing: 20) {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
            ForEach(badges, id: \.symbol) { badge in
                VStack(spacing: 4) {
                    LineSymbolBadge(symbol: badge.symbol, color: badge.color)
                    Text(badge.symbol)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }

        // The Seibu train logo at a size where its details are inspectable
        LineSymbolBadge(symbol: "SI", color: .orange, dimension: 96)
    }
    .padding()
    .frame(width: 260)
}
