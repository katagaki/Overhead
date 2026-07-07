import SwiftUI
import Backbone

// MARK: - Line Symbol Badge
/// Renders line symbol badges matching each operator's official signage:
/// - JR East (J..): rounded square, thick color frame, sharp-cornered white core,
///   black Helvetica-style letters (signage uses Frutiger; Hind is the bundled substitute)
/// - Tokyo Metro / Toei subway: circle with color ring (~16% of diameter),
///   near-black letter (signage uses Futura)
/// - Keisei (KS): circle with thinner blue ring and BLUE letters
/// - Tobu (TS/TI/TN/TD/TJ): rounded square, rounder corners than JR,
///   color stroke with rounded white core
/// - Nippori-Toneri Liner (NT): rounded square with pink outer + green inner border

struct LineSymbolBadge: View {
    let symbol: String
    let color: Color
    /// Badge side length; all internal metrics scale proportionally.
    var dimension: CGFloat = 32

    private static let tobuSymbols: Set<String> = ["TS", "TI", "TN", "TD", "TJ"]
    private static let metroLetterColor = Color(hex: "#232021")
    private static let nipporiToneriGreen = Color(hex: "#69B444")

    /// Scale factor relative to the 32pt reference design.
    private var f: CGFloat { dimension / 32 }

    var body: some View {
        switch symbol {
        case "NT":
            nipporiToneriBadge
        case "KS":
            keiseiBadge
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
        symbolText(.custom("Hind-Bold", fixedSize: (symbol.count > 1 ? 16.5 : 20) * f),
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
        symbolText(.custom("Hind-Bold", fixedSize: 15 * f), color: .black, inset: 4.5 * f,
                   nudge: 15 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 7 * f))
            .overlay(
                RoundedRectangle(cornerRadius: 7 * f)
                    .strokeBorder(color, lineWidth: 3.5 * f)
            )
    }

    // MARK: - Keisei: blue ring, blue letters

    private var keiseiBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: 15 * f), color: color, inset: 4.5 * f,
                   nudge: 15 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(color, lineWidth: 3.2 * f)
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

    // MARK: - Tokyo Metro / Toei: thick color ring

    private var metroBadge: some View {
        symbolText(.custom("Futura-Bold", fixedSize: (symbol.count > 1 ? 11 : 15) * f),
                   color: Self.metroLetterColor, inset: 7 * f)
            // Futura-Bold's "C" has uneven side bearings — nudge to optical center
            .offset(x: symbol == "C" ? -0.75 * f : 0)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(color, lineWidth: 5 * f)
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
