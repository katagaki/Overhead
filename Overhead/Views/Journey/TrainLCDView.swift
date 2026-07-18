import SwiftUI
import Backbone

// MARK: - Train LCD View

struct TrainLCDView: View {
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
    private static let headerHeight: CGFloat = designHeight * 0.33
    private static let maxUpcomingStops = 7
    private static let lcdRed = Color(hex: "#D7000F")
    private static let passedOpacity: CGFloat = 0.4
    private static let passedBandGray = Color(hex: "#8E9196")
    private static let languageFlipSeconds = 4.0

    private static let allLines = StaticTrainData.trainLines()
    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "H:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            GeometryReader { geo in
                let scale = geo.size.width / Self.designWidth
                let english = Int(
                    context.date.timeIntervalSinceReferenceDate / Self.languageFlipSeconds
                ) % 2 == 1
                VStack(spacing: 0) {
                    header(now: context.date, english: english)
                        .frame(height: Self.headerHeight)
                    progression(now: context.date)
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

    // MARK: - Header (black area)

    private func header(now: Date, english: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            destinationPlate(english: english)

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 3) {
                    Text(headlineLabel(english: english))
                        .font(.system(size: english ? 10 : 12, weight: .bold))
                    Spacer()
                    Text(verbatim: english ? "Time" : "現在時刻")
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
                            scaledStationBadge(station, dimension: 26)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26 * 0.21 + 1.5)
                                        .strokeBorder(Color.black, lineWidth: 1.5)
                                        .padding(-1.5)
                                )
                        }
                        HorizontallySquashed {
                            Text(english ? station.nameEn : station.name)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                                .kerning(english ? 0 : 5.0)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 2)

            carColumn(english: english)
                .padding(.top, 2)
        }
        .padding(.trailing, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hue: 0.0, saturation: 0.0, brightness: 0.1))
    }

    private func destinationPlate(english: Bool) -> some View {
        VStack(spacing: 2) {
            Text(english ? typeNameEn : typeName)
                .font(.system(size: 15, weight: .black))
                .kerning(english ? 0 : typeKerning)
                .padding(.leading, english ? 0 : typeKerning)
                .foregroundColor(displayColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .modifier(ItalicSkew())
                .frame(maxWidth: .infinity)
                .frame(height: 18)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 3))

            Spacer(minLength: 0)

            if english {
                HStack(alignment: .bottom, spacing: 3) {
                    Text(verbatim: "for")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.bottom, 2)
                    HorizontallySquashed(maxWidth: 60) {
                        Text(verbatim: destinationStation?.nameEn ?? "")
                            .font(.system(size: 13, weight: .heavy))
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.85), radius: 1, x: 0, y: 0)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            } else {
                Text(destinationStation?.name ?? "")
                    .font(.system(size: 16, weight: .heavy))
                    .lineLimit(1)
                    .kerning(3.0)
                    .minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.85), radius: 1, x: 0, y: 0)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }

            Text(verbatim: "ゆき")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .opacity(english ? 0 : 1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(EdgeInsets(top: 4, leading: 5, bottom: 3, trailing: 16))
        .frame(width: 102)
        .frame(maxHeight: .infinity)
        .background(PlateShape().fill(displayColor))
    }

    @ViewBuilder
    private func carColumn(english: Bool) -> some View {
        let numberBox = Text(verbatim: "\(carNumber)")
            .font(.system(size: 16, weight: .heavy))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundColor(displayColor)
            .frame(width: 18, height: 18)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 2))
        Group {
            if english {
                HStack(alignment: .top, spacing: 3) {
                    Text(verbatim: "Car No.")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize()
                    numberBox
                }
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    numberBox
                    Text(verbatim: "号車")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 56, alignment: .trailing)
    }

    // MARK: - Progression (white area)

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
            .padding(.bottom, 2)

            ZStack(alignment: .leading) {
                let tailPad = max(0, colWidth / 2 - 6)
                let totalWidth = colWidth * CGFloat(max(columns.count, 1))
                ArrowBandShape(tipOnTrailing: orientation == .right)
                    .fill(displayColor)
                    .frame(height: 17)
                    .padding(orientation == .right ? .leading : .trailing, tailPad)
                // The stretch behind the train turns gray, marker to tail edge.
                if orientation == .right {
                    Rectangle()
                        .fill(Self.passedBandGray)
                        .frame(width: max(0, markerCenter - tailPad), height: 17)
                        .offset(x: tailPad)
                } else {
                    Rectangle()
                        .fill(Self.passedBandGray)
                        .frame(width: max(0, totalWidth - tailPad - markerCenter), height: 17)
                        .offset(x: markerCenter)
                }
                HStack(spacing: 0) {
                    ForEach(columns) { col in
                        Group {
                            if col.isCurrent {
                                Color.clear
                            } else if col.isPassed {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                            } else {
                                minuteCircle(col, showsUnit: col.id == farthestId(in: columns))
                            }
                        }
                        .frame(width: colWidth)
                    }
                }
                Group {
                    if state.currentStationIndex != nil {
                        currentMarker
                            .offset(x: markerCenter - 27 / 2)
                    } else {
                        movingMarker
                            .offset(x: markerCenter - 11 / 2)
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
                        .opacity(col.isPassed ? Self.passedOpacity : 1)
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
        VerticalStationName(name: name, fontSize: 11, charBox: 12,
                            availableHeight: 52, color: .black, columnAnchor: .bottom)
    }

    private func minuteCircle(_ col: LCDStop, showsUnit: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
            if let minutes = col.minutes {
                Text(verbatim: "\(minutes)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: 12)
                if showsUnit {
                    Text(verbatim: "(分)")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: orientation == .right ? -13 : 13)
                }
            }
        }
    }

    private var currentMarker: some View {
        let flipped = orientation == .right
        return ZStack {
            ArrowBandShape(tipOnTrailing: flipped)
                .fill(Self.lcdRed)
                .overlay(ArrowBandShape(tipOnTrailing: flipped).stroke(Color.white, lineWidth: 1.5))
                .frame(width: 27, height: 21)
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .offset(x: flipped ? -2.5 : 2.5)
        }
    }

    /// The in-transit marker: a solid chevron pointing the direction of travel.
    private var movingMarker: some View {
        let flipped = orientation == .right
        return TravelChevronShape(pointsTrailing: flipped)
            .fill(Self.lcdRed)
            .overlay(TravelChevronShape(pointsTrailing: flipped).stroke(Color.white, lineWidth: 1.5))
            .frame(width: 11, height: 20)
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
        let minutes: Int?    // nil for the current column (red marker) and passed stops
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

    private func farthestId(in columns: [LCDStop]) -> String? {
        orientation == .right ? columns.last?.id : columns.first?.id
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

    private func headlineLabel(english: Bool) -> String {
        if english {
            return state.currentStationIndex != nil ? "Now stopping at" : "Next"
        }
        return state.currentStationIndex != nil ? "ただいま" : "つぎは"
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

    /// Raw type names are camel-cased ("CommuterRapid") — space them out.
    private var typeNameEn: String {
        journey.service.trainType.rawValue.reduce(into: "") { result, char in
            if char.isUppercase && !result.isEmpty { result.append(" ") }
            result.append(char)
        }
    }

    private var typeKerning: CGFloat {
        switch typeName.count {
        case ...2: return 12
        case 3: return 5
        case 4: return 1.5
        default: return 0
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

private struct TravelChevronShape: Shape {
    var pointsTrailing = false

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width / 3, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.width / 3, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.width * 2 / 3, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return pointsTrailing ? p.mirroredHorizontally(in: rect) : p
    }
}

private struct ArrowBandShape: Shape {
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

extension Path {
    /// The same path flipped about the rect's vertical centerline.
    func mirroredHorizontally(in rect: CGRect) -> Path {
        applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: rect.minX + rect.maxX, ty: 0))
    }
}

// MARK: - Italic Skew

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
