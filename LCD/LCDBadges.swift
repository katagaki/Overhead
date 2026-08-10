import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// True when green dominates red — distinguishes Yokohama Green from Ginza, which share the "G" prefix.
    /// Mirrors the app target's Color.isGreenDominant (LCD target is self-contained, can't import it).
    var isGreenDominant: Bool {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return g > r + 0.2
        #else
        return false
        #endif
    }

    /// True for Shibayama's green — Saitama Railway shares the "SR" prefix and
    /// its blue passes `isGreenDominant` (g .40 vs r 0), so green must also beat blue.
    var isShibayamaGreen: Bool {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return g > r + 0.2 && g > b
        #else
        return false
        #endif
    }
}

// MARK: - LCD Line Symbol Badge

/// Compact line symbol badge for Live Activity, self-contained; mirrors LineSymbolBadge at 24pt.
struct LCDLineSymbolBadge: View {
    let symbol: String
    let color: Color

    private static let tobuSymbols: Set<String> = ["TS", "TI", "TN", "TD", "TJ"]
    private static let odakyuSymbols: Set<String> = ["OH", "OE", "OT"]
    // Tsukuba Express (TX) signage uses the same filled-square style as Tokyu.
    private static let tokyuStyleSymbols: Set<String> = ["TY", "DT", "MG", "OM", "IK", "SG", "TM", "KD", "SH", "TX"]
    // Setagaya's yellow plate carries dark grey letters, not white.
    private static let tokyuLetterColors: [String: Color] = ["SG": Color(hex: "#595757")]
    private static let seibuSymbols: Set<String> = ["SI", "SS", "SK", "ST", "SW", "SY"]
    private static let keioSymbols: Set<String> = ["KO", "IN"]
    private static let keikyuRingBlue = Color(hex: "#00A7E1")
    private static let keikyuLetterBlue = Color(hex: "#1E50A2")
    private static let seibuLetterColor = Color(hex: "#414D66")
    private static let rinkaiLightBlue = Color(hex: "#96C7C1")
    static let minatomiraiWave = Color(hex: "#5FC5EA")
    private static let tamaGreen = Color(hex: "#3C605F")
    static let enodenYellow = Color(hex: "#FFE277")
    static let enodenGreen = Color(hex: "#0C6346")
    static let enodenLetterColor = Color(hex: "#231F20")
    static let seasideIndigo = Color(hex: "#43397E")
    static let yurikamomeRed = Color(hex: "#E60012")


    var body: some View {
        switch symbol {
        case "NT":
            nipporiToneriBadge
        case "R":
            rinkaiBadge
        case "TT":
            tamaBadge
        case "B":
            filledBadge(in: AnyShape(Circle()))
        case "G" where color.isGreenDominant:
            filledBadge(in: AnyShape(Circle()))
        case "SA":
            arakawaSymbolBadge
        case "U":
            yurikamomeSymbolBadge
        case "NS":
            newShuttleBadge
        case "EN":
            enodenBadge
        case "SR":
            // Both SR operators use a thin ring and an unbolded grotesque;
            // only Shibayama sets the letters in the line color.
            srSymbolBadge
        case "KS":
            keiseiBadge(condensed: true)
        case "HS":
            keiseiBadge(condensed: false)
        case "MO":
            squareBadge(cornerRadius: 5.5, borderWidth: 2.6)
        case "TR":
            circleBadge(ringWidth: 2.9, textColor: .black, hind: false, condensed: true)
        case "KK":
            circleBadge(ringWidth: 2.0, textColor: Self.keikyuLetterBlue, hind: true,
                        ringColor: Self.keikyuRingBlue)
        case "SO":
            sotetsuBadge
        case "MM":
            minatomiraiBadge
        case "I":
            mitaSymbolBadge
        case "SL":
            seasideSymbolBadge
        case _ where Self.keioSymbols.contains(symbol):
            circleBadge(ringWidth: 3.0, textColor: color, hind: true)
        case "TX":
            // TX sets a white keyline inside the plate; Tokyu's is plain.
            filledBadge(in: AnyShape(RoundedRectangle(cornerRadius: 5)))
                .overlay(RoundedRectangle(cornerRadius: 3.6)
                    .strokeBorder(Color.white, lineWidth: 1).padding(1.2))
        case _ where Self.tokyuStyleSymbols.contains(symbol):
            filledBadge(in: AnyShape(RoundedRectangle(cornerRadius: 6)),
                        textColor: Self.tokyuLetterColors[symbol] ?? .white)
        case _ where Self.seibuSymbols.contains(symbol):
            seibuTrainBadge
        case _ where Self.odakyuSymbols.contains(symbol):
            squircleBadge(cornerRadius: 10, borderWidth: 2.6, textColor: color)
        case _ where Self.tobuSymbols.contains(symbol):
            squareBadge(cornerRadius: 5.5, borderWidth: 2.6)
        case "JR":
            squareBadge(cornerRadius: 3, borderWidth: 2.6, textColor: color)
        case _ where symbol.hasPrefix("J"):
            squareBadge(cornerRadius: 3, borderWidth: 2.6)
        default:
            circleBadge(ringWidth: 4.7, textColor: .black, hind: false)
        }
    }

    private var rinkaiBadge: some View {
        Text(symbol)
            .font(.custom("Helvetica-Bold", fixedSize: 10))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background {
                ZStack {
                    Circle()
                        .fill(Self.rinkaiLightBlue)
                    Circle()
                        .fill(Color.white)
                        .padding(2.6)
                    Circle()
                        .fill(color)
                        .padding(3.4)
                }
            }
    }

    private func circleBadge(ringWidth: CGFloat, textColor: Color, hind: Bool,
                             ringColor: Color? = nil, condensed: Bool = false) -> some View {
        symbolText(color: textColor, inset: ringWidth + 1, hind: hind, condensed: condensed)
            // Futura-Bold's "M" sits low; lift it to stay optically centered
            .offset(y: !hind && symbol == "M" ? -0.6 : 0)
            .frame(width: 24, height: 24)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(ringColor ?? color, lineWidth: ringWidth)
            )
    }

    private func squareBadge(cornerRadius: CGFloat, borderWidth: CGFloat,
                             textColor: Color = .black) -> some View {
        symbolText(color: textColor, inset: borderWidth + 1, hind: true)
            .frame(width: 24, height: 24)
            .background(Color.white, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(color, lineWidth: borderWidth)
            )
    }

    private var tamaBadge: some View {
        symbolText(color: Self.tamaGreen, inset: 3.6, hind: true)
            .frame(width: 24, height: 24)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Self.tamaGreen, lineWidth: 2.6)
            )
    }

    private func squircleBadge(cornerRadius: CGFloat, borderWidth: CGFloat,
                               textColor: Color) -> some View {
        symbolText(color: textColor, inset: borderWidth + 1, hind: true)
            .frame(width: 24, height: 24)
            .background(Color.white, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(color, lineWidth: borderWidth)
            )
    }

    private var seibuTrainBadge: some View {
        ZStack {
            LCDSeibuTrainLegs()
                .fill(color)

            UnevenRoundedRectangle(
                topLeadingRadius: 7.2, bottomLeadingRadius: 1.7,
                bottomTrailingRadius: 1.7, topTrailingRadius: 7.2,
                style: .continuous
            )
            .fill(color)
            .frame(width: 19.7, height: 16.8)
            .offset(y: -3.6)

            RoundedRectangle(cornerRadius: 2.4, style: .continuous)
                .fill(Color.white)
                .frame(width: 14.4, height: 9.1)
                .offset(y: -5.3)

            Text(symbol)
                .font(.custom("Hind-Bold", fixedSize: 7.2))
                .kerning(symbol.count > 1 ? -0.4 : 0)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.black)
                .frame(width: 13.4)
                .offset(y: -4.7)

            ForEach([-1.0, 1.0], id: \.self) { side in
                Circle()
                    .fill(Color.white)
                    .frame(width: 2.6, height: 2.6)
                    .offset(x: side * 4.8, y: 2.4)
            }
        }
        .frame(width: 24, height: 24)
    }

    private var nipporiToneriBadge: some View {
        symbolText(color: .black, inset: 4.5, hind: true)
            .frame(width: 24, height: 24)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 3.8))
            .overlay(
                RoundedRectangle(cornerRadius: 3.8)
                    .strokeBorder(color, lineWidth: 1.8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 1.8)
                    .strokeBorder(Color(hex: "#69B444"), lineWidth: 1.1)
                    .padding(2.9)
            )
    }

    private func keiseiBadge(condensed: Bool) -> some View {
        Text(symbol)
            .font(.system(size: symbol.count > 1 ? 11 : 13.5, weight: .bold)
                .width(condensed ? .condensed : .standard))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(color)
            .padding(.horizontal, 3.4)
            .frame(width: 24, height: 24)
            .background(Color.white, in: Circle())
            .overlay(
                // Thicker than before, but lighter than the Metro ring (4.7)
                Circle()
                    .strokeBorder(color, lineWidth: 3.1)
            )
    }

    private func filledBadge(in shape: AnyShape, textColor: Color = .white) -> some View {
        symbolText(color: textColor, inset: 3, hind: true)
            .frame(width: 24, height: 24)
            .background(color, in: shape)
    }

    private var arakawaSymbolBadge: some View {
        symbolText(color: .black, inset: 6, hind: true)
            .frame(width: 24, height: 24)
            .background {
                ZStack {
                    Circle().fill(color)
                    LCDSakuraBlossom().fill(Color.white).padding(1.5)
                }
            }
    }

    private var yurikamomeSymbolBadge: some View {
        // The line mark is a plain filled disc; the red bar belongs to the
        // station number badge only.
        symbolText(color: .white, inset: 3, hind: false)
            .frame(width: 24, height: 24)
            .background(color, in: Circle())
    }

    private var srSymbolBadge: some View {
        Text(symbol)
            .font(.system(size: color.isShibayamaGreen ? 16 : 11.5,
                          weight: color.isShibayamaGreen ? .medium : .regular)
                .width(color.isShibayamaGreen ? .condensed : .standard))
            .lineLimit(1).minimumScaleFactor(0.5)
            .foregroundColor(color.isShibayamaGreen ? color : .black)
            .frame(width: 24, height: 24)
            .background(Color.white, in: Circle())
            .overlay(Circle().strokeBorder(color,
                lineWidth: color.isShibayamaGreen ? 1.5 : 2.5))
    }

    private var mitaSymbolBadge: some View {
        LCDSerifI()
            .fill(Color.black)
            .frame(width: 6, height: 8.8)
            .frame(width: 24, height: 24)
            .background(Color.white, in: Circle())
            .overlay(Circle().strokeBorder(color, lineWidth: 4.7))
    }

    private var seasideSymbolBadge: some View {
        Text(symbol)
            .font(.custom("Helvetica-Bold", fixedSize: 9.5))
            .lineLimit(1).minimumScaleFactor(0.5)
            .foregroundColor(.white)
            .offset(y: -2)
            .frame(width: 24, height: 24)
            .background {
                ZStack {
                    Circle().fill(Color.white)
                    LCDSeasideWave().fill(Self.seasideIndigo).clipShape(Circle()).padding(24 * 0.075)
                    Circle().strokeBorder(Self.seasideIndigo, lineWidth: 24 * 0.026)
                }
            }
    }

    private var enodenBadge: some View {
        symbolText(color: Self.enodenLetterColor, inset: 3.4, hind: false)
            .frame(width: 24, height: 24)
            .background {
                ZStack {
                    Circle().fill(Self.enodenYellow)
                    Circle().fill(Self.enodenGreen).padding(24 * 0.05)
                    Circle().fill(Color.white).padding(24 * 0.10)
                }
            }
    }

    private var newShuttleBadge: some View {
        Text(symbol)
            .font(.system(size: 10, weight: .bold).width(.expanded))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(.white)
            .padding(.horizontal, 3)
            .frame(width: 24, height: 24)
            .background(color, in: LCDFlatTopHexagon())
    }

    /// みなとみらい線's line mark is a disc carrying a single large M.
    private var minatomiraiBadge: some View {
        Text("M")
            .font(.custom("Futura-Bold", fixedSize: 14.5))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(.white)
            .offset(y: -0.4)   // Futura's M sits low in its line box
            .frame(width: 24, height: 24)
            .background(color, in: Circle())
    }

    private var sotetsuBadge: some View {
        VStack(spacing: 1.5) {
            Text(symbol)
                .font(.system(size: 8.5, weight: .bold))
                .fontWidth(.expanded)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.white)
            Rectangle()
                .fill(Color(hex: "#EE7B01"))
                .frame(width: 13.5, height: 1.4)
        }
        .frame(width: 24, height: 24)
        .background(color, in: RoundedRectangle(cornerRadius: 5))
    }

    private func symbolText(color: Color, inset: CGFloat, hind: Bool,
                            condensed: Bool = false) -> some View {
        let size: CGFloat = symbol.count > 1 ? 13.875 : 15
        return Text(symbol)
            .font(condensed
                  ? .system(size: symbol.count > 1 ? 11 : 13.5, weight: .bold).width(.condensed)
                  : hind
                    ? .custom("Hind-Bold", fixedSize: size)
                    : .custom("Futura-Bold", fixedSize: symbol.count > 1 ? 8.25 : 11.25))
            .kerning(symbol.count > 1 ? -0.4 : 0)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(color)
            // Hind's tall metrics leave caps 0.085em above the box center
            .offset(y: hind ? size * 0.085 : 0)
            .padding(.horizontal, inset)
    }
}

extension LCDLineSymbolBadge {
    /// Scales the fixed 24pt badge rather than re-deriving its metrics.
    @ViewBuilder
    func sized(_ dimension: CGFloat) -> some View {
        if dimension == 24 {
            self
        } else {
            scaleEffect(dimension / 24)
                .frame(width: dimension, height: dimension)
        }
    }
}

// MARK: - LCD Station Number Badge

/// Self-contained port of the app's StationNumberBadge (e.g. "JJ08"),
/// parameterized by dimension; keep the operator styles in sync with it.
struct LCDStationNumberBadge: View {
    let code: String
    let color: Color
    var dimension: CGFloat = 22

    private static let squarePrefixes: Set<String> = [
        // Tobu
        "TS", "TI", "TN", "TD", "TJ",
        // Tokyo Monorail's plate is the same rounded square
        "MO",
    ]
    private static let splitPrefixes: Set<String> = [
        // Odakyu
        "OH", "OE", "OT",
    ]
    private static let filledSquarePrefixes: Set<String> = [
        // Tokyu
        "TY", "DT", "MG", "OM", "IK", "SG", "TM", "KD", "SH",
        // Tsukuba Express (same filled-square style as Tokyu)
        "TX",
    ]
    private static let seibuPrefixes: Set<String> = [
        "SI", "SS", "SK", "ST", "SW", "SY",
    ]
    // Setagaya's yellow plate carries a dark grey code, not white.
    private static let filledLetterColors: [String: Color] = ["SG": Color(hex: "#595757")]
    private static let keioPrefixes: Set<String> = ["KO", "IN"]
    private static let keiseiStylePrefixes: Set<String> = ["KS", "HS"]

    private static let nipporiToneriGreen = Color(hex: "#69B444")
    private static let keikyuRingBlue = Color(hex: "#00A7E1")
    private static let keikyuLetterBlue = Color(hex: "#1E50A2")
    private static let seibuLetterColor = Color(hex: "#111D16")
    private static let sotetsuOrange = Color(hex: "#EE7B01")
    private static let minatomiraiNavy = Color(hex: "#1F2A54")
    private static let rinkaiLightBlue = Color(hex: "#96C7C1")
    static let minatomiraiWave = Color(hex: "#5FC5EA")
    private static let tamaGreen = Color(hex: "#3C605F")
    static let enodenYellow = Color(hex: "#FFE277")
    static let enodenGreen = Color(hex: "#0C6346")
    static let enodenLetterColor = Color(hex: "#231F20")
    static let seasideIndigo = Color(hex: "#43397E")
    static let yurikamomeRed = Color(hex: "#E60012")


    private var parsed: (prefix: String, number: String) {
        let letters = code.prefix(while: \.isLetter)
        let digits = code.drop(while: \.isLetter)
        return (String(letters), String(digits))
    }

    var body: some View {
        let (prefix, number) = parsed

        if code.isEmpty {
            EmptyView()
        } else if prefix.hasPrefix("J") || Self.squarePrefixes.contains(prefix) {
            // Tobu's plate is rounder than JR's.
            squareBadge(prefix: prefix, number: number,
                        cornerRadius: Self.squarePrefixes.contains(prefix) ? dimension * 0.26 : nil)
        } else if Self.seibuPrefixes.contains(prefix) {
            seibuBadge(prefix: prefix, number: number)
        } else if Self.filledSquarePrefixes.contains(prefix) {
            filledSquareBadge(prefix: prefix, number: number)
        } else if prefix == "MM" {
            minatomiraiBadge(prefix: prefix, number: number)
        } else if prefix == "KK" {
            keikyuBadge(prefix: prefix, number: number)
        } else if Self.keioPrefixes.contains(prefix) {
            keioBadge(prefix: prefix, number: number)
        } else if prefix == "SO" {
            sotetsuBadge(prefix: prefix, number: number)
        } else if Self.splitPrefixes.contains(prefix) {
            squircleBadge(prefix: prefix, number: number)
        } else if Self.keiseiStylePrefixes.contains(prefix) {
            keiseiBadge(prefix: prefix, number: number, condensed: prefix != "HS")
        } else if prefix == "TR" {
            condensedCircleBadge(prefix: prefix, number: number, ringWidth: dimension * 0.081)
        } else if prefix == "NT" {
            nipporiToneriBadge(prefix: prefix, number: number)
        } else if prefix == "R" {
            rinkaiBadge(prefix: prefix, number: number)
        } else if prefix == "TT" {
            tamaBadge(prefix: prefix, number: number)
        } else if prefix == "B" || (prefix == "G" && color.isGreenDominant) {
            yokohamaBadge(prefix: prefix, number: number)
        } else if prefix == "SA" {
            arakawaBadge(prefix: prefix, number: number)
        } else if prefix == "U" {
            yurikamomeBadge(prefix: prefix, number: number)
        } else if prefix == "NS" {
            newShuttleBadge(prefix: prefix, number: number)
        } else if prefix == "EN" {
            enodenBadge(prefix: prefix, number: number)
        } else if prefix == "SL" {
            seasideBadge(number: number)
        } else if prefix == "SR" {
            srBadge(prefix: prefix, number: number,
                    letterColor: color.isShibayamaGreen ? color : .black)
        } else if prefix == "I" {
            mitaBadge(number: number)
        } else {
            circleBadge(prefix: prefix, number: number)
        }
    }

    // MARK: Tama Monorail: JR-style square, green frame and code

    @ViewBuilder
    private func tamaBadge(prefix: String, number: String) -> some View {
        let d = dimension
        let prefixSize = d * 0.58
        let numberSize = d * 0.79

        VStack(spacing: 1) {
            Text(prefix)
                .font(.custom("Hind-Bold", fixedSize: prefixSize))
                .offset(y: prefixSize * 0.24)
                .frame(maxWidth: .infinity)
                .frame(height: prefixSize * 0.75)

            Text(number)
                .font(.custom("Hind-Bold", fixedSize: numberSize))
                .offset(y: numberSize * -0.06)
                .frame(maxWidth: .infinity)
                .frame(height: numberSize * 0.75)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        // Signage sets the code in black; only the frame is green.
        .foregroundColor(.black)
        .frame(width: d, height: d)
        // JR-style: rounded outer plate, sharp-cornered white core.
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: d * 0.21).fill(Self.tamaGreen)
                Rectangle().fill(Color.white).padding(d * 0.107)
            }
        }
    }

    // MARK: Yokohama Municipal: filled line-color circle, white stacked code

    @ViewBuilder
    private func newShuttleBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.system(size: d * 0.34, weight: .bold).width(.expanded))
                .frame(height: d * 0.34)
                .offset(y: d * 0.04)

            Text(number)
                .font(.system(size: d * 0.38, weight: .bold).width(.expanded))
                .frame(height: d * 0.38)
                .offset(y: d * -0.02)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .foregroundColor(.white)
        .frame(width: d, height: d)
        .background(color, in: LCDFlatTopHexagon())
    }

    private func condensedCircleBadge(prefix: String, number: String,
                                      ringWidth: CGFloat? = nil) -> some View {
        let d = dimension
        let big = ringWidth != nil   // thin-ringed lines have room for a larger code

        return VStack(spacing: 0) {
            Text(prefix)
                .font(.system(size: d * (big ? 0.40 : 0.32), weight: .bold).width(.condensed))
                .frame(height: d * (big ? 0.38 : 0.36))
                .offset(y: d * 0.04)

            Text(number)
                .font(.system(size: d * (big ? 0.46 : 0.36), weight: .bold).width(.condensed))
                .frame(height: d * (big ? 0.44 : 0.40))
                .offset(y: d * -0.04)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(.black)
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(color, lineWidth: d * 0.13)
        )
    }

    @ViewBuilder
    private func yokohamaBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Helvetica-Bold", fixedSize: d * 0.42))
                .frame(height: d * 0.36)
                .offset(y: d * 0.04)

            Text(number)
                .font(.custom("Helvetica-Bold", fixedSize: d * 0.58))
                .frame(height: d * 0.46)
                .offset(y: d * -0.02)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(.white)
        .frame(width: d, height: d)
        .background(color, in: Circle())
    }

    // MARK: JR East / Tobu: rounded square frame

    @ViewBuilder
    private func squareBadge(prefix: String, number: String,
                             cornerRadius: CGFloat? = nil) -> some View {
        let d = dimension
        let prefixSize = d * 0.58
        let numberSize = d * 0.79

        VStack(spacing: 1) {
            Text(prefix)
                .font(.custom("Hind-Bold", fixedSize: prefixSize))
                .offset(y: prefixSize * 0.24)
                .frame(maxWidth: .infinity)
                .frame(height: prefixSize * 0.75)

            Text(number)
                .font(.custom("Hind-Bold", fixedSize: numberSize))
                .offset(y: numberSize * -0.06)
                .frame(maxWidth: .infinity)
                .frame(height: numberSize * 0.75)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(.black)
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? d * 0.21))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius ?? d * 0.21)
                .strokeBorder(color, lineWidth: d * 0.107)
        )
    }

    // MARK: Tokyu: filled rounded square

    @ViewBuilder
    private func filledSquareBadge(prefix: String, number: String) -> some View {
        let d = dimension
        let prefixSize = d * 0.74
        let numberSize = d * 0.88

        VStack(spacing: 1) {
            Text(prefix)
                .font(.custom("Hind-Bold", fixedSize: prefixSize))
                .offset(y: prefixSize * 0.24)
                .frame(maxWidth: .infinity)
                .frame(height: prefixSize * 0.65)

            Text(number)
                .font(.custom("Hind-Bold", fixedSize: numberSize))
                .offset(y: numberSize * -0.02)
                .frame(maxWidth: .infinity)
                .frame(height: numberSize * 0.75)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Self.filledLetterColors[prefix] ?? .white)
        .frame(width: d, height: d)
        .background(color, in: RoundedRectangle(cornerRadius: d * (prefix == "TX" ? 0.20 : 0.25)))
        // TX sets a white keyline inside the plate; Tokyu's is plain.
        .overlay {
            if prefix == "TX" {
                RoundedRectangle(cornerRadius: d * 0.15)
                    .strokeBorder(Color.white, lineWidth: d * 0.045)
                    .padding(d * 0.05)
            }
        }
    }

    // MARK: Minatomirai: two-tone filled square

    @ViewBuilder
    private func minatomiraiBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Helvetica-Bold", fixedSize: d * 0.30))
                .frame(maxWidth: .infinity)
                .frame(height: d * 0.36)

            Text(number)
                .font(.custom("Helvetica-Bold", fixedSize: d * 0.52))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(.white)
        .frame(width: d, height: d)
        .background {
            ZStack(alignment: .top) {
                color
                LCDMinatomiraiWave()
                    .fill(Self.minatomiraiWave)
                    .frame(height: d * 0.20)
                    .offset(y: d * 0.26)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: d * 0.16))
    }

    // MARK: Keikyu: white circle, light-blue ring, blue code

    @ViewBuilder
    private func keikyuBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Hind", fixedSize: d * 0.50))
                .offset(y: d * 0.04)
                .frame(height: d * 0.32)

            Text(number)
                .font(.custom("Hind-Semibold", fixedSize: d * 0.94))
                .offset(y: d * 0.01)
                .frame(height: d * 0.46)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Self.keikyuLetterBlue)
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Self.keikyuRingBlue, lineWidth: d * 0.08)
        )
    }

    // MARK: Keio: split circle

    @ViewBuilder
    private func keioBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Hind-Bold", fixedSize: d * 0.62))
                .offset(y: d * 0.52 * 0.13)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: d * 0.44)
                .background(color)

            Text(number)
                .font(.custom("Hind-Bold", fixedSize: d * 0.84))
                .offset(y: d * 0.44 * -0.02)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, maxHeight: d * 0.5)
                .background(Color.white)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(width: d, height: d)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(color, lineWidth: d * 0.06)
        )
    }

    // MARK: Sotetsu: filled navy square, orange rule

    @ViewBuilder
    private func sotetsuBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: d * 0.07) {
            Text(prefix)
                .font(.system(size: d * 0.50, weight: .semibold))
                .fontWidth(.expanded)
                .frame(height: d * 0.20)

            Rectangle()
                .fill(Self.sotetsuOrange)
                .frame(width: d * 0.9, height: max(1, d * 0.04))

            Text(number)
                .font(.system(size: d * 0.93, weight: .regular))
                .frame(height: d * 0.40)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(.white)
        .frame(width: d, height: d)
        .background(color, in: RoundedRectangle(cornerRadius: d * 0.2))
    }

    // MARK: Metro / Toei: circle ring

    @ViewBuilder
    private func circleBadge(prefix: String, number: String,
                             letterColor: Color = .black) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Futura-Bold", fixedSize: d * 0.38))
                // Bound the width so a three-letter prefix (SMR) is scaled down
                // to clear the ring instead of running under it.
                .frame(width: d * 0.58, height: d * 0.42)
                .offset(y: d * 0.039)

            Text(number)
                .font(.custom("Futura-Bold", fixedSize: d * 0.38))
                .frame(height: d * 0.42)
                .offset(y: d * -0.068)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.45)
        .foregroundColor(letterColor)
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(color, lineWidth: d * 0.13)
        )
    }

    // MARK: Toden Arakawa: filled cherry blossom

    @ViewBuilder
    private func arakawaBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Hind", fixedSize: d * 0.40))
                .frame(width: d * 0.58, height: d * 0.24)
                .offset(y: d * 0.075)

            Text(number)
                .font(.custom("Hind", fixedSize: d * 0.74))
                .kerning(d * 0.02)
                .frame(height: d * 0.50)
                .offset(y: d * 0.015)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        // Signage sets the code in black on the rose blossom.
        .foregroundColor(.black)
        .frame(width: d, height: d)
        .background {
            ZStack {
                Circle().fill(color)
                LCDSakuraBlossom().fill(Color.white).padding(d * 0.06)
            }
        }
    }

    // MARK: Yurikamome: filled circle split by a red bar

    @ViewBuilder
    private func yurikamomeBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.system(size: d * 0.68, weight: .black))
                .frame(height: d * 0.36)
                .offset(y: d * -0.005)

            Rectangle().fill(Self.yurikamomeRed)
                .frame(width: d * 0.88, height: d * 0.06)

            Text(number)
                .font(.system(size: d * 0.74, weight: .black))
                .frame(height: d * 0.38)
                .offset(y: d * -0.02)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .foregroundColor(.white)
        .frame(width: d, height: d)
        .background(color, in: Circle())
        .overlay(Circle().strokeBorder(Color.white, lineWidth: d * 0.05))
    }

    // MARK: Shibayama: thin line-color ring, code in the line color

    @ViewBuilder
    private func srBadge(prefix: String, number: String, letterColor: Color) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.system(size: d * (color.isShibayamaGreen ? 0.50 : 0.36),
                      weight: color.isShibayamaGreen ? .medium : .regular)
                    .width(color.isShibayamaGreen ? .condensed : .standard))
                .frame(width: d * 0.58, height: d * 0.28)
                .offset(y: d * 0.05)

            Text(number)
                .font(.system(size: d * (color.isShibayamaGreen ? 0.86 : 0.58), weight: .regular)
                    .width(color.isShibayamaGreen ? .condensed : .standard))
                .frame(height: d * 0.58)
                .offset(y: d * -0.03)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .foregroundColor(letterColor)
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(color,
            lineWidth: d * (color.isShibayamaGreen ? 0.062 : 0.105)))
    }

    // MARK: Toei Mita: the "I" is drawn, not set

    @ViewBuilder
    private func mitaBadge(number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            LCDSerifI()
                .fill(Color.black)
                .frame(width: d * 0.175, height: d * 0.235)
                .frame(height: d * 0.34)
                .offset(y: d * 0.025)

            Text(number)
                .font(.custom("Futura-Bold", fixedSize: d * 0.38))
                .frame(height: d * 0.42)
                .offset(y: d * -0.06)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(.black)
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(color, lineWidth: d * 0.13))
    }

    // MARK: Enoden: white core, green ring inside a pale yellow outer ring

    @ViewBuilder
    private func enodenBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Helvetica-Bold", fixedSize: d * 0.30))
                .frame(width: d * 0.56, height: d * 0.30)
                .offset(y: d * 0.05)

            Text(number)
                .font(.custom("Helvetica-Bold", fixedSize: d * 0.56))
                .frame(width: d * 0.66, height: d * 0.48)
                .offset(y: d * -0.02)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .foregroundColor(Self.enodenLetterColor)
        .frame(width: d, height: d)
        .background {
            ZStack {
                Circle().fill(Self.enodenYellow)
                Circle().fill(Self.enodenGreen).padding(d * 0.05)
                Circle().fill(Color.white).padding(d * 0.10)
            }
        }
    }

    // MARK: Seaside Line: filled indigo disc over a white wave, number only

    @ViewBuilder
    private func seasideBadge(number: String) -> some View {
        let d = dimension

        // Signage sets 1–9 without a leading zero.
        Text(number.drop(while: { $0 == "0" }))
            .font(.custom("Helvetica-Bold", fixedSize: d * 0.58))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundColor(.white)
            .offset(y: d * -0.105)
            .frame(width: d, height: d)
            .background {
                ZStack {
                    Circle().fill(Color.white)
                    LCDSeasideWave().fill(Self.seasideIndigo)
                        .clipShape(Circle())
                        .padding(d * 0.075)
                    Circle().strokeBorder(Self.seasideIndigo, lineWidth: d * 0.026)
                }
            }
    }

    // MARK: Rinkai: filled navy circle, light blue outer ring

    @ViewBuilder
    private func rinkaiBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Helvetica-Bold", fixedSize: d * 0.46))
                .frame(height: d * 0.24)
                .offset(y: d * 0.005)

            Text(number)
                .font(.custom("Helvetica-Bold", fixedSize: d * 0.64))
                .frame(height: d * 0.36)
                .offset(y: d * 0.008)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(.white)
        .frame(width: d, height: d)
        .background {
            ZStack {
                Circle()
                    .fill(Self.rinkaiLightBlue)
                Circle()
                    .fill(Color.white)
                    .padding(d * 0.11)
                Circle()
                    .fill(color)
                    .padding(d * 0.14)
            }
        }
    }

    // MARK: Nippori-Toneri Liner: pink outer + green inner border

    @ViewBuilder
    private func nipporiToneriBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Helvetica", fixedSize: d * 0.4))
                .offset(y: d * 0.01)
                .frame(height: d * 0.28)

            Text(number)
                .font(.custom("Helvetica", fixedSize: d * 0.6))
                .fontWeight(.bold)
                .offset(y: d * 0.36 * 0.02)
                .frame(height: d * 0.34)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(.black)
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: d * 0.156))
        .overlay(
            RoundedRectangle(cornerRadius: d * 0.156)
                .strokeBorder(color, lineWidth: d * 0.075)
        )
        .overlay(
            RoundedRectangle(cornerRadius: d * 0.075)
                .strokeBorder(Self.nipporiToneriGreen, lineWidth: d * 0.044)
                .padding(d * 0.119)
        )
    }

    // MARK: Keisei / Hokuso: circle ring, line-color code

    @ViewBuilder
    private func keiseiBadge(prefix: String, number: String, condensed: Bool = true) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            // Keisei's letters are bold condensed, matching the line symbol badge;
            // Hokuso sets the same plate at normal width. The number stays Helvetica.
            Text(prefix)
                .font(.system(size: d * 0.30, weight: .bold)
                    .width(condensed ? .condensed : .standard))
                .frame(height: d * 0.34)
                .offset(y: d * 0.021)

            Text(number)
                .font(.custom("Helvetica", fixedSize: d * 0.54))
                .frame(height: d * 0.46)
                .offset(y: d * -0.021)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(color)
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(color, lineWidth: d * 0.09)
        )
    }

    // MARK: Seibu: split rounded square

    @ViewBuilder
    private func seibuBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Hind-Bold", fixedSize: d * 0.58))
                .offset(y: d * 0.34 * 0.13)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: d * 0.42)
                .background(color)

            Text(number)
                .font(.custom("Hind-Bold", fixedSize: d * 0.82))
                .offset(y: d * 0.52 * 0.02)
                .foregroundColor(Self.seibuLetterColor)
                .frame(maxWidth: .infinity, maxHeight: d * 0.5)
                .background(Color.white)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(width: d, height: d)
        .clipShape(RoundedRectangle(cornerRadius: d * 0.25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: d * 0.25, style: .continuous)
                .strokeBorder(color, lineWidth: d * 0.09)
        )
    }

    // MARK: Odakyu: very-round squircle, line-color code over a rule

    @ViewBuilder
    private func squircleBadge(prefix: String, number: String) -> some View {
        let d = dimension

        VStack(spacing: d * 0.04) {
            Text(prefix)
                .font(.custom("Hind-Bold", fixedSize: d * 0.60))
                .offset(y: d * 0.30 * 0.085)
                .frame(height: d * 0.25)

            Text(number)
                .font(.custom("Hind-Bold", fixedSize: d * 0.90))
                .offset(y: d * 0.058)
                .frame(height: d * 0.32)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(color)
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: d * 0.45, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: d * 0.45, style: .continuous)
                .strokeBorder(color, lineWidth: d * 0.09)
        )
    }
}

// MARK: - Seibu Train Legs (LCD copy)

/// The splayed legs under the Seibu train-front logo. Duplicated from the
/// main app's SeibuTrainLegs because the LCD target is self-contained.
/// Saitama New Shuttle's plate. Duplicated from the app target, which the widget can't import.
/// 都電荒川線's badge is a five-petal cherry blossom, not a circle.
struct LCDSerifI: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        // One stroke weight, used for the stem and both bars, so they match.
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

struct LCDSakuraBlossom: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var path = Path()
        // Core disc plus five overlapping lobes; the non-zero winding unions them.
        path.addEllipse(in: CGRect(x: c.x - r * 0.52, y: c.y - r * 0.52,
                                   width: r * 1.04, height: r * 1.04))
        for k in 0..<5 {
            let a = -CGFloat.pi / 2 + CGFloat(k) * 2 * .pi / 5
            let pc = CGPoint(x: c.x + cos(a) * r * 0.62, y: c.y + sin(a) * r * 0.62)
            path.addEllipse(in: CGRect(x: pc.x - r * 0.38, y: pc.y - r * 0.38,
                                       width: r * 0.76, height: r * 0.76))
        }
        return path
    }
}

/// The swoosh across みなとみらい線's navy band.
struct LCDMinatomiraiWave: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        // One full sine period spanning the whole width, drawn as a band that
        // tapers towards each edge and is thickest in the middle.
        func wave(_ side: CGFloat) -> [CGPoint] {
            let inset: CGFloat = 0.07                       // keep it off the plate edges
            return stride(from: 0.0, through: 1.0, by: 0.025).map { t in
                let taper = 0.22 + 0.78 * sin(.pi * t)          // thin at the ends
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

struct LCDSeasideWave: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func p(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + w * fx, y: rect.minY + h * fy)
        }
        var path = Path()
        path.move(to: rect.origin)
        path.addLine(to: p(1, 0))
        path.addLine(to: p(1, 0.80))
        path.addQuadCurve(to: p(0.72, 0.755), control: p(0.86, 0.72))
        path.addQuadCurve(to: p(0.46, 0.815), control: p(0.60, 0.875))
        path.addQuadCurve(to: p(0.20, 0.745), control: p(0.32, 0.695))
        path.addQuadCurve(to: p(0, 0.80), control: p(0.08, 0.815))
        path.closeSubpath()
        return path
    }
}

struct LCDFlatTopHexagon: Shape {
    /// New Shuttle's plate is wider than tall (1000:860) with the flats on the
    /// very top and bottom edges and the points 24.7% in from each side.
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = min(rect.height, w / 1.163)
        let top = rect.midY - h / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.247, y: top))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.247, y: top))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.247, y: top + h))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.247, y: top + h))
        path.closeSubpath()
        return path
    }
}

struct LCDSeibuTrainLegs: Shape {
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
