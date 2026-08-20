import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Renders one style large, old vs spec, for eyeballing a mismatch.
@MainActor
func zoom(styleId: String, rows: [Row], registry: BadgeStyleRegistry, outDir: String) {
    guard let sample = rows.first(where: { $0.config.style == styleId }) else { return }
    guard let spec = registry.spec(styleId) else { return }
    let code = sample.codes.first ?? "\(sample.config.symbol)01"
    let prefix = String(code.prefix(while: \.isLetter))
    let D: CGFloat = 160

    let view = VStack(spacing: 18) {
        Text("\(styleId)   \(sample.nameJa)   symbol=\(sample.config.symbol)  code=\(code)")
            .font(.system(size: 13, weight: .bold))
        HStack(spacing: 26) {
            VStack { Text("OLD line").font(.system(size: 10))
                OldLineSymbolBadge(symbol: sample.oldSymbol, color: sample.color, dimension: D) }
            VStack { Text("SPEC line").font(.system(size: 10))
                SpecLineSymbolBadge(symbol: sample.config.symbol, color: sample.color,
                                    dimension: D, spec: spec, overrides: sample.config.colors) }
            VStack { Text("OLD stn").font(.system(size: 10))
                OldStationNumberBadge(code: code, color: sample.color, opacity: 1.0, size: .compact)
                    .scaleEffect(D / 32).frame(width: D, height: D) }
            VStack { Text("SPEC stn").font(.system(size: 10))
                SpecStationNumberBadge(code: code, color: sample.color, opacity: 1.0,
                                       side: 32, spec: registry.spec(sample.config.stationStyle(forPrefix: prefix))!,
                                       overrides: sample.config.colors)
                    .scaleEffect(D / 32).frame(width: D, height: D) }
        }
    }
    .padding(20)
    .background(Color.white)

    // Where exactly do they differ? Print the bounding box of changed pixels.
    if let a = rasterize(OldLineSymbolBadge(symbol: sample.oldSymbol, color: sample.color, dimension: 32), 32),
       let b = rasterize(SpecLineSymbolBadge(symbol: sample.config.symbol, color: sample.color,
                                             dimension: 32, spec: spec, overrides: sample.config.colors), 32) {
        var minX = 9999, maxX = -1, minY = 9999, maxY = -1, n = 0
        for y in 0..<a.h {
            for x in 0..<a.w {
                let i = (y * a.w + x) * 4
                var d = 0
                for k in 0..<3 { d = max(d, abs(Int(a.px[i+k]) - Int(b.px[i+k]))) }
                if d > 0 { n += 1; minX = min(minX,x); maxX = max(maxX,x); minY = min(minY,y); maxY = max(maxY,y) }
            }
        }
        if n > 0 {
            print("  [\(styleId)] line diff \(n)px  bbox x:\(minX)...\(maxX) y:\(minY)...\(maxY)  (canvas \(a.w)x\(a.h))")
            var shown = 0
            for y in 0..<a.h where shown < 10 {
                for x in 0..<a.w where shown < 10 {
                    let i = (y * a.w + x) * 4
                    var d = 0
                    for k in 0..<3 { d = max(d, abs(Int(a.px[i+k]) - Int(b.px[i+k]))) }
                    if d > 0 {
                        print("      (\(x),\(y)) old=\(a.px[i]),\(a.px[i+1]),\(a.px[i+2]) spec=\(b.px[i]),\(b.px[i+1]),\(b.px[i+2])")
                        shown += 1
                    }
                }
            }
        }
    }

    let r = ImageRenderer(content: view)
    r.scale = 2
    if let cg = r.cgImage {
        let url = URL(fileURLWithPath: "\(outDir)/zoom-\(styleId).png")
        if let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(dest, cg, nil)
            CGImageDestinationFinalize(dest)
        }
    }
}

@MainActor
func selfTest(_ registry: BadgeStyleRegistry) {
    let g = Color(hex: "#9ACD32")
    func cmp(_ name: String, _ a: some View, _ b: some View) {
        guard let x = rasterize(a, 32), let y = rasterize(b, 32) else { return }
        let d = diff(x, y)
        print("  \(name): \(d.differing)/\(d.total) px maxΔ=\(d.maxDelta)")
    }
    cmp("RoundedRect view vs BadgePath",
        RoundedRectangle(cornerRadius: 4).fill(g),
        BadgePath(shape: "roundedRect", radius: 4).fill(g))
    cmp("RoundedRect in ZStack vs bare",
        RoundedRectangle(cornerRadius: 4).fill(g),
        ZStack { RoundedRectangle(cornerRadius: 4).fill(g) })
    cmp("bare vs .background wrapper",
        RoundedRectangle(cornerRadius: 4).fill(g),
        Color.clear.background { RoundedRectangle(cornerRadius: 4).fill(g) })
    cmp("bare vs padding(0)",
        RoundedRectangle(cornerRadius: 4).fill(g),
        RoundedRectangle(cornerRadius: 4).fill(g).padding(0))
    cmp("bare vs Group{if}",
        RoundedRectangle(cornerRadius: 4).fill(g),
        Group { if true { RoundedRectangle(cornerRadius: 4).fill(g) } })
    let shape = "roundedRect"
    cmp("bare vs Group{switch}",
        RoundedRectangle(cornerRadius: 4).fill(g),
        Group { switch shape {
            case "circle": Circle().fill(g)
            default: RoundedRectangle(cornerRadius: 4).fill(g) } })
    cmp("bare vs Group{switch}+padding0",
        RoundedRectangle(cornerRadius: 4).fill(g),
        Group { switch shape {
            case "circle": Circle().fill(g)
            default: RoundedRectangle(cornerRadius: 4).fill(g) } }.padding(0))
    cmp("jr background: manual vs manual",
        Color.clear.frame(width: 32, height: 32).background {
            ZStack { RoundedRectangle(cornerRadius: 4).fill(g)
                     Rectangle().fill(Color.white).padding(3.5) } },
        Color.clear.frame(width: 32, height: 32).background {
            ZStack { ForEach(0..<2, id: \.self) { i in
                Group { if i == 0 { RoundedRectangle(cornerRadius: 4).fill(g) }
                        else { Rectangle().fill(Color.white) } }
                .padding(i == 0 ? 0 : 3.5) } } })
    // Hand-written replica of the current jr plate, to bisect spec vs pipeline.
    let manualJR = Text("JY")
        .font(.custom("Hind-Bold", fixedSize: 18.5))
        .kerning(-0.5)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .foregroundColor(.black)
        .offset(y: 16.5 * 0.085)
        .padding(.horizontal, 4)
        .frame(width: 32, height: 32)
        .background {
            ZStack { RoundedRectangle(cornerRadius: 4).fill(g)
                     Rectangle().fill(Color.white).padding(3.5) }
        }
    cmp("OLD jr plate vs manual replica",
        OldLineSymbolBadge(symbol: "JY", color: g, dimension: 32), manualJR)
    cmp("manual replica vs bare-background-only",
        Color.clear.frame(width: 32, height: 32).background {
            ZStack { RoundedRectangle(cornerRadius: 4).fill(g)
                     Rectangle().fill(Color.white).padding(3.5) } },
        Color.clear.frame(width: 32, height: 32).background {
            ZStack { RoundedRectangle(cornerRadius: 4).fill(g)
                     Rectangle().fill(Color.white).padding(3.5) } }
            .overlay { EmptyView() })
    let specJR = SpecLineSymbolBadge(symbol: "JY", color: g, dimension: 32,
                                     spec: registry.spec("jr")!, overrides: nil)
    cmp("manual replica vs SPEC jr", manualJR, specJR)
    // Layers only, no text, to separate plate from type.
    cmp("plate only: manual vs SPEC-style layers",
        Color.clear.frame(width: 32, height: 32).background {
            ZStack { RoundedRectangle(cornerRadius: 4).fill(g)
                     Rectangle().fill(Color.white).padding(3.5) } },
        Color.clear.frame(width: 32, height: 32).background {
            ZStack { RoundedRectangle(cornerRadius: 4, style: .circular).fill(g)
                     Rectangle().fill(Color(hex: "#FFFFFF")).padding(3.5) } })
    cmp("text only: manual vs SPEC-ish",
        Text("JY").font(.custom("Hind-Bold", fixedSize: 18.5)).kerning(-0.5)
            .lineLimit(1).minimumScaleFactor(0.5).foregroundColor(.black)
            .offset(y: 16.5 * 0.085).padding(.horizontal, 4).frame(width: 32, height: 32),
        Text("JY").font(.custom("Hind-Bold", fixedSize: 18.5)).kerning(-0.5)
            .lineLimit(1).minimumScaleFactor(0.5).foregroundColor(Color(hex: "#000000"))
            .offset(x: 0, y: 16.5 * 0.085).padding(.horizontal, 4).frame(width: 32, height: 32))
    cmp("bare vs ForEach-in-ZStack",
        RoundedRectangle(cornerRadius: 4).fill(g),
        ZStack { ForEach(Array([0].enumerated()), id: \.offset) { _, _ in
            RoundedRectangle(cornerRadius: 4).fill(g) } })
}

/// Writes each badge to its own PNG so a page can lay them out freely.
@MainActor
func exportIndividual(rows: [Row], registry: BadgeStyleRegistry, outDir: String) -> [[String: String]] {
    let dir = "\(outDir)/png"
    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

    func write(_ view: some View, _ name: String) -> String? {
        let r = ImageRenderer(content: view.frame(width: 32, height: 32))
        r.scale = 3
        guard let cg = r.cgImage else { return nil }
        let url = URL(fileURLWithPath: "\(dir)/\(name).png")
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, cg, nil)
        return CGImageDestinationFinalize(dest) ? "\(name).png" : nil
    }

    var manifest: [[String: String]] = []
    for row in rows {
        let slug = row.id.replacingOccurrences(of: ":", with: "_")
                         .replacingOccurrences(of: ".", with: "_")
        let overrides = row.config.colors
        let spec = registry.spec(row.config.style)!

        var entry: [String: String] = [
            "id": row.id, "nameJa": row.nameJa, "style": row.config.style,
            "symbol": row.config.symbol, "color": row.color.hexOut,
        ]
        entry["lineOld"] = write(OldLineSymbolBadge(symbol: row.oldSymbol, color: row.color,
                                                    dimension: 32), "\(slug)-line-old") ?? ""
        entry["lineNew"] = write(SpecLineSymbolBadge(symbol: row.config.symbol, color: row.color,
                                                     dimension: 32, spec: spec,
                                                     overrides: overrides), "\(slug)-line-new") ?? ""
        var codes: [String] = []
        for (i, code) in row.codes.prefix(3).enumerated() {
            let prefix = String(code.prefix(while: \.isLetter))
            let sSpec = registry.spec(row.config.stationStyle(forPrefix: prefix))!
            _ = write(OldStationNumberBadge(code: code, color: row.color, opacity: 1.0,
                                            size: .compact), "\(slug)-stn\(i)-old")
            _ = write(SpecStationNumberBadge(code: code, color: row.color, opacity: 1.0,
                                             side: 32, spec: sSpec, overrides: overrides),
                      "\(slug)-stn\(i)-new")
            codes.append("\(code)|\(slug)-stn\(i)-old.png|\(slug)-stn\(i)-new.png")
        }
        entry["codes"] = codes.joined(separator: ";")
        manifest.append(entry)
    }
    return manifest
}

extension Color {
    var hexOut: String {
        let (r, g, b) = rgbComponents
        return String(format: "#%02X%02X%02X", Int((r*255).rounded()),
                      Int((g*255).rounded()), Int((b*255).rounded()))
    }
}
