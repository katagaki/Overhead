import SwiftUI
import Backbone
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Metro LCD View

struct MetroLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    private var displayColor: Color {
        let firstLegId = journey.line.id.split(separator: "+").first.map(String.init)
            ?? journey.line.id
        guard let hex = LineColors.lcdOverrides[firstLegId] else { return lineColor }
        return Color(hex: hex)
    }

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
                    if StationNumberBadge.rendersAsCircle(
                        code: station.stationCode, color: stationColor(station),
                        styleOverride: journey.line.badgeStyle
                    ) {
                        scaledStationBadge(station, dimension: 40)
                            .offset(y: 2.5)
                    } else {
                        scaledStationBadge(station, dimension: 31)
                    }
                }
                HorizontallySquashed {
                    Text(station.name)
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.black)
                        .lineLimit(1)
                }
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
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(displayColor)
                .frame(height: 2.5)
        }
    }

    // MARK: - Progression (white area)

    private func progression(now: Date) -> some View {
        let (builtCols, builtSlot) = columns(now: now)
        let mirrored = orientation == .left
        let cols = mirrored ? Array(builtCols.reversed()) : builtCols
        let markerSlot = mirrored ? CGFloat(builtCols.count) - builtSlot : builtSlot
        let leadInset = mirrored ? Self.columnsTrailing : Self.columnsLeading
        let colWidth = (Self.designWidth - Self.columnsLeading - Self.columnsTrailing)
            / CGFloat(max(cols.count, 1))
        let markerCenter = leadInset + markerSlot * colWidth

        return VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(cols) { col in
                    transferList(col.transfers)
                        .frame(width: colWidth, alignment: .bottomLeading)
                }
            }
            .padding(.leading, leadInset)
            .padding(.bottom, 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(cols) { col in
                        Group {
                            if col.isCurrent {
                                Color.clear
                            } else if col.isPassed {
                                passedBox
                            } else {
                                minuteBox(col.minutes)
                            }
                        }
                        .frame(width: colWidth)
                    }
                }
                .padding(.leading, leadInset)

                DirectionMarker(pointsLeading: mirrored)
                    .fill(Self.markerBlue)
                    .overlay(DirectionMarker(pointsLeading: mirrored).stroke(Color.white, lineWidth: 1.2))
                    .frame(width: 17, height: Self.bandHeight)
                    .offset(x: max(0, markerCenter - 8.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: Self.bandHeight)
            .metalBandGradient(displayColor)
            .compositingGroup()
            .shadow(color: .black.opacity(0.4), radius: 0.8, x: 0, y: 1)
            .overlay(alignment: mirrored ? .bottomLeading : .bottomTrailing) {
                Text(verbatim: "分")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0.5, x: 0, y: 0.8)
                    .padding(mirrored ? .leading : .trailing, 9)
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
            .padding(.leading, leadInset)
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
            .padding(.leading, leadInset)
            .frame(height: Self.namesHeight)
            .frame(maxWidth: .infinity, alignment: .leading)

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

    private func verticalName(_ name: String, passed: Bool) -> some View {
        VerticalStationName(name: name, fontSize: 11.5, charBox: 12,
                            availableHeight: Self.namesHeight - 8,
                            color: passed ? Self.passedGray : .black,
                            columnAnchor: .top, justifiedSingle: true)
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

private struct DirectionMarker: Shape {
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

// MARK: - Metal Band Gradient

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
