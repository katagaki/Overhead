import SwiftUI
import Backbone

// MARK: - Train LCD View

/// Simulation of the in-car overhead LCD (16:9): black header with the train
/// type plate, terminus, next station and car number, over a white strip with
/// the upcoming stops progressing right to left toward an arrow tip.
struct TrainLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color

    /// LCD chrome color (plate, band, car box). Some lines' in-car identity
    /// differs from their wayfinding color; badges keep `lineColor`.
    private var displayColor: Color {
        let firstLegId = journey.line.id.split(separator: "+").first.map(String.init)
            ?? journey.line.id
        guard let hex = LineColors.lcdOverrides[firstLegId] else { return lineColor }
        return Color(hex: hex)
    }

    // Fixed design canvas, scaled to the available width so every metric
    // (fonts, badges, strokes) stays proportional on any device.
    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = designWidth * 9 / 16
    private static let headerHeight: CGFloat = designHeight * 0.3
    private static let maxUpcomingStops = 7
    private static let lcdRed = Color(hex: "#D7000F")

    private static let allLines = StaticTrainData.trainLines()
    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "H:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f
    }()

    var body: some View {
        TimelineView(.everyMinute) { context in
            GeometryReader { geo in
                let scale = geo.size.width / Self.designWidth
                VStack(spacing: 0) {
                    header(now: context.date)
                        .frame(height: Self.headerHeight)
                    progression(now: context.date)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: Self.designWidth, height: Self.designHeight)
                .scaleEffect(scale, anchor: .topLeading)
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(6)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Header (black area)

    private func header(now: Date) -> some View {
        HStack(alignment: .top, spacing: 10) {
            destinationPlate

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 3) {
                    Text(headlineLabel)
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                    Text(verbatim: "現在時刻")
                        .font(.system(size: 8, weight: .medium))
                        .opacity(0.85)
                    Text(Self.clockFormatter.string(from: now))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 3)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 2))
                }
                .foregroundColor(.white)

                if let station = headlineStation {
                    HStack(spacing: 8) {
                        if !station.stationCode.isEmpty {
                            // Black keyline around the badge, outside its
                            // colored frame.
                            scaledStationBadge(station, dimension: 26)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26 * 0.21 + 1.5)
                                        .strokeBorder(Color.black, lineWidth: 1.5)
                                        .padding(-1.5)
                                )
                        }
                        Text(station.name)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                            .kerning(5.0)
                            .lineLimit(1)
                            .minimumScaleFactor(0.3)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 2)

            carColumn
                .padding(.top, 2)
        }
        .padding(.trailing, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hue: 0.0, saturation: 0.0, brightness: 0.1))
    }

    /// Line-color plate with an arrow tip: train type in a white box over the
    /// terminus name and ゆき.
    private var destinationPlate: some View {
        VStack(spacing: 2) {
            Text(typeName)
                .font(.system(size: 15, weight: .black))
                .kerning(typeKerning)
                // Kerning trails the last glyph too; pad the leading edge by
                // the same amount so the text stays centered.
                .padding(.leading, typeKerning)
                .foregroundColor(displayColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .modifier(ItalicSkew())
                .frame(maxWidth: .infinity)
                .frame(height: 18)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 3))

            Spacer(minLength: 0)

            Text(destinationStation?.name ?? "")
                .font(.system(size: 16, weight: .heavy))
                .lineLimit(1)
                .kerning(3.0)
                .minimumScaleFactor(0.5)
                .shadow(color: .black.opacity(0.85), radius: 1, x: 0, y: 0)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)

            Text(verbatim: "ゆき")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(EdgeInsets(top: 4, leading: 5, bottom: 3, trailing: 16))
        .frame(width: 102)
        .frame(maxHeight: .infinity)
        .background(PlateShape().fill(displayColor))
    }

    private var carColumn: some View {
        VStack(spacing: 2) {
            Text(verbatim: "\(carNumber)")
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(displayColor)
                .frame(width: 26, height: 20)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 2))
            Text(verbatim: "号車")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Progression (white area)

    private func progression(now: Date) -> some View {
        let columns = stops(now: now)
        let colWidth = (Self.designWidth - 20) / CGFloat(max(columns.count, 1))

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(columns) { col in
                    verticalName(col.station.name)
                        .frame(width: colWidth, height: 52, alignment: .bottom)
                }
            }
            .padding(.bottom, 2)

            ZStack(alignment: .leading) {
                ArrowBandShape()
                    .fill(displayColor)
                    .frame(height: 17)
                    .padding(.trailing, max(0, colWidth / 2 - 6))
                HStack(spacing: 0) {
                    ForEach(columns) { col in
                        Group {
                            if col.isCurrent {
                                currentMarker
                            } else {
                                minuteCircle(col, showsUnit: col.id == columns.first?.id)
                            }
                        }
                        .frame(width: colWidth)
                    }
                }
            }
            .frame(height: 21)

            HStack(spacing: 0) {
                ForEach(columns) { col in
                    Group {
                        if !col.station.stationCode.isEmpty {
                            scaledStationBadge(col.station, dimension: 15)
                        }
                    }
                    .frame(width: colWidth, height: 16)
                }
            }

            HStack(alignment: .top, spacing: 0) {
                ForEach(columns) { col in
                    transferList(col.transfers)
                        .frame(width: colWidth, alignment: .topLeading)
                }
            }
            .padding(.top, 2)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 10)
        .padding(.top, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .overlay(alignment: .bottomTrailing) {
            Text(verbatim: "時刻は目安であり、実際とは異なる場合があります。")
                .font(.system(size: 6))
                .foregroundColor(.black.opacity(0.55))
                .padding(.trailing, 5)
                .padding(.bottom, 2)
        }
    }

    private func verticalName(_ name: String) -> some View {
        let chars = Array(name)
        // ~1.25 line-height per glyph; shrink long names to fit the row.
        let size = min(11, 52 / (CGFloat(chars.count) * 1.25))
        return VStack(spacing: 0) {
            ForEach(chars.indices, id: \.self) { i in
                Text(String(chars[i]))
                    .font(.system(size: size, weight: .bold))
            }
        }
        .foregroundColor(.black)
    }

    private func minuteCircle(_ col: LCDStop, showsUnit: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
            Text(verbatim: "\(col.minutes ?? 0)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 12)
            if showsUnit {
                Text(verbatim: "(分)")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: 13)
            }
        }
    }

    private var currentMarker: some View {
        ZStack {
            ArrowBandShape()
                .fill(Self.lcdRed)
                .overlay(ArrowBandShape().stroke(Color.white, lineWidth: 1.5))
                .frame(width: 27, height: 21)
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .offset(x: 2.5)
        }
    }

    private func transferList(_ lines: [TrainLine]) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(lines) { line in
                HStack(alignment: .top, spacing: 1.5) {
                    LineSymbolBadge(symbol: line.lineSymbol, color: line.color, dimension: 7)
                    Text(line.name)
                        .font(.system(size: 6.5, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(.horizontal, 1)
        .padding(.top, 1)
    }

    // MARK: - Data

    private struct LCDStop: Identifiable {
        let id: String
        let station: Station
        let minutes: Int?    // nil for the current column (red marker)
        let isCurrent: Bool
        let transfers: [TrainLine]
    }

    /// Columns left to right: farthest upcoming stop first, the station the
    /// train is at (or just left) last, so travel reads right to left.
    private func stops(now: Date) -> [LCDStop] {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return [] }
        let entries = Dictionary(
            journey.journeyTimetable.map { ($0.stationId, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        let ref = max(0, min(state.currentStationIndex ?? state.segmentFrom, stations.count - 1))
        let nowSec = Self.railSeconds(at: now)
        let delaySec = state.delayMinutes * 60

        let upcoming = stations[(ref + 1)...]
            .compactMap { station -> LCDStop? in
                guard let entry = entries[station.id],
                      let arr = entry.arrivalSeconds() ?? entry.departureSeconds()
                else { return nil }  // express passes this station
                return LCDStop(
                    id: station.id,
                    station: station,
                    minutes: max(0, (arr + delaySec - nowSec + 59) / 60),
                    isCurrent: false,
                    transfers: transfers(at: station)
                )
            }
            .prefix(Self.maxUpcomingStops)

        var columns = Array(upcoming.reversed())
        columns.append(LCDStop(
            id: stations[ref].id,
            station: stations[ref],
            minutes: nil,
            isCurrent: true,
            transfers: transfers(at: stations[ref])
        ))
        return columns
    }

    /// Other bundled lines serving the same physical station (matched by
    /// Japanese name), excluding the line(s) being ridden.
    private func transfers(at station: Station) -> [TrainLine] {
        let ridden = Set(journey.line.id.split(separator: "+").map(String.init))
        return Array(
            Self.allLines
                .filter { line in
                    !ridden.contains(line.id)
                        && line.stations.contains { $0.name == station.name }
                }
                .prefix(3)
        )
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

    private var typeName: String {
        journey.service.trainType == .local ? "各駅停車" : journey.service.trainType.displayNameJa
    }

    private var typeKerning: CGFloat {
        switch typeName.count {
        case ...2: return 12
        case 3: return 5
        case 4: return 1.5
        default: return 0
        }
    }

    /// No car data exists — derive a stable 1...10 from the journey ID so the
    /// display stays constant for the ride.
    private var carNumber: Int {
        Int(journey.id.uuid.0 % 10) + 1
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
            stationName: station.name
        )
        .scaleEffect(dimension / 28)
        .frame(width: dimension, height: dimension)
    }

    /// Seconds since midnight JST; early-morning hours count as 24:00+ to
    /// match rail-convention timetable times.
    private static func railSeconds(at date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let c = cal.dateComponents([.hour, .minute, .second], from: date)
        var s = (c.hour ?? 0) * 3600 + (c.minute ?? 0) * 60 + (c.second ?? 0)
        if s < 4 * 3600 { s += 24 * 3600 }
        return s
    }
}

// MARK: - Shapes

/// Rectangle with an arrow tip on the trailing edge (the destination plate).
private struct PlateShape: Shape {
    func path(in rect: CGRect) -> Path {
        let tip: CGFloat = 12
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - tip, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - tip, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Horizontal band with an arrow tip on the leading edge (direction of travel).
private struct ArrowBandShape: Shape {
    func path(in rect: CGRect) -> Path {
        let tip: CGFloat = 6
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + tip, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + tip, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Italic Skew

/// Synthetic italic — system fonts don't oblique CJK glyphs, so shear the
/// rendered text instead.
private struct ItalicSkew: ViewModifier {
    func body(content: Content) -> some View {
        content.modifier(SkewEffect(shear: 0.22))
    }
}

private struct SkewEffect: GeometryEffect {
    var shear: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            a: 1, b: 0, c: -shear, d: 1,
            tx: shear * size.height / 2, ty: 0
        ))
    }
}
