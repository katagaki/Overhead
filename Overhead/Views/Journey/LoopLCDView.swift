import SwiftUI
import UIKit
import Backbone

// MARK: - Loop LCD View

/// Simulation of the E231-era loop-line LCD: stops ride a receding 3D arc as
/// shrinking minute circles, with the next station's transfer guidance on the right.
struct LoopLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    private var displayColor: Color {
        let firstLegId = journey.line.id.split(separator: "+").first.map(String.init)
            ?? journey.line.id
        guard let hex = LineColors.lcdOverrides[firstLegId] else { return lineColor }
        return Color(hex: hex)
    }

    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = designWidth * 9 / 16
    private static let headerHeight: CGFloat = 58
    private static let maxStops = 5
    private static let markerRed = Color(hex: "#7A2B20")
    private static let languageFlipSeconds = 4.0

    // Stop layout, dialed in by hand: arc position, circle radius, per-label nudges.
    private static let stopT: [CGFloat] = [0.2, 0.33, 0.44, 0.53, 0.62]
    private static let stopRadius: [CGFloat] = [10.7, 10.0, 9.5, 8.2, 7.9]
    private static let labelDX: [CGFloat] = [-5, -8, -13, -4, -4.35]
    private static let labelDY: [CGFloat] = [-2, -3, -6, -11, -12]
    private static let labelSize: [CGFloat] = [21.2, 19.7, 18.4, 17.4, 14.5]
    private static let arrowT: CGFloat = 0.14
    private static let nextGold = Color(hex: "#EFC13D")

    // Cubic sweep, ends past the white edges so the panel clips them flat;
    // dialed in by hand.
    private static let arcNear = CGPoint(x: 114, y: 176)
    private static let arcControl1 = CGPoint(x: 113, y: 60)
    private static let arcControl2 = CGPoint(x: 267, y: -5)
    private static let arcFar = CGPoint(x: 401.4, y: -10.3)

    // Eased taper: hold width through the middle, shed it near the tip.
    private static func arcWidth(_ t: CGFloat) -> CGFloat {
        51.4 - 46.8 * pow(t, 1.15)
    }

    private static let allLines = StaticTrainData.trainLines()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            GeometryReader { geo in
                let scale = geo.size.width / Self.designWidth
                let english = Int(
                    context.date.timeIntervalSinceReferenceDate / Self.languageFlipSeconds
                ) % 2 == 1
                VStack(spacing: 0) {
                    header(english: english)
                        .frame(height: Self.headerHeight)
                    arcBody(now: context.date)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: Self.designWidth, height: Self.designHeight)
                .scaleEffect(scale, anchor: .topLeading)
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(6)
            .glassEffect(.regular.tint(Color(red: 0.2, green: 0.26, blue: 0.33).opacity(0.4)), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Header

    private func header(english: Bool) -> some View {
        HStack(spacing: 0) {
            // Terminal, hugging the bottom.
            VStack(alignment: .trailing, spacing: -1) {
                Text(destinationStation?.name ?? "")
                    .font(.system(size: 12.5, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(verbatim: "方面")
                    .font(.system(size: 6.5, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(width: 54, alignment: .trailing)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.leading, 6)
            .padding(.bottom, 3)

            Rectangle()
                .fill(displayColor)
                .frame(width: 13)
                .padding(.bottom, 3)
                .padding(.leading, 7)

            // Top-aligned with the color box.
            Text(english ? "Next" : headlineLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 3)
                .padding(.leading, 7)

            spreadName(english: english)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .offset(y: 3)

            // Car number, stacked and sheared, tucked into the top-right corner.
            VStack(alignment: .center, spacing: -2) {
                Text(verbatim: "\(carNumber)")
                    .font(.system(size: 14, weight: .regular))
                Text(verbatim: "号車")
                    .font(.system(size: 6.5, weight: .regular))
            }
            .foregroundColor(.white)
            .modifier(CarNumberSkew())
            .frame(maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 3)
            .padding(.leading, 8)
            .padding(.trailing, 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hue: 0, saturation: 0, brightness: 0.08))
    }

    /// The station name spread across the header; English stays one centered run.
    @ViewBuilder
    private func spreadName(english: Bool) -> some View {
        if let station = headlineStation {
            if english {
                Text(station.nameEn)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            } else {
                // Fixed gaps scaled to name length so short names still spread;
                // long names squash horizontally to stay on one line.
                let chars = Array(station.name)
                HorizontallySquashed {
                    HStack(spacing: 90 / CGFloat(max(chars.count, 2))) {
                        ForEach(chars.indices, id: \.self) { i in
                            Text(String(chars[i]))
                                .font(.system(size: 46, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Arc Body

    private func arcBody(now: Date) -> some View {
        let stops = upcomingStops(now: now)
        let mirrored = orientation == .right

        return ZStack {
            Canvas { ctx, size in
                func x(_ p: CGPoint) -> CGPoint {
                    mirrored ? CGPoint(x: size.width - p.x, y: p.y) : p
                }

                // Tapered band as one filled polygon: each edge is the
                // centerline offset along its normal by the local half-width.
                let samples = 25
                var upperEdge: [CGPoint] = []
                var lowerEdge: [CGPoint] = []
                for i in 0...samples {
                    let t = CGFloat(i) / CGFloat(samples)
                    let p = arcPoint(t)
                    let n = arcNormal(t)
                    let half = Self.arcWidth(t) / 2
                    upperEdge.append(x(CGPoint(x: p.x - n.x * half, y: p.y - n.y * half)))
                    lowerEdge.append(x(CGPoint(x: p.x + n.x * half, y: p.y + n.y * half)))
                }
                var band = Path()
                band.move(to: upperEdge[0])
                for p in upperEdge.dropFirst() { band.addLine(to: p) }
                for p in lowerEdge.reversed() { band.addLine(to: p) }
                band.closeSubpath()
                ctx.fill(band, with: .color(displayColor))

                // Faux depth: a shadow line hugging the band's lower edge.
                var shadow = Path()
                for (i, t) in (0...samples).map({ (CGFloat($0) / CGFloat(samples)) }).enumerated() {
                    let p = arcPoint(t)
                    let n = arcNormal(t)
                    let offset = Self.arcWidth(t) / 2 + 1.5
                    let point = x(CGPoint(x: p.x + n.x * offset, y: p.y + n.y * offset))
                    if i == 0 { shadow.move(to: point) } else { shadow.addLine(to: point) }
                }
                ctx.stroke(
                    shadow, with: .color(arcShadowColor),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .butt)
                )

                // Stops: minute circles shrinking with distance.
                for (index, stop) in stops.enumerated() {
                    let t = Self.stopT[min(index, Self.stopT.count - 1)]
                    let p = x(arcPoint(t))
                    let radius = Self.stopRadius[min(index, Self.stopRadius.count - 1)]
                    let circleRect = CGRect(
                        x: p.x - radius, y: p.y - radius,
                        width: radius * 2, height: radius * 2
                    )
                    // The nearest stop rides a gold circle with a white rim.
                    ctx.fill(
                        Path(ellipseIn: circleRect),
                        with: .color(index == 0 ? Self.nextGold : .white)
                    )
                    if index == 0 {
                        ctx.stroke(
                            Path(ellipseIn: circleRect),
                            with: .color(.white),
                            lineWidth: 1.5
                        )
                    }

                    if let minutes = stop.minutes {
                        ctx.draw(
                            ctx.resolve(
                                Text(verbatim: "\(minutes)")
                                    .font(.system(size: radius * 0.95, weight: .heavy))
                                    .foregroundColor(.black)
                            ),
                            at: p
                        )
                    }
                    let clearance = Self.arcWidth(t) / 2 + 7
                    if index == stops.count - 1 {
                        ctx.draw(
                            ctx.resolve(
                                Text(verbatim: "(分)")
                                    .font(.system(size: 5.5, weight: .bold))
                                    .foregroundColor(.black)
                            ),
                            at: CGPoint(
                                x: p.x + (mirrored ? -clearance : clearance),
                                y: p.y
                            ),
                            anchor: mirrored ? .trailing : .leading
                        )
                    }

                    let labelDX = Self.labelDX[min(index, Self.labelDX.count - 1)]
                    let labelDY = Self.labelDY[min(index, Self.labelDY.count - 1)]
                    let name = ctx.resolve(
                        Text(stop.station.name)
                            .font(.system(
                                size: Self.labelSize[min(index, Self.labelSize.count - 1)],
                                weight: .bold
                            ))
                            .foregroundColor(.black)
                    )
                    let labelPoint = CGPoint(
                        x: p.x + (mirrored ? clearance - labelDX : -clearance + labelDX),
                        y: p.y + labelDY
                    )
                    let labelAnchor: UnitPoint = mirrored ? .leading : .trailing
                    // Long names would run off the screen edge the label grows
                    // toward, so squash them horizontally to fit that gap.
                    let labelRoom = mirrored
                        ? size.width - labelPoint.x - 4
                        : labelPoint.x - 4
                    let nameWidth = name.measure(in: CGSize(width: 1000, height: 1000)).width
                    let labelScale = nameWidth > labelRoom && labelRoom > 0
                        ? labelRoom / nameWidth : 1
                    if labelScale < 1 {
                        ctx.drawLayer { layer in
                            layer.translateBy(x: labelPoint.x, y: labelPoint.y)
                            layer.scaleBy(x: labelScale, y: 1)
                            layer.draw(name, at: .zero, anchor: labelAnchor)
                        }
                    } else {
                        ctx.draw(name, at: labelPoint, anchor: labelAnchor)
                    }
                }

                // The train: an upward chevron, rotated toward the direction of travel.
                let markerCenter = x(arcPoint(Self.arrowT))
                let sx: CGFloat = mirrored ? -1 : 1
                let chevron: [CGPoint] = [
                    CGPoint(x: -15, y: 0),   // left arm end, top
                    CGPoint(x: 0, y: -6),    // apex, outer
                    CGPoint(x: 15, y: 0),    // right arm end, top
                    CGPoint(x: 15, y: 12),   // right arm end, bottom
                    CGPoint(x: 0, y: 6),     // apex, inner
                    CGPoint(x: -15, y: 12),  // left arm end, bottom
                ]
                var marker = Path()
                marker.move(to: CGPoint(x: sx * chevron[0].x, y: chevron[0].y))
                for p in chevron.dropFirst() {
                    marker.addLine(to: CGPoint(x: sx * p.x, y: p.y))
                }
                marker.closeSubpath()
                ctx.drawLayer { layer in
                    layer.translateBy(x: markerCenter.x, y: markerCenter.y)
                    layer.rotate(by: .degrees(mirrored ? -24 : 24))
                    layer.fill(marker, with: .color(Self.markerRed))
                    layer.stroke(marker, with: .color(.white), lineWidth: 1.8)
                }
            }

            transferPanel
                .frame(
                    maxWidth: .infinity, maxHeight: .infinity,
                    alignment: mirrored ? .bottomLeading : .bottomTrailing
                )
                .padding(.bottom, 13)
                .padding(mirrored ? .leading : .trailing, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .overlay(alignment: .bottomTrailing) {
            Text(verbatim: "のりかえ、待合せ時間は含まれません。電車により多少時間が異なります。")
                .font(.system(size: 5.5))
                .foregroundColor(.black.opacity(0.55))
                .padding(.trailing, 5)
                .padding(.bottom, 2)
        }
    }

    private func arcPoint(_ t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let a = mt * mt * mt
        let b = 3 * mt * mt * t
        let c = 3 * mt * t * t
        let d = t * t * t
        return CGPoint(
            x: a * Self.arcNear.x + b * Self.arcControl1.x + c * Self.arcControl2.x + d * Self.arcFar.x,
            y: a * Self.arcNear.y + b * Self.arcControl1.y + c * Self.arcControl2.y + d * Self.arcFar.y
        )
    }

    /// The band's shadow: the line color, darkened.
    private var arcShadowColor: Color {
        let ui = UIColor(displayColor)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return displayColor
        }
        return Color(hue: h, saturation: s, brightness: b * 0.55, opacity: a)
    }

    /// Unit tangent to the arc, pointing up it (toward the far end).
    private func arcTangent(_ t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let a = 3 * mt * mt
        let b = 6 * mt * t
        let c = 3 * t * t
        let dx = a * (Self.arcControl1.x - Self.arcNear.x)
            + b * (Self.arcControl2.x - Self.arcControl1.x)
            + c * (Self.arcFar.x - Self.arcControl2.x)
        let dy = a * (Self.arcControl1.y - Self.arcNear.y)
            + b * (Self.arcControl2.y - Self.arcControl1.y)
            + c * (Self.arcFar.y - Self.arcControl2.y)
        let length = max(sqrt(dx * dx + dy * dy), 0.001)
        return CGPoint(x: dx / length, y: dy / length)
    }

    /// Unit normal to the arc pointing toward its lower-right side.
    private func arcNormal(_ t: CGFloat) -> CGPoint {
        let tangent = arcTangent(t)
        // Rotating the tangent -90° puts the normal on the lower-right side.
        return CGPoint(x: -tangent.y, y: tangent.x)
    }

    // MARK: - Transfer Panel

    @ViewBuilder
    private var transferPanel: some View {
        if let station = headlineStation {
            let lines = transfers(at: station)
            if !lines.isEmpty {
                VStack(alignment: .trailing, spacing: 2.5) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(verbatim: "\(station.name)駅")
                            .font(.system(size: 9, weight: .heavy))
                        Text(verbatim: "乗換えのご案内")
                            .font(.system(size: 7.5, weight: .regular))
                    }
                    .padding(.bottom, 3)

                    ForEach(lines) { line in
                        HStack(spacing: 4) {
                            LineSymbolBadge(symbol: line.lineSymbol, color: line.color, dimension: 9)
                            Text(line.name)
                                .font(.system(size: 7, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }
                .foregroundColor(.black)
                .frame(width: 92, alignment: .trailing)
            }
        }
    }

    // MARK: - Data

    private struct ArcStop: Identifiable {
        let id: String
        let station: Station
        let minutes: Int?
    }

    /// The next stops in travel order with minutes to arrival, nearest first.
    private func upcomingStops(now: Date) -> [ArcStop] {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return [] }
        let entries = Dictionary(
            journey.journeyTimetable.map { ($0.stationId, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        let ref = max(0, min(state.currentStationIndex ?? state.segmentFrom, stations.count - 1))
        let nowSec = Self.railSeconds(at: now)
        let delaySec = state.delayMinutes * 60

        return Array(
            stations[min(ref + 1, stations.count)...]
                .compactMap { station -> ArcStop? in
                    guard let entry = entries[station.id] else { return nil }
                    let arr = entry.arrivalSeconds() ?? entry.departureSeconds()
                    return ArcStop(
                        id: station.id,
                        station: station,
                        minutes: arr.map { max(0, ($0 + delaySec - nowSec + 59) / 60) }
                    )
                }
                .prefix(Self.maxStops)
        )
    }

    private var headlineLabel: String {
        state.currentStationIndex != nil ? "ただいま" : "次は"
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

    /// No car data exists — derive a stable 1...10 from the journey ID.
    private var carNumber: Int {
        Int(journey.id.uuid.0 % 10) + 1
    }

    private func transfers(at station: Station) -> [TrainLine] {
        guard !journey.line.isCustom else { return [] }
        let ridden = Set(journey.line.id.split(separator: "+").map(String.init))
        return Array(
            Self.allLines
                .filter { line in
                    !ridden.contains(line.id)
                        && line.stations.contains { $0.name == station.name }
                }
                .prefix(6)
        )
    }

    /// Synthetic italic — system fonts don't oblique CJK glyphs.
    private struct CarNumberSkew: GeometryEffect {
        func effectValue(size: CGSize) -> ProjectionTransform {
            ProjectionTransform(CGAffineTransform(
                a: 1, b: 0, c: -0.18, d: 1,
                tx: 0.18 * size.height / 2, ty: 0
            ))
        }
    }

    /// Seconds since midnight JST; early-morning hours count as 24:00+.
    private static func railSeconds(at date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let c = cal.dateComponents([.hour, .minute, .second], from: date)
        var s = (c.hour ?? 0) * 3600 + (c.minute ?? 0) * 60 + (c.second ?? 0)
        if s < 4 * 3600 { s += 24 * 3600 }
        return s
    }
}


