import SwiftUI
import Backbone

// MARK: - Millennium LCD View

struct MillenniumLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = 116
    private static let headerHeight: CGFloat = 34
    private static let stripInset: CGFloat = 8
    private static let nodeAreaHeight: CGFloat = 20
    private static let namesAreaHeight: CGFloat = 54
    private static let lineY: CGFloat = 11.5
    private static let badgeDiameter: CGFloat = 12
    private static let maxColumns = 9
    private static let panelNavy = Color(hex: "#19265C")
    private static let bandBlue = Color(hex: "#2C3F96")
    private static let highlightYellow = Color(hex: "#FFE45C")
    private static let plateBlue = Color(hex: "#A9BEE8")
    private static let passedGray = Color(hex: "#9CA1AC")
    private static let arrowRed = Color(hex: "#D7000F")

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / Self.designWidth
            VStack(spacing: 0) {
                header
                    .frame(height: Self.headerHeight)
                strip
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, Self.stripInset)
                    .padding(.bottom, Self.stripInset)
            }
            .frame(width: Self.designWidth, height: Self.designHeight)
            .background(Self.panelNavy)
            .scaleEffect(scale, anchor: .topLeading)
        }
        .aspectRatio(Self.designWidth / Self.designHeight, contentMode: .fit)
        .modifier(LCDScreenClip())
        .padding(6)
        .glassEffect(.regular.tint(Color(red: 0.2, green: 0.26, blue: 0.33).opacity(0.4)), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Header (navy)

    private var header: some View {
        HStack(spacing: 8) {
            typePlate
                .frame(width: 108, alignment: .leading)

            Spacer(minLength: 0)

            if let station = headlineStation {
                HStack(spacing: 5) {
                    stationBadge(for: station, dimension: 18)
                    HorizontallySquashed(maxWidth: 190) {
                        Text(station.name)
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 2) {
                Text(verbatim: "\(carNumber)")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(Self.panelNavy)
                    .frame(width: 11, height: 11)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 2))
                Text(verbatim: "号車")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(width: 108, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var typePlate: some View {
        VStack(spacing: 0) {
            Text(typeName)
                .font(.system(size: 11, weight: .heavy))
                .kerning(typeName.count <= 2 ? 6 : 0.5)
                .foregroundColor(Self.panelNavy)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(verbatim: "\(destinationStation?.name ?? "")行き")
                .font(.system(size: 6.5, weight: .bold))
                .foregroundColor(Self.panelNavy.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 30)
        .frame(maxHeight: .infinity)
        .frame(minWidth: 104)
        .background(SlantedPlateShape().fill(Self.plateBlue))
        .overlay(
            PlateEdgeStripes()
                .stroke(Self.plateBlue, lineWidth: 1.5)
        )
    }

    // MARK: - Route Strip (white)

    private var strip: some View {
        let (builtCols, builtSlot) = columns()
        let dwelling = state.currentStationIndex != nil
        let mirrored = orientation == .left
        let cols = mirrored ? Array(builtCols.reversed()) : builtCols
        let markerSlot = mirrored ? CGFloat(builtCols.count) - builtSlot : builtSlot
        let colWidth = (Self.designWidth - Self.stripInset * 2) / CGFloat(max(cols.count, 1))
        let markerX = markerSlot * colWidth
        let arrowWidth = Self.badgeDiameter * 0.7

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(cols) { col in
                    verticalName(col.station.name, passed: col.isPassed)
                        .frame(width: colWidth, alignment: .center)
                        .frame(maxHeight: .infinity)
                        .background(col.isHighlighted ? Self.highlightYellow : .clear)
                }
            }
            .frame(maxHeight: .infinity)

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(cols) { col in
                        (col.isHighlighted ? Self.highlightYellow : Color.clear)
                            .frame(width: colWidth)
                    }
                }
                .padding(.top, -1)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(mirrored ? Self.bandBlue : Self.passedGray)
                        .frame(width: max(0, markerX))
                    Rectangle()
                        .fill(mirrored ? Self.passedGray : Self.bandBlue)
                }
                .frame(height: 2.5)
                .offset(y: Self.lineY - 1.25)

                HStack(spacing: 0) {
                    ForEach(cols) { col in
                        Group {
                            if dwelling && col.isHighlighted {
                                Color.clear
                            } else {
                                stationBadge(for: col.station, dimension: Self.badgeDiameter, dimmed: col.isPassed)
                            }
                        }
                        .frame(width: colWidth, height: Self.badgeDiameter)
                    }
                }
                .offset(y: Self.lineY - Self.badgeDiameter / 2)

                MillenniumArrowShape(pointsLeading: mirrored)
                    .fill(Self.arrowRed)
                    .frame(width: arrowWidth, height: arrowWidth * 0.9)
                    .offset(
                        x: markerX - arrowWidth / 2,
                        y: Self.lineY - arrowWidth * 0.9 / 2
                    )
            }
            .frame(height: Self.nodeAreaHeight)
        }
        .background(alignment: .leading) {
            ZStack(alignment: .leading) {
                Color.white
                SlantedPlateShape(skew: 56)
                    .fill(Self.plateBlue.opacity(0.22))
                    .overlay(
                        PlateEdgeStripes(skew: 56, gap: 8)
                            .stroke(Self.plateBlue.opacity(0.22), lineWidth: 2.5)
                    )
                    .frame(width: 115)
                    .offset(x: 180)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func verticalName(_ name: String, passed: Bool) -> some View {
        VerticalStationName(name: name, fontSize: 9, charBox: 9.5,
                            availableHeight: Self.namesAreaHeight - 8,
                            color: passed ? Self.passedGray : Self.panelNavy,
                            columnAnchor: .top, justifiedSingle: true)
            .padding(.top, 4)
            .frame(height: Self.namesAreaHeight, alignment: .top)
    }

    @ViewBuilder
    private func stationBadge(for station: Station, dimension: CGFloat, dimmed: Bool = false) -> some View {
        if station.stationCode.isEmpty {
            Circle()
                .fill(Color.white)
                .overlay(Circle().strokeBorder(
                    dimmed ? Self.passedGray : Self.panelNavy, lineWidth: 1
                ))
                .frame(width: dimension, height: dimension)
        } else {
            StationNumberBadge(
                code: station.stationCode,
                color: stationColor(station),
                size: .regular,
                stationName: station.name,
                styleOverride: journey.line.badgeStyle
            )
            .scaleEffect(dimension / 28)
            .frame(width: dimension, height: dimension)
            .grayscale(dimmed ? 1 : 0)
            .opacity(dimmed ? 0.6 : 1)
        }
    }

    private func stationColor(_ station: Station) -> Color {
        StaticTrainData.line(containingStationId: station.id)?.trainLine.color ?? lineColor
    }

    // MARK: - Data

    private struct MillenniumColumn: Identifiable {
        let id: String
        let station: Station
        let isPassed: Bool
        let isHighlighted: Bool
    }

    private func columns() -> ([MillenniumColumn], CGFloat) {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return ([], 0) }
        let entries = Dictionary(
            journey.journeyTimetable.map { ($0.stationId, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        let dwellIndex = state.currentStationIndex.map { max(0, min($0, stations.count - 1)) }
        let ref = dwellIndex ?? max(0, min(state.segmentFrom, stations.count - 1))
        let highlightIndex = dwellIndex
            ?? max(0, min(state.segmentTo, stations.count - 1))

        let stops = stations.indices.filter { entries[stations[$0].id] != nil }
        let passed = stops.filter { $0 < ref }.suffix(5)
        let remaining = stops.filter { $0 >= ref }
        let window = Array(passed) + remaining

        let cols = window.prefix(Self.maxColumns).map { idx in
            MillenniumColumn(
                id: stations[idx].id,
                station: stations[idx],
                isPassed: idx < highlightIndex,
                isHighlighted: idx == highlightIndex
            )
        }
        let refSlot = CGFloat(passed.count)
        let markerSlot = dwellIndex != nil
            ? refSlot + 0.5
            : min(refSlot + 1, CGFloat(cols.count))
        return (cols, markerSlot)
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

    private var typeName: String {
        journey.service.trainType == .local ? "各駅停車" : journey.service.trainType.displayNameJa
    }

    private var carNumber: Int {
        Int(journey.id.uuid.0 % 10) + 1
    }
}

// MARK: - Arrow Shape

private struct MillenniumArrowShape: Shape {
    var pointsLeading = false

    func path(in rect: CGRect) -> Path {
        let notch = rect.width * 0.42
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
        p.closeSubpath()
        return pointsLeading ? p.mirroredHorizontally(in: rect) : p
    }
}

// MARK: - Slanted Plate Shape

private struct PlateEdgeStripes: Shape {
    var skew: CGFloat = 26
    var gap: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX - gap, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + skew - gap, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX - skew + gap, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX + gap, y: rect.maxY))
        return p
    }
}

private struct SlantedPlateShape: Shape {
    var skew: CGFloat = 26

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - skew, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + skew, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
