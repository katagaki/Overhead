import SwiftUI
import Backbone

// MARK: - Station Number Badge

/// Renders station number badges matching each operator's real signage.
struct StationNumberBadge: View {
    let code: String
    let color: Color
    var opacity: Double = 1.0
    var size: BadgeSize = .regular
    var stationName: String? = nil
    /// Forces a shape for user-created lines, whose codes match no operator.
    var styleOverride: BadgeStyle? = nil

    enum BadgeSize {
        case compact  // For list rows
        case regular  // For journey view station labels
    }

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
    // Setagaya's yellow plate carries dark grey code, not white.
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
    private static let tamaGreen = Color(hex: "#3C605F")  // green even though the route line is orange

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

    /// Plate corner radius as a fraction of the badge side, per style.
    private static let roundedRatio: CGFloat = 6 / 28
    private static let sharpRatio: CGFloat = 2 / 28
    private static let filledRatio: CGFloat = 0.25

    /// For callers drawing their own ring around the plate — an outline at the
    /// wrong radius reads as a second, mismatched badge.
    static func cornerRadiusRatio(code: String, color: Color, styleOverride: BadgeStyle? = nil) -> CGFloat {
        if rendersAsCircle(code: code, color: color, styleOverride: styleOverride) { return 0.5 }
        switch styleOverride {
        case .rounded: return roundedRatio
        case .square: return sharpRatio
        case .filled: return filledRatio
        default: return roundedRatio
        }
    }

    /// Mirrors `body`'s dispatch; `color` disambiguates the shared "G" prefix.
    static func rendersAsCircle(code: String, color: Color, styleOverride: BadgeStyle? = nil) -> Bool {
        if let styleOverride { return styleOverride == .ring }
        let prefix = String(code.prefix(while: \.isLetter))
        if prefix.hasPrefix("J") || squarePrefixes.contains(prefix) { return false }
        if seibuPrefixes.contains(prefix) { return false }
        if filledSquarePrefixes.contains(prefix) { return false }
        if splitPrefixes.contains(prefix) { return false }
        if ["MM", "SO", "NT", "TT", "NS"].contains(prefix) { return false }
        return true
    }

    var body: some View {
        let (prefix, number) = parsed

        if let styleOverride {
            switch styleOverride {
            case .rounded: squareBadge(prefix: prefix, number: number)
            case .ring: circleBadge(prefix: prefix, number: number)
            case .filled: filledSquareBadge(prefix: prefix, number: number)
            case .square: plainSquareBadge(prefix: prefix, number: number)
            }
        } else {
            operatorBadge(prefix: prefix, number: number)
        }
    }

    @ViewBuilder
    private func operatorBadge(prefix: String, number: String) -> some View {
        if prefix.hasPrefix("J") || Self.squarePrefixes.contains(prefix) {
            squareBadge(prefix: prefix, number: number)
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
            // Hokuso shares the ringed circle but sets its code at normal width.
            keiseiBadge(prefix: prefix, number: number, condensed: prefix != "HS")
        } else if prefix == "TR" {
            // Toyo Rapid: Metro-style ring, condensed system face.
            circleBadge(prefix: prefix, number: number, condensed: true)
        } else if prefix == "NT" {
            nipporiToneriBadge(prefix: prefix, number: number)
        } else if prefix == "R" {
            rinkaiBadge(prefix: prefix, number: number)
        } else if prefix == "TT" {
            tamaBadge(prefix: prefix, number: number)
        } else if prefix == "B" || (prefix == "G" && color.isGreenDominant) {
            // "G" is shared with Tokyo Metro Ginza (orange); color disambiguates.
            yokohamaBadge(prefix: prefix, number: number)
        } else if prefix == "NS" {
            newShuttleBadge(prefix: prefix, number: number)
        } else {
            circleBadge(prefix: prefix, number: number)
        }
    }

    // MARK: - Tama Monorail: JR-style square, green frame and code

    @ViewBuilder
    private func tamaBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension
        let prefixSize = d * 0.58
        let numberSize = d * 0.79

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
        .foregroundColor(Self.tamaGreen.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Self.tamaGreen.opacity(opacity), lineWidth: 3)
        )
    }

    // MARK: - New Shuttle: filled line-color hexagon, white stacked italic code

    @ViewBuilder
    private func newShuttleBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.system(size: d * 0.30, weight: .bold).italic())
                .frame(height: d * 0.40)
                .offset(y: d * 0.05)

            Text(number)
                .font(.system(size: d * 0.36, weight: .bold).italic())
                .frame(height: d * 0.44)
                .offset(y: d * -0.03)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Color.white.opacity(opacity))
        .frame(width: d, height: d)
        .background(color.opacity(opacity), in: FlatTopHexagon())
    }

    // MARK: - Yokohama Municipal: filled line-color circle, white stacked code

    @ViewBuilder
    private func yokohamaBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Helvetica-Bold", size: d * 0.34))
                .frame(height: d * 0.44)
                .offset(y: d * 0.04)

            Text(number)
                .font(.custom("Helvetica-Bold", size: d * 0.44))
                .frame(height: d * 0.50)
                .offset(y: d * -0.02)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Color.white.opacity(opacity))
        .frame(width: d, height: d)
        .background(color.opacity(opacity), in: Circle())
    }

    // MARK: - Code stack

    /// Prefix over number. A blank prefix (custom lines with no symbol) collapses
    /// to one centered number — the empty row otherwise sinks it and fills the plate.
    @ViewBuilder
    private func codeStack(
        prefix: String, number: String, font: String,
        prefixSize: CGFloat, numberSize: CGFloat, soloSize: CGFloat,
        prefixHeight: CGFloat, numberHeight: CGFloat,
        prefixOffset: CGFloat = 0, numberOffset: CGFloat = 0,
        spacing: CGFloat = 0
    ) -> some View {
        if prefix.isEmpty {
            Text(number)
                .font(.custom(font, size: soloSize))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        } else {
            VStack(spacing: spacing) {
                Text(prefix)
                    .font(.custom(font, size: prefixSize))
                    .offset(y: prefixOffset)
                    .frame(maxWidth: .infinity)
                    .frame(height: prefixHeight)

                Text(number)
                    .font(.custom(font, size: numberSize))
                    .offset(y: numberOffset)
                    .frame(maxWidth: .infinity)
                    .frame(height: numberHeight)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
    }

    // MARK: - JR East / Tobu: Rounded Square Frame

    @ViewBuilder
    private func squareBadge(prefix: String, number: String, textColor: Color = .black) -> some View {
        let d = badgeDimension
        // Generous sizes: Hind's cap height is only 0.678em.
        let prefixSize = d * 0.58
        let numberSize = d * 0.79

        codeStack(prefix: prefix, number: number, font: "Hind-Bold",
                  prefixSize: prefixSize, numberSize: numberSize, soloSize: d * 0.72,
                  prefixHeight: prefixSize * 0.75, numberHeight: numberSize * 0.75,
                  prefixOffset: prefixSize * 0.24, numberOffset: numberSize * -0.06,
                  spacing: 1)
        .foregroundColor(textColor.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(color.opacity(opacity), lineWidth: 3)
        )
    }

    // MARK: - Custom: Thin-Border Sharp Square

    @ViewBuilder
    private func plainSquareBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension
        let prefixSize = d * 0.58
        let numberSize = d * 0.79

        codeStack(prefix: prefix, number: number, font: "Hind-Bold",
                  prefixSize: prefixSize, numberSize: numberSize, soloSize: d * 0.72,
                  prefixHeight: prefixSize * 0.75, numberHeight: numberSize * 0.75,
                  prefixOffset: prefixSize * 0.24, numberOffset: numberSize * -0.06,
                  spacing: 1)
        .foregroundColor(Color.black.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        // Sharp corners leave more white than the rounded style, so the frame
        // runs slightly heavier to keep the core the same visual size.
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(color.opacity(opacity), lineWidth: 3.5)
        )
    }

    // MARK: - Tokyu / Minatomirai: Filled Rounded Square

    @ViewBuilder
    private func filledSquareBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension
        let prefixSize = d * 0.64
        let numberSize = d * 0.76

        codeStack(prefix: prefix, number: number, font: "Hind-Bold",
                  prefixSize: prefixSize, numberSize: numberSize, soloSize: d * 0.70,
                  prefixHeight: prefixSize * 0.65, numberHeight: numberSize * 0.75,
                  prefixOffset: prefixSize * 0.24, numberOffset: numberSize * -0.02,
                  spacing: 1)
        .foregroundColor((Self.filledLetterColors[prefix] ?? .white).opacity(opacity))
        .frame(width: d, height: d)
        .background(color.opacity(opacity), in: RoundedRectangle(cornerRadius: d * 0.25))
    }

    // MARK: - Minatomirai: Two-Tone Filled Square

    @ViewBuilder
    private func minatomiraiBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Helvetica-Bold", size: d * 0.28))
                .frame(maxWidth: .infinity)
                .frame(height: d * 0.38)
                .background(Self.minatomiraiNavy.opacity(opacity))

            Text(number)
                .font(.custom("Helvetica-Bold", size: d * 0.46))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color.opacity(opacity))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Color.white.opacity(opacity))
        .frame(width: d, height: d)
        .clipShape(RoundedRectangle(cornerRadius: d * 0.16))
    }

    // MARK: - Keikyu: White Circle, Light-Blue Ring, Blue Code

    @ViewBuilder
    private func keikyuBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Hind", size: d * 0.60))
                .offset(y: d * 0.30 * 0.24)
                .frame(height: d * 0.4)

            Text(number)
                .font(.custom("Hind-Semibold", size: d * 0.82))
                .offset(y: d * 0.42 * 0.02)
                .frame(height: d * 0.40)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Self.keikyuLetterBlue.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Self.keikyuRingBlue.opacity(opacity), lineWidth: d * 0.08)
        )
    }

    // MARK: - Keio: Split Circle

    @ViewBuilder
    private func keioBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Hind-Bold", size: d * 0.62))
                .offset(y: d * 0.52 * 0.13)
                .foregroundColor(Color.white.opacity(opacity))
                .frame(maxWidth: .infinity)
                .frame(height: d * 0.44)
                .background(color.opacity(opacity))

            Text(number)
                .font(.custom("Hind-Bold", size: d * 0.84))
                .offset(y: d * 0.44 * -0.02)
                .foregroundColor(Color.black.opacity(opacity))
                .frame(maxWidth: .infinity, maxHeight: d * 0.5)
                .background(Color.white)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(width: d, height: d)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(color.opacity(opacity), lineWidth: d * 0.06)
        )
    }

    // MARK: - Sotetsu: Filled Navy Square, Orange Rule

    @ViewBuilder
    private func sotetsuBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        // Expanded-width SF is the closest system substitute for the flat, wide face.
        VStack(spacing: d * 0.07) {
            Text(prefix)
                .font(.system(size: d * 0.50, weight: .semibold))
                .fontWidth(.expanded)
                .frame(height: d * 0.20)

            Rectangle()
                .fill(Self.sotetsuOrange.opacity(opacity))
                .frame(width: d * 0.9, height: max(1, d * 0.04))

            Text(number)
                .font(.system(size: d * 0.93, weight: .regular))
                .frame(height: d * 0.40)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Color.white.opacity(opacity))
        .frame(width: d, height: d)
        .background(color.opacity(opacity), in: RoundedRectangle(cornerRadius: d * 0.2))
    }

    // MARK: - Metro / Toei / Keisei: Circle Ring

    private func circleBadge(prefix: String, number: String, condensed: Bool = false) -> some View {
        let d = badgeDimension

        if condensed {
            return AnyView(condensedCircleBadge(prefix: prefix, number: number))
        }
        return AnyView(codeStack(prefix: prefix, number: number, font: "Futura-Bold",
                  prefixSize: d * 0.38, numberSize: d * 0.38, soloSize: d * 0.50,
                  prefixHeight: d * 0.42, numberHeight: d * 0.42,
                  prefixOffset: 1.10, numberOffset: -1.90)
        .foregroundColor(Color.black.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(color.opacity(opacity), lineWidth: d * 0.13)
        ))
    }

    /// Same ringed circle, set in a condensed system face (Toyo Rapid).
    private func condensedCircleBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        return VStack(spacing: 0) {
            Text(prefix)
                .font(.system(size: d * 0.32, weight: .bold).width(.condensed))
                .frame(height: d * 0.36)
                .offset(y: d * 0.04)

            Text(number)
                .font(.system(size: d * 0.36, weight: .bold).width(.condensed))
                .frame(height: d * 0.40)
                .offset(y: d * -0.04)
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

    // MARK: - Rinkai: Filled Navy Circle, Light Blue Outer Ring

    @ViewBuilder
    private func rinkaiBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Helvetica-Bold", size: d * 0.28))
                .frame(height: d * 0.25)

            Text(number)
                .font(.custom("Helvetica-Bold", size: d * 0.38))
                .frame(height: d * 0.34)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Color.white.opacity(opacity))
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
            .opacity(opacity)
        }
    }

    // MARK: - Nippori-Toneri Liner: Pink Outer + Green Inner Border

    /// Mirrors LineSymbolBadge.nipporiToneriBadge's double border proportions at 32pt.
    @ViewBuilder
    private func nipporiToneriBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Helvetica", size: d * 0.4))
                .offset(y: d * 0.01)
                .frame(height: d * 0.28)

            Text(number)
                .font(.custom("Helvetica", size: d * 0.6))
                .fontWeight(.bold)
                .offset(y: d * 0.36 * 0.02)
                .frame(height: d * 0.34)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Color.black.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: d * 0.156))
        .overlay(
            RoundedRectangle(cornerRadius: d * 0.156)
                .strokeBorder(color.opacity(opacity), lineWidth: d * 0.075)
        )
        .overlay(
            RoundedRectangle(cornerRadius: d * 0.075)
                .strokeBorder(Self.nipporiToneriGreen.opacity(opacity), lineWidth: d * 0.044)
                .padding(d * 0.119)
        )
    }

    // MARK: - Keisei / Hokuso: Circle Ring, Line-Color Helvetica Code

    @ViewBuilder
    private func keiseiBadge(prefix: String, number: String, condensed: Bool = true) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.system(size: d * 0.30, weight: .bold)
                    .width(condensed ? .condensed : .standard))
                .frame(height: d * 0.34)
                .offset(y: 0.6)

            Text(number)
                .font(.custom("Helvetica", size: d * 0.44))
                .frame(height: d * 0.42)
                .offset(y: -0.6)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(color.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(color.opacity(opacity), lineWidth: d * 0.09)
        )
    }

    // MARK: - Seibu: Split Rounded Square

    @ViewBuilder
    private func seibuBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Hind-Bold", size: d * 0.58))
                .offset(y: d * 0.34 * 0.13)
                .foregroundColor(Color.white.opacity(opacity))
                .frame(maxWidth: .infinity)
                .frame(height: d * 0.42)
                .background(color.opacity(opacity))

            Text(number)
                .font(.custom("Hind-Bold", size: d * 0.82))
                .offset(y: d * 0.52 * 0.02)
                .foregroundColor(Self.seibuLetterColor.opacity(opacity))
                .frame(maxWidth: .infinity, maxHeight: d * 0.5)
                .background(Color.white)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(width: d, height: d)
        .clipShape(RoundedRectangle(cornerRadius: d * 0.25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: d * 0.25, style: .continuous)
                .strokeBorder(color.opacity(opacity), lineWidth: 2.5)
        )
    }

    // MARK: - Odakyu: Very-Round Squircle, Line-Color Code Over a Rule

    @ViewBuilder
    private func squircleBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: d * 0.04) {
            Text(prefix)
                .font(.custom("Hind-Bold", size: d * 0.60))
                .offset(y: d * 0.30 * 0.085)
                .frame(height: d * 0.25)

            Text(number)
                .font(.custom("Hind-Bold", size: d * 0.90))
                .offset(y: d * 2.90 * 0.02)
                .frame(height: d * 0.32)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(color.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: d * 0.45, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: d * 0.45, style: .continuous)
                .strokeBorder(color.opacity(opacity), lineWidth: 2.5)
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let badges: [(code: String, color: Color, station: String)] = [
        ("Z02", .indigo, "表参道"),
        ("JL19", .gray, "綾瀬"),
        ("TS01", .blue, "浅草"),
        ("SI01", .orange, "池袋"),
        ("MG01", .blue, "目黒"),
        ("MM04", .blue, "みなとみらい"),
        ("KK01", .red, "泉岳寺"),
        ("KO01", .pink, "新宿"),
        ("SO01", .blue, "横浜"),
        ("OH05", .teal, "代々木上原"),
        ("KS55", .blue, "千葉中央"),
        ("NT01", .pink, "日暮里"),
        ("R04", Color(hex: "#222D65"), "東京テレポート"),
        ("TT12", Color(hex: "#F08300"), "立川北"),
        ("B25", Color(hex: "#3577BC"), "新横浜"),
        ("G05", Color(hex: "#4BA672"), "センター北"),
    ]

    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
        ForEach(badges, id: \.code) { badge in
            VStack(spacing: 4) {
                StationNumberBadge(
                    code: badge.code,
                    color: badge.color,
                    opacity: 1.0,
                    size: .regular,
                    stationName: badge.station
                )
                Text(badge.station)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }
    .padding()
    .frame(width: 300)
}
