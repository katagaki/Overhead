import SwiftUI
import Backbone

// MARK: - Chuo-Sobu Line LCD View

/// Simulation of the E235-series in-car LCD (16:9), Joban-style stop progression.
struct ChuoSobuLineLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    /// LCD chrome color (type text, band, car box); badges keep `lineColor`.
    private var displayColor: Color {
        let firstLegId = journey.line.id.split(separator: "+").first.map(String.init)
            ?? journey.line.id
        guard let hex = LineColors.lcdOverrides[firstLegId] else { return lineColor }
        return Color(hex: hex)
    }

    // Fixed design canvas, scaled to available width.
    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = designWidth * 9 / 16
    private static let headerHeight: CGFloat = designHeight * 0.3
    private static let maxUpcomingStops = 7
    private static let barGray = Color(hex: "#B3B6BB")
    private static let passedOpacity: CGFloat = 0.4

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
            .glassEffect(.regular.tint(Color(red: 0.2, green: 0.26, blue: 0.33).opacity(0.4)), in: RoundedRectangle(cornerRadius: 12))
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

    /// Train type in line color with white outline, wrapped every 2 kanji.
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

    /// White box: badge docked left, name spread across the rest.
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

    /// Characters spread across the box; long names squash horizontally to
    /// stay on one line.
    private func spreadName(_ name: String) -> some View {
        let chars = Array(name)
        let size: CGFloat = chars.count <= 4 ? 27 : 18
        return SpreadSquashName(chars: chars, size: size)
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
        let (columns, markerSlot) = stops(now: now)
        let colWidth = (Self.designWidth - 20) / CGFloat(max(columns.count, 1))
        let markerCenter = markerSlot * colWidth

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(columns) { col in
                    verticalName(col.station.name)
                        .frame(width: colWidth, height: 52, alignment: .bottom)
                        .opacity(col.isPassed ? Self.passedOpacity : 1)
                }
            }

            // Station codes horizontally under the names, not badges.
            HStack(spacing: 0) {
                ForEach(columns) { col in
                    Text(hyphenatedCode(col.station))
                        .font(.system(size: 6.5, weight: .heavy))
                        .foregroundColor(.black)
                        .frame(width: colWidth, height: 8)
                        .opacity(col.isPassed ? Self.passedOpacity : 1)
                }
            }

            ZStack(alignment: .leading) {
                YamanoteArrowBandShape(tipOnTrailing: orientation == .right)
                    .fill(displayColor)
                    .frame(height: 17)
                    .padding(orientation == .right ? .leading : .trailing, -10)
                HStack(spacing: 0) {
                    ForEach(columns) { col in
                        Group {
                            if col.isCurrent {
                                Color.clear
                            } else {
                                minuteBox(col)
                            }
                        }
                        .frame(width: colWidth)
                        .opacity(col.isPassed ? Self.passedOpacity : 1)
                    }
                }
                currentMarker
                    .offset(x: markerCenter - 27 / 2)
            }
            .frame(height: 21)
            .overlay(alignment: orientation == .right ? .leading : .trailing) {
                Text(verbatim: "（分）")
                    .font(.system(size: 6.5, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: orientation == .right ? -9 : 9)
            }

            HStack(alignment: .top, spacing: 0) {
                ForEach(columns) { col in
                    transferList(col.transfers)
                        .frame(width: colWidth, alignment: .topLeading)
                        .opacity(col.isPassed ? Self.passedOpacity : 1)
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

    // Long names squash vertically; mixed kanji/katakana names split into
    // parallel columns with the shorter part spaced out, like the real display.
    private func verticalName(_ name: String) -> some View {
        VerticalStationName(name: name, fontSize: 11, charBox: 12,
                            availableHeight: 52, color: .black, columnAnchor: .bottom)
    }

    /// Minute-count box (E235 uses boxes, not the E233's circles).
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
        let flipped = orientation == .right
        return YamanoteArrowBandShape(tipOnTrailing: flipped)
            .fill(displayColor)
            .overlay(YamanoteArrowBandShape(tipOnTrailing: flipped).stroke(Color.white, lineWidth: 1.5))
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
        let minutes: Int?    // nil for the current column (marker) and passed stops
        let isCurrent: Bool
        let isPassed: Bool
        let transfers: [TrainLine]
    }

    /// Columns and the marker slot (in column-widths from the leading edge).
    private func stops(now: Date) -> ([LCDStop], CGFloat) {
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

        let upcoming = stations[(ref + 1)...]
            .compactMap { station -> LCDStop? in
                guard let entry = entries[station.id] else { return nil }
                let arr = entry.arrivalSeconds() ?? entry.departureSeconds()
                return LCDStop(
                    id: station.id,
                    station: station,
                    minutes: arr.map { max(0, ($0 + delaySec - nowSec + 59) / 60) },
                    isCurrent: false,
                    isPassed: false,
                    transfers: transfers(at: station)
                )
            }
            .prefix(Self.maxUpcomingStops)

        var columns = Array(upcoming.reversed())
        let upcomingCount = columns.count

        if dwellIndex != nil {
            columns.append(LCDStop(
                id: stations[ref].id, station: stations[ref], minutes: nil,
                isCurrent: true, isPassed: false, transfers: transfers(at: stations[ref])
            ))
        }
        let markerSlot = CGFloat(upcomingCount) + (dwellIndex != nil ? 0.5 : 0)

        let passedUpper = dwellIndex != nil ? ref : ref + 1
        let deficit = Self.maxUpcomingStops + 1 - columns.count
        if deficit > 0 {
            let passed = stations[..<passedUpper]
                .filter { entries[$0.id] != nil }
                .suffix(deficit)
                .reversed()
                .map { station in
                    LCDStop(
                        id: station.id, station: station, minutes: nil,
                        isCurrent: false, isPassed: true,
                        transfers: transfers(at: station)
                    )
                }
            columns.append(contentsOf: passed)
        }

        if orientation == .right {
            return (columns.reversed(), CGFloat(columns.count) - markerSlot)
        }
        return (columns, markerSlot)
    }

    /// Other lines serving the same station, excluding the ridden line(s).
    private func transfers(at station: Station) -> [TrainLine] {
        guard !journey.line.isCustom else { return [] }
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

    /// Stable 1...10 derived from the journey ID (no real car data).
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
            stationName: station.name,
            styleOverride: journey.line.badgeStyle
        )
        .scaleEffect(dimension / 28)
        .frame(width: dimension, height: dimension)
    }

    /// Seconds since midnight JST; pre-04:00 counts as 24:00+ (rail convention).
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

/// Horizontal band with an arrow tip on the leading edge (or trailing when `tipOnTrailing`).
private struct YamanoteArrowBandShape: Shape {
    var tipOnTrailing = false

    func path(in rect: CGRect) -> Path {
        let tip: CGFloat = 6
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + tip, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + tip, y: rect.maxY))
        p.closeSubpath()
        return tipOnTrailing ? p.mirroredHorizontally(in: rect) : p
    }
}
