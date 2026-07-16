import SwiftUI
import Backbone

// MARK: - Galaxy LCD View

/// Original space-retro panel: starfield, gold next-station, stops as planets on a dashed orbit.
struct GalaxyLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = designWidth * 9 / 16
    private static let maxStops = 7
    private static let gold = Color(hex: "#E9D28A")
    private static let goldDark = Color(hex: "#C9AB5E")
    private static let cream = Color(hex: "#EFE3C0")
    private static let passedBlue = Color(hex: "#3D466E")
    private static let futureBlue = Color(hex: "#8EA0D8")
    private static let mutedBlue = Color(hex: "#7D88B5")

    // Orbit: a flat parabola low in the panel.
    private static let orbitStart = CGPoint(x: -10, y: 176)
    private static let orbitControl = CGPoint(x: 180, y: 126)
    private static let orbitEnd = CGPoint(x: 370, y: 176)

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / Self.designWidth
            ZStack {
                RadialGradient(
                    colors: [Color(hex: "#16204A"), Color(hex: "#0B1030"), Color(hex: "#060A1E")],
                    center: UnitPoint(x: 0.7, y: 0.1),
                    startRadius: 0, endRadius: 400
                )
                starfield
                nextBlock
                orbit
                plaque
                frame
            }
            .frame(width: Self.designWidth, height: Self.designHeight)
            .scaleEffect(scale, anchor: .topLeading)
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(6)
        .glassEffect(.regular.tint(Color(red: 0.2, green: 0.26, blue: 0.33).opacity(0.4)), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Atmosphere

    private var starfield: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 8.0)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                for i in 0..<70 {
                    let x = CGFloat((i * 97 + 31) % 360)
                    let y = CGFloat((i * 61 + 17) % 190)
                    let r = 0.4 + CGFloat(i % 3) * 0.35
                    let twinkle = 0.3 + 0.45 * abs(sin(t * 0.8 + Double(i)))
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(.white.opacity(twinkle))
                    )
                }
                _ = size
            }
        }
        .allowsHitTesting(false)
    }

    private var frame: some View {
        RoundedRectangle(cornerRadius: 6)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color(hex: "#8A6A2F"), Self.gold,
                        Color(hex: "#8A6A2F"), Self.goldDark,
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 5
            )
            .allowsHitTesting(false)
    }

    // MARK: - Next Station

    private var nextBlock: some View {
        VStack(spacing: 5) {
            Text(headlineLabel)
                .font(.system(size: 10))
                .padding(.leading, 9)
                .foregroundColor(Self.goldDark)

            Text(headlineStation?.name ?? "")
                .font(.system(size: nameSize))
                .kerning(8)
                .padding(.leading, 6)
                .foregroundColor(Self.cream)
                .shadow(color: Self.gold.opacity(0.35), radius: 10)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(spacedRomaji)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Self.mutedBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .offset(y: -46)
    }

    private var nameSize: CGFloat {
        (headlineStation?.name.count ?? 2) > 4 ? 30 : 40
    }

    private var spacedRomaji: String {
        (headlineStation?.nameEn.uppercased() ?? "").map(String.init).joined(separator: " ")
    }

    // MARK: - Orbit

    private var orbit: some View {
        let stops = orbitStops
        return Canvas { ctx, _ in
            var path = Path()
            path.move(to: Self.orbitStart)
            path.addQuadCurve(to: Self.orbitEnd, control: Self.orbitControl)
            ctx.stroke(
                path,
                with: .color(Color(hex: "#4A5480")),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1, 5])
            )

            for (index, stop) in stops.enumerated() {
                let t = stops.count > 1
                    ? 0.08 + 0.84 * Double(index) / Double(stops.count - 1)
                    : 0.5
                let p = orbitPoint(CGFloat(t))

                if stop.isCurrent {
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9)),
                        with: .color(Self.gold)
                    )
                    var ring = Path(ellipseIn: CGRect(x: p.x - 8.5, y: p.y - 3, width: 17, height: 6))
                    ring = ring.applying(
                        CGAffineTransform(translationX: -p.x, y: -p.y)
                            .concatenating(CGAffineTransform(rotationAngle: -16 * .pi / 180))
                            .concatenating(CGAffineTransform(translationX: p.x, y: p.y))
                    )
                    ctx.stroke(ring, with: .color(Self.goldDark), lineWidth: 1.2)
                } else {
                    let r: CGFloat = 3.2
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                        with: .color(stop.isPassed ? Self.passedBlue : Self.futureBlue)
                    )
                }

                let name = ctx.resolve(
                    Text(stop.station.name)
                        .font(.system(size: 6.5, weight: stop.isCurrent ? .bold : .medium))
                        .foregroundColor(stop.isCurrent ? Self.cream : Self.mutedBlue)
                )
                ctx.draw(name, at: CGPoint(x: p.x, y: p.y + 13))
            }
        }
        .overlay(orbitBadges)
        .allowsHitTesting(false)
    }

    /// Real station badges floating above the planets, dimmed once passed.
    private var orbitBadges: some View {
        let stops = orbitStops
        return ZStack {
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                if !stop.station.stationCode.isEmpty {
                    let t = stops.count > 1
                        ? 0.08 + 0.84 * Double(index) / Double(stops.count - 1)
                        : 0.5
                    let p = orbitPoint(CGFloat(t))
                    scaledStationBadge(stop.station, dimension: 11)
                        .grayscale(stop.isPassed ? 1 : 0)
                        .opacity(stop.isPassed ? 0.45 : 0.9)
                        .position(x: p.x, y: p.y - 14)
                }
            }
        }
    }

    private func stationColor(_ station: Station) -> Color {
        StaticTrainData.line(containingStationId: station.id)?.trainLine.color ?? lineColor
    }

    @ViewBuilder
    private func scaledStationBadge(_ station: Station, dimension: CGFloat) -> some View {
        StationNumberBadge(
            code: station.stationCode,
            color: stationColor(station),
            size: .regular,
            stationName: station.name,
            styleOverride: journey.line.badgeStyle
        )
        .scaleEffect(dimension / 28)
        .frame(width: dimension, height: dimension)
    }

    private func orbitPoint(_ t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let x = mt * mt * Self.orbitStart.x + 2 * mt * t * Self.orbitControl.x + t * t * Self.orbitEnd.x
        let y = mt * mt * Self.orbitStart.y + 2 * mt * t * Self.orbitControl.y + t * t * Self.orbitEnd.y
        return CGPoint(x: x, y: y)
    }

    // MARK: - Plaque

    private var plaque: some View {
        Text(verbatim: "銀河急行　\(destinationStation?.name ?? "")ゆき")
            .font(.system(size: 8))
            .foregroundColor(Color(hex: "#3A2A10"))
            .padding(.horizontal, 13)
            .padding(.vertical, 2.5)
            .background(
                LinearGradient(
                    colors: [Self.gold, Color(hex: "#B98F3E")],
                    startPoint: .top, endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 1.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 10)
    }

    // MARK: - Data

    private struct OrbitStop: Identifiable {
        let id: String
        let station: Station
        let isPassed: Bool
        let isCurrent: Bool
    }

    private var orbitStops: [OrbitStop] {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return [] }
        let ref = max(0, min(state.currentStationIndex ?? state.segmentFrom, stations.count - 1))
        let start = max(0, min(ref - 3, stations.count - Self.maxStops))
        let window = stations[start..<min(start + Self.maxStops, stations.count)]
        let ordered = window.enumerated().map { offset, station in
            OrbitStop(
                id: station.id,
                station: station,
                isPassed: start + offset < ref,
                isCurrent: start + offset == ref
            )
        }
        return orientation == .right ? ordered : ordered.reversed()
    }

    private var headlineLabel: String {
        state.currentStationIndex != nil ? "ただいま" : "つぎは"
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
