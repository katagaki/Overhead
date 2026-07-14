import SwiftUI
import Backbone

// MARK: - Yamanote LCD View

/// Simulation of the E235-series in-car LCD (16:9): gray header bar with the
/// train type in outlined line-color text (wrapping every two kanji), a white
/// box holding the next station's badge and name, and the car number — over a
/// Joban-style stop progression whose arrow marker is line-colored with no
/// center circle.
struct YamanoteLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color

    /// LCD chrome color (type text, band, car box). Some lines' in-car
    /// identity differs from their wayfinding color; badges keep `lineColor`.
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
    private static let barGray = Color(hex: "#B3B6BB")

    private static let allLines = StaticTrainData.trainLines()

    var body: some View {
        TimelineView(.everyMinute) { context in
            GeometryReader { geo in
                let scale = geo.size.width / Self.designWidth
                VStack(spacing: 0) {
                    header
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

    // MARK: - Header (gray bar)

    private var header: some View {
        ZStack {
            stationBox
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            outlinedType
                .padding(.top, 4)
                .padding(.leading, 7)
        }
        .overlay(alignment: .topTrailing) {
            carColumn
                .padding(.top, 4)
                .padding(.trailing, 7)
        }
        .background(Self.barGray)
    }

    /// Train type in line color with a white outline, wrapped every 2 kanji
    /// (各駅停車 → 各駅 / 停車).
    private var outlinedType: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(typeLines.enumerated()), id: \.offset) { _, line in
                outlinedText(line, size: 15)
            }
        }
    }

    private func outlinedText(_ text: String, size: CGFloat) -> some View {
        // SwiftUI has no glyph stroke; stack offset white copies behind.
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = CGFloat(i) * .pi / 4
                Text(text)
                    .font(.system(size: size, weight: .heavy))
                    .foregroundColor(.white)
                    .offset(x: cos(angle) * 1.1, y: sin(angle) * 1.1)
            }
            Text(text)
                .font(.system(size: size, weight: .heavy))
                .foregroundColor(displayColor)
        }
    }

    private static let boxHeight: CGFloat = 44

    /// White hard-edged box: the station's badge docked left at near-full
    /// height, the name's characters spread across the remaining width.
    private var stationBox: some View {
        HStack(spacing: 0) {
            if let station = headlineStation {
                if !station.stationCode.isEmpty {
                    scaledStationBadge(station, dimension: Self.boxHeight - 9)
                        .padding(4.5)
                }
                spreadName(station.name)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 190, height: Self.boxHeight)
        .background(Color.white)
        .overlay(
            Rectangle().strokeBorder(
                LinearGradient(
                    colors: [Color(hex: "#D8DADD"), Color(hex: "#6E7176")],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 1.5
            )
        )
    }

    /// Characters distributed evenly across the available width.
    private func spreadName(_ name: String) -> some View {
        let chars = Array(name)
        let size: CGFloat = chars.count <= 4 ? 27 : 18
        return HStack(spacing: 0) {
            ForEach(chars.indices, id: \.self) { i in
                if i > 0 { Spacer(minLength: 0) }
                Text(String(chars[i]))
                    .font(.system(size: size, weight: .heavy))
                    .foregroundColor(.black)
            }
        }
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
                .foregroundColor(.black)
        }
    }

    // MARK: - Progression (white area, Joban-style)

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

            // Station codes horizontally under the names, not badges.
            HStack(spacing: 0) {
                ForEach(columns) { col in
                    Text(hyphenatedCode(col.station))
                        .font(.system(size: 6.5, weight: .heavy))
                        .foregroundColor(.black)
                        .frame(width: colWidth, height: 8)
                }
            }

            ZStack(alignment: .leading) {
                // Runs past the content padding to the display's right edge.
                YamanoteArrowBandShape()
                    .fill(displayColor)
                    .frame(height: 17)
                    .padding(.trailing, -10)
                HStack(spacing: 0) {
                    ForEach(columns) { col in
                        Group {
                            if col.isCurrent {
                                currentMarker
                            } else {
                                minuteBox(col)
                            }
                        }
                        .frame(width: colWidth)
                    }
                }
            }
            .frame(height: 21)
            .overlay(alignment: .trailing) {
                Text(verbatim: "（分）")
                    .font(.system(size: 6.5, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: 9)
            }

            HStack(alignment: .top, spacing: 0) {
                ForEach(columns) { col in
                    transferList(col.transfers)
                        .frame(width: colWidth, alignment: .topLeading)
                }
            }
            .padding(.top, 3)
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
        let charBox: CGFloat = 12
        let natural = charBox * CGFloat(chars.count)
        return VStack(spacing: 0) {
            ForEach(chars.indices, id: \.self) { i in
                Text(String(chars[i]))
                    .font(.system(size: 11, weight: .bold))
                    .frame(height: charBox)
            }
        }
        // Names too long for the row squash vertically at full glyph size,
        // like the real display.
        .scaleEffect(x: 1, y: min(1, 52 / natural), anchor: .bottom)
        .foregroundColor(.black)
    }

    /// White 16:10 rectangle with the minute count — the E235 uses boxes,
    /// not the E233's circles.
    private func minuteBox(_ col: LCDStop) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 21, height: 21 * 10 / 16)
            if let minutes = col.minutes {
                Text(verbatim: "\(minutes)")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: 19)
            }
        }
    }

    /// Line-colored arrow marker — no center circle, unlike the Joban one.
    private var currentMarker: some View {
        YamanoteArrowBandShape()
            .fill(displayColor)
            .overlay(YamanoteArrowBandShape().stroke(Color.white, lineWidth: 1.5))
            .frame(width: 27, height: 21)
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
        let minutes: Int?    // nil for the current column (marker)
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
                // No entry at all = express passes this station. An entry
                // with no times (schedule-less journey) is still a stop.
                guard let entry = entries[station.id] else { return nil }
                let arr = entry.arrivalSeconds() ?? entry.departureSeconds()
                return LCDStop(
                    id: station.id,
                    station: station,
                    minutes: arr.map { max(0, ($0 + delaySec - nowSec + 59) / 60) },
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

    private var headlineStation: Station? {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return nil }
        let index = state.currentStationIndex ?? state.segmentTo
        return stations[max(0, min(index, stations.count - 1))]
    }

    private var typeName: String {
        journey.service.trainType == .local ? "各駅停車" : journey.service.trainType.displayNameJa
    }

    /// Wrapped every 2 characters: 各駅停車 → [各駅, 停車].
    private var typeLines: [String] {
        let chars = Array(typeName)
        return stride(from: 0, to: chars.count, by: 2).map {
            String(chars[$0..<min($0 + 2, chars.count)])
        }
    }

    /// "JY28" → "JY-28", matching the code style under the names.
    private func hyphenatedCode(_ station: Station) -> String {
        let code = station.stationCode
        let letters = code.prefix(while: \.isLetter)
        let digits = code.drop(while: \.isLetter)
        guard !letters.isEmpty, !digits.isEmpty else { return code }
        return "\(letters)-\(digits)"
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

/// Horizontal band with an arrow tip on the leading edge (direction of travel).
private struct YamanoteArrowBandShape: Shape {
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
