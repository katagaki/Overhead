import SwiftUI
import Backbone

// MARK: - Keisei LCD View

/// 京成 3000/3100 series in-car LCD: a white destination strip over a deep blue
/// headline band, then a board of every remaining stop above a blue run bar.
struct KeiseiLCDView: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    private static let designWidth: CGFloat = 360
    private static let designHeight: CGFloat = designWidth * 3 / 4
    private static let destRowHeight: CGFloat = 33.5
    private static let headlineHeight: CGFloat = 45
    private static let ruleHeight: CGFloat = 1.5
    private static let footerHeight: CGFloat = 17.5
    private static let maxColumns = 9
    private static let boardTopPad: CGFloat = 5
    /// The islands on the top bar float on the chrome with a hairline gap.
    private static let islandGap: CGFloat = 2
    private static let nameRowHeight: CGFloat = 80
    private static let badgeRowHeight: CGFloat = 20
    private static let bandHeight: CGFloat = 12.5
    /// The box tracks the badge above it, so the two read as one column.
    private static let minuteBox = CGSize(width: badgeRowHeight, height: 10)
    private static let markerRed = Color(hex: "#C8102E")
    private static let boardInk = Color(hex: "#11223F")
    private static let boardBackground = Color(hex: "#FDFDFF")
    private static let footerBackground = Color(hex: "#E7EEF8")

    private static var allLines: [TrainLine] { StaticTrainData.trainLines() }

    /// The chrome takes the line's own hue, pushed to the display's deep blue.
    // Held to the luminance the Keisei blue lands at, so a yellow or orange
    // line darkens to the same weight instead of glaring or going muddy.
    private var bandBlue: Color { lineColor.lcdChrome(luminance: 0.089) }
    private var headlineBlue: Color { lineColor.lcdChrome(luminance: 0.060) }

    /// The headline band lifts slightly toward its top edge.
    private var headlineGradient: LinearGradient {
        LinearGradient(colors: [lineColor.lcdChrome(luminance: 0.082), headlineBlue],
                       startPoint: .top, endPoint: .bottom)
    }

    /// The board grounds white at the names and cools toward the foot.
    private var boardGradient: LinearGradient {
        LinearGradient(colors: [.white, Color(hex: "#DCE3EE")],
                       startPoint: .top, endPoint: .bottom)
    }

    /// The run bar keeps a little depth of its own.
    private func bandGradient(_ base: Color) -> LinearGradient {
        LinearGradient(colors: [base.lcdChrome(luminance: 0.125),
                                base.lcdChrome(luminance: 0.089)],
                       startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            GeometryReader { geo in
                let scale = geo.size.width / Self.designWidth
                let language = LCDLanguageRotation.current(at: context.date)
                let phase = LCDPhase.of(journey: journey, state: state, now: context.date)
                VStack(spacing: 0) {
                    destinationRow(language: language)
                        .frame(height: Self.destRowHeight)
                    Rectangle()
                        .fill(Self.markerRed)
                        .frame(height: Self.ruleHeight)
                    headline(phase: phase, language: language)
                        .frame(height: Self.headlineHeight)
                    board(now: context.date, language: language)
                        .frame(maxHeight: .infinity)
                    Rectangle()
                        .fill(Self.boardInk)
                        .frame(height: 1.5)
                }
                .frame(width: Self.designWidth, height: Self.designHeight)
                .scaleEffect(scale, anchor: .topLeading)
            }
            .aspectRatio(Self.designWidth / Self.designHeight, contentMode: .fit)
            .modifier(LCDScreenClip())
            .modifier(LCDBezel())
        }
    }

    // MARK: - Destination row

    /// Three islands — type, destination, car — floating on the chrome blue.
    private func destinationRow(language: TrainLCDLanguage) -> some View {
        HStack(spacing: Self.islandGap) {
            typePlate(language: language)
            destinationIsland(language: language)
            carBox(language: language)
        }
        .padding(.horizontal, Self.islandGap)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(headlineGradient)
    }

    private func destinationIsland(language: TrainLCDLanguage) -> some View {
        HStack(spacing: 4) {
            if let destination = journey.destinationStation,
               !destination.stationCode.isEmpty {
                outlinedBadge(destination, dimension: 25, outline: .white, width: 1)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                if language.isLatin {
                    Text(verbatim: "for")
                        .font(LCDFont.latin(size: 10, weight: .bold))
                        .foregroundColor(Self.boardInk)
                }
                HorizontallySquashed(maxWidth: 190, alignment: .leading) {
                    Text(language.destinationName(journey))
                        .font(language.isLatin ? LCDFont.latin(size: 20, weight: .bold)
                                      : LCDFont.gothic(size: 22, weight: .bold))
                        .foregroundColor(Self.boardInk)
                        .lineLimit(1)
                }
                .frame(height: 25)
                if !language.isLatin {
                    Text(verbatim: language.destinationSuffix(japanese: "行"))
                        .font(LCDFont.gothic(size: 14, weight: .bold))
                        .foregroundColor(Self.boardInk)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.white, Color(hex: "#E4E9F3")],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private func typePlate(language: TrainLCDLanguage) -> some View {
        Text(language.typeName(ja: typeName, en: typeNameEn))
            .font(language.isLatin ? LCDFont.latin(size: 11, weight: .bold)
                          : LCDFont.gothic(size: 17, weight: .bold))
            .multilineTextAlignment(.center)
            .lineLimit(language.isLatin ? 2 : 1)
            .lineSpacing(-1)
            .minimumScaleFactor(0.6)
            .foregroundColor(.white)
            .padding(.horizontal, 3)
            .frame(width: 57)
            .frame(maxHeight: .infinity)
            .background(
                LinearGradient(colors: [typeColor.opacity(0.92), typeColor],
                               startPoint: .top, endPoint: .bottom)
            )
            .overlay(Rectangle().strokeBorder(Color.white, lineWidth: 0.8))
    }

    private func carBox(language: TrainLCDLanguage) -> some View {
        VStack(spacing: -0.5) {
            Text(verbatim: "Car No.")
                .font(LCDFont.latin(size: 9, weight: .bold))
            HStack(alignment: .firstTextBaseline, spacing: 0.5) {
                Text(verbatim: "\(carNumber)")
                    .font(LCDFont.latin(size: 16, weight: .bold))
                if !language.isLatin {
                    Text(verbatim: language.carLabel)
                        .font(LCDFont.gothic(size: 7.5, weight: .bold))
                }
            }
        }
        .foregroundColor(Self.boardInk)
        .fixedSize()
        .frame(width: 40, height: Self.destRowHeight - 4, alignment: .center)
        .frame(maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.white, Color(hex: "#E4E9F3")],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    // MARK: - Headline

    private func headline(phase: LCDPhase, language: TrainLCDLanguage) -> some View {
        let station = headlineStation
        return HStack(spacing: 5) {
            Text(phaseLabel(phase, language: language))
                .font(language.isLatin ? LCDFont.latin(size: 12, weight: .bold)
                              : LCDFont.gothic(size: 13, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 62, alignment: .trailing)
            if let station {
                if !station.stationCode.isEmpty {
                    outlinedBadge(station, dimension: 36, outline: .white, width: 1.4)
                }
                HStack(spacing: 5) {
                    HorizontallySquashed(maxWidth: 240, alignment: .leading) {
                        Text(language.name(station))
                            .font(language.isLatin ? LCDFont.latin(size: 29, weight: .bold)
                                          : LCDFont.gothic(size: 33, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(height: 38)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(headlineGradient)
    }

    private var headlineStation: Station? {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return nil }
        let index = state.currentStationIndex ?? state.segmentTo
        return stations[max(0, min(index, stations.count - 1))]
    }

    private func phaseLabel(_ phase: LCDPhase, language: TrainLCDLanguage) -> String {
        language.headline(phase) { japanese(phase: $0) }
    }

    private func japanese(phase: LCDPhase) -> String {
        switch phase {
        case .dwelling: return "ただいま"
        case .approaching: return "まもなく"
        case .next: return "つぎは"
        }
    }

    // MARK: - Board

    private func board(now: Date, language: TrainLCDLanguage) -> some View {
        let (columns, markerSlot) = stops(now: now)
        let colWidth = (Self.designWidth - 8) / CGFloat(max(columns.count, 1))

        return VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(columns) { col in
                    VerticalStationName(name: col.station.name, fontSize: 19, charBox: 19,
                                        availableHeight: Self.nameRowHeight,
                                        color: Self.boardInk,
                                        columnAnchor: .top, justifiedSingle: false, gothic: true)
                        .frame(width: colWidth, height: Self.nameRowHeight, alignment: .top)
                        .opacity(col.isPassed ? 0.35 : 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: rowAlignment)
            .padding(.bottom, 2)

            HStack(spacing: 0) {
                ForEach(columns) { col in
                    outlinedBadge(col.station, dimension: Self.badgeRowHeight,
                                  outline: .white, width: 1)
                        .frame(width: colWidth, height: Self.badgeRowHeight)
                        .opacity(col.isPassed ? 0.35 : 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: rowAlignment)
            .padding(.bottom, 1)

            band(columns: columns, colWidth: colWidth, markerSlot: markerSlot)
                .padding(.horizontal, -4)

            HStack(alignment: .top, spacing: 0) {
                ForEach(columns) { col in
                    transferList(col.transfers, language: language)
                        .frame(width: colWidth, alignment: .top)
                        .opacity(col.isPassed ? 0.35 : 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: rowAlignment)
            .padding(.top, 1.5)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 4)
        .padding(.top, Self.boardTopPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(boardGradient)
        .overlay(alignment: .bottom) { footer(language: language) }
    }

    /// Travel runs toward the leading edge, as the real board reads.
    private var rowAlignment: Alignment { orientation == .right ? .leading : .trailing }

    private func band(columns: [LCDStop], colWidth: CGFloat, markerSlot: Int?) -> some View {
        ZStack {
            SegmentedBand(
                segments: LCDBandSegments.of(columns.map(\.station), fallback: lineColor,
                                             columnWidth: colWidth,
                                             // The bar runs full-bleed past the board's inset.
                                             origin: 4,
                                             travelsForward: orientation == .right),
                fallback: lineColor
            ) { color in
                Rectangle()
                    .fill(bandGradient(color))
                    .frame(height: Self.bandHeight)
            }
            HStack(spacing: 0) {
                ForEach(Array(columns.enumerated()), id: \.element.id) { index, col in
                    stopBox(col, isMarker: index == markerSlot)
                        .frame(width: colWidth, height: Self.bandHeight)
                }
            }
            .frame(maxWidth: .infinity, alignment: rowAlignment)
            // The bar runs full-bleed; its boxes keep the board's own inset so
            // each one centres under its badge.
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.bandHeight)
    }

    @ViewBuilder
    private func stopBox(_ col: LCDStop, isMarker: Bool) -> some View {
        if col.isStop || isMarker {
            Rectangle()
                .fill(isMarker ? Self.markerRed : Color.white)
                .frame(width: Self.minuteBox.width, height: Self.minuteBox.height)
                // The red mark needs its own edge against the bar.
                .overlay {
                    if isMarker {
                        Rectangle().strokeBorder(Color.white, lineWidth: 1)
                    }
                }
                .overlay {
                    if let minutes = col.minutes, !isMarker {
                        Text(verbatim: "\(minutes)")
                            .font(LCDFont.latin(size: 8.5, weight: .bold))
                            .foregroundColor(Self.boardInk)
                    }
                }
        } else {
            Color.clear
        }
    }

    private func transferList(_ lines: [TrainLine], language: TrainLCDLanguage) -> some View {
        VStack(spacing: 0.5) {
            if !lines.isEmpty {
                Image(systemName: "tram.fill")
                    .font(.system(size: 6.5))
                    .foregroundColor(Self.boardInk)
                ForEach(lines) { line in
                    LCDTransferLineName(name: language.lineName(line), fontSize: 6.5,
                                        symbol: line.lineSymbol, badgeColor: line.color,
                                        badgeStyleId: line.badgeStyleId,
                                        badgeLineId: line.id, color: Self.boardInk)
                }
            }
        }
    }

    /// 「◯◯の次は◯◯にとまります。」— the strip along the foot of the board.
    @ViewBuilder
    private func footer(language: TrainLCDLanguage) -> some View {
        let stations = journey.journeyStations
        let index = (state.currentStationIndex ?? state.segmentTo)
        if stations.indices.contains(index), stations.indices.contains(index + 1) {
            let here = stations[index], next = stations[index + 1]
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(Self.markerRed)
                if language.isLatin {
                    Text(verbatim: "The stop after")
                        .font(LCDFont.latin(size: 8, weight: .medium))
                    footerStation(here, language: language)
                    Text(verbatim: "is")
                        .font(LCDFont.latin(size: 8, weight: .medium))
                    footerStation(next, language: language)
                } else {
                    footerStation(here, language: language)
                    Text(verbatim: language.nextStopConnector)
                        .font(LCDFont.gothic(size: 8))
                    footerStation(next, language: language)
                    Text(verbatim: language.nextStopSuffix)
                        .font(LCDFont.gothic(size: 8))
                }
            }
            .foregroundColor(Self.boardInk)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(height: Self.footerHeight)
            .background(Self.footerBackground)
        }
    }

    private func footerStation(_ station: Station, language: TrainLCDLanguage) -> some View {
        HStack(spacing: 1.5) {
            if !station.stationCode.isEmpty {
                scaledStationBadge(station, dimension: 10)
            }
            Text(language.name(station))
                .font(language.isLatin ? LCDFont.latin(size: 8.5, weight: .bold)
                              : LCDFont.gothic(size: 9, weight: .bold))
        }
    }

    // MARK: - Data

    private struct LCDStop: Identifiable {
        let id: String
        let station: Station
        let minutes: Int?
        /// Passed-through stations keep their name and badge but take no box.
        let isStop: Bool
        let isPassed: Bool
        let transfers: [TrainLine]
    }

    /// Every station ahead, stop or not, plus the slot the red mark sits in.
    private func stops(now: Date) -> ([LCDStop], Int?) {
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return ([], nil) }
        let entries = Dictionary(
            journey.journeyTimetable.map { ($0.stationId, $0) },
            uniquingKeysWith: { a, _ in a }
        )
        let dwellIndex = state.currentStationIndex.map { max(0, min($0, stations.count - 1)) }
        let ref = dwellIndex ?? max(0, min(state.segmentFrom, stations.count - 1))
        let nowSec = LCDPhase.railSeconds(at: now)
        let delaySec = state.delayMinutes * 60

        func column(_ station: Station, passed: Bool) -> LCDStop {
            let entry = entries[station.id]
            let arrival = entry?.arrivalSeconds() ?? entry?.departureSeconds()
            return LCDStop(
                id: station.id, station: station,
                minutes: passed ? nil : arrival.map { max(0, ($0 + delaySec - nowSec + 59) / 60) },
                isStop: entry != nil, isPassed: passed,
                transfers: transfers(at: station)
            )
        }

        let ahead = stations[ref...].prefix(Self.maxColumns).map { column($0, passed: false) }
        let deficit = Self.maxColumns - ahead.count
        let behind = deficit > 0
            ? stations[..<ref].suffix(deficit).map { column($0, passed: true) }
            : []

        // The board reads toward the destination: the run trails to the right.
        let all = Array((behind + ahead).reversed())
        let slot = ahead.count - 1
        if orientation == .right {
            return (all.reversed(), all.count - 1 - slot)
        }
        return (all, slot)
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

    private var typeName: String {
        journey.service.trainType == .local ? "普通" : journey.service.trainType.displayNameJa
    }

    private var typeNameEn: String { journey.service.trainType.displayNameEn }

    /// 特急-family plates are red on the real display; everything else is dark.
    private var typeColor: Color {
        switch journey.service.trainType {
        case .local: return Color(hex: "#2B2E33")
        case .limitedExpress, .commuterLimitedExpress, .rapidLimitedExpress:
            return Self.markerRed
        case .express, .sectionExpress, .rapidExpress, .commuterExpress:
            return Color(hex: "#E07800")
        case .rapid, .sectionRapid, .commuterRapid, .specialRapid:
            return Color(hex: "#0E7A46")
        default: return Color(hex: "#2B2E33")
        }
    }

    private var carNumber: Int { Int(journey.id.uuid.0 % 10) + 1 }

    private func stationColor(_ station: Station) -> Color {
        StaticTrainData.line(containingStationId: station.id)?.trainLine.color ?? lineColor
    }

    /// The badge plus a matching outline, so it separates from the ground.
    @ViewBuilder
    private func outlinedBadge(_ station: Station, dimension: CGFloat,
                               outline: Color, width: CGFloat) -> some View {
        let ratio = StationNumberBadge.cornerRadiusRatio(
            code: station.stationCode, color: stationColor(station),
            styleOverride: journey.line.badgeStyleId, lineId: journey.line.id
        )
        scaledStationBadge(station, dimension: dimension)
            .overlay(
                RoundedRectangle(cornerRadius: dimension * ratio + width)
                    .strokeBorder(outline, lineWidth: width)
                    .padding(-width)
            )
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

private extension Color {
    /// The line's hue, darkened until it reads at `luminance`. A fixed
    /// brightness is not enough — at 0.52 a blue line lands dark and an
    /// orange one lands muddy, because the eye weights the channels
    /// differently.
    func lcdChrome(luminance target: CGFloat, saturation satFactor: CGFloat = 1.15) -> Color {
        #if canImport(UIKit)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let sat = min(1, max(0, s * satFactor))
        var low: CGFloat = 0, high: CGFloat = 1
        for _ in 0..<14 {
            let mid = (low + high) / 2
            if UIColor(hue: h, saturation: sat, brightness: mid, alpha: 1)
                .relativeLuminance < target {
                low = mid
            } else {
                high = mid
            }
        }
        return Color(hue: h, saturation: sat, brightness: (low + high) / 2, opacity: a)
        #else
        return self
        #endif
    }
}

private extension UIColor {
    var relativeLuminance: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        func linear(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }
}
