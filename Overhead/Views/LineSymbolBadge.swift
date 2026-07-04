import SwiftUI
import Backbone

// MARK: - Line Symbol Badge
/// Renders line symbol badges matching each operator's official signage:
/// - JR East (J..): rounded square, thick color frame, sharp-cornered white core,
///   black Helvetica-style letters (signage uses Frutiger)
/// - Tokyo Metro / Toei subway: circle with thick color ring (~22% of diameter),
///   near-black letter (signage uses Futura)
/// - Keisei (KS): circle with thinner blue ring and BLUE letters
/// - Tobu (TS/TI/TN/TD/TJ): rounded square, rounder corners than JR,
///   color stroke with rounded white core
/// - Nippori-Toneri Liner (NT): rounded square with pink outer + green inner border

struct LineSymbolBadge: View {
    let symbol: String
    let color: Color

    private static let tobuSymbols: Set<String> = ["TS", "TI", "TN", "TD", "TJ"]
    private static let metroLetterColor = Color(hex: "#232021")
    private static let nipporiToneriGreen = Color(hex: "#69B444")

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
        symbolText(.custom("HelveticaNeue-Bold", fixedSize: symbol.count > 1 ? 14 : 17),
                   color: .black, inset: 5)
            .frame(width: 32, height: 32)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                    Rectangle()
                        .fill(Color.white)
                        .padding(3.5)
                }
            }
    }

    // MARK: - Tobu: rounder square, rounded white core

    private var tobuBadge: some View {
        symbolText(.custom("HelveticaNeue-Bold", fixedSize: 13), color: .black, inset: 5)
            .frame(width: 32, height: 32)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(color, lineWidth: 3.5)
            )
    }

    // MARK: - Keisei: blue ring, blue letters

    private var keiseiBadge: some View {
        symbolText(.custom("HelveticaNeue-Bold", fixedSize: 13), color: color, inset: 5)
            .frame(width: 32, height: 32)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(color, lineWidth: 3.2)
            )
    }

    // MARK: - Nippori-Toneri Liner: pink outer + green inner border

    private var nipporiToneriBadge: some View {
        symbolText(.custom("HelveticaNeue-Bold", fixedSize: 12), color: .black, inset: 6)
            .frame(width: 32, height: 32)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(color, lineWidth: 2.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2.4)
                    .strokeBorder(Self.nipporiToneriGreen, lineWidth: 1.4)
                    .padding(3.8)
            )
    }

    // MARK: - Tokyo Metro / Toei: thick color ring

    private var metroBadge: some View {
        symbolText(.custom("Futura-Bold", fixedSize: symbol.count > 1 ? 11 : 15),
                   color: Self.metroLetterColor, inset: 8)
            .frame(width: 32, height: 32)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(color, lineWidth: 7)
            )
    }

    // MARK: - Shared Text

    private func symbolText(_ font: Font, color: Color, inset: CGFloat) -> some View {
        Text(symbol)
            .font(font)
            .kerning(symbol.count > 1 ? -0.5 : 0)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(color)
            .padding(.horizontal, inset)
    }
}
