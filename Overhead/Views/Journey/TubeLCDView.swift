import SwiftUI
import UIKit
import Backbone

// MARK: - Tube LCD View

struct TubeLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color

    private static let designWidth: CGFloat = 360
    private static let gridColumns = 150
    private static let gridRows = MonoLEDRaster.rows
    private static let dotPitch: CGFloat = 2.2
    private static let bezelX: CGFloat = (designWidth - CGFloat(gridColumns) * dotPitch) / 2
    private static let bezelY: CGFloat = 9
    private static let designHeight: CGFloat = CGFloat(gridRows) * dotPitch + bezelY * 2
    private static let staticPageSeconds: Double = 3.6
    private static let scrollDotsPerSecond: Double = 42
    private static let amber = Color(hex: "#FF9200")

    @MainActor private static var pageCache: [String: [TubePage]] = [:]

    var body: some View {
        let pages = currentPages
        GeometryReader { geo in
            let scale = geo.size.width / Self.designWidth
            ZStack {
                Color(hue: 0.08, saturation: 0.3, brightness: 0.04)
                offDots
                onDots(pages)
            }
            .frame(width: Self.designWidth, height: Self.designHeight)
            .scaleEffect(scale, anchor: .topLeading)
        }
        .aspectRatio(Self.designWidth / Self.designHeight, contentMode: .fit)
        .modifier(LCDScreenClip())
        .modifier(LCDBezel())
    }

    private var offDots: some View {
        Canvas { ctx, _ in
            for row in 0..<Self.gridRows {
                for col in 0..<Self.gridColumns {
                    ctx.fill(
                        Path(ellipseIn: Self.dotRect(col: col, row: row)),
                        with: .color(Self.amber.opacity(0.07))
                    )
                }
            }
        }
    }

    private func onDots(_ pages: [TubePage]) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, _ in
                guard !pages.isEmpty else { return }
                let (page, columnOffset) = frame(at: context.date, pages: pages)
                for col in 0..<Self.gridColumns {
                    let sourceColumn = col + columnOffset
                    guard sourceColumn >= 0, sourceColumn < page.raster.width else { continue }
                    for row in 0..<Self.gridRows where page.raster.isOn(column: sourceColumn, row: row) {
                        ctx.fill(
                            Path(ellipseIn: Self.dotRect(col: col, row: row)),
                            with: .color(Self.amber)
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

    private func frame(at date: Date, pages: [TubePage]) -> (TubePage, Int) {
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

    private func duration(of page: TubePage) -> Double {
        page.scrolls
            ? Double(page.raster.width + Self.gridColumns) / Self.scrollDotsPerSecond
            : Self.staticPageSeconds
    }

    // MARK: - Messages

    private var pageKey: String {
        let stations = journey.journeyStations
        let ref = state.currentStationIndex ?? state.segmentTo
        let id = stations.indices.contains(ref) ? stations[ref].id : ""
        return "\(journey.line.id)|\(journey.service.destinationStationId)|"
            + "\(id)|\(state.currentStationIndex != nil)|\(state.delayMinutes)"
    }

    private var currentPages: [TubePage] {
        let key = pageKey
        if let cached = Self.pageCache[key] { return cached }
        let built = buildPages()
        Self.pageCache[key] = built
        return built
    }

    private func buildPages() -> [TubePage] {
        guard let station = headlineStation else { return [] }
        let dwelling = state.currentStationIndex != nil
        let destEn = destinationStation?.nameEn ?? ""
        var pages: [TubePage] = []
        pages.append(TubePage(text: dwelling
            ? "This station is \(station.nameEn)"
            : "Next station: \(station.nameEn)"))
        pages.append(TubePage(text: "This train is for \(destEn)"))
        if state.delayMinutes > 0 {
            pages.append(TubePage(text: "This train is delayed by approx. \(state.delayMinutes) min"))
        }
        return pages.map { page in
            page.raster.width > Self.gridColumns
                ? TubePage(text: page.text, scrolls: true)
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
}

// MARK: - Tube Page

private struct TubePage {
    let text: String
    let scrolls: Bool
    let raster: MonoLEDRaster

    init(text: String, scrolls: Bool = false) {
        self.text = text
        self.scrolls = scrolls
        self.raster = MonoLEDRaster(text: text)
    }
}

// MARK: - Mono LED Raster

private struct MonoLEDRaster {
    static let rows = 16

    let width: Int
    private let dots: [Bool]

    func isOn(column: Int, row: Int) -> Bool {
        dots[row * width + column]
    }

    init(text: String) {
        // 16-dot bitmap gothic; at 15pt its dots land on the pixel grid.
        let font = UIFont(name: "DotGothic16-Regular", size: 15)
            ?? UIFont.systemFont(ofSize: 14, weight: .regular)

        let attributed = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: UIColor.white,
        ])

        let width = max(1, Int(ceil(attributed.size().width)))
        let height = Self.rows

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height), format: format
        ).image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            ctx.cgContext.setShouldAntialias(false)
            ctx.cgContext.setShouldSmoothFonts(false)
            // Baseline pinned to an integer row so the dot grid stays aligned.
            attributed.draw(at: CGPoint(x: 0, y: 14 - font.ascender))
        }

        var dots = [Bool](repeating: false, count: width * height)
        if let cg = image.cgImage,
           let data = cg.dataProvider?.data,
           let bytes = CFDataGetBytePtr(data) {
            let bytesPerRow = cg.bytesPerRow
            let bytesPerPixel = cg.bitsPerPixel / 8
            for row in 0..<min(height, cg.height) {
                for col in 0..<min(width, cg.width) {
                    let p = row * bytesPerRow + col * bytesPerPixel
                    let r = max(Int(bytes[p]), Int(bytes[p + 2]))
                    let g = Int(bytes[p + 1])
                    if r + g > 130 { dots[row * width + col] = true }
                }
            }
        }
        self.width = width
        self.dots = dots
    }
}
