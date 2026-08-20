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

    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = designWidth * 9 / 16
    private static let headerHeight: CGFloat = 58
    private static let maxStops = 5
    private static let markerRed = Color(hex: "#7A2B20")
    private static let languageFlipSeconds = 4.0

    // Stop layout, dialed in by hand.
    private static let stopT: [CGFloat] = [0.2, 0.33, 0.44, 0.53, 0.62]
    private static let stopRadius: [CGFloat] = [10.7, 10.0, 9.5, 8.2, 7.9]
    private static let labelDX: [CGFloat] = [-5, -8, -13, -4, -4.35]
    private static let labelDY: [CGFloat] = [-2, -3, -6, -11, -12]
    private static let labelSize: [CGFloat] = [21.2, 19.7, 18.4, 17.4, 14.5]
    private static let arrowT: CGFloat = 0.14
    private static let nextGold = Color(hex: "#EFC13D")

    // Cubic sweep, ends past the white edges so the panel clips them flat.
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
                let phase = LCDPhase.of(journey: journey, state: state, now: context.date)
                VStack(spacing: 0) {
                    header(english: english, phase: phase)
                        .frame(height: Self.headerHeight)
                    arcBody(now: context.date, english: english)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: Self.designWidth, height: Self.designHeight)
                .scaleEffect(scale, anchor: .topLeading)
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .modifier(LCDScreenClip())
            .modifier(LCDBezel())
        }
    }

    // MARK: - Header

    private func header(english: Bool, phase: LCDPhase) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(journey.destinationNameJa)
                    .font(LCDFont.gothic(size: 12.5, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(height: 13)
                Text(verbatim: "方面")
                    .font(LCDFont.gothic(size: 6.5, weight: .bold))
                    .frame(height: 7)
            }
            .foregroundColor(.white)
            .frame(width: 54, alignment: .trailing)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.leading, 6)
            .padding(.bottom, 3)

            Rectangle()
                .fill(lineColor)
                .frame(width: 13)
                .padding(.bottom, 3)
                .padding(.leading, 7)

            Text(headlineLabel(english: english, phase: phase))
                .font(english ? LCDFont.latin(size: 10, weight: .bold)
                              : LCDFont.gothic(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 3)
                .padding(.leading, 7)

            spreadName(english: english)
                .frame(maxWidth: .infinity)
                // Cap at the slot height: the gothic name's tall line box
                // would otherwise inflate the row, displacing the flexible
                // and edge-anchored siblings (color bar gap, 次は, 号車).
                .frame(height: Self.headerHeight)
                .padding(.horizontal, namePadding(english: english))
                // Descenders (Mejiro, Nippori) would otherwise graze the bar's
                // bottom edge, so the romaji rides a touch higher than the kanji.
                .offset(y: english ? 1 : 3)

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
        // Pin to the design height: the gothic name's tall line box would
        // otherwise inflate the header, sinking bottom-anchored items under
        // the arc body and pushing the top row off screen.
        .frame(height: Self.headerHeight)
        .background(Color(hue: 0, saturation: 0, brightness: 0.08))
    }

    @ViewBuilder
    private func spreadName(english: Bool) -> some View {
        if let station = headlineStation {
            if english {
                HorizontallySquashed {
                    Text(station.nameEn)
                        .font(LCDFont.latin(size: 46, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            } else {
                let chars = Array(station.name)
                // Four kanji only fit at full height once the gaps tighten and
                // the glyphs give up a few points — otherwise they squash.
                let wide = chars.count >= 4
                HorizontallySquashed {
                    HStack(spacing: wide ? 5 : 90 / CGFloat(max(chars.count, 2))) {
                        ForEach(chars.indices, id: \.self) { i in
                            Text(String(chars[i]))
                                .font(LCDFont.gothic(size: wide ? 42 : 46, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }

    /// The name slot's side inset; four-kanji names need the extra room.
    private func namePadding(english: Bool) -> CGFloat {
        if english { return 6 }
        return (headlineStation?.name.count ?? 0) >= 4 ? 8 : 22
    }

    // MARK: - Arc Body

    private func arcBody(now: Date, english: Bool) -> some View {
        let stops = arcStops(now: now)
        let mirrored = orientation == .right

        return ZStack {
            Canvas { ctx, size in
                func x(_ p: CGPoint) -> CGPoint {
                    mirrored ? CGPoint(x: size.width - p.x, y: p.y) : p
                }

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
                ctx.fill(band, with: .color(lineColor))

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

                for (index, stop) in stops.enumerated() {
                    let t = Self.stopT[min(index, Self.stopT.count - 1)]
                    let p = x(arcPoint(t))
                    let radius = Self.stopRadius[min(index, Self.stopRadius.count - 1)]
                    let circleRect = CGRect(
                        x: p.x - radius, y: p.y - radius,
                        width: radius * 2, height: radius * 2
                    )
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
                        // On the arc's centerline just past the last bubble, so it
                        // follows the band instead of drifting off its lower edge.
                        ctx.draw(
                            ctx.resolve(
                                Text(verbatim: "(分)")
                                    .font(LCDFont.gothic(size: 5.5, weight: .bold))
                                    .foregroundColor(.black)
                            ),
                            at: x(arcPoint(t + 0.05)),
                            anchor: .center
                        )
                    }

                    let labelDX = Self.labelDX[min(index, Self.labelDX.count - 1)]
                    let labelDY = Self.labelDY[min(index, Self.labelDY.count - 1)]
                    let labelSize = Self.labelSize[min(index, Self.labelSize.count - 1)]
                    let name = ctx.resolve(
                        english
                            ? Text(stop.station.nameEn)
                                .font(LCDFont.latin(size: labelSize * 0.8, weight: .bold))
                                .foregroundColor(.black)
                            : Text(stop.station.name)
                                .font(LCDFont.gothic(size: labelSize, weight: .bold))
                                .foregroundColor(.black)
                    )
                    let labelPoint = CGPoint(
                        x: p.x + (mirrored ? clearance - labelDX : -clearance + labelDX),
                        y: p.y + labelDY
                    )
                    let labelAnchor: UnitPoint = mirrored ? .leading : .trailing
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

                let markerCenter = x(arcPoint(Self.arrowT))
                let sx: CGFloat = mirrored ? -1 : 1
                let chevron: [CGPoint] = [
                    CGPoint(x: -15, y: 0),
                    CGPoint(x: 0, y: -6),
                    CGPoint(x: 15, y: 0),
                    CGPoint(x: 15, y: 12),
                    CGPoint(x: 0, y: 6),
                    CGPoint(x: -15, y: 12),
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
        // The arc bezier overshoots the top edge; on screen the Canvas clips
        // it, but ImageRenderer (share/PiP frames) does not — clip explicitly.
        .clipped()
        .overlay(alignment: .bottomTrailing) {
            Text(verbatim: "のりかえ、待合せ時間は含まれません。電車により多少時間が異なります。")
                .font(LCDFont.gothic(size: 5.5))
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

    private var arcShadowColor: Color {
        let ui = UIColor(lineColor)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return lineColor
        }
        return Color(hue: h, saturation: s, brightness: b * 0.55, opacity: a)
    }

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

    private func arcNormal(_ t: CGFloat) -> CGPoint {
        let tangent = arcTangent(t)
        return CGPoint(x: -tangent.y, y: tangent.x)
    }

    // MARK: - Transfer Panel

    @ViewBuilder
    private var transferPanel: some View {
        if let station = headlineStation {
            let lines = transfers(at: station)
            if !lines.isEmpty {
                VStack(alignment: .trailing, spacing: 2.5) {
                    VStack(alignment: .trailing, spacing: 2.5) {
                        Text(verbatim: "\(station.name)駅")
                            .font(LCDFont.gothic(size: 9, weight: .heavy))
                            .frame(height: 10)
                        Text(verbatim: "乗換えのご案内")
                            .font(LCDFont.gothic(size: 7.5, weight: .regular))
                            .frame(height: 8)
                    }
                    .padding(.bottom, 3)

                    ForEach(lines) { line in
                        HStack(spacing: 4) {
                            LineSymbolBadge(symbol: line.lineSymbol, color: line.color, dimension: 9,
                                            styleOverride: line.badgeStyle)
                            Text(line.name)
                                .font(LCDFont.gothic(size: 7, weight: .bold))
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

    /// Nearest first; while dwelling the current station leads ("ただいま"),
    /// else the nearest upcoming stop leads ("次は").
    private func arcStops(now: Date) -> [ArcStop] {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return [] }
        let entries = Dictionary(
            journey.journeyTimetable.map { ($0.stationId, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        let dwellIndex = state.currentStationIndex.map { max(0, min($0, stations.count - 1)) }
        let ref = dwellIndex ?? max(0, min(state.segmentFrom, stations.count - 1))
        let nowSec = Self.railSeconds(at: now)
        let delaySec = state.delayMinutes * 60

        var result: [ArcStop] = []
        if let dwell = dwellIndex {
            result.append(ArcStop(id: stations[dwell].id, station: stations[dwell], minutes: nil))
        }
        result.append(contentsOf:
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
        )
        return Array(result.prefix(Self.maxStops))
    }

    private func headlineLabel(english: Bool, phase: LCDPhase) -> String {
        switch phase {
        case .next: return english ? "Next" : "次は"
        case .approaching: return english ? "Soon" : "まもなく"
        case .dwelling: return english ? "Now at" : "ただいま"
        }
    }

    private var headlineStation: Station? {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return nil }
        let index = state.currentStationIndex ?? state.segmentTo
        return stations[max(0, min(index, stations.count - 1))]
    }

    /// No car data exists; derive a stable 1...10 from the journey ID.
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

    private struct CarNumberSkew: GeometryEffect {
        func effectValue(size: CGSize) -> ProjectionTransform {
            ProjectionTransform(CGAffineTransform(
                a: 1, b: 0, c: -0.18, d: 1,
                tx: 0.18 * size.height / 2, ty: 0
            ))
        }
    }

    private static func railSeconds(at date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let c = cal.dateComponents([.hour, .minute, .second], from: date)
        var s = (c.hour ?? 0) * 3600 + (c.minute ?? 0) * 60 + (c.second ?? 0)
        if s < 4 * 3600 { s += 24 * 3600 }
        return s
    }
}


