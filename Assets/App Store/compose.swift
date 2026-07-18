#!/usr/bin/env swift
// Composes App Store screenshots (iPhone 6.5", 1242 x 2688) from raw
// simulator captures in Raw/<lang>/: gradient background, header + caption,
// and the capture wrapped in a device frame. Output goes to <lang>/.
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
                caption: "東京から取手まで、内蔵の時刻表からすぐ検索。\n地下でも圏外でも使えます。"
            ),
            "en": Copy(
                header: "Plan trips offline",
                caption: "From Tokyo to Toride with bundled\ntimetables. No signal needed."
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
                caption: "乗車中の位置を駅ごとに追いかけて、\nつぎの停車駅までの分数もひと目で。"
            ),
            "en": Copy(
                header: "Know where you are",
                caption: "Follow your ride station by station,\nwith minutes to every stop."
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
                caption: "山手線風をはじめ、12種類のLCDスタイルを収録。\n気分に合わせて切り替えられます。"
            ),
            "en": Copy(
                header: "The in-train display",
                caption: "Twelve LCD styles to ride with,\nincluding this Yamanote look."
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
                caption: "東京メトロ風の表示で、停車駅と\n残り時間をチェック。"
            ),
            "en": Copy(
                header: "Underground, on track",
                caption: "A Tokyo Metro style board with stops\nand minutes remaining."
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
                caption: "始発から終電まで、全駅の発車時刻。\n方面ごとにさっと確認できます。"
            ),
            "en": Copy(
                header: "Timetables built in",
                caption: "First train to last at every station,\nsorted by direction."
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
                caption: "路線の除外や歩く速さなど、\n検索条件を自分好みに調整。"
            ),
            "en": Copy(
                header: "Route it your way",
                caption: "Exclude lines you would rather skip\nand match your walking pace."
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
                caption: "駅も時刻表もバッジも自由に設定。\n作った路線はファイルで共有できます。"
            ),
            "en": Copy(
                header: "Build your own line",
                caption: "Stations, timetables, and badges, all yours.\nShare finished lines as files."
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
                caption: "よく使うルートを保存して、\nいつもの旅をすぐにスタート。"
            ),
            "en": Copy(
                header: "One tap to ride",
                caption: "Save your usual routes\nand start riding right away."
            ),
        ],
        gradientTop: color(0x2A1C5E), gradientBottom: color(0x0E0A1F)
    ),
]

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
    guard let rawRep = raw.representations.first else { return false }
    let rawPixelSize = NSSize(width: rawRep.pixelsWide, height: rawRep.pixelsHigh)

    let image = NSImage(size: canvasSize)
    image.lockFocus()

    // Background gradient, top to bottom.
    NSGradient(starting: shot.gradientTop, ending: shot.gradientBottom)?
        .draw(in: NSRect(origin: .zero, size: canvasSize), angle: -90)

    // Text block. AppKit's origin is bottom-left, so lay out from the top edge.
    let headerFont = NSFont.systemFont(ofSize: 74, weight: .bold)
    let captionFont = NSFont.systemFont(ofSize: 39, weight: .medium)

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineSpacing = 12

    let headerAttrs: [NSAttributedString.Key: Any] = [
        .font: headerFont,
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph,
    ]
    let captionAttrs: [NSAttributedString.Key: Any] = [
        .font: captionFont,
        .foregroundColor: NSColor.white.withAlphaComponent(0.72),
        .paragraphStyle: paragraph,
    ]

    let textWidth: CGFloat = canvasSize.width - 120
    let headerString = NSAttributedString(string: copy.header, attributes: headerAttrs)
    let captionString = NSAttributedString(string: copy.caption, attributes: captionAttrs)
    let headerHeight = headerString.boundingRect(
        with: NSSize(width: textWidth, height: 400), options: .usesLineFragmentOrigin
    ).height.rounded(.up)
    let captionHeight = captionString.boundingRect(
        with: NSSize(width: textWidth, height: 400), options: .usesLineFragmentOrigin
    ).height.rounded(.up)

    let topPadding: CGFloat = 132
    let headerTop = canvasSize.height - topPadding
    headerString.draw(
        with: NSRect(x: 60, y: headerTop - headerHeight, width: textWidth, height: headerHeight),
        options: .usesLineFragmentOrigin
    )
    let captionTop = headerTop - headerHeight - 36
    captionString.draw(
        with: NSRect(x: 60, y: captionTop - captionHeight, width: textWidth, height: captionHeight),
        options: .usesLineFragmentOrigin
    )

    // Device frame: fill the space under the caption, bottom-anchored.
    let bezel: CGFloat = 32
    let textBottom = captionTop - captionHeight
    let deviceTopMargin: CGFloat = 72
    let deviceBottomMargin: CGFloat = 96
    let availableHeight = textBottom - deviceTopMargin - deviceBottomMargin
    let screenHeight = availableHeight - bezel * 2
    let screenWidth = (screenHeight * rawPixelSize.width / rawPixelSize.height).rounded()
    let screenRect = NSRect(
        x: ((canvasSize.width - screenWidth) / 2).rounded(),
        y: deviceBottomMargin + bezel,
        width: screenWidth,
        height: screenHeight
    )
    let deviceRect = screenRect.insetBy(dx: -bezel, dy: -bezel)

    // Same corner curvature as the hardware: display radius scaled from capture.
    let screenRadius = 190 * screenWidth / rawPixelSize.width
    let deviceRadius = screenRadius + bezel

    // Soft drop shadow behind the device.
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.55)
    shadow.shadowBlurRadius = 60
    shadow.shadowOffset = NSSize(width: 0, height: -24)
    shadow.set()
    let devicePath = NSBezierPath(roundedRect: deviceRect, xRadius: deviceRadius, yRadius: deviceRadius)
    NSColor(srgbRed: 0.09, green: 0.09, blue: 0.10, alpha: 1).setFill()
    devicePath.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    // Screen content clipped to the display corners.
    NSGraphicsContext.current?.saveGraphicsState()
    NSBezierPath(roundedRect: screenRect, xRadius: screenRadius, yRadius: screenRadius).addClip()
    raw.draw(in: screenRect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.current?.restoreGraphicsState()

    // Bezel edge highlight.
    let edgePath = NSBezierPath(
        roundedRect: deviceRect.insetBy(dx: 1.5, dy: 1.5),
        xRadius: deviceRadius - 1.5, yRadius: deviceRadius - 1.5
    )
    edgePath.lineWidth = 3
    NSColor.white.withAlphaComponent(0.16).setStroke()
    edgePath.stroke()

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

var allOK = true
for language in languages {
    for shot in screenshots {
        allOK = compose(shot, language: language) && allOK
    }
}
exit(allOK ? 0 : 1)
