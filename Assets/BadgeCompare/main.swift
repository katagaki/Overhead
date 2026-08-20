import SwiftUI
import AppKit
import CoreText
import UniformTypeIdentifiers

// MARK: - Data

let linesRoot = "/Users/katagaki/Developer/Overhead/StaticData/Lines"
let stylesRoot = "/Users/katagaki/Developer/Overhead/StaticData/BadgeStyles"
let registry = BadgeStyleRegistry(directory: stylesRoot)
let outDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "/private/tmp/claude-501/-Users-katagaki-Developer-Overhead/6fe36b5a-87a4-4bd8-bb26-843a8576d4ab/scratchpad/badges"

struct RawStation: Decodable { let stationCode: String? }
struct RawLine: Decodable {
    let id: String, nameJa: String, colorHex: String
    let stations: [RawStation]
}
struct BadgeFile: Decodable { let lines: [String: LineBadgeConfig] }

/// The hardcoded table the app uses today (TrainLine.symbolForRailwayId) —
/// drives the OLD side of the comparison only.
let symbolForRailwayId: [String: String] = [
    "Railway:JR-East.Yamanote": "JY", "Railway:JR-East.KeihinTohoku": "JK",
    "Railway:JR-East.ChuoRapid": "JC", "Railway:JR-East.ChuoSobuLocal": "JB",
    "Railway:JR-East.SaikyoKawagoe": "JA", "Railway:JR-East.Keiyo": "JE",
    "Railway:JR-East.Yokohama": "JH", "Railway:JR-East.Nambu": "JN",
    "Railway:JR-East.YokosukaSobu": "JO", "Railway:JR-East.Tokaido": "JT",
    "Railway:JR-East.Utsunomiya": "JU", "Railway:JR-East.Takasaki": "JU",
    "Railway:JR-East.ShonanShinjuku": "JS", "Railway:JR-East.JobanRapid": "JJ",
    "Railway:JR-East.JobanLocal": "JL", "Railway:JR-East.Musashino": "JM",
    "Railway:JR-East.Tsurumi": "JI", "Railway:JR-East.Ome": "JC",
    "Railway:JR-East.Itsukaichi": "JC", "Railway:JR-East.NaritaExpress": "JO",
    "Railway:JR-East.Uchibo": "JR", "Railway:JR-East.Sotobo": "JR",
    "Railway:JR-East.Sagami": "JR", "Railway:JR-East.Hachiko": "JR",
    "Railway:JR-East.Kawagoe": "JR", "Railway:JR-East.Togane": "JR",
    "Railway:JR-East.Kashima": "JR", "Railway:JR-East.Kururi": "JR",
    "Railway:JR-East.Agatsuma": "JR", "Railway:JR-East.Joetsu": "JR",
    "Railway:TokyoMetro.Ginza": "G", "Railway:TokyoMetro.Marunouchi": "M",
    "Railway:TokyoMetro.MarunouchiBranch": "Mb", "Railway:TokyoMetro.Hibiya": "H",
    "Railway:TokyoMetro.Tozai": "T", "Railway:TokyoMetro.Chiyoda": "C",
    "Railway:TokyoMetro.Yurakucho": "Y", "Railway:TokyoMetro.Hanzomon": "Z",
    "Railway:TokyoMetro.Namboku": "N", "Railway:TokyoMetro.Fukutoshin": "F",
    "Railway:Toei.Asakusa": "A", "Railway:Toei.Mita": "I",
    "Railway:Toei.Shinjuku": "S", "Railway:Toei.Oedo": "E",
    "Railway:Toei.NipporiToneri": "NT", "Railway:Toei.Toden": "SA",
    "Railway:Hokuso.Hokuso": "HS", "Railway:Tobu.Isesaki": "TI",
]

func oldSymbol(_ line: RawLine) -> String {
    if let s = symbolForRailwayId[line.id] { return s }
    for st in line.stations {
        let letters = (st.stationCode ?? "").prefix(while: \.isLetter)
        if !letters.isEmpty { return String(letters) }
    }
    return ""
}

struct Row {
    let id: String, nameJa: String, folder: String
    let color: Color
    let oldSymbol: String
    let config: LineBadgeConfig
    /// One representative station code per distinct prefix on the line.
    let codes: [String]
}

func loadRows() -> [Row] {
    var rows: [Row] = []
    let fm = FileManager.default
    let folders = (try! fm.contentsOfDirectory(atPath: linesRoot)).sorted()
    for folder in folders {
        let dir = "\(linesRoot)/\(folder)"
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue else { continue }
        let lines = try! JSONDecoder().decode([RawLine].self,
                        from: Data(contentsOf: URL(fileURLWithPath: "\(dir)/Line.json")))
        let badges = try! JSONDecoder().decode(BadgeFile.self,
                        from: Data(contentsOf: URL(fileURLWithPath: "\(dir)/Badge.json"))).lines
        for line in lines {
            guard let cfg = badges[line.id] else {
                FileHandle.standardError.write("MISSING Badge.json entry: \(line.id)\n".data(using: .utf8)!)
                continue
            }
            var seen = Set<String>()
            var codes: [String] = []
            for st in line.stations {
                let code = st.stationCode ?? ""
                guard !code.isEmpty else { continue }
                let p = String(code.prefix(while: \.isLetter))
                if seen.insert(p).inserted { codes.append(code) }
            }
            rows.append(Row(id: line.id, nameJa: line.nameJa, folder: folder,
                            color: Color(hex: line.colorHex),
                            oldSymbol: oldSymbol(line), config: cfg, codes: codes))
        }
    }
    return rows
}

// MARK: - Rasterise & diff

@MainActor
func rasterize<V: View>(_ view: V, _ side: CGFloat, scale: CGFloat = 3) -> (w: Int, h: Int, px: [UInt8])? {
    let renderer = ImageRenderer(content:
        view.frame(width: side, height: side).background(Color.white))
    renderer.scale = scale
    guard let cg = renderer.cgImage else { return nil }
    let w = cg.width, h = cg.height
    var buf = [UInt8](repeating: 0, count: w * h * 4)
    let ok: Bool = buf.withUnsafeMutableBytes { raw -> Bool in
        guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return false }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return true
    }
    return ok ? (w, h, buf) : nil
}

struct DiffResult { let differing: Int; let maxDelta: Int; let total: Int }

func diff(_ a: (w: Int, h: Int, px: [UInt8]), _ b: (w: Int, h: Int, px: [UInt8])) -> DiffResult {
    guard a.w == b.w, a.h == b.h else { return DiffResult(differing: -1, maxDelta: 255, total: 0) }
    var differing = 0, maxDelta = 0
    let n = a.px.count
    var i = 0
    while i < n {
        var d = 0
        for k in 0..<3 { d = max(d, abs(Int(a.px[i + k]) - Int(b.px[i + k]))) }
        if d > 0 { differing += 1; maxDelta = max(maxDelta, d) }
        i += 4
    }
    return DiffResult(differing: differing, maxDelta: maxDelta, total: n / 4)
}

// MARK: - Contact sheet

struct BadgePairRow: View {
    let row: Row
    let flagged: Bool

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text(row.nameJa).font(.system(size: 11, weight: .medium))
                Text("\(row.config.style)   \(row.id)")
                    .font(.system(size: 8)).foregroundColor(.secondary)
            }
            .frame(width: 240, alignment: .leading)

            // Line badge: old | new
            HStack(spacing: 6) {
                OldLineSymbolBadge(symbol: row.oldSymbol, color: row.color, dimension: 32)
                SpecLineSymbolBadge(symbol: row.config.symbol, color: row.color,
                                    dimension: 32, spec: registry.spec(row.config.style)!,
                                    overrides: row.config.colors)
            }
            .frame(width: 88)

            Rectangle().fill(Color.gray.opacity(0.25)).frame(width: 1, height: 34)
                .padding(.horizontal, 8)

            // Station badges: old | new, one pair per distinct code prefix
            HStack(spacing: 14) {
                ForEach(row.codes.prefix(3), id: \.self) { code in
                    let prefix = String(code.prefix(while: \.isLetter))
                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            OldStationNumberBadge(code: code, color: row.color,
                                                  opacity: 1.0, size: .compact)
                            SpecStationNumberBadge(code: code, color: row.color,
                                                   opacity: 1.0, side: 32,
                                                   spec: registry.spec(row.config.stationStyle(forPrefix: prefix))!,
                                                   overrides: row.config.colors)
                        }
                        Text(code).font(.system(size: 7)).foregroundColor(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(width: 260, alignment: .leading)

            Text(flagged ? "● DIFF" : "")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.red)
                .frame(width: 46, alignment: .leading)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(flagged ? Color.red.opacity(0.10) : Color.clear)
    }
}

struct Sheet: View {
    let title: String
    let rows: [(Row, Bool)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.system(size: 13, weight: .bold))
                Spacer()
                Text("left = current (hardcoded)    right = from BadgeStyles/*.json")
                    .font(.system(size: 9)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 10).padding(.top, 8).padding(.bottom, 6)

            ForEach(Array(rows.enumerated()), id: \.offset) { idx, pair in
                BadgePairRow(row: pair.0, flagged: pair.1)
                    .background(idx % 2 == 0 ? Color.gray.opacity(0.05) : Color.clear)
            }
        }
        .frame(width: 700, alignment: .leading)
        .background(Color.white)
    }
}

// MARK: - Run

@MainActor
func run() {
    // Register the app's bundled faces; Hind is not a system font.
    let fontDir = "/Users/katagaki/Developer/Overhead/Overhead/Fonts"
    for f in (try? FileManager.default.contentsOfDirectory(atPath: fontDir)) ?? [] where f.hasSuffix(".ttf") {
        CTFontManagerRegisterFontsForURL(
            URL(fileURLWithPath: "\(fontDir)/\(f)") as CFURL, .process, nil)
    }

    let rows = loadRows()
    var flags: [String: Bool] = [:]
    var report: [String] = []
    var diffCount = 0

    for row in rows {
        var rowDiffers = false
        var notes: [String] = []

        let oldLine = rasterize(OldLineSymbolBadge(symbol: row.oldSymbol, color: row.color, dimension: 32), 32)
        let newLine = rasterize(SpecLineSymbolBadge(symbol: row.config.symbol, color: row.color,
                                                    dimension: 32, spec: registry.spec(row.config.style)!,
                                                    overrides: row.config.colors), 32)
        if let a = oldLine, let b = newLine {
            let d = diff(a, b)
            if d.differing > 0 {
                rowDiffers = true
                notes.append("line badge: \(d.differing)/\(d.total) px, maxΔ=\(d.maxDelta)")
            }
        }
        if row.oldSymbol != row.config.symbol {
            rowDiffers = true
            notes.append("symbol '\(row.oldSymbol)' -> '\(row.config.symbol)'")
        }

        for code in row.codes {
            let prefix = String(code.prefix(while: \.isLetter))
            let oa = rasterize(OldStationNumberBadge(code: code, color: row.color,
                                                     opacity: 1.0, size: .compact), 32)
            let nb = rasterize(SpecStationNumberBadge(code: code, color: row.color,
                                                      opacity: 1.0, side: 32,
                                                      spec: registry.spec(row.config.stationStyle(forPrefix: prefix))!,
                                                      overrides: row.config.colors), 32)
            if let a = oa, let b = nb {
                let d = diff(a, b)
                if d.differing > 0 {
                    rowDiffers = true
                    notes.append("station \(code): \(d.differing)/\(d.total) px, maxΔ=\(d.maxDelta)")
                }
            }
        }

        flags[row.id] = rowDiffers
        if rowDiffers {
            diffCount += 1
            report.append("DIFF  \(row.nameJa)  [\(row.id)]  style=\(row.config.style)")
            for n in notes { report.append("        \(n)") }
        }
    }

    // Sheets, grouped by style so like-for-like sits together.
    try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
    let sorted = rows.sorted {
        ($0.config.style, $0.id) < ($1.config.style, $1.id)
    }
    let perPage = 20
    var page = 0
    var index = 0
    while index < sorted.count {
        let slice = Array(sorted[index..<min(index + perPage, sorted.count)])
        let pageRows = slice.map { ($0, flags[$0.id] ?? false) }
        page += 1
        let styleSpan = "\(slice.first!.config.style) … \(slice.last!.config.style)"
        let sheet = Sheet(title: "Badge comparison — page \(page)  (\(styleSpan))", rows: pageRows)
        let renderer = ImageRenderer(content: sheet)
        renderer.scale = 2
        if let cg = renderer.cgImage {
            let url = URL(fileURLWithPath: String(format: "%@/page%02d.png", outDir, page))
            if let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, cg, nil)
                CGImageDestinationFinalize(dest)
            }
        }
        index += perPage
    }

    if ProcessInfo.processInfo.environment["SELFTEST"] != nil { print("--- self test ---"); selfTest(registry) }

    if ProcessInfo.processInfo.environment["MBTRIAL"] != nil {
        fitWideSymbols()
        pickerPreview(registry: registry, outDir: outDir)
    }

    if ProcessInfo.processInfo.environment["EXPORT"] != nil {
        let manifest = exportIndividual(rows: sorted, registry: registry, outDir: outDir)
        if let data = try? JSONSerialization.data(withJSONObject: manifest,
                                                  options: [.prettyPrinted]) {
            try? data.write(to: URL(fileURLWithPath: "\(outDir)/manifest.json"))
        }
        print("exported \(manifest.count) rows to \(outDir)/png")
    }

    if let zoomList = ProcessInfo.processInfo.environment["ZOOM"] {
        for sid in zoomList.split(separator: ",") {
            zoom(styleId: String(sid), rows: rows, registry: registry, outDir: outDir)
        }
        print("zoom sheets written")
    }

    print("lines compared: \(rows.count)")
    print("station plates compared: \(rows.reduce(0) { $0 + $1.codes.count })")
    print("rows with any difference: \(diffCount)")
    print("sheets written: \(page) -> \(outDir)")
    if !report.isEmpty {
        print("\n--- differences ---")
        for line in report { print(line) }
    }
}

MainActor.assumeIsolated { run() }
