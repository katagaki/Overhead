import SwiftUI
import Backbone

// MARK: - Rinkai LCD View

/// TWR りんかい線 70-000 series: a black header under a coloured rail, over a
/// light board of every remaining stop.
struct RinkaiLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = designWidth * 9 / 16
    private static let headerHeight: CGFloat = 58
    /// The blue rail capping the header, full width.
    private static let railHeight: CGFloat = 7
    /// How far the header content stops above the board; the bar runs to it.
    private static let barFoot: CGFloat = 2
    private static let maxUpcomingStops = 7
    private static let typeGreenTop = Color(hex: "#2F8A76")
    private static let typeGreenBottom = Color(hex: "#48B29C")
    private static let headerBlack = Color(hex: "#17171C")
    private static let markerRed = Color(hex: "#D7000F")
    private static let boxGrayTop = Color(hex: "#FBFBFD")
    private static let boxGrayBottom = Color(hex: "#D3D6DE")
    private static let codeInk = Color(hex: "#1B2233")
    private static let carBoxGray = Color(hex: "#C9CCD4")
    private static let nameRowHeight: CGFloat = 60
    private static let bandHeight: CGFloat = 16
    private static let minuteBox = CGSize(width: 18, height: 13)
    /// How far the run carries on past the last stop.
    private static let bandTail: CGFloat = 18

    private static var allLines: [TrainLine] { StaticTrainData.trainLines() }

    // Chrome takes the line's own colour.
    private var railBlue: Color { lineColor.lcdTint(saturation: 1.3, brightness: 0.81) }
    private var bandLight: Color { lineColor.lcdTint(saturation: 1.25, brightness: 0.86) }
    private var bandDark: Color { lineColor.lcdTint(saturation: 1.3, brightness: 0.56) }
    private var boardBackground: Color { lineColor.lcdTint(saturation: 0.045, brightness: 0.975) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            GeometryReader { geo in
                let scale = geo.size.width / Self.designWidth
                let english = LCDLanguageRotation.current(at: context.date) == .en
                VStack(spacing: 0) {
                    header(english: english)
                        .frame(height: Self.headerHeight)
                    board(now: context.date, english: english)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: Self.designWidth, height: Self.designHeight)
                .scaleEffect(scale, anchor: .topLeading)
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .modifier(LCDScreenClip())
            .modifier(LCDBezel())
        }
    }

    // MARK: - Header

    private func header(english: Bool) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    .init(color: Self.headerBlack, location: 0),
                    .init(color: railBlue, location: 0.14),
                    .init(color: railBlue, location: 0.86),
                    .init(color: Self.headerBlack, location: 1)
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: Self.railHeight)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(height: 0.7)
            }
            content(english: english)
                .frame(maxHeight: .infinity)
                .background(Self.headerBlack)
                .overlay(alignment: .topLeading) { typeTag(english: english) }
                .overlay(alignment: .topTrailing) { carBox(english: english) }
        }
    }

    private func content(english: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 7) {
            Text(english ? journey.line.nameEn : journey.line.name)
                .font(english ? LCDFont.latin(size: 14, weight: .bold)
                              : LCDFont.gothic(size: 17, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(width: 80, alignment: .leading)
                .padding(.bottom, Self.barFoot)

            // Docked to the board edge, so it carries no bottom hairline.
            Rectangle()
                .fill(railBlue)
                .overlay(BarOutline().stroke(Color.white.opacity(0.55), lineWidth: 0.6))
                .frame(width: 13)
                .frame(maxHeight: .infinity)
                .padding(.top, 7)

            // The pair centres on itself and sits on the bar's foot.
            HStack(alignment: .center, spacing: 7) {
                if let destination = journey.destinationStation,
                   !destination.stationCode.isEmpty {
                    scaledStationBadge(destination, dimension: 24)
                }
                HStack(alignment: .firstTextBaseline, spacing: english ? 5 : 10) {
                    if english {
                        Text(verbatim: "for")
                            .font(LCDFont.latin(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    HorizontallySquashed(maxWidth: 140, alignment: .leading) {
                        Text(english ? journey.destinationNameEn : journey.destinationNameJa)
                            .font(english ? LCDFont.latin(size: 28, weight: .bold)
                                          : LCDFont.gothic(size: 31, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(height: 34)
                    if !english {
                        Text(verbatim: "ゆき")
                            .font(LCDFont.gothic(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.bottom, Self.barFoot)
        }
        .padding(.leading, 6)
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Hangs off the rail's hairline, rounded on the bottom corners only.
    private func typeTag(english: Bool) -> some View {
        let plate = UnevenRoundedRectangle(bottomLeadingRadius: 4, bottomTrailingRadius: 4)
        return Text(english ? typeNameEn : typeName)
            .font(english ? LCDFont.latin(size: 10, weight: .bold)
                          : LCDFont.gothic(size: 12, weight: .bold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .fixedSize()
            .padding(.horizontal, 5)
            .frame(height: 17)
            .background(plate.fill(LinearGradient(
                colors: [Self.typeGreenTop, Self.typeGreenBottom],
                startPoint: .top, endPoint: .bottom
            )))
            .overlay(CarPlateOutline(radius: 4).stroke(Color.white.opacity(0.8), lineWidth: 0.7))
            .padding(.leading, 6)
    }

    /// Hung from the rail's hairline, rounded on the bottom corners only.
    private func carBox(english: Bool) -> some View {
        let plate = UnevenRoundedRectangle(bottomLeadingRadius: 4, bottomTrailingRadius: 4)
        return HStack(alignment: .firstTextBaseline, spacing: 1.5) {
            if english {
                Text(verbatim: "Car")
                    .font(LCDFont.latin(size: 9, weight: .bold))
            }
            Text(verbatim: "\(carNumber)")
                .font(LCDFont.latin(size: 15, weight: .bold))
            if !english {
                Text(verbatim: "号車")
                    .font(LCDFont.gothic(size: 9, weight: .bold))
            }
        }
        .foregroundColor(.white)
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 5)
        .frame(height: 18)
        .background(
            plate.fill(LinearGradient(
                colors: [Self.headerBlack, Color(hex: "#3E3E48")],
                startPoint: .top, endPoint: .bottom
            ))
        )
        .overlay(CarPlateOutline(radius: 4).stroke(Color.white.opacity(0.8), lineWidth: 0.7))
        .padding(.trailing, 5)
    }

    // MARK: - Board

    private func board(now: Date, english: Bool) -> some View {
        let (columns, markerSlot) = stops(now: now)
        let colWidth = (Self.designWidth - 16 - Self.bandTail) / CGFloat(max(columns.count, 1))
        let markerCenter = markerSlot * colWidth

        return VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(columns) { col in
                    columnName(col.station, english: english)
                        .frame(width: colWidth, height: Self.nameRowHeight, alignment: .center)
                        .opacity(col.isPassed ? 0.4 : 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: rowAlignment)

            HStack(spacing: 0) {
                ForEach(columns) { col in
                    Text(hyphenatedCode(col.station.stationCode))
                        .font(LCDFont.latin(size: 7.5, weight: .bold))
                        .foregroundColor(Self.codeInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: colWidth, height: 11)
                        .opacity(col.isPassed ? 0.4 : 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: rowAlignment)

            band(columns: columns, colWidth: colWidth, markerCenter: markerCenter)

            HStack(alignment: .top, spacing: 0) {
                ForEach(columns) { col in
                    transferList(col.transfers)
                        .frame(width: colWidth, alignment: .topLeading)
                        .opacity(col.isPassed ? 0.4 : 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: rowAlignment)
            .padding(.top, 2)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 8)
        .padding(.top, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(boardBackground)
        .overlay(alignment: .bottomTrailing) {
            Text(verbatim: "のりかえ、待合せ時間は含まれません。電車により多少時間が異なります。")
                .font(LCDFont.gothic(size: 5.5))
                .foregroundColor(Self.codeInk)
                .padding(.trailing, 4)
                .padding(.bottom, 2)
        }
    }

    /// Travel runs toward the trailing edge unless the rider flipped it.
    private var rowAlignment: Alignment { orientation == .right ? .trailing : .leading }

    private func band(columns: [LCDStop], colWidth: CGFloat, markerCenter: CGFloat) -> some View {
        let flipped = orientation == .right
        let runWidth = colWidth * CGFloat(max(columns.count, 1))

        return ZStack(alignment: flipped ? .trailing : .leading) {
            // Centred in the board, clear of both edges.
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(
                    colors: [bandLight, bandDark],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(maxWidth: .infinity)
                .frame(height: Self.bandHeight)
            HStack(spacing: 0) {
                ForEach(columns) { col in
                    Group {
                        if col.isPassed {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 7, height: 7)
                        } else {
                            // The served stop keeps its plate, empty.
                            minuteBox(col, showsUnit: col.id == farthestId(in: columns))
                        }
                    }
                    .frame(width: colWidth, height: Self.bandHeight)
                }
            }
            .frame(width: runWidth, alignment: flipped ? .trailing : .leading)

            // markerCenter runs from the leading end; flipped anchors trailing.
            marker()
                .offset(x: flipped ? markerCenter - runWidth + 8 : markerCenter - 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.bandHeight)
    }

    private func minuteBox(_ col: LCDStop, showsUnit: Bool) -> some View {
        HStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Self.boxGrayTop, Self.boxGrayBottom],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: Self.minuteBox.width, height: Self.minuteBox.height)
                if let minutes = col.minutes {
                    Text(verbatim: "\(minutes)")
                        .font(LCDFont.latin(size: 12.5, weight: .bold))
                        .foregroundColor(Self.codeInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: Self.minuteBox.width - 2)
                }
            }
            if showsUnit {
                Text(verbatim: "分")
                    .font(LCDFont.gothic(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 13)
            }
        }
        // The 分 rides the band beside the last plate, off its own column.
        .offset(x: showsUnit ? (orientation == .right ? -6.5 : 6.5) : 0)
    }

    /// A red chevron, white-outlined, standing just proud of the band.
    private func marker() -> some View {
        let pointsTrailing = orientation != .right
        return TravelChevron(pointsTrailing: pointsTrailing)
            .fill(Self.markerRed)
            .overlay(TravelChevron(pointsTrailing: pointsTrailing)
                .stroke(Color.white, lineWidth: 1.2))
            .frame(width: 16, height: Self.bandHeight + 2)
    }

    /// Kanji stays through the English phase; the side column carries the
    /// other signage languages.
    private func columnName(_ station: Station, english: Bool) -> some View {
        HStack(alignment: .center, spacing: 1) {
            VerticalStationName(name: station.name, fontSize: 13, charBox: 12,
                                availableHeight: Self.nameRowHeight, color: .black,
                                columnAnchor: .top, justifiedSingle: true, gothic: true)
                .frame(height: Self.nameRowHeight, alignment: .top)
            let reading = english ? station.nameZhHans : station.nameKo
            if !reading.isEmpty {
                VerticalStationName(name: reading, fontSize: 5.5, weight: .medium, charBox: 6,
                                    availableHeight: Self.nameRowHeight,
                                    color: Self.codeInk.opacity(0.8),
                                    columnAnchor: .top, gothic: true)
                    .frame(height: Self.nameRowHeight, alignment: .center)
            }
        }
    }

    private func transferList(_ lines: [TrainLine]) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(lines) { line in
                LCDTransferLineName(name: line.name, fontSize: 6,
                                    symbol: line.lineSymbol, badgeColor: line.color,
                                    badgeStyleId: line.badgeStyleId,
                                    badgeLineId: line.id, color: Self.codeInk)
            }
        }
        .padding(.horizontal, 1)
        .padding(.top, 1)
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

        // The board reads toward the destination, so the current stop leads.
        var columns: [LCDStop] = []
        if dwellIndex != nil {
            columns.append(LCDStop(
                id: stations[ref].id, station: stations[ref], minutes: nil,
                isCurrent: true, isPassed: false, transfers: transfers(at: stations[ref])
            ))
        }
        columns.append(contentsOf: upcoming)
        let markerSlot = dwellIndex != nil ? 0.5 : CGFloat(0)

        let passedUpper = dwellIndex != nil ? ref : ref + 1
        let deficit = Self.maxUpcomingStops + 1 - columns.count
        var leading: [LCDStop] = []
        if deficit > 0 {
            leading = stations[..<passedUpper]
                .filter { entries[$0.id] != nil }
                .suffix(deficit)
                .map { station in
                    LCDStop(id: station.id, station: station, minutes: nil,
                            isCurrent: false, isPassed: true,
                            transfers: transfers(at: station))
                }
        }
        let all = leading + columns
        let slot = CGFloat(leading.count) + markerSlot

        if orientation == .right {
            return (all.reversed(), CGFloat(all.count) - slot)
        }
        return (all, slot)
    }

    private func farthestId(in columns: [LCDStop]) -> String? {
        orientation == .right ? columns.first?.id : columns.last?.id
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
                .prefix(3)
        )
    }

    /// R08 → R-08, the way the plate is set in running text.
    private func hyphenatedCode(_ code: String) -> String {
        guard let split = code.firstIndex(where: \.isNumber), split != code.startIndex else {
            return code
        }
        return code[..<split] + "-" + code[split...]
    }

    /// A through service names the line being ridden now, switching at the
    /// junction.
    private var currentLine: TrainLine {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return journey.line }
        let index = state.currentStationIndex ?? state.segmentTo
        let station = stations[max(0, min(index, stations.count - 1))]
        return StaticTrainData.line(containingStationId: station.id)?.trainLine ?? journey.line
    }

    private var typeName: String {
        journey.service.trainType == .local ? "各駅停車" : journey.service.trainType.displayNameJa
    }

    private var typeNameEn: String {
        journey.service.trainType.rawValue.reduce(into: "") { result, char in
            if char.isUppercase && !result.isEmpty { result.append(" ") }
            result.append(char)
        }
    }

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
            styleOverride: journey.line.badgeStyleId,
            lineId: journey.line.id
        )
        .scaleEffect(dimension / 28)
        .frame(width: dimension, height: dimension)
    }
}

// MARK: - Shapes

/// The separator bar's hairline: sides and top only — its foot meets the board.
private struct BarOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}

/// The car plate's hairline: sides and bottom only — the rail draws its top.
private struct CarPlateOutline: Shape {
    var radius: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
        p.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.maxY),
                       control: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - radius),
                       control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

/// The same notched arrow the Metro strip uses, pointing the way of travel.
private struct TravelChevron: Shape {
    var pointsTrailing = true

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
