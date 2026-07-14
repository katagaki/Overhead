import SwiftUI
import UIKit
import Backbone

// MARK: - LED Matrix View

/// Simulation of the 3-color LED dot-matrix above the doors of older stock:
/// a wide black housing with a 16-row dot grid cycling static JA/EN
/// next-station pages and scrolling full-sentence messages, orange text with
/// green train types and red delay notices.
struct LEDMatrixView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color

    // Fixed design canvas, scaled to the available width so the dot pitch
    // stays proportional on any device.
    private static let designWidth: CGFloat = 360
    private static let gridColumns = 120
    private static let gridRows = LEDRaster.rows
    private static let dotPitch: CGFloat = 2.8
    private static let bezelX: CGFloat = (designWidth - CGFloat(gridColumns) * dotPitch) / 2
    private static let bezelY: CGFloat = 7
    private static let designHeight: CGFloat = CGFloat(gridRows) * dotPitch + bezelY * 2
    private static let staticPageSeconds: Double = 3.8
    private static let scrollDotsPerSecond: Double = 42

    /// Rasterizing is (comparatively) slow; keep pages per message set so
    /// body stays cheap. Keyed by everything the panel says.
    @MainActor private static var pageCache: [String: [LEDPage]] = [:]

    var body: some View {
        let pages = currentPages
        GeometryReader { geo in
            let scale = geo.size.width / Self.designWidth
            ZStack {
                Color(hue: 0, saturation: 0, brightness: 0.05)
                offDots
                onDots(pages)
            }
            .frame(width: Self.designWidth, height: Self.designHeight)
            .scaleEffect(scale, anchor: .topLeading)
        }
        .aspectRatio(Self.designWidth / Self.designHeight, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(6)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }

    /// Unlit LEDs, drawn once — a faint grid so the panel reads as hardware.
    private var offDots: some View {
        Canvas { ctx, _ in
            for row in 0..<Self.gridRows {
                for col in 0..<Self.gridColumns {
                    ctx.fill(
                        Path(ellipseIn: Self.dotRect(col: col, row: row)),
                        with: .color(.white.opacity(0.055))
                    )
                }
            }
        }
    }

    private func onDots(_ pages: [LEDPage]) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, _ in
                guard !pages.isEmpty else { return }
                let (page, columnOffset) = frame(at: context.date, pages: pages)
                for col in 0..<Self.gridColumns {
                    let sourceColumn = col + columnOffset
                    guard sourceColumn >= 0, sourceColumn < page.raster.width else { continue }
                    for row in 0..<Self.gridRows {
                        let colorIndex = page.raster.dot(column: sourceColumn, row: row)
                        guard colorIndex > 0 else { continue }
                        ctx.fill(
                            Path(ellipseIn: Self.dotRect(col: col, row: row)),
                            with: .color(LEDColor(rawValue: colorIndex - 1)!.color)
                        )
                    }
                }
            }
        }
    }

    private static func dotRect(col: Int, row: Int) -> CGRect {
        CGRect(
            x: bezelX + CGFloat(col) * dotPitch,
            y: bezelY + CGFloat(row) * dotPitch,
            width: dotPitch, height: dotPitch
        ).insetBy(dx: dotPitch * 0.14, dy: dotPitch * 0.14)
    }

    // MARK: - Page Cycle

    /// The page on screen at `date` and its scroll offset in source columns.
    /// Static pages hold centered; scrolling pages enter from the right edge
    /// and run off the left.
    private func frame(at date: Date, pages: [LEDPage]) -> (LEDPage, Int) {
        let cycle = pages.reduce(0) { $0 + duration(of: $1) }
        var t = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle)
        for page in pages {
            let d = duration(of: page)
            if t < d {
                if page.scrolls {
                    let travelled = Int(t * Self.scrollDotsPerSecond)
                    return (page, travelled - Self.gridColumns)
                }
                return (page, -(Self.gridColumns - page.raster.width) / 2)
            }
            t -= d
        }
        return (pages[0], 0)
    }

    private func duration(of page: LEDPage) -> Double {
        page.scrolls
            ? Double(page.raster.width + Self.gridColumns) / Self.scrollDotsPerSecond
            : Self.staticPageSeconds
    }

    // MARK: - Messages

    /// Inputs that change what the panel says; rebuild rasters only then.
    private var pageKey: String {
        let stations = journey.journeyStations
        let ref = state.currentStationIndex ?? state.segmentTo
        let id = stations.indices.contains(ref) ? stations[ref].id : ""
        return "\(journey.line.id)|\(journey.service.destinationStationId)|"
            + "\(id)|\(state.currentStationIndex != nil)|\(state.delayMinutes)"
    }

    private var currentPages: [LEDPage] {
        let key = pageKey
        if let cached = Self.pageCache[key] { return cached }
        let built = buildPages()
        Self.pageCache[key] = built
        return built
    }

    private func buildPages() -> [LEDPage] {
        let dwelling = state.currentStationIndex != nil
        guard let station = headlineStation else { return [] }
        let destination = destinationStation
        let type = typeNameJa
        let lineJa = strippedLineName

        var built: [LEDPage] = []
        // Static JA / EN next-station pages.
        built.append(LEDPage(segments: [
            .init(text: dwelling ? "ただいま " : "つぎは ", color: .green),
            .init(text: station.name, color: .orange),
        ], scrolls: false))
        built.append(LEDPage(segments: dwelling
            ? [.init(text: station.nameEn, color: .orange)]
            : [.init(text: "Next ", color: .green),
               .init(text: station.nameEn, color: .orange)],
            scrolls: false))
        // Scrolling full-sentence JA / EN pages.
        built.append(LEDPage(segments: [
            .init(text: "この電車は、\(lineJa) ", color: .orange),
            .init(text: type, color: .green),
            .init(text: " \(destination?.name ?? "")ゆきです。", color: .orange),
        ], scrolls: true))
        built.append(LEDPage(segments: [
            .init(text: "This is the ", color: .orange),
            .init(text: typeNameEn, color: .green),
            .init(text: " train bound for \(destination?.nameEn ?? "").", color: .orange),
        ], scrolls: true))
        if state.delayMinutes > 0 {
            built.append(LEDPage(segments: [
                .init(text: "ただいま、約\(state.delayMinutes)分遅れて運転しております。ご迷惑をおかけいたします。", color: .red),
            ], scrolls: true))
        }
        // A page wider than the panel can't hold statically; scroll it.
        return built.map { page in
            page.raster.width > Self.gridColumns && !page.scrolls
                ? LEDPage(segments: page.segments, scrolls: true)
                : page
        }
    }

    private var headlineStation: Station? {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return nil }
        let index = state.currentStationIndex ?? state.segmentTo
        return stations[max(0, min(index, stations.count - 1))]
    }

    private var destinationStation: Station? {
        journey.line.stations.first { $0.id == journey.service.destinationStationId }
            ?? journey.journeyStations.last
    }

    private var typeNameJa: String {
        journey.service.trainType == .local ? "各駅停車" : journey.service.trainType.displayNameJa
    }

    /// First leg's line name without a trailing train-type qualifier — the
    /// type is spoken separately (常磐線各駅停車 → 常磐線).
    private var strippedLineName: String {
        let component = journey.line.name.components(separatedBy: "〜").first
            ?? journey.line.name
        // Longest first so 特別快速 strips before 快速
        let suffixes = ["通勤快速", "特別快速", "各駅停車", "快速", "急行", "特急"]
        for suffix in suffixes
        where component.hasSuffix(suffix) && component.count > suffix.count {
            return String(component.dropLast(suffix.count))
        }
        return component
    }

    /// "SemiExpress" → "Semi Express"; raw values are already English.
    private var typeNameEn: String {
        journey.service.trainType.rawValue
            .replacingOccurrences(
                of: "([a-z])([A-Z])", with: "$1 $2",
                options: .regularExpression
            )
    }
}

// MARK: - LED Page

private struct LEDPage {
    struct Segment {
        let text: String
        let color: LEDColor
    }

    let segments: [Segment]
    let scrolls: Bool
    let raster: LEDRaster

    init(segments: [Segment], scrolls: Bool) {
        self.segments = segments
        self.scrolls = scrolls
        self.raster = LEDRaster(segments: segments)
    }
}

private enum LEDColor: UInt8 {
    case orange, green, red

    var color: Color {
        switch self {
        case .orange: return Color(hex: "#FF9E00")
        case .green: return Color(hex: "#61E82B")
        case .red: return Color(hex: "#FF3A24")
        }
    }

    var uiColor: UIColor {
        switch self {
        case .orange: return UIColor(red: 1, green: 0.62, blue: 0, alpha: 1)
        case .green: return UIColor(red: 0.38, green: 0.91, blue: 0.17, alpha: 1)
        case .red: return UIColor(red: 1, green: 0.23, blue: 0.14, alpha: 1)
        }
    }
}

// MARK: - LED Raster

/// Text rasterized to the dot grid: draws the colored segments into a
/// 16px-tall bitmap at 1x and quantizes each pixel to off/orange/green/red.
private struct LEDRaster {
    static let rows = 16

    let width: Int
    /// Row-major; 0 = off, else LEDColor.rawValue + 1.
    private let dots: [UInt8]

    func dot(column: Int, row: Int) -> UInt8 {
        dots[row * width + column]
    }

    init(segments: [LEDPage.Segment]) {
        let attributed = NSMutableAttributedString()
        for segment in segments {
            attributed.append(NSAttributedString(
                string: segment.text,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: segment.color.uiColor,
                ]
            ))
        }

        let textSize = attributed.size()
        let width = max(1, Int(ceil(textSize.width)))
        let height = Self.rows

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height), format: format
        ).image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            // Aliased text — one pixel per dot, like a real bitmap font.
            // Antialiased edges otherwise pass the threshold and fatten
            // every stroke.
            ctx.cgContext.setShouldAntialias(false)
            ctx.cgContext.setShouldSmoothFonts(false)
            attributed.draw(at: CGPoint(x: 0, y: (CGFloat(height) - textSize.height) / 2))
        }

        var dots = [UInt8](repeating: 0, count: width * height)
        if let cg = image.cgImage,
           let data = cg.dataProvider?.data,
           let bytes = CFDataGetBytePtr(data) {
            let bytesPerRow = cg.bytesPerRow
            let bytesPerPixel = cg.bitsPerPixel / 8
            for row in 0..<min(height, cg.height) {
                for col in 0..<min(width, cg.width) {
                    let p = row * bytesPerRow + col * bytesPerPixel
                    // Byte order varies (RGBA/BGRA); green is at index 1 in
                    // both, and blue is negligible in every LED color, so
                    // treat max(first, third) as red.
                    let r = max(Int(bytes[p]), Int(bytes[p + 2]))
                    let g = Int(bytes[p + 1])
                    guard r + g > 130 else { continue }  // dark pixel: LED off
                    let led: LEDColor = g > r ? .green : (r > g * 2 ? .red : .orange)
                    dots[row * width + col] = led.rawValue + 1
                }
            }
        }
        self.width = width
        self.dots = dots
    }
}
