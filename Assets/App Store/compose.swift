#!/usr/bin/env swift
// Composes App Store screenshots (iPhone 6.5", 1242 x 2688) from raw
// simulator captures in Raw/<lang>/: gradient background, one-line header
// and caption in Hind, and the capture masked with Display@2x.png over the
// Hardware@2x.png device frame. Output goes to <lang>/.
// Usage: swift compose.swift

import AppKit

let canvasSize = NSSize(width: 1242, height: 2688)
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let languages = ["ja", "en"]

struct Copy {
    let header: String
    let caption: String
}

struct Screenshot {
    let rawName: String
    let outName: String
    /// Keyed by language code.
    let copy: [String: Copy]
    /// Gradient stops, top to bottom.
    let gradientTop: NSColor
    let gradientBottom: NSColor
}

func color(_ hex: UInt32) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

let screenshots: [Screenshot] = [
    Screenshot(
        rawName: "02-planner",
        outName: "01-planner",
        copy: [
            "ja": Copy(
                header: "オフラインで動く時刻表",
                caption: "東京から取手まで、内蔵の時刻表ですぐ検索"
            ),
            "en": Copy(
                header: "Plan trips offline",
                caption: "Tokyo to Toride from bundled timetables, no signal"
            ),
        ],
        gradientTop: color(0x2A1C5E), gradientBottom: color(0x0E0A1F)
    ),
    Screenshot(
        rawName: "03-journey",
        outName: "02-journey",
        copy: [
            "ja": Copy(
                header: "いま、どこを走ってる？",
                caption: "いまの位置と、つぎの駅までの分数をひと目で"
            ),
            "en": Copy(
                header: "Know where you are",
                caption: "Follow your ride with minutes to every stop"
            ),
        ],
        gradientTop: color(0x0C3B26), gradientBottom: color(0x05130C)
    ),
    Screenshot(
        rawName: "05-lcd-yamanote",
        outName: "03-lcd-yamanote",
        copy: [
            "ja": Copy(
                header: "車内ディスプレイを再現",
                caption: "山手線風など、12種類のLCDスタイルを収録"
            ),
            "en": Copy(
                header: "The in-train display",
                caption: "Twelve LCD styles, including this Yamanote look"
            ),
        ],
        gradientTop: color(0x3A4409), gradientBottom: color(0x121504)
    ),
    Screenshot(
        rawName: "04-lcd-metro",
        outName: "04-lcd-metro",
        copy: [
            "ja": Copy(
                header: "地下鉄でも、そのまま",
                caption: "東京メトロ風の表示で停車駅と残り時間を確認"
            ),
            "en": Copy(
                header: "Underground, on track",
                caption: "A Tokyo Metro style board with minutes left"
            ),
        ],
        gradientTop: color(0x093A52), gradientBottom: color(0x04131B)
    ),
    Screenshot(
        rawName: "06-timetable",
        outName: "05-timetable",
        copy: [
            "ja": Copy(
                header: "駅の時刻表も内蔵",
                caption: "始発から終電まで、全駅の発車時刻を方面別に"
            ),
            "en": Copy(
                header: "Timetables built in",
                caption: "First train to last at every station, by direction"
            ),
        ],
        gradientTop: color(0x333A45), gradientBottom: color(0x101318)
    ),
    Screenshot(
        rawName: "07-avoid",
        outName: "06-customize",
        copy: [
            "ja": Copy(
                header: "苦手な路線は避ける",
                caption: "路線の除外や歩く速さで検索を自分好みに"
            ),
            "en": Copy(
                header: "Route it your way",
                caption: "Skip certain lines and match your walking pace"
            ),
        ],
        gradientTop: color(0x2A1C5E), gradientBottom: color(0x0E0A1F)
    ),
    Screenshot(
        rawName: "08-customline",
        outName: "07-mylines",
        copy: [
            "ja": Copy(
                header: "マイ路線を作ろう",
                caption: "駅も時刻表も自由に設定、ファイルで共有も"
            ),
            "en": Copy(
                header: "Build your own line",
                caption: "Stations, timetables, and badges, all yours to share"
            ),
        ],
        gradientTop: color(0x0B2C63), gradientBottom: color(0x040F22)
    ),
    Screenshot(
        rawName: "01-home",
        outName: "08-favorites",
        copy: [
            "ja": Copy(
                header: "お気に入りからワンタップ",
                caption: "よく使うルートを保存して、ワンタップで出発"
            ),
            "en": Copy(
                header: "One tap to ride",
                caption: "Save your usual routes and start right away"
            ),
        ],
        gradientTop: color(0x2A1C5E), gradientBottom: color(0x0E0A1F)
    ),
]

// MARK: - Fonts

// Hind covers Latin only; Japanese falls back to the system cascade.
func registerHindFonts() {
    let fontsDir = scriptDir
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Overhead/Fonts")
    for file in ["Hind-Bold.ttf", "Hind-SemiBold.ttf", "Hind-Medium.ttf", "Hind-Regular.ttf"] {
        CTFontManagerRegisterFontsForURL(
            fontsDir.appendingPathComponent(file) as CFURL, .process, nil
        )
    }
}

func font(_ name: String, _ size: CGFloat, fallbackWeight: NSFont.Weight) -> NSFont {
    NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size, weight: fallbackWeight)
}

/// Draws one line centered at `top`, shrinking until it fits `maxWidth`.
/// Returns the drawn height.
@discardableResult
func drawLine(
    _ text: String,
    fontName: String,
    size: CGFloat,
    fallbackWeight: NSFont.Weight,
    color: NSColor,
    top: CGFloat,
    maxWidth: CGFloat
) -> CGFloat {
    var fontSize = size
    var attrs: [NSAttributedString.Key: Any] = [:]
    var lineSize = NSSize.zero
    while fontSize > 10 {
        attrs = [
            .font: font(fontName, fontSize, fallbackWeight: fallbackWeight),
            .foregroundColor: color,
        ]
        lineSize = (text as NSString).size(withAttributes: attrs)
        if lineSize.width <= maxWidth { break }
        fontSize -= 2
    }
    (text as NSString).draw(
        at: NSPoint(x: (canvasSize.width - lineSize.width) / 2, y: top - lineSize.height),
        withAttributes: attrs
    )
    return lineSize.height
}

// MARK: - Device frame

let hardwareImage = NSImage(contentsOf: scriptDir.appendingPathComponent("Hardware@2x.png"))!
let displayImage = NSImage(contentsOf: scriptDir.appendingPathComponent("Display@2x.png"))!

func cgImage(of image: NSImage) -> CGImage {
    image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
}

let hardwareCG = cgImage(of: hardwareImage)
let displayCG = cgImage(of: displayImage)
let hardwarePixel = NSSize(width: hardwareCG.width, height: hardwareCG.height)
let displayPixel = NSSize(width: displayCG.width, height: displayCG.height)
// The display mask sits centered within the hardware frame.
let displayOrigin = NSPoint(
    x: (hardwarePixel.width - displayPixel.width) / 2,
    y: (hardwarePixel.height - displayPixel.height) / 2
)

/// The raw capture clipped by the display mask, on a hardware-sized canvas.
func maskedScreen(raw: NSImage) -> NSImage {
    let rawCG = cgImage(of: raw)
    let image = NSImage(size: hardwarePixel)
    image.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    let displayRect = CGRect(origin: displayOrigin, size: displayPixel)
    ctx.clip(to: displayRect, mask: displayCG)

    // Aspect-fill the display area.
    let rawSize = CGSize(width: rawCG.width, height: rawCG.height)
    let scale = max(displayPixel.width / rawSize.width, displayPixel.height / rawSize.height)
    let drawSize = CGSize(width: rawSize.width * scale, height: rawSize.height * scale)
    let drawRect = CGRect(
        x: displayRect.midX - drawSize.width / 2,
        y: displayRect.midY - drawSize.height / 2,
        width: drawSize.width,
        height: drawSize.height
    )
    ctx.draw(rawCG, in: drawRect)
    image.unlockFocus()
    return image
}

// MARK: - Composition

func compose(_ shot: Screenshot, language: String) -> Bool {
    guard let copy = shot.copy[language] else { return false }
    let rawURL = scriptDir
        .appendingPathComponent("Raw")
        .appendingPathComponent(language)
        .appendingPathComponent("\(shot.rawName).png")
    guard let raw = NSImage(contentsOf: rawURL) else {
        print("missing raw capture: \(rawURL.path)")
        return false
    }

    let image = NSImage(size: canvasSize)
    image.lockFocus()

    // Background gradient, top to bottom.
    NSGradient(starting: shot.gradientTop, ending: shot.gradientBottom)?
        .draw(in: NSRect(origin: .zero, size: canvasSize), angle: -90)

    // One-line header and caption. AppKit's origin is bottom-left.
    let textWidth = canvasSize.width - 96
    let headerTop = canvasSize.height - 84
    let headerHeight = drawLine(
        copy.header, fontName: "Hind-Bold", size: 88, fallbackWeight: .bold,
        color: .white, top: headerTop, maxWidth: textWidth
    )
    let captionTop = headerTop - headerHeight - 6
    let captionHeight = drawLine(
        copy.caption, fontName: "Hind-Medium", size: 46, fallbackWeight: .medium,
        color: .white, top: captionTop, maxWidth: textWidth
    )

    // Device: hardware frame below, display-masked capture above.
    let textBottom = captionTop - captionHeight
    let deviceTopMargin: CGFloat = 64
    let deviceBottomMargin: CGFloat = 88
    let availableHeight = textBottom - deviceTopMargin - deviceBottomMargin
    let aspect = hardwarePixel.width / hardwarePixel.height
    var deviceSize = NSSize(width: availableHeight * aspect, height: availableHeight)
    if deviceSize.width > canvasSize.width - 120 {
        deviceSize.width = canvasSize.width - 120
        deviceSize.height = deviceSize.width / aspect
    }
    let deviceRect = NSRect(
        x: ((canvasSize.width - deviceSize.width) / 2).rounded(),
        y: deviceBottomMargin,
        width: deviceSize.width,
        height: deviceSize.height
    )

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.55)
    shadow.shadowBlurRadius = 60
    shadow.shadowOffset = NSSize(width: 0, height: -24)
    shadow.set()
    hardwareImage.draw(in: deviceRect)
    NSGraphicsContext.current?.restoreGraphicsState()

    maskedScreen(raw: raw).draw(in: deviceRect)

    image.unlockFocus()

    // Rasterize at exactly 1242 x 2688 pixels.
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width), pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { return false }
    bitmap.size = canvasSize
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(in: NSRect(origin: .zero, size: canvasSize))
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else { return false }
    let outDir = scriptDir.appendingPathComponent(language)
    try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
    let outURL = outDir.appendingPathComponent("\(shot.outName).png")
    do {
        try png.write(to: outURL)
        print("wrote \(language)/\(outURL.lastPathComponent)")
        return true
    } catch {
        print("failed to write \(outURL.path): \(error)")
        return false
    }
}

registerHindFonts()
var allOK = true
for language in languages {
    for shot in screenshots {
        allOK = compose(shot, language: language) && allOK
    }
}
exit(allOK ? 0 : 1)
