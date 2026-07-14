import SwiftUI
import Backbone

// MARK: - Millennium LCD View

/// Simulation of a monorail-style wide in-car LCD: navy panel with the train
/// type and terminus at the left, the next station's number badge and name in
/// the middle, a weather widget at the right, and a white route strip below —
/// vertical station names over a blue band of numbered circles, with the next
/// station's column highlighted in yellow.
struct MillenniumLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color

    // Fixed design canvas, scaled to the available width so every metric
    // (fonts, badges, strokes) stays proportional on any device.
    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = 116
    private static let headerHeight: CGFloat = 34
    private static let stripInset: CGFloat = 8
    private static let nodeAreaHeight: CGFloat = 20
    // Strip height (designHeight − header − bottom inset) minus the node area.
    private static let namesAreaHeight: CGFloat = 54
    private static let lineY: CGFloat = 14      // thin line's center in the node area
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
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(6)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Header (navy)

    private var header: some View {
        HStack(spacing: 8) {
            typePlate
                .frame(width: 88, alignment: .leading)

            Spacer(minLength: 0)

            if let station = headlineStation {
                HStack(spacing: 5) {
                    stationBadge(for: station, dimension: 18)
                    Text(station.name)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
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
            .frame(width: 88, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Light blue slanted plate: train type over the terminus, both in navy.
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
        .padding(.horizontal, 9)
        .frame(height: 26)
        .frame(minWidth: 76)
        .background(SlantedPlateShape().fill(Self.plateBlue))
        .overlay(
            PlateEdgeStripes()
                .stroke(Self.plateBlue, lineWidth: 1.5)
        )
    }

    // MARK: - Route Strip (white)

    private var strip: some View {
        let (cols, markerSlot) = columns()
        let colWidth = (Self.designWidth - Self.stripInset * 2) / CGFloat(max(cols.count, 1))
        let markerX = markerSlot * colWidth
        // 70% of the station badge, in the Tokyo Metro notched-arrow shape.
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
                // Overlap the names row's highlight so no seam shows.
                .padding(.top, -1)

                // Thin line: gray behind the train, blue ahead.
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Self.passedGray)
                        .frame(width: max(0, markerX))
                    Rectangle()
                        .fill(Self.bandBlue)
                }
                .frame(height: 2.5)
                .offset(y: Self.lineY - 1.25)

                HStack(spacing: 0) {
                    ForEach(cols) { col in
                        stationBadge(for: col.station, dimension: Self.badgeDiameter, dimmed: col.isPassed)
                            .frame(width: colWidth)
                    }
                }
                .offset(y: Self.lineY - Self.badgeDiameter / 2)

                // Vertically centered on the line, straddling it.
                MillenniumArrowShape()
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
                // Faint watermark parallelogram, same slant as the plate,
                // with the same flanking stripes.
                SlantedPlateShape(skew: 24)
                    .fill(Self.plateBlue.opacity(0.22))
                    .overlay(
                        PlateEdgeStripes(skew: 24, gap: 8)
                            .stroke(Self.plateBlue.opacity(0.22), lineWidth: 2.5)
                    )
                    .frame(width: 115)
                    .offset(x: 122)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    /// Characters justified top-to-bottom in a fixed height so the first and
    /// last characters align across columns; names too long to fit are
    /// condensed vertically instead (same treatment as the Metro LCD).
    private func verticalName(_ name: String, passed: Bool) -> some View {
        let chars = Array(name)
        let charBox: CGFloat = 9.5
        let available = Self.namesAreaHeight - 8
        let natural = charBox * CGFloat(chars.count)

        return VStack(spacing: 0) {
            ForEach(chars.indices, id: \.self) { i in
                if i > 0 { Spacer(minLength: 0) }
                Text(String(chars[i]))
                    .font(.system(size: 9, weight: .bold))
                    .frame(height: charBox)
            }
        }
        .frame(height: max(available, natural))
        .scaleEffect(x: 1, y: min(1, available / natural), anchor: .top)
        .foregroundColor(passed ? Self.passedGray : Self.panelNavy)
        .padding(.top, 4)
        .frame(height: Self.namesAreaHeight, alignment: .top)
    }

    /// The station's real numbering badge; a plain dot when it has no code.
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
                stationName: station.name
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

    /// Columns left to right in travel direction: up to 5 already-passed
    /// stations trail behind, and the headline (next or dwelling) station's
    /// column is highlighted. `markerSlot` positions the red arrow in column
    /// widths from the strip's leading edge — on the boundary while moving,
    /// mid-column while dwelling.
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

        // Express-passed stations (no timetable entry) never get a column.
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

    /// No car data exists — derive a stable 1...10 from the journey ID so the
    /// display stays constant for the ride.
    private var carNumber: Int {
        Int(journey.id.uuid.0 % 10) + 1
    }
}

// MARK: - Arrow Shape

/// Right-pointing arrow with a chevron-notched tail (the red position marker
/// above the line).
private struct MillenniumArrowShape: Shape {
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
        return p
    }
}

// MARK: - Slanted Plate Shape

/// Thin decorative lines flanking the plate, parallel to its slanted edges.
private struct PlateEdgeStripes: Shape {
    var skew: CGFloat = 7
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

/// Parallelogram leaning left (the type plate and strip watermark).
private struct SlantedPlateShape: Shape {
    var skew: CGFloat = 7

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
