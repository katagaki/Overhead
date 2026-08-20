import SwiftUI
import AppKit
import CoreText
import UniformTypeIdentifiers

/// Renders the Mb plate at a range of vertical nudges, to pick one by eye.
@MainActor
func mbTrialOld(registry: BadgeStyleRegistry, outDir: String) {
    let red = Color(hex: "#E60012")
    guard var spec = registry.spec("metro") else { return }
    let candidates: [CGFloat?] = [nil, -0.4, -0.6, -0.8, -1.0]

    func variant(_ dy: CGFloat?) -> BadgeStyleSpec {
        var s = spec
        var map = s.line.glyphOffsetY ?? [:]
        if let dy { map["Mb"] = dy } else { map.removeValue(forKey: "Mb") }
        s.line.glyphOffsetY = map
        return s
    }

    let view = VStack(spacing: 22) {
        Text("丸ノ内線分岐線 — vertical nudge for “Mb”")
            .font(.system(size: 14, weight: .bold))
        HStack(alignment: .top, spacing: 30) {
            ForEach(Array(candidates.enumerated()), id: \.offset) { _, dy in
                VStack(spacing: 8) {
                    SpecLineSymbolBadge(symbol: "Mb", color: red, dimension: 132,
                                        spec: variant(dy), overrides: nil)
                    Text(dy == nil ? "current (0)" : String(format: "%.1f", dy!))
                        .font(.system(size: 11, weight: dy == nil ? .regular : .semibold))
                        .foregroundColor(dy == nil ? .secondary : .primary)
                }
            }
        }
        HStack(spacing: 30) {
            VStack(spacing: 8) {
                SpecLineSymbolBadge(symbol: "M", color: red, dimension: 132,
                                    spec: spec, overrides: nil)
                Text("“M” for reference (−0.8)").font(.system(size: 11)).foregroundColor(.secondary)
            }
            VStack(spacing: 8) {
                SpecStationNumberBadge(code: "Mb03", color: red, opacity: 1, side: 132,
                                       spec: spec, overrides: nil)
                Text("station plate (unchanged)").font(.system(size: 11)).foregroundColor(.secondary)
            }
        }
    }
    .padding(28)
    .background(Color.white)

    let r = ImageRenderer(content: view)
    r.scale = 2
    if let cg = r.cgImage,
       let dest = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: "\(outDir)/mb-trial.png") as CFURL,
        UTType.png.identifier as CFString, 1, nil) {
        CGImageDestinationAddImage(dest, cg, nil)
        CGImageDestinationFinalize(dest)
    }
    print("wrote mb-trial.png")
}

/// Renders Mb with the ring's inner edge marked, at several sizes/nudges,
/// to see exactly where the glyphs sit relative to the aperture.
@MainActor
func mbInspect(registry: BadgeStyleRegistry, outDir: String) {
    let red = Color(hex: "#E60012")
    guard let base = registry.spec("metro") else { return }
    let D: CGFloat = 260

    func tweak(size: CGFloat?, dy: CGFloat?, inset: CGFloat?) -> BadgeStyleSpec {
        var s = base
        if let size { s.line.sizeMulti = size }
        if let inset { s.line.insetH = inset }
        var map = s.line.glyphOffsetY ?? [:]
        if let dy { map["Mb"] = dy }
        s.line.glyphOffsetY = map
        return s
    }

    // The white aperture: radius = D/2 - ringWidth, ring is 6.2/32 of the side.
    let ring = 6.2 / 32 * D
    let aperture = D - 2 * ring

    func cell(_ label: String, _ spec: BadgeStyleSpec) -> some View {
        VStack(spacing: 10) {
            ZStack {
                SpecLineSymbolBadge(symbol: "Mb", color: red, dimension: D,
                                    spec: spec, overrides: nil)
                Circle()
                    .strokeBorder(Color.cyan.opacity(0.9), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(width: aperture, height: aperture)
            }
            .frame(width: D, height: D)
            Text(label).font(.system(size: 13, weight: .semibold))
        }
    }

    let view = VStack(spacing: 26) {
        Text("“Mb” inside the aperture — cyan ring is the inner edge of the red band")
            .font(.system(size: 15, weight: .bold))
        HStack(spacing: 34) {
            cell("current  size 11 / dy −0.6", tweak(size: nil, dy: -0.6, inset: nil))
            cell("size 10 / dy −0.6", tweak(size: 10, dy: -0.6, inset: nil))
            cell("size 9.5 / dy −0.5", tweak(size: 9.5, dy: -0.5, inset: nil))
        }
    }
    .padding(30)
    .background(Color.white)

    let r = ImageRenderer(content: view)
    r.scale = 2
    if let cg = r.cgImage,
       let dest = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: "\(outDir)/mb-inspect.png") as CFURL,
        UTType.png.identifier as CFString, 1, nil) {
        CGImageDestinationAddImage(dest, cg, nil)
        CGImageDestinationFinalize(dest)
    }
    print("wrote mb-inspect.png  aperture=\(aperture) of \(D)")
}

/// All three multi-character symbols on the metro ring, against the aperture.
@MainActor
func wideSymbols(registry: BadgeStyleRegistry, outDir: String) {
    guard let base = registry.spec("metro") else { return }
    let D: CGFloat = 210
    let ring = 6.2 / 32 * D
    let aperture = D - 2 * ring
    let cases: [(String, Color)] = [
        ("Mb", Color(hex: "#E60012")), ("RN", Color(hex: "#E85298")), ("SMR", Color(hex: "#0072BC")),
    ]
    let sizes: [CGFloat?] = [nil, 10, 9.5, 8.5]

    func spec(_ sym: String, _ size: CGFloat?) -> BadgeStyleSpec {
        var s = base
        if let size { var m = s.line.glyphSize ?? [:]; m[sym] = size; s.line.glyphSize = m }
        return s
    }

    let view = VStack(spacing: 24) {
        Text("Multi-character symbols vs the ring aperture (cyan = inner edge)")
            .font(.system(size: 15, weight: .bold))
        ForEach(Array(cases.enumerated()), id: \.offset) { _, item in
            HStack(spacing: 26) {
                ForEach(Array(sizes.enumerated()), id: \.offset) { _, size in
                    VStack(spacing: 8) {
                        ZStack {
                            SpecLineSymbolBadge(symbol: item.0, color: item.1, dimension: D,
                                                spec: spec(item.0, size), overrides: nil)
                            Circle().strokeBorder(Color.cyan.opacity(0.9),
                                style: StrokeStyle(lineWidth: 1.3, dash: [5, 4]))
                                .frame(width: aperture, height: aperture)
                        }
                        .frame(width: D, height: D)
                        Text(size == nil ? "current (11)" : String(format: "%.1f", size!))
                            .font(.system(size: 12, weight: size == nil ? .regular : .semibold))
                            .foregroundColor(size == nil ? .secondary : .primary)
                    }
                }
            }
        }
    }
    .padding(28)
    .background(Color.white)

    let r = ImageRenderer(content: view)
    r.scale = 2
    if let cg = r.cgImage,
       let dest = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: "\(outDir)/wide-symbols.png") as CFURL,
        UTType.png.identifier as CFString, 1, nil) {
        CGImageDestinationAddImage(dest, cg, nil); CGImageDestinationFinalize(dest)
    }
    print("wrote wide-symbols.png")
}

/// Largest font size whose inked bounds fit inside a plate's circular aperture.
/// The text box is a rectangle but the aperture is a circle, so a symbol can be
/// narrower than the box and still clip the ring at its corners.
@MainActor
func fitWideSymbols() {
    struct Case { let symbol: String; let font: String; let systemSize: Bool
                  let ringRatio: CGFloat; let start: CGFloat; let style: String }
    let cases = [
        Case(symbol: "Mb",  font: "Futura-Bold", systemSize: false, ringRatio: 6.2/32, start: 11, style: "metro"),
        Case(symbol: "RN",  font: "Futura-Bold", systemSize: false, ringRatio: 6.2/32, start: 11, style: "metro"),
        Case(symbol: "SMR", font: "Futura-Bold", systemSize: false, ringRatio: 6.2/32, start: 11, style: "metro"),
        Case(symbol: "TR",  font: "",            systemSize: true,  ringRatio: 3.9/32, start: 15, style: "toyoRapid"),
    ]
    // Measure at a large reference so rounding doesn't dominate, then scale back.
    let ref: CGFloat = 32

    func ink(_ s: String, _ family: String, _ size: CGFloat, _ system: Bool) -> CGSize {
        let font: NSFont = system
            ? NSFont.systemFont(ofSize: size, weight: .bold)
            : (NSFont(name: family, size: size) ?? NSFont.systemFont(ofSize: size))
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .kern: s.count > 1 ? -0.5 * (size / 11) : 0,
        ]
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(string: s, attributes: attrs))
        let b = CTLineGetImageBounds(line, nil)
        return CGSize(width: b.width, height: b.height)
    }

    print("--- fitting multi-character symbols to the aperture ---")
    for c in cases {
        let r = (ref - 2 * c.ringRatio * ref) / 2      // aperture radius at 32pt
        let margin: CGFloat = 1.0                       // breathing room, in 32pt units
        var lo: CGFloat = 4, hi: CGFloat = c.start, best = c.start
        for _ in 0..<40 {
            let mid = (lo + hi) / 2
            let s = ink(c.symbol, c.font, mid, c.systemSize)
            let dx = s.width / 2 + margin
            let dy = s.height / 2 + margin
            if dx * dx + dy * dy <= r * r { best = mid; lo = mid } else { hi = mid }
        }
        let now = ink(c.symbol, c.font, c.start, c.systemSize)
        let fits = (now.width/2 + margin) * (now.width/2 + margin)
                 + (now.height/2 + margin) * (now.height/2 + margin) <= r * r
        print(String(format: "  %-4@ style=%-10@ aperture r=%.2f  current %.1f (ink %.1f×%.1f) %@  → fits at %.1f",
                     c.symbol as NSString, c.style as NSString, r, c.start,
                     now.width, now.height,
                     (fits ? "OK" : "OVERFLOWS") as NSString, floor(best * 10) / 10))
    }
}

/// Vertical shift that puts a symbol's *ink* on the plate's centre. SwiftUI
/// centres the line box, but Futura-Bold's caps sit low in theirs.
@MainActor
func opticalNudges() {
    let cases: [(String, CGFloat)] = [("M", 15), ("Mb", 9.3), ("RN", 10.5), ("SMR", 7.1)]
    print("--- optical nudges (32pt reference) ---")
    for (sym, size) in cases {
        guard let font = NSFont(name: "Futura-Bold", size: size) else { continue }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .kern: sym.count > 1 ? -0.5 * (size / 11) : 0,
        ]
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(string: sym, attributes: attrs))
        var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        let ink = CTLineGetImageBounds(line, nil)
        let inkCentre = ink.minY + ink.height / 2       // above baseline
        let boxCentre = (ascent - descent) / 2          // above baseline
        let offsetY = inkCentre - boxCentre             // SwiftUI offset(y:), −ve = up
        print(String(format: "  %-4@ size %.1f  ink %.1f×%.1f  nudge %.2f",
                     sym as NSString, size, ink.width, ink.height, offsetY))
    }
}

/// Fitted sizes with candidate nudges, against the aperture and the true centre.
@MainActor
func finalCheck(registry: BadgeStyleRegistry, outDir: String) {
    guard let base = registry.spec("metro") else { return }
    let D: CGFloat = 190
    let ring = 6.2 / 32 * D
    let aperture = D - 2 * ring
    let cases: [(String, CGFloat, Color)] = [
        ("Mb", 9.3, Color(hex: "#E60012")),
        ("RN", 10.5, Color(hex: "#E85298")),
        ("SMR", 7.1, Color(hex: "#0072BC")),
    ]
    let nudges: [CGFloat] = [0, -0.3, -0.5]

    func spec(_ sym: String, _ size: CGFloat, _ dy: CGFloat) -> BadgeStyleSpec {
        var s = base
        var sz = s.line.glyphSize ?? [:]; sz[sym] = size; s.line.glyphSize = sz
        var oy = s.line.glyphOffsetY ?? [:]; oy[sym] = dy; s.line.glyphOffsetY = oy
        return s
    }

    let view = VStack(spacing: 22) {
        Text("Fitted sizes — cyan = aperture, magenta = true centre")
            .font(.system(size: 14, weight: .bold))
        ForEach(Array(cases.enumerated()), id: \.offset) { _, c in
            HStack(spacing: 30) {
                ForEach(Array(nudges.enumerated()), id: \.offset) { _, dy in
                    VStack(spacing: 8) {
                        ZStack {
                            SpecLineSymbolBadge(symbol: c.0, color: c.2, dimension: D,
                                                spec: spec(c.0, c.1, dy), overrides: nil)
                            Circle().strokeBorder(Color.cyan.opacity(0.85),
                                style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                                .frame(width: aperture, height: aperture)
                            Rectangle().fill(Color(hex: "#FF00AA").opacity(0.55))
                                .frame(width: aperture, height: 1)
                        }
                        .frame(width: D, height: D)
                        Text("\(c.0)  \(String(format: "%.1f", c.1)) / dy \(String(format: "%.1f", dy))")
                            .font(.system(size: 11.5, weight: .medium))
                    }
                }
            }
        }
    }
    .padding(26)
    .background(Color.white)

    let r = ImageRenderer(content: view)
    r.scale = 2
    if let cg = r.cgImage,
       let dest = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: "\(outDir)/final-check.png") as CFURL,
        UTType.png.identifier as CFString, 1, nil) {
        CGImageDestinationAddImage(dest, cg, nil); CGImageDestinationFinalize(dest)
    }
    print("wrote final-check.png")
}

/// Line plate and station plate together, at the shipped settings.
@MainActor
func shipped(registry: BadgeStyleRegistry, outDir: String) {
    guard let spec = registry.spec("metro") else { return }
    let D: CGFloat = 170
    let lineAp = D - 2 * (6.2 / 32 * D)
    let stnAp = D - 2 * (0.13 * D)
    let cases: [(String, String, Color, String)] = [
        ("Mb", "Mb03", Color(hex: "#E60012"), "丸ノ内線分岐線"),
        ("RN", "RN1",  Color(hex: "#E85298"), "流鉄流山線"),
        ("SMR", "SMR1", Color(hex: "#0072BC"), "湘南モノレール"),
    ]
    let view = VStack(spacing: 20) {
        Text("Shipped settings — line plate and station plate")
            .font(.system(size: 14, weight: .bold))
        ForEach(Array(cases.enumerated()), id: \.offset) { _, c in
            HStack(spacing: 34) {
                Text(c.3).font(.system(size: 13, weight: .semibold)).frame(width: 150, alignment: .leading)
                ZStack {
                    SpecLineSymbolBadge(symbol: c.0, color: c.2, dimension: D, spec: spec, overrides: nil)
                    Circle().strokeBorder(Color.cyan.opacity(0.8),
                        style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])).frame(width: lineAp, height: lineAp)
                }.frame(width: D, height: D)
                ZStack {
                    SpecStationNumberBadge(code: c.1, color: c.2, opacity: 1, side: D,
                                           spec: spec, overrides: nil)
                    Circle().strokeBorder(Color.cyan.opacity(0.8),
                        style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])).frame(width: stnAp, height: stnAp)
                }.frame(width: D, height: D)
            }
        }
    }
    .padding(26).background(Color.white)
    let r = ImageRenderer(content: view); r.scale = 2
    if let cg = r.cgImage,
       let dest = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: "\(outDir)/shipped.png") as CFURL,
        UTType.png.identifier as CFString, 1, nil) {
        CGImageDestinationAddImage(dest, cg, nil); CGImageDestinationFinalize(dest)
    }
    print("wrote shipped.png")
}

/// Fits a station plate's prefix row, which sits above centre where the
/// aperture's chord is narrower than at the middle.
@MainActor
func fitStationPrefixes() {
    let side: CGFloat = 32
    let r = (side - 2 * 0.13 * side) / 2          // metro station ring is 0.13 of the side
    let rowH = 0.42 * side
    let stackTop = (side - 2 * rowH) / 2
    let prefixCentreFromTop = stackTop + rowH / 2 + 1.10   // +offsetY from the style
    let dy = side / 2 - prefixCentreFromTop        // how far above centre the ink sits
    let margin: CGFloat = 0.8

    print("--- fitting station prefixes (aperture r=\(String(format: "%.2f", r)), row sits \(String(format: "%.2f", dy)) above centre) ---")
    for sym in ["Mb", "RN", "SMR", "M"] {
        var lo: CGFloat = 0.10, hi: CGFloat = 0.38, best: CGFloat = 0.38
        for _ in 0..<40 {
            let mid = (lo + hi) / 2
            let size = mid * side
            guard let f = NSFont(name: "Futura-Bold", size: size) else { break }
            let line = CTLineCreateWithAttributedString(
                NSAttributedString(string: sym, attributes: [.font: f]))
            let ink = CTLineGetImageBounds(line, nil)
            let w = ink.width / 2 + margin
            let h = abs(dy) + ink.height / 2 + margin
            if w * w + h * h <= r * r { best = mid; lo = mid } else { hi = mid }
        }
        let cur = 0.38 * side
        let f = NSFont(name: "Futura-Bold", size: cur)!
        let ink = CTLineGetImageBounds(
            CTLineCreateWithAttributedString(NSAttributedString(string: sym, attributes: [.font: f])), nil)
        let ok = pow(ink.width/2 + margin, 2) + pow(abs(dy) + ink.height/2 + margin, 2) <= r * r
        print(String(format: "  %-4@ current 0.380 (ink %.1f×%.1f) %@  → fits at %.3f",
                     sym as NSString, ink.width, ink.height,
                     (ok ? "OK" : "OVERFLOWS") as NSString, floor(best * 1000) / 1000))
    }
}

/// Station plates at candidate prefix sizes, against the aperture.
@MainActor
func stationCandidates(registry: BadgeStyleRegistry, outDir: String) {
    guard let base = registry.spec("metro") else { return }
    let D: CGFloat = 150
    let ap = D - 2 * (0.13 * D)
    let cases: [(String, String, Color)] = [
        ("Mb", "Mb03", Color(hex: "#E60012")),
        ("RN", "RN1", Color(hex: "#E85298")),
        ("SMR", "SMR1", Color(hex: "#0072BC")),
        ("M", "M06", Color(hex: "#E60012")),
    ]
    let sizes: [CGFloat?] = [nil, 0.30, 0.26, 0.22]

    func spec(_ p: String, _ v: CGFloat?) -> BadgeStyleSpec {
        var s = base
        if let v, var st = s.station { var m = st.prefixSizes ?? [:]; m[p] = v; st.prefixSizes = m; s.station = st }
        return s
    }

    let view = VStack(spacing: 18) {
        Text("Station plates — prefix size candidates (cyan = aperture)")
            .font(.system(size: 14, weight: .bold))
        ForEach(Array(cases.enumerated()), id: \.offset) { _, c in
            HStack(spacing: 26) {
                ForEach(Array(sizes.enumerated()), id: \.offset) { _, v in
                    VStack(spacing: 6) {
                        ZStack {
                            SpecStationNumberBadge(code: c.1, color: c.2, opacity: 1, side: D,
                                                   spec: spec(c.0, v), overrides: nil)
                            Circle().strokeBorder(Color.cyan.opacity(0.85),
                                style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                                .frame(width: ap, height: ap)
                        }.frame(width: D, height: D)
                        Text(v == nil ? "\(c.1)  current .380" : String(format: "%.2f", v!))
                            .font(.system(size: 11, weight: v == nil ? .regular : .semibold))
                            .foregroundColor(v == nil ? .secondary : .primary)
                    }
                }
            }
        }
    }
    .padding(24).background(Color.white)
    let r = ImageRenderer(content: view); r.scale = 2
    if let cg = r.cgImage,
       let dest = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: "\(outDir)/station-candidates.png") as CFURL,
        UTType.png.identifier as CFString, 1, nil) {
        CGImageDestinationAddImage(dest, cg, nil); CGImageDestinationFinalize(dest)
    }
    print("wrote station-candidates.png")
}

/// What the マイ路線 style picker offers: every style drawn with one line's
/// own symbol and colour.
@MainActor
func pickerPreview(registry: BadgeStyleRegistry, outDir: String) {
    let color = Color(hex: "#F15A22")
    let symbol = "YH"
    let code = "YH01"
    let ids = registry.styles.values
        .sorted { ($0.nameJa ?? $0.id) < ($1.nameJa ?? $1.id) }
    let cols = 5

    let view = VStack(spacing: 14) {
        Text("マイ路線 — badge styles offered (symbol “\(symbol)”, the line's own colour)")
            .font(.system(size: 15, weight: .bold))
        ForEach(Array(stride(from: 0, to: ids.count, by: cols)), id: \.self) { start in
            HStack(alignment: .top, spacing: 14) {
                ForEach(start..<min(start + cols, ids.count), id: \.self) { i in
                    let spec = ids[i]
                    VStack(spacing: 7) {
                        HStack(spacing: 7) {
                            SpecLineSymbolBadge(symbol: symbol, color: color, dimension: 34,
                                                spec: spec, overrides: nil)
                            SpecStationNumberBadge(code: code, color: color, opacity: 1,
                                                   side: 34, spec: spec, overrides: nil)
                        }
                        Text(spec.nameJa ?? spec.id)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(width: 118)
                    }
                    .padding(.vertical, 10)
                    .frame(width: 130)
                    .background(Color(white: 0.97), in: RoundedRectangle(cornerRadius: 12))
                }
                if start + cols > ids.count {
                    ForEach(0..<(start + cols - ids.count), id: \.self) { _ in
                        Color.clear.frame(width: 130, height: 1)
                    }
                }
            }
        }
    }
    .padding(22)
    .background(Color.white)

    let r = ImageRenderer(content: view); r.scale = 2
    if let cg = r.cgImage,
       let dest = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: "\(outDir)/picker.png") as CFURL,
        UTType.png.identifier as CFString, 1, nil) {
        CGImageDestinationAddImage(dest, cg, nil); CGImageDestinationFinalize(dest)
    }
    print("wrote picker.png (\(ids.count) styles)")
}
