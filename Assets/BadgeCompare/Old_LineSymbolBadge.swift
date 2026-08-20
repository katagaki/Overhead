import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// True when green dominates red — distinguishes Yokohama Green from Ginza, which share the "G" prefix.
    var isGreenDominant: Bool {
        let (r, g, b) = rgbComponents
        return g > r + 0.2
    }

    /// Saitama Railway shares "SR" and its blue passes `isGreenDominant`
    /// (g .40 vs r 0), so Shibayama's green must beat blue too.
    var isShibayamaGreen: Bool {
        let (r, g, b) = rgbComponents
        return g > r + 0.2 && g > b
    }
}

// MARK: - Line Symbol Badge

struct OldLineSymbolBadge: View {
    let symbol: String
    let color: Color
    /// Badge side length; all internal metrics scale proportionally.
    var dimension: CGFloat = 32
    /// Forces a shape for user-created lines, whose symbols match no operator.
    var styleOverride: BadgeStyle? = nil

    private static let tobuSymbols: Set<String> = ["TS", "TI", "TN", "TD", "TJ"]
    private static let odakyuSymbols: Set<String> = ["OH", "OE", "OT"]
    // Tsukuba Express (TX) signage uses the same filled-square style as Tokyu.
    private static let tokyuStyleSymbols: Set<String> = ["TY", "DT", "MG", "OM", "IK", "SG", "TM", "KD", "SH", "TX"]
    // Setagaya's yellow plate carries dark grey letters, not white.
    private static let tokyuLetterColors: [String: Color] = ["SG": Color(hex: "#595757")]
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
    private static let tamaGreen = Color(hex: "#1A948B")
    // Enoden signage: pale yellow outer ring, dark green inner ring, near-black code.
    private static let enodenYellow = Color(hex: "#FFE277")
    private static let enodenGreen = Color(hex: "#0C6346")
    private static let enodenLetterColor = Color(hex: "#231F20")
    private static let yurikamomeRed = Color(hex: "#E60012")
    private static let seasideIndigo = Color(hex: "#43397E")

    /// Scale factor relative to the 32pt reference design.
    private var f: CGFloat { dimension / 32 }

    var body: some View {
        if let styleOverride {
            customBadge(styleOverride)
        } else {
            operatorBadge
        }
    }

    // MARK: - Custom line symbol badges

    @ViewBuilder
    private func customBadge(_ style: BadgeStyle) -> some View {
        switch style {
        case .rounded: jrBadge
        case .ring: metroBadge()
        case .filled: tokyuBadge
        case .square:
            symbolText(.custom("Hind-Bold", fixedSize: (symbol.count > 1 ? 18.5 : 20) * f),
                       color: .black, inset: 4 * f,
                       nudge: (symbol.count > 1 ? 16.5 : 20) * f * 0.085)
                .frame(width: dimension, height: dimension)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 2 * f))
                .overlay(
                    RoundedRectangle(cornerRadius: 2 * f)
                        .strokeBorder(color, lineWidth: 3.5 * f)
                )
        }
    }

    @ViewBuilder
    private var operatorBadge: some View {
        switch symbol {
        case "NT":
            nipporiToneriBadge
        case "KS":
            keiseiBadge(condensed: true)
        case "HS":
            // Hokuso shares Keisei's ringed circle but sets its code at normal
            // width, so it needs a smaller size to clear the ring.
            keiseiBadge(condensed: false, size: 14.5)
        case "MO":
            // Tokyo Monorail's plate is a rounded rectangle, not a circle.
            tobuBadge
        case "TR":
            // Toyo Rapid: thin ring matching its station badge, condensed face.
            metroBadge(condensed: true, ringWidth: 3.9 * f)
        case "KK":
            keikyuBadge
        case "SO":
            sotetsuBadge
        case "MM":
            minatomiraiBadge
        case "I":
            mitaBadge
        case "SL":
            seasideBadge
        case "R":
            rinkaiBadge
        case "TT":
            tamaBadge
        case "B":
            yokohamaBadge
        case "G" where color.isGreenDominant:
            yokohamaBadge
        case "SA":
            arakawaBadge
        case "U":
            yurikamomeBadge
        case "NS":
            newShuttleBadge
        case "EN":
            enodenBadge
        case "CD":
            choshiBadge
        case "SR":
            srBadge
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
        case "JR":
            // Lines with no station numbering show the JR mark in the line-colored frame.
            jrWordmarkBadge
        case _ where symbol.hasPrefix("J"):
            jrBadge
        default:
            metroBadge()
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

    // MARK: - JR East: the JR mark, for lines with no station numbering

    private var jrWordmarkBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: 17 * f), color: .black, inset: 4 * f,
                   nudge: 15 * f * 0.085)
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

    // MARK: - New Shuttle: Filled Hexagon

    private var newShuttleBadge: some View {
        symbolText(.system(size: 13.5 * f, weight: .bold).width(.expanded), color: .white,
                   inset: 4.5 * f)
            .frame(width: dimension, height: dimension)
            .background(color, in: FlatTopHexagon())
    }

    // MARK: - Toden Arakawa: Cherry Blossom

    private var arakawaBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: 15 * f), color: .black, inset: 7 * f,
                   nudge: 15 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background {
                ZStack {
                    Circle().fill(color)
                    SakuraBlossom().fill(Color.white).padding(2 * f)
                }
            }
    }

    // MARK: - Yurikamome: Filled Circle, Red Bar

    private var yurikamomeBadge: some View {
        // The bar belongs to the station badge only.
        symbolText(.custom("Helvetica-Bold", fixedSize: 19 * f), color: .white, inset: 4 * f)
            .frame(width: dimension, height: dimension)
            .background(color, in: Circle())
    }

    // MARK: - Enoden: White Core, Green Ring, Yellow Outer Ring

    private var enodenBadge: some View {
        symbolText(.custom("Helvetica-Bold", fixedSize: 14 * f),
                   color: Self.enodenLetterColor, inset: 6 * f)
            .frame(width: dimension, height: dimension)
            .background {
                ZStack {
                    Circle()
                        .fill(Self.enodenYellow)
                    Circle()
                        .fill(Self.enodenGreen)
                        .padding(2 * f)
                    Circle()
                        .fill(Color.white)
                        .padding(5 * f)
                }
            }
    }

    // MARK: - Choshi: white plate, hairline black keyline, black letters

    /// Alone among the operators, 銚子電鉄's numbering plate carries no line
    /// colour at all — it is black on white, so `color` is deliberately unused.
    private var choshiBadge: some View {
        symbolText(.custom("Hind-Bold", fixedSize: 17 * f), color: .black, inset: 3 * f,
                   nudge: 15 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: RoundedRectangle(cornerRadius: dimension * 0.031))
            .overlay(
                RoundedRectangle(cornerRadius: dimension * 0.031)
                    .strokeBorder(Color.black, lineWidth: dimension * 0.030)
            )
    }

    // MARK: - Keisei: blue ring, line-color bold condensed letters

    private func keiseiBadge(condensed: Bool, size: CGFloat = 17) -> some View {
        symbolText(.system(size: size * f, weight: .bold).width(condensed ? .condensed : .standard),
                   color: color, inset: 4.5 * f)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: Circle())
            .overlay(
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
        symbolText(.custom("Hind-Bold", fixedSize: 18.5 * f),
                   color: Self.tokyuLetterColors[symbol] ?? .white, inset: 4.5 * f,
                   nudge: 15 * f * 0.085)
            .frame(width: dimension, height: dimension)
            .background(color, in: RoundedRectangle(cornerRadius: 8 * f))
            // TX sets a white keyline inside the plate; Tokyu's is plain.
            .overlay {
                if symbol == "TX" {
                    RoundedRectangle(cornerRadius: 5.5 * f)
                        .strokeBorder(Color.white, lineWidth: 1.3 * f)
                        .padding(2.6 * f)
                }
            }
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

    private var mitaBadge: some View {
        SerifI()
            .fill(Self.metroLetterColor)
            .frame(width: 7.8 * f, height: 11.5 * f)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: Circle())
            .overlay(Circle().strokeBorder(color, lineWidth: 6.2 * f))
    }

    private var srBadge: some View {
        Text(symbol)
            .font(.system(size: (color.isShibayamaGreen ? 20.5 : 15) * f,
                          weight: color.isShibayamaGreen ? .medium : .regular)
                .width(color.isShibayamaGreen ? .condensed : .standard))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(color.isShibayamaGreen ? color : Self.metroLetterColor)
            .padding(.horizontal, 4 * f)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: Circle())
            .overlay(Circle().strokeBorder(color,
                lineWidth: (color.isShibayamaGreen ? 2.0 : 3.4) * f))
    }

    /// The station badge's disc, lettered instead of numbered.
    private var seasideBadge: some View {
        Text(symbol)
            .font(.custom("Helvetica-Bold", fixedSize: 13 * f))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(.white)
            .offset(y: -3 * f)
            .frame(width: dimension, height: dimension)
            .background {
                ZStack {
                    Circle().fill(Color.white)
                    SeasideWave().fill(Self.seasideIndigo)
                        .clipShape(Circle())
                        .padding(dimension * 0.075)
                    Circle().strokeBorder(Self.seasideIndigo, lineWidth: dimension * 0.026)
                }
            }
    }

    /// A disc carrying a single large M.
    private var minatomiraiBadge: some View {
        Text("M")
            .font(.custom("Futura-Bold", fixedSize: 19 * f))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(.white)
            .offset(y: -0.5 * f)
            .frame(width: dimension, height: dimension)
            .background(color, in: Circle())
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

    private func metroBadge(condensed: Bool = false, letterColor: Color? = nil,
                            ringWidth: CGFloat? = nil) -> some View {
        symbolText(condensed
                     ? .system(size: 15 * f, weight: .bold).width(.condensed)
                     : .custom("Futura-Bold", fixedSize: (symbol.count > 1 ? 11 : 15) * f),
                   color: letterColor ?? Self.metroLetterColor, inset: 7 * f)
            // Futura-Bold's "C" has uneven side bearings — nudge to optical center
            .offset(x: symbol == "C" ? -0.75 * f : 0)
            // Futura-Bold's "M" sits low in its line box; lift it so it stays
            // optically centered inside the thick ring
            .offset(y: symbol == "M" ? -0.8 * f : 0)
            .frame(width: dimension, height: dimension)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(color, lineWidth: ringWidth ?? 6.2 * f)
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

// MARK: - Flat-Top Hexagon

/// Saitama New Shuttle's plate: points at the left and right edges, flat top and bottom.
struct FlatTopHexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let inset = h * 0.08          // flat edges sit just inside the top and bottom
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.28, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.28, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.28, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.28, y: rect.maxY - inset))
        path.closeSubpath()
        return path
    }
}

/// 都電荒川線's badge is a five-petal cherry blossom.
/// 三田線's "I" has top and bottom bars; system faces draw a bare stem.
struct SerifI: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        // One stroke weight for the stem and both bars.
        let t = w * 0.34
        let barW = w * 0.74
        let barX = rect.minX + (w - barW) / 2
        var p = Path()
        p.addRect(CGRect(x: barX, y: rect.minY, width: barW, height: t))
        p.addRect(CGRect(x: rect.midX - t / 2, y: rect.minY, width: t, height: h))
        p.addRect(CGRect(x: barX, y: rect.maxY - t, width: barW, height: t))
        return p
    }
}

struct SakuraBlossom: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var path = Path()
        // Non-zero winding unions the core and the five lobes.
        path.addEllipse(in: CGRect(x: c.x - r * 0.64, y: c.y - r * 0.64,
                                   width: r * 1.28, height: r * 1.28))
        for k in 0..<5 {
            let a = -CGFloat.pi / 2 + CGFloat(k) * 2 * .pi / 5
            let pc = CGPoint(x: c.x + cos(a) * r * 0.60, y: c.y + sin(a) * r * 0.60)
            path.addEllipse(in: CGRect(x: pc.x - r * 0.40, y: pc.y - r * 0.40,
                                       width: r * 0.80, height: r * 0.80))
        }
        return path
    }
}

/// The swoosh across みなとみらい線's plate.
struct MinatomiraiWave: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        // One sine period, tapered towards both ends.
        func wave(_ side: CGFloat) -> [CGPoint] {
            let inset: CGFloat = 0.07
            return stride(from: 0.0, through: 1.0, by: 0.025).map { t in
                let taper = 0.22 + 0.78 * sin(.pi * t)
                return CGPoint(x: rect.minX + w * (inset + t * (1 - 2 * inset)),
                               y: rect.minY + h * (0.5 + side * 0.11 * taper
                                                   + 0.21 * sin(2 * .pi * t)))
            }
        }
        let top = wave(-1), bottom = wave(1).reversed()
        path.move(to: top[0])
        top.dropFirst().forEach { path.addLine(to: $0) }
        bottom.forEach { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }
}

// MARK: - Seaside Wave

/// Seaside Line's disc, broken by the wave that names the line.
struct SeasideWave: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let crest = rect.minY + h * 0.70
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: crest + h * 0.06))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.5, y: crest + h * 0.05),
                          control: CGPoint(x: rect.minX + w * 0.75, y: crest - h * 0.06))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: crest + h * 0.06),
                          control: CGPoint(x: rect.minX + w * 0.25, y: crest + h * 0.16))
        path.closeSubpath()
        return path
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
