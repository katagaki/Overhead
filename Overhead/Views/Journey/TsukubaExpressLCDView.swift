import SwiftUI
import Backbone

// MARK: - Tsukuba Express LCD View

/// TX-2000 series door strip: an ultra-wide travel-time board — angled romaji
/// in English, vertical kanji in Japanese, over a run of minute plates.
struct TsukubaExpressLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = 76
    private static let maxUpcomingStops = 7
    private static let gutter: CGFloat = 40
    /// Room on the band's leading end for the "min" cell.
    private static let leadIn: CGFloat = 27
    /// Slack past the last stop, where the band runs on to its cap.
    private static let trailTail: CGFloat = 18
    private static let nameRowHeight: CGFloat = 35
    private static let codeRowHeight: CGFloat = 9
    private static let bandHeight: CGFloat = 12
    private static let minuteBox = CGSize(width: 12, height: 8.5)
    private static let bandPastTop = Color(hex: "#8B90A1")
    private static let bandPastBottom = Color(hex: "#5A5F70")
    private static let languageFlipSeconds = 4.0
    private static let passedSlate = Color(hex: "#A6AABB")
    private static let ink = Color(hex: "#2B3049")
    private static let markerYellow = Color(hex: "#F2C230")
    private static let panel = Color(hex: "#EEEFF5")

    private static var allLines: [TrainLine] { StaticTrainData.trainLines() }

    // The run still to come takes the line's own colour.
    private var runTop: Color { lineColor.lcdTint(saturation: 1.5, brightness: 0.90) }
    private var runBottom: Color { lineColor.lcdTint(saturation: 1.6, brightness: 0.70) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            GeometryReader { geo in
                let scale = geo.size.width / Self.designWidth
                let english = Int(
                    context.date.timeIntervalSinceReferenceDate / Self.languageFlipSeconds
                ) % 2 == 1
                strip(now: context.date, english: english)
                    .frame(width: Self.designWidth, height: Self.designHeight)
                    .scaleEffect(scale, anchor: .topLeading)
            }
            .aspectRatio(Self.designWidth / Self.designHeight, contentMode: .fit)
            .modifier(LCDScreenClip())
            .modifier(LCDBezel())
        }
    }

    private func strip(now: Date, english: Bool) -> some View {
        let (columns, markerSlot) = stops(now: now)
        let usable = Self.designWidth - Self.gutter - Self.leadIn - Self.trailTail - 8
        let colWidth = usable / CGFloat(max(columns.count, 1))
        let markerCenter = markerSlot * colWidth
        let mirrored = orientation == .right

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(columns) { col in
                    Group {
                        if english {
                            AngledTXName(en: col.station.nameEn, ja: col.station.name,
                                         width: colWidth, height: Self.nameRowHeight,
                                         mirrored: mirrored,
                                         color: col.isPassed ? Self.passedSlate : Self.ink)
                        } else {
                            verticalName(col)
                        }
                    }
                    .frame(width: colWidth, height: Self.nameRowHeight)
                }
            }
            .padding(mirrored ? .trailing : .leading, Self.leadIn)
            .frame(maxWidth: .infinity, alignment: mirrored ? .trailing : .leading)

            HStack(spacing: 0) {
                ForEach(columns) { col in
                    Text(hyphenatedCode(col.station.stationCode))
                        .font(LCDFont.latin(size: 6, weight: .bold))
                        .foregroundColor(col.isPassed ? Self.passedSlate : Self.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: colWidth, height: Self.codeRowHeight)
                }
            }
            .padding(mirrored ? .trailing : .leading, Self.leadIn)
            .frame(maxWidth: .infinity, alignment: mirrored ? .trailing : .leading)

            band(columns: columns, colWidth: colWidth,
                 markerCenter: markerCenter, mirrored: mirrored, english: english)

            HStack(alignment: .top, spacing: 0) {
                ForEach(columns) { col in
                    caption(col, width: colWidth, english: english)
                        .frame(width: colWidth, alignment: .topLeading)
                }
            }
            .padding(mirrored ? .trailing : .leading, Self.leadIn)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.leading, Self.gutter)
        .padding(.trailing, 8)
        .padding(.top, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.white, Self.panel],
                           startPoint: .top, endPoint: .bottom)
        )
        .overlay(alignment: .topLeading) { gutterLabels(english: english) }
    }

    private func gutterLabels(english: Bool) -> some View {
        Text(verbatim: english ? "Travel Times" : "所要時間")
            .font(english ? LCDFont.latin(size: 5.5)
                          : LCDFont.gothic(size: 6))
            .foregroundColor(Self.ink)
            .lineLimit(1)
            .fixedSize()
            .frame(width: Self.gutter + 6, alignment: .trailing)
            .offset(y: 2 + Self.nameRowHeight)
    }

    /// The Japanese face sets the stops vertically, reading beside them.
    private func verticalName(_ col: LCDStop) -> some View {
        let tint = col.isPassed ? Self.passedSlate : Self.ink
        return HStack(alignment: .bottom, spacing: 0.5) {
            VerticalStationName(name: col.station.name, fontSize: 7.5, charBox: 7.5,
                                availableHeight: Self.nameRowHeight, color: tint,
                                columnAnchor: .bottom, gothic: true)
            if !col.station.nameKo.isEmpty {
                VerticalStationName(name: col.station.nameKo, fontSize: 4,
                                    weight: .medium, charBox: 4.2,
                                    availableHeight: Self.nameRowHeight,
                                    color: tint.opacity(0.85),
                                    columnAnchor: .bottom, gothic: true)
            }
        }
        .frame(height: Self.nameRowHeight, alignment: .bottom)
    }

    private func band(columns: [LCDStop], colWidth: CGFloat,
                      markerCenter: CGFloat, mirrored: Bool, english: Bool) -> some View {
        colourBand(columns: columns, colWidth: colWidth, markerCenter: markerCenter,
                   mirrored: mirrored, english: english)
    }

    /// The line's colour for what is left, grey for what is already run.
    private func colourBand(columns: [LCDStop], colWidth: CGFloat,
                            markerCenter: CGFloat, mirrored: Bool,
                            english: Bool) -> some View {
        let count = CGFloat(max(columns.count, 1))
        let runWidth = colWidth * count
        let lead = Self.leadIn
        let ahead = mirrored   // chevrons point the way the train is going
        // Distances run from the band's leading end, whichever side that is.
        func span(_ from: CGFloat, _ width: CGFloat) -> CGFloat {
            mirrored ? -(from + lead) : from + lead
        }
        func centred(_ at: CGFloat, _ width: CGFloat) -> CGFloat {
            mirrored ? -(at + lead - width / 2) : at + lead - width / 2
        }

        return ZStack(alignment: mirrored ? .trailing : .leading) {
            TXBandShape(roundedOnTrailing: !mirrored)
                .fill(LinearGradient(colors: [runTop, runBottom],
                                     startPoint: .top, endPoint: .bottom))
                .frame(height: Self.bandHeight)

            // Everything behind the train, capped where the train stands.
            UnevenRoundedRectangle(
                topLeadingRadius: mirrored ? Self.bandHeight / 2 : 0,
                bottomLeadingRadius: mirrored ? Self.bandHeight / 2 : 0,
                bottomTrailingRadius: mirrored ? 0 : Self.bandHeight / 2,
                topTrailingRadius: mirrored ? 0 : Self.bandHeight / 2
            )
                .fill(LinearGradient(colors: [Self.bandPastTop, Self.bandPastBottom],
                                     startPoint: .top, endPoint: .bottom))
                // Reach under the point, or its notch shows the run through.
                .frame(width: max(0, runWidth - markerCenter + Self.trailTail),
                       height: Self.bandHeight)
                .offset(x: span(markerCenter, 0))
            TXChevron(pointsTrailing: ahead)
                .fill(LinearGradient(colors: [Self.bandPastTop, Self.bandPastBottom],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 7, height: Self.bandHeight)
                .offset(x: centred(markerCenter + 5, 7))

            HStack(spacing: 0) {
                ForEach(columns) { col in
                    Group {
                        if col.isCurrent {
                            Color.clear
                        } else {
                            plate(col)
                        }
                    }
                    .frame(width: colWidth, height: Self.bandHeight)
                }
            }
            .padding(mirrored ? .trailing : .leading, lead)
            .frame(maxWidth: .infinity, alignment: mirrored ? .trailing : .leading)

            Text(verbatim: english ? "min" : "分")
                .font(english ? LCDFont.latin(size: 6, weight: .bold)
                              : LCDFont.gothic(size: 7, weight: .bold))
                .foregroundColor(.white)
                .frame(width: lead - Self.bandHeight, height: Self.bandHeight)
                .padding(mirrored ? .trailing : .leading, Self.bandHeight)

            TXChevron(pointsTrailing: ahead)
                .fill(LinearGradient(
                    colors: [Self.markerYellow, Self.markerYellow.opacity(0.78)],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(TXChevron(pointsTrailing: ahead)
                    .stroke(Color.white, lineWidth: 0.8))
                .frame(width: 11, height: Self.bandHeight + 1.5)
                .offset(x: centred(markerCenter, 11))
        }
        .frame(height: Self.bandHeight)
    }

    /// The white minute plate both faces share.
    private func plate(_ col: LCDStop) -> some View {
        Group {
            if let minutes = col.minutes {
                Text(verbatim: "\(minutes)")
                    .font(LCDFont.latin(size: 7.5, weight: .bold))
                    .foregroundColor(Self.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Color.clear
            }
        }
        .frame(width: Self.minuteBox.width, height: Self.minuteBox.height)
        .background(Color.white)
        .overlay(Rectangle().strokeBorder(Self.ink.opacity(0.55), lineWidth: 0.5))
    }

    @ViewBuilder
    private func caption(_ col: LCDStop, width: CGFloat, english: Bool) -> some View {
        if let line = col.transfers.first {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(Self.ink.opacity(0.5))
                    .frame(width: 0.7, height: 4)
                Rectangle()
                    .fill(Self.ink.opacity(0.5))
                    .frame(width: max(0, width - 4), height: 0.5)
                HStack(alignment: .top, spacing: 1.5) {
                    LineSymbolBadge(symbol: line.lineSymbol, color: line.color, dimension: 5.5,
                                    styleOverride: line.badgeStyleId, lineId: line.id)
                    Text(english ? line.nameEn : line.name)
                        .font(english ? LCDFont.latin(size: 4.6)
                                      : LCDFont.gothic(size: 4.6))
                        .foregroundColor(col.isPassed ? Self.passedSlate : Self.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: max(0, width - 9), alignment: .leading)
                }
                .padding(.top, 1)
            }
            .padding(.leading, max(0, width / 2 - 1))
        } else {
            // An empty column would ignore its width and shift the row left.
            Color.clear
        }
    }

    // MARK: - Data

    private struct LCDStop: Identifiable {
        let id: String
        let station: Station
        let minutes: Int?
        let isCurrent: Bool
        let isPassed: Bool
        let transfers: [TrainLine]
    }

    private func stops(now: Date) -> ([LCDStop], CGFloat) {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return ([], 0) }
        let entries = Dictionary(
            journey.journeyTimetable.map { ($0.stationId, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        let dwellIndex = state.currentStationIndex.map { max(0, min($0, stations.count - 1)) }
        let ref = dwellIndex ?? max(0, min(state.segmentFrom, stations.count - 1))
        let nowSec = LCDPhase.railSeconds(at: now)
        let delaySec = state.delayMinutes * 60

        let upcoming = stations[(ref + 1)...]
            .compactMap { station -> LCDStop? in
                guard let entry = entries[station.id] else { return nil }
                let arrival = entry.arrivalSeconds() ?? entry.departureSeconds()
                return LCDStop(
                    id: station.id,
                    station: station,
                    minutes: arrival.map { max(0, ($0 + delaySec - nowSec + 59) / 60) },
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
            columns.append(contentsOf: stations[..<passedUpper]
                .filter { entries[$0.id] != nil }
                .suffix(deficit)
                .reversed()
                .map { station in
                    LCDStop(id: station.id, station: station, minutes: nil,
                            isCurrent: false, isPassed: true,
                            transfers: transfers(at: station))
                })
        }

        if orientation == .right {
            return (columns.reversed(), CGFloat(columns.count) - markerSlot)
        }
        return (columns, markerSlot)
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

    private func hyphenatedCode(_ code: String) -> String {
        guard let split = code.firstIndex(where: \.isNumber), split != code.startIndex else {
            return code
        }
        return code[..<split] + "-" + code[split...]
    }
}

// MARK: - Angled bilingual label

/// Romaji leading, kanji trailing, climbing away from the band like the real
/// TX strip sets its stop names.
private struct AngledTXName: View {
    let en: String
    let ja: String
    let width: CGFloat
    let height: CGFloat
    var mirrored = false
    var color: Color = .black

    private static let degrees: CGFloat = 60

    /// The board breaks romaji after its hyphens rather than shrinking it.
    private var romajiLines: [String] {
        guard en.contains("-") else { return [en] }
        var lines: [String] = []
        var current = ""
        for part in en.split(separator: "-", omittingEmptySubsequences: false) {
            if current.isEmpty {
                current = String(part)
            } else {
                lines.append(current + "-")
                current = String(part)
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    var body: some View {
        let run = (height - 2) / sin(Self.degrees * .pi / 180) * 1.5
        VStack(alignment: mirrored ? .trailing : .leading, spacing: -0.5) {
            ForEach(Array(romajiLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(LCDFont.latin(size: 6.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Text(ja)
                .font(LCDFont.gothic(size: 5))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .foregroundColor(color)
        .frame(maxWidth: run, alignment: mirrored ? .trailing : .leading)
        .rotationEffect(
            .degrees(mirrored ? Self.degrees : -Self.degrees),
            anchor: mirrored ? .bottomTrailing : .bottomLeading
        )
        .frame(width: width, height: height,
               alignment: mirrored ? .bottomTrailing : .bottomLeading)
        .offset(x: mirrored ? -max(0, width / 2 - 5) : max(0, width / 2 - 5))
    }
}

// MARK: - Shapes

private struct TXBandShape: Shape {
    var roundedOnTrailing = true

    func path(in rect: CGRect) -> Path {
        let r = rect.height / 2
        // The leading end is chisel-cut at 45°, tip on the bottom corner.
        let cut = rect.height
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.midY), radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return roundedOnTrailing ? p : p.mirroredHorizontally(in: rect)
    }
}

/// The same notched arrow the Metro strip uses, pointing the way of travel.
private struct TXChevron: Shape {
    var pointsTrailing = false

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
        return pointsTrailing ? p : p.mirroredHorizontally(in: rect)
    }
}

private extension Color {
    /// The line's own hue, pushed to a fixed brightness for LCD chrome.
    /// Saturation scales from the source so grey lines stay grey.
    func lcdTint(saturation satFactor: CGFloat, brightness: CGFloat) -> Color {
        #if canImport(UIKit)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h,
                     saturation: min(1, max(0, s * satFactor)),
                     brightness: min(1, max(0, brightness)),
                     opacity: a)
        #else
        return self
        #endif
    }
}
