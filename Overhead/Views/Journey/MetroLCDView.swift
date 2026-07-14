import SwiftUI
import Backbone
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Metro LCD View

/// Simulation of the Tokyo Metro in-car LCD (16:9): white destination strip,
/// silver headline band with the next station, and a metallic line-color band
/// running left to right — up to two already-passed stations trail behind the
/// blue direction marker, transfers sit above the band and vertical station
/// names below it.
struct MetroLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color

    /// LCD chrome color (band). Some lines' in-car identity differs from
    /// their wayfinding color; badges keep `lineColor`.
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
    private static let destStripHeight: CGFloat = 25
    private static let headlineHeight: CGFloat = 39
    private static let bandHeight: CGFloat = 16
    private static let codesHeight: CGFloat = 10
    private static let namesHeight: CGFloat = 56
    private static let columnsLeading: CGFloat = 8
    private static let columnsTrailing: CGFloat = 26
    private static let maxColumns = 8
    private static let markerBlue = Color(hex: "#1D2088")
    private static let passedGray = Color(hex: "#8E9196")

    private static let allLines = StaticTrainData.trainLines()

    var body: some View {
        TimelineView(.everyMinute) { context in
            GeometryReader { geo in
                let scale = geo.size.width / Self.designWidth
                VStack(spacing: 0) {
                    destinationStrip
                        .frame(height: Self.destStripHeight)
                    headlineBand
                        .frame(height: Self.headlineHeight)
                    progression(now: context.date)
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

    // MARK: - Destination Strip (top, white)

    private var destinationStrip: some View {
        HStack(spacing: 8) {
            typeBox
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(destinationStation?.name ?? "")
                    .font(.system(size: 15, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(verbatim: "ゆき")
                    .font(.system(size: 15, weight: .heavy))
            }
            .foregroundColor(.black)
            Spacer()
        }
        .padding(.leading, 6)
        .overlay(alignment: .trailing) {
            carBox
                .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .metalBandGradient(.white)
    }

    /// Train type in white italic on a line-color box with the metallic
    /// sheen.
    private var typeBox: some View {
        Text(typeName)
            .font(.system(size: 13, weight: .heavy))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .modifier(MetroSkewEffect(shear: 0.22))
            .frame(width: 66, height: 19)
            .metalBandGradient(displayColor)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    private var carBox: some View {
        HStack(spacing: 3) {
            Text(verbatim: "\(carNumber)")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(.white)
                .frame(width: 17, height: 17)
                .background(
                    Color(hue: 0, saturation: 0, brightness: 0.12),
                    in: RoundedRectangle(cornerRadius: 3)
                )
            Text(verbatim: "号車")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.black)
        }
    }

    // MARK: - Headline Band (silver gradient)

    private var headlineBand: some View {
        HStack(spacing: 9) {
            Text(headlineLabel)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .padding(.leading, 52)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 5)
            if let station = headlineStation {
                if !station.stationCode.isEmpty {
                    // Circle badges sit low so the bottom just clips at the
                    // band edge, the curve peeking at the rule; other shapes
                    // stay centered and unmasked.
                    if StationNumberBadge.rendersAsCircle(
                        code: station.stationCode, color: stationColor(station)
                    ) {
                        scaledStationBadge(station, dimension: 40)
                            .offset(y: 2.5)
                    } else {
                        scaledStationBadge(station, dimension: 31)
                    }
                }
                Text(station.name)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.35)
                    // Centered in whatever space remains right of the badge,
                    // nudged left of true center by the trailing padding.
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 28)
            } else {
                Spacer(minLength: 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#F4F5F7"), location: 0),
                    .init(color: Color(hex: "#DCDFE4"), location: 0.55),
                    .init(color: Color(hex: "#F7F8FA"), location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipped()
        // Line-color rule along the band's bottom edge; the clipped badge
        // bottom meets it.
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(displayColor)
                .frame(height: 2.5)
        }
    }

    // MARK: - Progression (white area)

    private func progression(now: Date) -> some View {
        let (cols, markerSlot) = columns(now: now)
        let colWidth = (Self.designWidth - Self.columnsLeading - Self.columnsTrailing)
            / CGFloat(max(cols.count, 1))
        let markerCenter = Self.columnsLeading + markerSlot * colWidth

        return VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(cols) { col in
                    transferList(col.transfers)
                        .frame(width: colWidth, alignment: .bottomLeading)
                }
            }
            .padding(.leading, Self.columnsLeading)
            .padding(.bottom, 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(cols) { col in
                        Group {
                            if col.isCurrent {
                                Color.clear  // marker overlays this slot
                            } else if col.isPassed {
                                passedBox
                            } else {
                                minuteBox(col.minutes)
                            }
                        }
                        .frame(width: colWidth)
                    }
                }
                .padding(.leading, Self.columnsLeading)

                DirectionMarker()
                    .fill(Self.markerBlue)
                    .overlay(DirectionMarker().stroke(Color.white, lineWidth: 1.2))
                    .frame(width: 17, height: Self.bandHeight)
                    .offset(x: max(0, markerCenter - 8.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: Self.bandHeight)
            .metalBandGradient(displayColor)
            // Flatten before shadowing — .shadow alone re-applies to every
            // child primitive (boxes, digits, marker) instead of the strip.
            .compositingGroup()
            .shadow(color: .black.opacity(0.4), radius: 0.8, x: 0, y: 1)
            .overlay(alignment: .bottomTrailing) {
                Text(verbatim: "分")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0.5, x: 0, y: 0.8)
                    .padding(.trailing, 9)
                    .padding(.bottom, 2)
            }

            HStack(spacing: 0) {
                ForEach(cols) { col in
                    Text(hyphenatedCode(col.station))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(col.isPassed ? Self.passedGray : .black)
                        .frame(width: colWidth)
                }
            }
            .padding(.leading, Self.columnsLeading)
            .frame(height: Self.codesHeight)
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color.black.opacity(0.8))
                .frame(height: 0.8)

            HStack(spacing: 0) {
                ForEach(cols) { col in
                    verticalName(col.station.name, passed: col.isPassed)
                        .frame(width: colWidth)
                }
            }
            .padding(.leading, Self.columnsLeading)
            .frame(height: Self.namesHeight)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Clear strip under the names so the disclaimer never collides.
            Color.clear
                .frame(height: 9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .overlay(alignment: .bottomTrailing) {
            Text(verbatim: "運転状況により、多少時間は異なります。")
                .font(.system(size: 6.5, weight: .bold))
                .foregroundColor(.black)
                .padding(.trailing, 6)
                .padding(.bottom, 2)
        }
    }

    private func minuteBox(_ minutes: Int?) -> some View {
        Text(verbatim: minutes.map(String.init) ?? "")
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: 15, height: Self.bandHeight - 2)
            .metalBandGradient(Color(hex: "#EFEFF1"))
    }

    private var passedBox: some View {
        Rectangle()
            .fill(Color(hex: "#C9CCD1"))
            .frame(width: 15, height: Self.bandHeight - 2)
    }

    private func transferList(_ lines: [TrainLine]) -> some View {
        VStack(alignment: .leading, spacing: 0.5) {
            ForEach(lines) { line in
                HStack(alignment: .top, spacing: 1.5) {
                    LineSymbolBadge(symbol: line.lineSymbol, color: line.color, dimension: 7)
                    Text(line.name)
                        .font(.system(size: 6.5, weight: .bold))
                        .kerning(-0.3)
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(.horizontal, 1)
    }

    /// Characters justified top-to-bottom so the first and last characters
    /// align across columns; names too long to fit are condensed vertically
    /// instead, like the real display.
    private func verticalName(_ name: String, passed: Bool) -> some View {
        let chars = Array(name)
        let charBox: CGFloat = 12
        let available = Self.namesHeight - 8
        let natural = charBox * CGFloat(chars.count)

        return VStack(spacing: 0) {
            ForEach(chars.indices, id: \.self) { i in
                if i > 0 { Spacer(minLength: 0) }
                Text(String(chars[i]))
                    .font(.system(size: 11.5, weight: .bold))
                    .frame(height: charBox)
            }
        }
        .frame(height: max(available, natural))
        .scaleEffect(x: 1, y: min(1, available / natural), anchor: .top)
        .foregroundColor(passed ? Self.passedGray : .black)
        .padding(.top, 4)
        .frame(height: Self.namesHeight, alignment: .top)
    }

    // MARK: - Data

    private struct MetroColumn: Identifiable {
        let id: String
        let station: Station
        let minutes: Int?    // nil for passed and current columns
        let isPassed: Bool
        let isCurrent: Bool  // dwelling here; marker replaces the minute box
        let transfers: [TrainLine]
    }

    /// Columns left to right in travel direction: up to 2 already-passed
    /// stations, then the rest of the journey. `markerSlot` positions the
    /// blue marker in column widths from the columns' leading edge — on the
    /// boundary while moving, mid-column while dwelling.
    private func columns(now: Date) -> ([MetroColumn], CGFloat) {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return ([], 0) }
        let entries = Dictionary(
            journey.journeyTimetable.map { ($0.stationId, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        let dwellIndex = state.currentStationIndex.map { max(0, min($0, stations.count - 1)) }
        let ref = dwellIndex ?? max(0, min(state.segmentFrom, stations.count - 1))
        let nowSec = Self.railSeconds(at: now)
        let delaySec = state.delayMinutes * 60

        // Express-passed stations (no timetable entry) never get a column.
        let previous = stations.indices
            .filter { $0 < ref || (dwellIndex == nil && $0 == ref) }
            .filter { entries[stations[$0].id] != nil }
            .suffix(2)

        var cols: [MetroColumn] = previous.map { idx in
            MetroColumn(
                id: stations[idx].id, station: stations[idx], minutes: nil,
                isPassed: true, isCurrent: false,
                transfers: transfers(at: stations[idx])
            )
        }
        if dwellIndex != nil {
            cols.append(MetroColumn(
                id: stations[ref].id, station: stations[ref], minutes: nil,
                isPassed: false, isCurrent: true,
                transfers: transfers(at: stations[ref])
            ))
        }
        let markerSlot = CGFloat(previous.count) + (dwellIndex != nil ? 0.5 : 0)

        let upcoming = stations.indices
            .filter { $0 > ref }
            .compactMap { idx -> MetroColumn? in
                let station = stations[idx]
                // No entry at all = express passes this station. An entry
                // with no times (schedule-less journey) is still a stop.
                guard let entry = entries[station.id] else { return nil }
                let arr = entry.arrivalSeconds() ?? entry.departureSeconds()
                return MetroColumn(
                    id: station.id, station: station,
                    minutes: arr.map { max(0, ($0 + delaySec - nowSec + 59) / 60) },
                    isPassed: false, isCurrent: false,
                    transfers: transfers(at: station)
                )
            }
            .prefix(max(0, Self.maxColumns - cols.count))
        cols.append(contentsOf: upcoming)
        return (cols, markerSlot)
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

    /// "G06" → "G-06", matching the code style under the band.
    private func hyphenatedCode(_ station: Station) -> String {
        let code = station.stationCode
        let letters = code.prefix(while: \.isLetter)
        let digits = code.drop(while: \.isLetter)
        guard !letters.isEmpty, !digits.isEmpty else { return code }
        return "\(letters)-\(digits)"
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

// MARK: - Skew Effect

/// Synthetic italic — system fonts don't oblique CJK glyphs, so shear the
/// rendered text instead.
private struct MetroSkewEffect: GeometryEffect {
    var shear: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            a: 1, b: 0, c: -shear, d: 1,
            tx: shear * size.height / 2, ty: 0
        ))
    }
}

// MARK: - Direction Marker

/// Right-pointing arrow with a chevron-notched tail (the blue "here" marker
/// riding the band).
private struct DirectionMarker: Shape {
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

// MARK: - Metal Band Gradient

/// Backs the modified view with the LCD band's metal-sheen gradient: flat
/// base color to the middle, a −10%-luminance crease just past it, easing
/// back to the base color at the bottom edge.
private struct MetalBandGradient: ViewModifier {
    let base: Color

    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                stops: [
                    .init(color: base, location: 0),
                    .init(color: base, location: 0.5),
                    .init(color: base.luminanceScaled(by: 0.9), location: 0.51),
                    .init(color: base, location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
        )
    }
}

private extension View {
    func metalBandGradient(_ base: Color) -> some View {
        modifier(MetalBandGradient(base: base))
    }
}

private extension Color {
    /// The same hue and saturation with HSB brightness scaled by `factor`.
    func luminanceScaled(by factor: CGFloat) -> Color {
        #if canImport(UIKit)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h, saturation: s, brightness: min(1, max(0, b * factor)), opacity: a)
        #else
        return self
        #endif
    }
}
