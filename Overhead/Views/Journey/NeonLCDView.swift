import SwiftUI
import Backbone

// MARK: - Neon LCD View

/// Original cyberpunk HUD panel (no real-world counterpart), the lineup's only dark panel.
struct NeonLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = designWidth * 9 / 16
    private static let maxRows = 7
    private static let cyan = Color(hex: "#56E6C8")
    private static let cyanDim = Color(hex: "#2A6F63")
    private static let magenta = Color(hex: "#FF5FA8")
    private static let magentaHot = Color(hex: "#FF2E88")
    private static let hudGray = Color(hex: "#8FA0C8")
    private static let rowBlue = Color(hex: "#9FB2D8")
    private static let glitchPeriod = 6.0

    private static let allLines = StaticTrainData.trainLines()
    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "H:mm:ss"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f
    }()

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / Self.designWidth
            ZStack(alignment: .topLeading) {
                background
                watermark
                hud
                main
                routePanel
                ticker
                scanBar
                scanlines
                corners
            }
            .frame(width: Self.designWidth, height: Self.designHeight)
            .scaleEffect(scale, anchor: .topLeading)
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .modifier(LCDScreenClip())
        .padding(6)
        .glassEffect(.regular.tint(Color(red: 0.2, green: 0.26, blue: 0.33).opacity(0.4)), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Atmosphere

    private var background: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "#0D1830"), Color(hex: "#070B18"), Color(hex: "#04060C")],
                center: UnitPoint(x: 0.75, y: 0),
                startRadius: 0, endRadius: 380
            )
            Canvas { ctx, size in
                var lines = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    lines.move(to: CGPoint(x: x, y: 0))
                    lines.addLine(to: CGPoint(x: x, y: size.height))
                    x += 17
                }
                var y: CGFloat = 0
                while y <= size.height {
                    lines.move(to: CGPoint(x: 0, y: y))
                    lines.addLine(to: CGPoint(x: size.width, y: y))
                    y += 17
                }
                ctx.stroke(lines, with: .color(Self.cyan.opacity(0.06)), lineWidth: 0.5)
            }
            .mask(LinearGradient(
                stops: [.init(color: .black, location: 0.3), .init(color: .clear, location: 0.95)],
                startPoint: .top, endPoint: .bottom
            ))
        }
    }

    private var scanlines: some View {
        Canvas { ctx, size in
            var y: CGFloat = 1.5
            var lines = Path()
            while y <= size.height {
                lines.move(to: CGPoint(x: 0, y: y))
                lines.addLine(to: CGPoint(x: size.width, y: y))
                y += 2
            }
            ctx.stroke(lines, with: .color(.black.opacity(0.18)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }

    private var scanBar: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let progress = (t / 7).truncatingRemainder(dividingBy: 1)
            LinearGradient(
                colors: [.clear, Self.cyan.opacity(0.08), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 30)
            .offset(y: -30 + (Self.designHeight + 30) * progress)
        }
        .allowsHitTesting(false)
    }

    private var watermark: some View {
        Text(String(headlineStation?.name.first ?? "　"))
            .font(.system(size: 150, weight: .heavy))
            .foregroundColor(.white.opacity(0.05))
            .offset(x: 150, y: 30)
    }

    private var corners: some View {
        Canvas { ctx, size in
            let inset: CGFloat = 8
            let arm: CGFloat = 13
            var p = Path()
            for (cx, cy, dx, dy) in [
                (inset, inset, 1.0, 1.0),
                (size.width - inset, inset, -1.0, 1.0),
                (inset, size.height - inset, 1.0, -1.0),
                (size.width - inset, size.height - inset, -1.0, -1.0),
            ] {
                p.move(to: CGPoint(x: cx + Double(arm) * dx, y: cy))
                p.addLine(to: CGPoint(x: cx, y: cy))
                p.addLine(to: CGPoint(x: cx, y: cy + Double(arm) * dy))
            }
            ctx.stroke(p, with: .color(Self.cyanDim), lineWidth: 1.5)
        }
        .allowsHitTesting(false)
    }

    // MARK: - HUD Row

    private var hud: some View {
        HStack(spacing: 6) {
            chip("\(journey.line.lineSymbol)::\(typeNameEn.uppercased())", color: Self.cyan, border: Self.cyanDim)
            chip("DEST::\(destinationStation?.name ?? "")", color: Self.magenta, border: Color(hex: "#7C2C55"))
            Spacer()
            TimelineView(.periodic(from: .now, by: 0.5)) { context in
                HStack(spacing: 1) {
                    Text(Self.clockFormatter.string(from: context.date))
                        .font(.system(size: 6.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Self.hudGray)
                    Text(verbatim: "_")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Self.cyan)
                        .opacity(Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0 ? 1 : 0)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 11)
    }

    private func chip(_ text: String, color: Color, border: Color) -> some View {
        Text(verbatim: text)
            .font(.system(size: 6, weight: .bold, design: .monospaced))
            .kerning(1.2)
            .foregroundColor(color)
            .lineLimit(1)
            .padding(.horizontal, 5)
            .padding(.vertical, 2.5)
            .background(color.opacity(0.06))
            .overlay(Rectangle().stroke(border, lineWidth: 0.5))
    }

    // MARK: - Main Readout

    private var main: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: state.currentStationIndex != nil ? "NOW_AT //" : "NEXT_STOP //")
                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                .kerning(3)
                .foregroundColor(Self.cyan)
                .shadow(color: Self.cyan.opacity(0.8), radius: 4)

            glitchName

            HStack(spacing: 7) {
                Text(headlineStation?.nameEn.uppercased() ?? "")
                    .font(.system(size: 8.5, weight: .semibold))
                    .kerning(4.5)
                    .foregroundColor(Self.magenta)
                    .shadow(color: Self.magenta.opacity(0.7), radius: 4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Self.magenta, .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: 48, height: 0.5)
            }

            etaLine
                .padding(.top, 7)
        }
        .padding(.leading, 16)
        .padding(.top, 42)
        .frame(maxWidth: 240, alignment: .leading)
    }

    private var glitchName: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let phase = t.truncatingRemainder(dividingBy: Self.glitchPeriod)
            let bursting = phase > Self.glitchPeriod - 0.35
            let jitterX = bursting ? sin(t * 91) * 3.5 : 0
            let jitterY = bursting ? cos(t * 73) * 1.4 : 0
            let name = headlineStation?.name ?? ""
            let font = Font.system(size: name.count > 4 ? 32 : 44, weight: .heavy)

            ZStack(alignment: .leading) {
                Text(name)
                    .font(font)
                    .foregroundColor(Color(hex: "#2AFFD6").opacity(0.8))
                    .offset(x: -1.8 + jitterX, y: jitterY)
                Text(name)
                    .font(font)
                    .foregroundColor(Self.magentaHot.opacity(0.8))
                    .offset(x: 1.8 - jitterX, y: -jitterY)
                Text(name)
                    .font(font)
                    .foregroundColor(Color(hex: "#F2FDFF"))
                    .shadow(color: Color(hex: "#56E6FF").opacity(0.55), radius: 7)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
    }

    private var etaLine: some View {
        Group {
            if state.delayMinutes > 0 {
                Text(verbatim: "DELAY +\(state.delayMinutes) MIN // HOLD")
                    .foregroundColor(Self.magentaHot)
            } else if let minutes = minutesToNext {
                Text(verbatim: "ETA \(String(format: "%02d", minutes)) MIN // ON TIME")
                    .foregroundColor(Self.hudGray)
            } else {
                Text(verbatim: "JOURNEY ACTIVE // ON TIME")
                    .foregroundColor(Self.hudGray)
            }
        }
        .font(.system(size: 7, weight: .medium, design: .monospaced))
        .kerning(1.4)
    }

    // MARK: - Route Stack

    private var routePanel: some View {
        let rows = routeRows
        return VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "ROUTE // \(journey.line.lineSymbol)")
                .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                .kerning(1.8)
                .foregroundColor(Self.cyan)
                .padding(.bottom, 4)
            Rectangle()
                .fill(Self.cyan.opacity(0.3))
                .frame(height: 0.5)
                .padding(.bottom, 3)

            ForEach(rows) { row in
                routeRow(row)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 9, bottom: 7, trailing: 8))
        .frame(width: 102, alignment: .leading)
        .background(Color(hex: "#0A1226").opacity(0.72))
        .clipShape(ChamferShape(cut: 8))
        .overlay(ChamferShape(cut: 8).stroke(Self.cyan.opacity(0.28), lineWidth: 0.5))
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 13)
        .padding(.top, 32)
    }

    private func routeRow(_ row: RouteRow) -> some View {
        HStack(spacing: 4) {
            if !row.station.stationCode.isEmpty {
                scaledStationBadge(row.station, dimension: 10)
                    .grayscale(row.isPassed ? 1 : 0)
                    .opacity(row.isPassed ? 0.4 : 1)
            }
            Text(row.station.name)
                .font(.system(size: 7.5, weight: row.isCurrent ? .bold : .medium))
                .foregroundColor(row.isCurrent ? .white : (row.isPassed ? Color(hex: "#4B5878") : Self.rowBlue))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 2)
            if row.isCurrent {
                TimelineView(.periodic(from: .now, by: 0.55)) { context in
                    Text(verbatim: "NEXT")
                        .font(.system(size: 4.8, weight: .bold, design: .monospaced))
                        .foregroundColor(Self.magenta)
                        .opacity(Int(context.date.timeIntervalSinceReferenceDate / 0.55) % 2 == 0 ? 1 : 0.15)
                }
            } else if row.isPassed {
                Text(verbatim: "PASS")
                    .font(.system(size: 4.8, weight: .bold, design: .monospaced))
                    .foregroundColor(Self.cyan.opacity(0.7))
            } else if let overflow = row.overflow {
                Text(verbatim: "+\(overflow)")
                    .font(.system(size: 4.8, weight: .bold, design: .monospaced))
                    .foregroundColor(Self.cyan.opacity(0.7))
            }
        }
        .padding(.vertical, 2.5)
        .padding(.leading, 9)
        .background(
            row.isCurrent
                ? LinearGradient(
                    colors: [Self.magentaHot.opacity(0.24), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
        )
        .overlay(alignment: .leading) {
            ZStack {
                Rectangle()
                    .fill(Self.cyan.opacity(0.3))
                    .frame(width: 0.5)
                Rectangle()
                    .fill(row.isCurrent ? Color(hex: "#3A1027") : (row.isPassed ? Color(hex: "#123029") : Color(hex: "#0B1120")))
                    .frame(width: 4.5, height: 4.5)
                    .rotationEffect(.degrees(45))
                    .overlay(
                        Rectangle()
                            .stroke(
                                row.isCurrent ? Self.magenta : (row.isPassed ? Self.cyanDim : Color(hex: "#3A4A6E")),
                                lineWidth: 0.8
                            )
                            .frame(width: 4.5, height: 4.5)
                            .rotationEffect(.degrees(45))
                    )
                    .shadow(color: row.isCurrent ? Self.magentaHot : .clear, radius: 3)
            }
            .padding(.leading, 2)
        }
    }

    // MARK: - Ticker

    private var ticker: some View {
        let segments = tickerSegments
        return VStack(spacing: 0) {
            Spacer()
            Rectangle()
                .fill(Self.cyan.opacity(0.25))
                .frame(height: 0.5)
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                Canvas { ctx, size in
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: "#050912").opacity(0.85)))
                    let resolved = segments.map { segment in
                        ctx.resolve(
                            Text(verbatim: segment.0)
                                .font(.system(size: 6.5, weight: .medium, design: .monospaced))
                                .kerning(1.2)
                                .foregroundColor(segment.1)
                        )
                    }
                    let widths = resolved.map {
                        $0.measure(in: CGSize(width: .greatestFiniteMagnitude, height: size.height)).width
                    }
                    let total = widths.reduce(0, +)
                    let cycle = max(total, size.width) + 40
                    let t = context.date.timeIntervalSinceReferenceDate
                    let offset = (t * 22).truncatingRemainder(dividingBy: cycle)
                    for base in [size.width - offset, size.width - offset + cycle] {
                        var x = base
                        for (text, width) in zip(resolved, widths) {
                            if x + width > 0 && x < size.width {
                                ctx.draw(text, at: CGPoint(x: x, y: size.height / 2), anchor: .leading)
                            }
                            x += width
                        }
                    }
                }
                .frame(height: 15.5)
            }
        }
    }

    private var tickerSegments: [(String, Color)] {
        var segments: [(String, Color)] = []
        segments.append(("DELAY:", Self.cyan))
        segments.append((
            state.delayMinutes > 0 ? "+\(String(format: "%02d", state.delayMinutes)):00 " : "+00:00 ",
            state.delayMinutes > 0 ? Self.magentaHot : Color(hex: "#7F96C4")
        ))
        if let station = headlineStation, let transfer = transfers(at: station).first {
            segments.append(("▸ TRANSFER:", Self.cyan))
            segments.append(("\(transfer.name)@\(station.name) ", Color(hex: "#7F96C4")))
        }
        segments.append(("▸ DEST:", Self.cyan))
        segments.append(("\(destinationStation?.nameEn.uppercased() ?? "") ", Color(hex: "#7F96C4")))
        segments.append(("▸ JOURNEY:", Self.cyan))
        segments.append(("ACTIVE ", Color(hex: "#7F96C4")))
        return segments
    }

    // MARK: - Data

    private struct RouteRow: Identifiable {
        let id: String
        let station: Station
        let isPassed: Bool
        let isCurrent: Bool
        let overflow: Int?
    }

    private var routeRows: [RouteRow] {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return [] }
        let ref = max(0, min(state.currentStationIndex ?? state.segmentFrom, stations.count - 1))
        let start = max(0, min(ref - 3, stations.count - Self.maxRows))
        let end = min(start + Self.maxRows, stations.count)
        let remaining = stations.count - end
        var rows = stations[start..<end].enumerated().map { offset, station in
            RouteRow(
                id: station.id,
                station: station,
                isPassed: start + offset < ref,
                isCurrent: start + offset == ref,
                overflow: (start + offset == end - 1 && remaining > 0) ? remaining : nil
            )
        }
        if orientation == .right { rows.reverse() }
        return rows
    }

    private var minutesToNext: Int? {
        let stations = journey.journeyStations
        guard state.currentStationIndex == nil,
              stations.indices.contains(state.segmentTo) else { return nil }
        let entries = Dictionary(
            journey.journeyTimetable.map { ($0.stationId, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        guard let entry = entries[stations[state.segmentTo].id],
              let arr = entry.arrivalSeconds() ?? entry.departureSeconds() else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let c = cal.dateComponents([.hour, .minute, .second], from: Date())
        var nowSec = (c.hour ?? 0) * 3600 + (c.minute ?? 0) * 60 + (c.second ?? 0)
        if nowSec < 4 * 3600 { nowSec += 24 * 3600 }
        return max(0, (arr + state.delayMinutes * 60 - nowSec + 59) / 60)
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

    private var typeNameEn: String {
        journey.service.trainType.rawValue
            .replacingOccurrences(
                of: "([a-z])([A-Z])", with: "$1 $2",
                options: .regularExpression
            )
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

    private func transfers(at station: Station) -> [TrainLine] {
        guard !journey.line.isCustom else { return [] }
        let ridden = Set(journey.line.id.split(separator: "+").map(String.init))
        return Array(
            Self.allLines
                .filter { line in
                    !ridden.contains(line.id)
                        && line.stations.contains { $0.name == station.name }
                }
                .prefix(1)
        )
    }
}

// MARK: - Chamfer Shape

private struct ChamferShape: Shape {
    let cut: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        p.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        p.closeSubpath()
        return p
    }
}
