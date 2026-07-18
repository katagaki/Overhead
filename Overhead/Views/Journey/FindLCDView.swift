import SwiftUI
import Backbone

// MARK: - FIND LCD View

/// Simulation of the NYC subway R160 FIND display: route bullet + next stop left, LED strip map right.
struct FindLCDView: View {
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
    private static let leftWidth: CGFloat = 104
    private static let maxStops = 9
    private static let headerBlue = Color(hex: "#163A6B")
    private static let ledGreen = Color(hex: "#29E02E")
    private static let ledDim = Color(hex: "#17701A")
    private static let toOrange = Color(hex: "#F0A500")
    private static let stripWhite = Color(hex: "#D9D9D9")

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / Self.designWidth
            HStack(spacing: 0) {
                leftColumn
                    .frame(width: Self.leftWidth)
                Rectangle()
                    .fill(Color(hex: "#2C2C2C"))
                    .frame(width: 1.5)
                strip
                    .frame(maxWidth: .infinity)
            }
            .frame(width: Self.designWidth, height: Self.designHeight)
            .background(Color.black)
            .scaleEffect(scale, anchor: .topLeading)
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .modifier(LCDScreenClip())
        .modifier(LCDBezel())
    }

    // MARK: - Left Column

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "Next Stop:")
                .font(.custom("HelveticaNeue-Bold", size: 9.5))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .frame(height: 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Self.headerBlue)

            VStack(alignment: .leading, spacing: 7) {
                bullet
                Text(headlineStation?.nameEn ?? "")
                    .font(.custom("HelveticaNeue-Bold", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 8)
            .padding(.top, 9)

            Spacer(minLength: 0)

            Text(verbatim: "to \(destinationStation?.nameEn.uppercased() ?? "")")
                .font(.custom("HelveticaNeue-Bold", size: 8.5))
                .foregroundColor(Self.toOrange)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
    }

    private var bullet: some View {
        LineSymbolBadge(symbol: journey.line.lineSymbol, color: displayColor, dimension: 26)
    }

    // MARK: - Strip Map

    private var strip: some View {
        let stops = upcomingStops
        return TimelineView(.periodic(from: .now, by: 0.5)) { context in
            Canvas { ctx, size in
                let blinkOn = Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
                let lineY = size.height - 58
                let mirrored = orientation == .left
                let leadInset: CGFloat = mirrored ? 30 : 13
                let trailInset: CGFloat = mirrored ? 13 : 30

                var line = Path()
                line.move(to: CGPoint(x: 8, y: lineY))
                line.addLine(to: CGPoint(x: size.width - 8, y: lineY))
                ctx.stroke(line, with: .color(Self.stripWhite), lineWidth: 2.5)

                let step = stops.count > 1
                    ? (size.width - leadInset - trailInset) / CGFloat(stops.count - 1)
                    : 0
                for (index, stop) in stops.enumerated() {
                    let slot = mirrored ? stops.count - 1 - index : index
                    let x = leadInset + CGFloat(slot) * step

                    let isNext = index == 0
                    let lit = !isNext || blinkOn
                    let dotRect = CGRect(x: x - 3.75, y: lineY - 3.75, width: 7.5, height: 7.5)
                    ctx.fill(Path(ellipseIn: dotRect), with: .color(lit ? Self.ledGreen : Self.ledDim))
                    if lit {
                        ctx.fill(
                            Path(ellipseIn: dotRect.insetBy(dx: -2, dy: -2)),
                            with: .color(Self.ledGreen.opacity(0.25))
                        )
                    }

                    let name = ctx.resolve(
                        Text(stop.nameEn)
                            .font(.custom("HelveticaNeue-Medium", size: 7.5))
                            .foregroundColor(.white)
                    )
                    ctx.drawLayer { layer in
                        layer.translateBy(x: mirrored ? x - 1 : x + 1, y: lineY - 9)
                        layer.rotate(by: .degrees(mirrored ? 42 : -42))
                        layer.draw(name, at: .zero, anchor: mirrored ? .bottomTrailing : .bottomLeading)
                    }
                }

                let arrowText = mirrored
                    ? "◀ \(destinationStation?.nameEn.uppercased() ?? "")"
                    : "\(destinationStation?.nameEn.uppercased() ?? "") ▶"
                ctx.draw(
                    Text(verbatim: arrowText)
                        .font(.custom("HelveticaNeue-Bold", size: 8))
                        .foregroundColor(Self.stripWhite),
                    at: CGPoint(
                        x: mirrored ? 10 : size.width - 10,
                        y: size.height - 26
                    ),
                    anchor: mirrored ? .leading : .trailing
                )
            }
        }
    }

    // MARK: - Data

    /// The next stops in travel order, starting with the immediate next.
    private var upcomingStops: [Station] {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return [] }
        let entries = Dictionary(
            journey.journeyTimetable.map { ($0.stationId, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        let ref = max(0, min(state.currentStationIndex ?? state.segmentFrom, stations.count - 1))
        return Array(
            stations[min(ref + 1, stations.count)...]
                .filter { entries[$0.id] != nil }
                .prefix(Self.maxStops)
        )
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
