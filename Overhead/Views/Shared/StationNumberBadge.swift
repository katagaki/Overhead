import SwiftUI
import Backbone

// MARK: - Station Number Badge
/// Renders station number badges matching the real signage of each operator:
/// - JR East / Tobu: rounded square with a line-color frame, white inner,
///   prefix stacked over number in black (e.g. JY01, TS01)
/// - Tokyo Metro / Toei: circle with a line-color ring, white inner,
///   prefix stacked over number in black Futura (e.g. G01, A01)
/// - Keisei / Hokuso: circle with a thinner line-color ring, white inner,
///   code in the LINE COLOR in regular Helvetica (e.g. KS55, HS05)
/// - Odakyu: very-round squircle with a line-color ring, white core, and
///   the code in the LINE COLOR split by a horizontal rule (e.g. OH14)
/// - Tokyu: FILLED rounded square in the line color with white stacked code
///   (e.g. TY01)
/// - Minatomirai: two-tone filled square — dark navy top band with white MM,
///   line-color bottom with white number, Helvetica (e.g. MM04)
/// - Keikyu: white circle, thin light-blue ring, BLUE stacked code (KK01)
/// - Keio: split circle — line-color top with white prefix, white bottom with
///   black number, line-color ring (KO01)
/// - Seibu: split rounded square — line-color top band with white prefix,
///   white bottom with dark navy number, line-color border (SI01)
/// - Nippori-Toneri Liner: rounded square with pink outer + green inner
///   border, black stacked code — matches the line badge (NT01)
/// - Sotetsu: filled navy rounded square, white code split by an orange rule
/// (Shapes verified against station signage photos, 2026-07)

struct StationNumberBadge: View {
    let code: String
    let color: Color
    var opacity: Double = 1.0
    var size: BadgeSize = .regular
    /// Japanese station name (currently unused; kept for future variants).
    var stationName: String? = nil

    enum BadgeSize {
        case compact  // For list rows
        case regular  // For journey view station labels
    }

    private static let squarePrefixes: Set<String> = [
        // Tobu
        "TS", "TI", "TN", "TD", "TJ",
    ]
    private static let splitPrefixes: Set<String> = [
        // Odakyu
        "OH", "OE", "OT",
    ]
    private static let filledSquarePrefixes: Set<String> = [
        // Tokyu
        "TY", "DT", "MG", "OM", "IK", "SG", "TM", "KD",
        // Tsukuba Express (same filled-square style as Tokyu)
        "TX",
    ]
    private static let seibuPrefixes: Set<String> = [
        "SI", "SS", "SK", "ST", "SW", "SY",
    ]
    private static let keioPrefixes: Set<String> = ["KO", "IN"]
    private static let keiseiStylePrefixes: Set<String> = ["KS", "HS"]

    private static let nipporiToneriGreen = Color(hex: "#69B444")
    private static let keikyuRingBlue = Color(hex: "#00A7E1")
    private static let keikyuLetterBlue = Color(hex: "#1E50A2")
    private static let seibuLetterColor = Color(hex: "#111D16")
    private static let sotetsuOrange = Color(hex: "#EE7B01")
    private static let minatomiraiNavy = Color(hex: "#1F2A54")
    private static let rinkaiLightBlue = Color(hex: "#96C7C1")

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

    var body: some View {
        let (prefix, number) = parsed

        // JR station codes start with "J" (JC, JY, JK, JB, etc.)
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
            keiseiBadge(prefix: prefix, number: number)
        } else if prefix == "NT" {
            nipporiToneriBadge(prefix: prefix, number: number)
        } else if prefix == "R" {
            rinkaiBadge(prefix: prefix, number: number)
        } else {
            circleBadge(prefix: prefix, number: number)
        }
    }

    // MARK: - JR East / Tobu: Rounded Square Frame

    @ViewBuilder
    private func squareBadge(prefix: String, number: String, textColor: Color = .black) -> some View {
        let d = badgeDimension
        // Sized so the letters and digits fill the white core like the real
        // JR East signage (Hind's cap height is only 0.678em, hence the
        // generous point sizes relative to the badge).
        let prefixSize = d * 0.58
        let numberSize = d * 0.79

        // Hind's line box is ~1.6x the point size (Devanagari metrics), so cap
        // each line to a tight frame and shift glyphs down to optical center
        // (caps sit 0.085em above the box center).
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
        .foregroundColor(textColor.opacity(opacity))
        .frame(width: d, height: d)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(color.opacity(opacity), lineWidth: 3)
        )
    }

    // MARK: - Tokyu / Minatomirai: Filled Rounded Square

    @ViewBuilder
    private func filledSquareBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension
        let prefixSize = d * 0.64
        let numberSize = d * 0.76

        VStack(spacing: 1) {
            Text(prefix)
                .font(.custom("Hind-Bold", size: prefixSize))
                .offset(y: prefixSize * 0.24)
                .frame(maxWidth: .infinity)
                .frame(height: prefixSize * 0.65)

            Text(number)
                .font(.custom("Hind-Bold", size: numberSize))
                .offset(y: numberSize * -0.02)
                .frame(maxWidth: .infinity)
                .frame(height: numberSize * 0.75)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(Color.white.opacity(opacity))
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

        // Sotetsu signage uses a flat, wide face; expanded-width SF is the
        // closest system substitute.
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

    /// Matches the official Tokyo Metro station numbering: colored ring
    /// (~13% of diameter), white core, Futura letter over number in black.
    @ViewBuilder
    private func circleBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Futura-Bold", size: d * 0.38))
                .frame(height: d * 0.42)
                .offset(y: 1.10)

            Text(number)
                .font(.custom("Futura-Bold", size: d * 0.38))
                .frame(height: d * 0.42)
                .offset(y: -1.90)
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

    /// Matches TWR Rinkai signage (user photo 2026-07-10): white stacked code
    /// on a filled navy circle, a thin white separator ring, and a pale blue
    /// outer ring (~11% of the diameter).
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

    /// Mirrors the line badge's double border (proportions match
    /// LineSymbolBadge.nipporiToneriBadge at 32pt).
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
    private func keiseiBadge(prefix: String, number: String) -> some View {
        let d = badgeDimension

        VStack(spacing: 0) {
            Text(prefix)
                .font(.custom("Helvetica", size: d * 0.30))
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
        ("Z02", .indigo, "表参道"),      // Tokyo Metro circle
        ("JL19", .gray, "綾瀬"),         // JR square
        ("TS01", .blue, "浅草"),         // Tobu square
        ("SI01", .orange, "池袋"),       // Seibu split square
        ("MG01", .blue, "目黒"),         // Tokyu filled square
        ("MM04", .blue, "みなとみらい"), // Minatomirai two-tone
        ("KK01", .red, "泉岳寺"),        // Keikyu blue-ring circle
        ("KO01", .pink, "新宿"),         // Keio split circle
        ("SO01", .blue, "横浜"),         // Sotetsu orange rule
        ("OH05", .teal, "代々木上原"),   // Odakyu squircle with rule
        ("KS55", .blue, "千葉中央"),     // Keisei Helvetica circle
        ("NT01", .pink, "日暮里"),       // Nippori-Toneri double border
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
