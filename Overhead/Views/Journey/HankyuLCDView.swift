import SwiftUI
import Backbone

// MARK: - Hankyu LCD View

/// Simulation of the Hankyu 1000-series half-size ultra-wide LCD: glossy two-tone header over a tinted route map.
struct HankyuLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = 110
    private static let headerHeight: CGFloat = 22
    private static let maxStops = 16
    private static let inkBlack = Color(hex: "#23241F")
    private static let tabBlack = Color(hex: "#2B2A30")
    private static let passedGray = Color(hex: "#A9AAA4")
    private static let nextYellow = Color(hex: "#FFE60D")
    private static let markerRed = Color(hex: "#E60012")

    private var mapBackground: some View {
        Color.white.overlay(lineColor.opacity(0.14))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            GeometryReader { geo in
                let scale = geo.size.width / Self.designWidth
                let phase = LCDPhase.of(journey: journey, state: state, now: context.date)
                VStack(spacing: 0) {
                    header(phase: phase)
                        .frame(height: Self.headerHeight)
                    Rectangle()
                        .fill(Color(hex: "#8F9296"))
                        .frame(height: 1)
                    map
                        .frame(maxHeight: .infinity)
                }
                .frame(width: Self.designWidth, height: Self.designHeight)
                .scaleEffect(scale, anchor: .topLeading)
            }
            .aspectRatio(Self.designWidth / Self.designHeight, contentMode: .fit)
            .modifier(LCDScreenClip())
            .modifier(LCDBezel())
        }
    }

    // MARK: - Header

    private func header(phase: LCDPhase) -> some View {
        HStack(spacing: 7) {
            typeTab

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(destinationStation?.name ?? "")
                    .font(.system(size: 12.5, weight: .bold))
                Text(verbatim: "ゆき")
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundColor(.white)
            .lineLimit(1)

            Spacer(minLength: 4)

            HStack(alignment: .center, spacing: 4) {
                Text(headlineLabel(phase: phase))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 3) {
                    HorizontallySquashed(maxWidth: 120) {
                        Text(headlineStation?.name ?? "")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Self.inkBlack)
                            .lineLimit(1)
                    }
                    if let station = headlineStation, !station.stationCode.isEmpty {
                        scaledStationBadge(station, dimension: 13)
                    }
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(RoundedRectangle(cornerRadius: 1.5).fill(Color.white))
                Text(verbatim: "です")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(headerBackground)
    }

    private var typeTab: some View {
        let radius: CGFloat = 8.5
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: radius,
            topTrailingRadius: radius
        )
        return Text(typeName)
            .font(.system(size: 10, weight: .heavy))
            .kerning(typeName.count <= 2 ? 8 : 1)
            .foregroundColor(.white)
            .padding(.leading, typeName.count <= 2 ? 18 : 10)
            .padding(.trailing, typeName.count <= 2 ? 10 : 9)
            .frame(maxHeight: .infinity)
            .background(
                shape.fill(
                    LinearGradient(
                        colors: [Self.tabBlack.luminanceScaled(by: 1.5), Self.tabBlack],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            )
            .overlay(shape.strokeBorder(Color.white, lineWidth: 1.2))
            .padding(.vertical, 1.5)
            .padding(.leading, -1.5)
    }

    private var headerBackground: some View {
        ZStack {
            lineColor
            DiagonalSplitShape(topFraction: 0.516, bottomFraction: 0.566)
                .fill(lineColor.hsbScaled(saturation: 1, brightness: 0.72))
            DiagonalSplitShape(topFraction: 0.52, bottomFraction: 0.57)
                .fill(lineColor.hsbScaled(saturation: 0.45, brightness: 1.08))
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.30), location: 0),
                    .init(color: .white.opacity(0.06), location: 0.45),
                    .init(color: .clear, location: 0.55),
                    .init(color: .black.opacity(0.10), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Route Map

    private static let captionHeight: CGFloat = 9
    private static let circleRowHeight: CGFloat = 14
    private static let lineHeight: CGFloat = 10.5
    private static let circleCenterFromBottom: CGFloat = 3 + captionHeight + 2 + circleRowHeight / 2

    private func lineGradient(_ base: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                base.luminanceScaled(by: 1.45),
                base,
                base.luminanceScaled(by: 0.62),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var map: some View {
        let model = mapModel

        return ZStack(alignment: .bottom) {
            routeLine(model: model)

            columns(model: model)

            trainMarker(model: model)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(mapBackground)
    }

    private func columns(model: MapModel) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
                ForEach(model.stops) { col in
                    VStack(spacing: 2) {
                        verticalName(col.station.name, passed: col.isPassed, current: col.isNext)
                            .frame(height: 44, alignment: .bottom)
                        stationCircle(col)
                            .frame(height: Self.circleRowHeight)
                        transferCaption(for: col.station)
                            .frame(height: Self.captionHeight, alignment: .top)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 3)
    }

    private func routeLine(model: MapModel) -> some View {
        GeometryReader { geo in
            let count = model.stops.count
            if count > 1 {
                let colWidth = (geo.size.width - 16) / CGFloat(count)
                let centerX = { (i: CGFloat) -> CGFloat in 8 + colWidth * (i + 0.5) }
                let x0 = centerX(0)
                let x1 = centerX(CGFloat(count - 1))
                let originX = orientation == .right ? x0 : x1
                let y = geo.size.height - Self.circleCenterFromBottom

                ZStack {
                    Rectangle()
                        .fill(lineGradient(lineColor))
                        .frame(width: x1 - x0, height: Self.lineHeight)
                        .position(x: (x0 + x1) / 2, y: y)
                    if let trainPos = model.trainPos {
                        let chevronX = centerX(CGFloat(trainPos))
                        Rectangle()
                            .fill(lineGradient(Self.passedGray))
                            .frame(width: abs(chevronX - originX), height: Self.lineHeight)
                            .position(x: (originX + chevronX) / 2, y: y)
                    }
                }
            }
        }
    }

    private func trainMarker(model: MapModel) -> some View {
        GeometryReader { geo in
            let count = model.stops.count
            if count > 1, let trainPos = model.trainPos {
                let colWidth = (geo.size.width - 16) / CGFloat(count)
                ZStack {
                    TrainChevronShape()
                        .fill(Self.markerRed)
                    TrainChevronShape()
                        .stroke(Color.white, lineWidth: 1.2)
                }
                .frame(width: 8, height: 12)
                .scaleEffect(x: orientation == .right ? 1 : -1)
                .position(
                    x: 8 + colWidth * (CGFloat(trainPos) + 0.5),
                    y: geo.size.height - Self.circleCenterFromBottom
                )
            }
        }
    }

    private func stationCircle(_ col: MapStop) -> some View {
        Circle()
            .fill(col.isNext ? Self.nextYellow : Color.white)
            .overlay(
                Circle().stroke(
                    col.isPassed ? Self.passedGray : lineColor,
                    lineWidth: 1
                )
            )
            .frame(width: 9.5, height: 9.5)
    }

    private func verticalName(_ name: String, passed: Bool, current: Bool) -> some View {
        VerticalStationName(name: name, fontSize: 7.5, weight: current ? .heavy : .bold,
                            charBox: 8.5, availableHeight: 44,
                            color: passed ? Self.passedGray : Self.inkBlack,
                            columnAnchor: .bottom)
    }

    @ViewBuilder
    private func transferCaption(for station: Station) -> some View {
        let transfers = transferLines(at: station)
        if transfers.isEmpty {
            Color.clear
        } else {
            VStack(spacing: 0) {
                ForEach(transfers.prefix(2), id: \.id) { line in
                    Text(line.name)
                        .font(.system(size: 4.6, weight: .bold))
                        .foregroundColor(Color(hex: line.colorHex))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
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

    // MARK: - Data

    private struct TransferLine {
        let id: String
        let name: String
        let colorHex: String
    }

    private static let transferLinesByStationName: [String: [TransferLine]] = {
        var map: [String: [TransferLine]] = [:]
        for trainLine in StaticTrainData.trainLines() {
            for station in trainLine.stations {
                map[station.name, default: []].append(
                    TransferLine(id: trainLine.id, name: trainLine.name, colorHex: trainLine.colorHex)
                )
            }
        }
        return map
    }()

    private func transferLines(at station: Station) -> [TransferLine] {
        let legIds = Set(journey.line.id.split(separator: "+").map(String.init))
        var seenNames: Set<String> = [journey.line.name]
        var result: [TransferLine] = []
        for line in Self.transferLinesByStationName[station.name] ?? []
        where !legIds.contains(line.id) && seenNames.insert(line.name).inserted {
            result.append(line)
        }
        return result
    }

    private struct MapStop: Identifiable {
        let id: String
        let station: Station
        let isPassed: Bool
        let isNext: Bool
    }

    private struct MapModel {
        let stops: [MapStop]
        let trainPos: Double?
    }

    private var mapModel: MapModel {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return MapModel(stops: [], trainPos: 0) }
        let ref = max(0, min(state.currentStationIndex ?? state.segmentFrom, stations.count - 1))
        let start = max(0, min(ref - 5, stations.count - Self.maxStops))
        let window = Array(stations[start..<min(start + Self.maxStops, stations.count)])

        let headline = headlineIndex
        let rawPos = Double(headline - start) - 0.42
        let travelPos: Double? = rawPos < 0 ? nil : min(rawPos, Double(window.count - 1))

        let ordered = window.enumerated().map { offset, station in
            MapStop(
                id: "\(start + offset)-\(station.id)",
                station: station,
                isPassed: start + offset < headline,
                isNext: start + offset == headline
            )
        }
        return MapModel(
            stops: orientation == .right ? ordered : ordered.reversed(),
            trainPos: travelPos.map { orientation == .right ? $0 : Double(window.count - 1) - $0 }
        )
    }

    private func headlineLabel(phase: LCDPhase) -> String {
        switch phase {
        case .next: return "つぎは"
        case .approaching: return "まもなく"
        case .dwelling: return "ただいま"
        }
    }

    private var headlineIndex: Int {
        let stations = journey.journeyStations
        let index = state.currentStationIndex ?? state.segmentTo
        return max(0, min(index, stations.count - 1))
    }

    private var headlineStation: Station? {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return nil }
        return stations[headlineIndex]
    }

    private var destinationStation: Station? {
        journey.line.stations.first { $0.id == journey.service.destinationStationId }
            ?? journey.journeyStations.last
    }

    private var typeName: String {
        journey.service.trainType == .local ? "普通" : journey.service.trainType.displayNameJa
    }
}

private struct DiagonalSplitShape: Shape {
    let topFraction: CGFloat
    let bottomFraction: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * topFraction, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * bottomFraction, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct TrainChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = rect.height
        let armWidth = rect.width * 0.45
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: armWidth, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: h / 2))
        path.addLine(to: CGPoint(x: armWidth, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: rect.width - armWidth, y: h / 2))
        path.closeSubpath()
        return path
    }
}

private extension Color {
    /// The same hue and saturation with HSB brightness scaled by `factor`.
    func luminanceScaled(by factor: CGFloat) -> Color {
        hsbScaled(saturation: 1, brightness: factor)
    }

    /// The same hue with HSB saturation and brightness scaled.
    func hsbScaled(saturation satFactor: CGFloat, brightness briFactor: CGFloat) -> Color {
        #if canImport(UIKit)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(
            hue: h,
            saturation: min(1, max(0, s * satFactor)),
            brightness: min(1, max(0, b * briFactor)),
            opacity: a
        )
        #else
        return self
        #endif
    }
}
