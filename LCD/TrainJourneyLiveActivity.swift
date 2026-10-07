import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Live Activity Widget

struct TrainJourneyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainJourneyAttributes.self) { context in
            LiveActivityContentView(attributes: context.attributes, state: context.state)
                .containerBackground(.clear, for: .widget)

        } dynamicIsland: { context in
            let attrs = context.attributes
            let state = context.state
            let nextIndex = state.nextStationIndex
            let leg = attrs.currentLeg(nextIndex: nextIndex)
            let legSymbol = leg?.lineSymbol ?? attrs.lineSymbol
            let legColor = Color(hex: leg?.lineColorHex ?? attrs.lineColorHex)

            return DynamicIsland {
                // Beside the camera, inset clear of the island's rounded corners.
                DynamicIslandExpandedRegion(.leading) {
                    IslandCornerTime(attributes: attrs, state: state, side: .leading)
                        .padding(.leading, 26)
                        .padding(.top, 12)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    IslandCornerTime(attributes: attrs, state: state, side: .trailing)
                        .padding(.trailing, 26)
                        .padding(.top, 12)
                }

                // Full width; .center would be squeezed between the corner times.
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedIslandView(attributes: attrs, state: state)
                }

            } compactLeading: {
                if !legSymbol.isEmpty {
                    LCDLineSymbolBadge(symbol: legSymbol, color: legColor)
                        .sized(23)
                        .padding(.leading, 1)
                } else {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(legColor)
                            .frame(width: 8, height: 8)
                        Text(state.nextStationName.prefix(3))
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                    }
                }

            } compactTrailing: {
                if state.isDelayed {
                    Text("+\(state.delayMinutes)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                } else if let transfer = attrs.upcomingTransfer(nextIndex: nextIndex),
                          !transfer.lineSymbol.isEmpty {
                    LCDLineSymbolBadge(symbol: transfer.lineSymbol,
                                       color: Color(hex: transfer.lineColorHex))
                        .sized(23)
                        .padding(.trailing, 1)
                } else if !attrs.destinationCode.isEmpty {
                    LCDStationNumberBadge(code: attrs.destinationCode,
                                          color: Color(hex: attrs.destinationColorHex),
                                          dimension: 23)
                        .padding(.trailing, 1)
                } else {
                    Text(attrs.destinationName.prefix(3))
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                }

            } minimal: {
                // Timer-driven ring keeps filling while the app is suspended.
                ProgressView(timerInterval: state.journeyInterval, countsDown: false) {
                } currentValueLabel: {
                    Circle()
                        .fill(legColor)
                        .frame(width: 6, height: 6)
                }
                .progressViewStyle(.circular)
                .tint(legColor)
            }
            // Insets above are measured from the island's edge.
            .contentMargins(.all, 0, for: .expanded)
        }
        // Lets the lock screen's two bands run to the container's edges.
        .contentMarginsDisabled()
        // Watch Smart Stack rendering (without this, watchOS shows a
        // bare system template).
        .supplementalActivityFamilies([.small])
    }
}

// MARK: - Family Switch

/// `.small` is the Watch Smart Stack; `.medium` the phone lock screen.
struct LiveActivityContentView: View {
    @Environment(\.activityFamily) private var family

    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState

    var body: some View {
        switch family {
        case .small:
            WatchLiveActivityView(attributes: attributes, state: state)
        default:
            LockScreenLiveActivityView(attributes: attributes, state: state)
        }
    }
}

// MARK: - Watch Smart Stack View

/// The phone lock screen's two-tone layout, condensed: black band with the
/// headline station, white band with the upcoming transfer and the ETA.
struct WatchLiveActivityView: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState

    private static let darkInk = Color.black.opacity(0.9)
    private static let darkInkSecondary = Color.black.opacity(0.65)

    /// Dwelling at a station; the headline shows it (ただいま) instead of
    /// the segment target (つぎは).
    private var dwellingIndex: Int? {
        guard let idx = state.currentStationIndex,
              attributes.stationNames.indices.contains(idx) else { return nil }
        return idx
    }

    private var headlineIndex: Int? { dwellingIndex ?? state.nextStationIndex }

    private var headlineName: String {
        dwellingIndex.map { attributes.stationNames[$0] } ?? state.nextStationName
    }

    private var headlineCode: String {
        guard let idx = headlineIndex,
              attributes.stationCodes.indices.contains(idx) else { return "" }
        return attributes.stationCodes[idx]
    }

    private var headlineColor: Color {
        Color(hex: attributes.stationColorHex(at: headlineIndex))
    }

    private var transfer: TrainJourneyAttributes.LegLine? {
        attributes.upcomingTransfer(nextIndex: state.nextStationIndex)
    }

    private var transferStationName: String {
        guard let transfer,
              attributes.stationNames.indices.contains(transfer.stationIndex) else { return "" }
        return attributes.stationNames[transfer.stationIndex]
    }

    /// Arrival at the next 乗換 when there is one, otherwise at the destination.
    private var displayedTime: Date {
        transfer.flatMap { attributes.stationTime(at: $0.stationIndex, delayMinutes: state.delayMinutes) }
            ?? state.estimatedArrival
    }

    var body: some View {
        VStack(spacing: 0) {
            topBand
            bottomBand
        }
    }

    private var topBand: some View {
        HStack(spacing: 6) {
            if !headlineCode.isEmpty {
                LCDStationNumberBadge(code: headlineCode, color: headlineColor, dimension: 26)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(dwellingIndex != nil ? "Label.NowAt" : "Label.Next")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.65))
                Text(headlineName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer(minLength: 0)
            if state.isDelayed {
                Text("LiveActivity.Delay.Minutes \(state.delayMinutes)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
            } else if let leg = attributes.currentLeg(nextIndex: state.nextStationIndex),
                      !leg.lineSymbol.isEmpty {
                LCDLineSymbolBadge(symbol: leg.lineSymbol,
                                   color: Color(hex: leg.lineColorHex))
                    .sized(20)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var bottomBand: some View {
        HStack(spacing: 4) {
            if let transfer, !transferStationName.isEmpty {
                Text("Label.Transfer")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.orange)
                if !transfer.lineSymbol.isEmpty {
                    LCDLineSymbolBadge(symbol: transfer.lineSymbol,
                                       color: Color(hex: transfer.lineColorHex))
                        .sized(14)
                }
                Text(transferStationName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Self.darkInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text(attributes.destinationName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Self.darkInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Label.GetOffAt")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Self.darkInkSecondary)
            }
            Spacer(minLength: 4)
            Text(displayedTime.lcdTime)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Self.darkInk)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}

// MARK: - Time Formatting

extension Date {
    private static let lcdFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f
    }()

    var lcdTime: String { Self.lcdFormatter.string(from: self) }
}

// MARK: - Island Corner Time

/// Beside the camera: when the rider next boards, changes or gets off on the
/// left, the final arrival on the right.
struct IslandCornerTime: View {
    enum Side { case leading, trailing }

    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState
    let side: Side

    private var content: (caption: LocalizedStringKey, time: Date) {
        guard side == .leading else { return ("Label.ArrivalTime", state.estimatedArrival) }
        if state.status == .notStarted {
            return ("Label.BoardingTime", state.departure)
        }
        if let transfer = attributes.upcomingTransfer(nextIndex: state.nextStationIndex),
           let time = attributes.stationTime(at: transfer.stationIndex, delayMinutes: state.delayMinutes) {
            return ("Label.NextTransfer", time)
        }
        return ("Label.GetOffTime", state.estimatedArrival)
    }

    var body: some View {
        let content = content
        VStack(alignment: side == .leading ? .leading : .trailing, spacing: 0) {
            Text(content.caption)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Color(white: 0.6))
            Text(content.time.lcdTime)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .lineLimit(1)
    }
}

// MARK: - Expanded Island View

struct ExpandedIslandView: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState

    private var nextIndex: Int {
        min(state.nextStationIndex ?? attributes.stationCount - 1, attributes.stationCount - 1)
    }

    private var nextStationCode: String {
        attributes.stationCodes.indices.contains(nextIndex) ? attributes.stationCodes[nextIndex] : ""
    }

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 0) {
                HStack(spacing: 5) {
                    Text("Label.Next")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                    if !nextStationCode.isEmpty {
                        LCDStationNumberBadge(code: nextStationCode,
                                              color: Color(hex: attributes.stationColorHex(at: nextIndex)),
                                              dimension: 22)
                    }
                    Text(state.nextStationName)
                        .font(.system(size: 21, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                Text(state.nextStationNameEn)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            IslandRouteLine(attributes: attributes, state: state)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 16)
    }
}

// MARK: - Lock Screen Live Activity View

struct LockScreenLiveActivityView: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState

    private var lineColor: Color { Color(hex: attributes.lineColorHex) }

    private var currentLeg: TrainJourneyAttributes.LegLine? {
        attributes.currentLeg(nextIndex: state.nextStationIndex)
    }

    private var legColor: Color {
        currentLeg.map { Color(hex: $0.lineColorHex) } ?? lineColor
    }

    private var nextStationCode: String {
        guard let idx = state.nextStationIndex,
              attributes.stationCodes.indices.contains(idx) else { return "" }
        return attributes.stationCodes[idx]
    }

    private var nextStationColor: Color {
        Color(hex: attributes.stationColorHex(at: state.nextStationIndex))
    }

    private var transferIndices: [Int] {
        attributes.legLines.dropFirst().map(\.stationIndex)
    }

    private var transferAtNextStop: TrainJourneyAttributes.LegLine? {
        guard let next = state.nextStationIndex else { return nil }
        return attributes.legLines.first { $0.stationIndex == next && $0.stationIndex > 0 }
    }

    private static let topSideColumnWidth: CGFloat = 96

    private static let darkInk = Color.black.opacity(0.9)
    private static let darkInkSecondary = Color.black.opacity(0.65)

    var body: some View {
        VStack(spacing: 0) {
            topPanel
            bottomPanel
        }
        .background(.clear)
    }

    // MARK: Top panel — terminal, big station name, mode

    private var topPanel: some View {
        ZStack {
            HStack(alignment: .center, spacing: 8) {
                Text("Destination.Suffix \(attributes.trainType) \(attributes.destinationName)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: Self.topSideColumnWidth, alignment: .leading)

                Spacer(minLength: 0)

                trackingModeBadge
                    .frame(width: Self.topSideColumnWidth, alignment: .trailing)
            }

            nextStationDisplay
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    private var nextStationDisplay: some View {
        VStack(spacing: 1) {
            HStack(spacing: 6) {
                if !nextStationCode.isEmpty {
                    LCDStationNumberBadge(code: nextStationCode, color: nextStationColor, dimension: 24)
                }
                Text(state.nextStationName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Text(state.nextStationNameEn)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, Self.topSideColumnWidth + 4)
    }

    // MARK: Bottom panel — the timeline, with the ETA on its trailing edge

    private var bottomPanel: some View {
        VStack(spacing: 2) {
            LCDLineView(
                stationNames: attributes.stationNames,
                stationCount: attributes.stationCount,
                progress: state.progress,
                currentStationIndex: state.currentStationIndex,
                lineColor: lineColor,
                stationStops: attributes.stationStops,
                journeyInterval: state.journeyInterval,
                nextStationIndexOverride: state.nextStationIndex,
                onLightBackground: true,
                transferIndices: transferIndices,
                stationColors: attributes.stationColors.map { Color(hex: $0) }
            )

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                if let transfer = transferAtNextStop {
                    transferCue(transfer)
                } else if state.status == .notStarted {
                    Text("LiveActivity.DepartsAt \(state.departure.lcdTime)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(Self.darkInk)
                }

                Spacer(minLength: 8)

                Text("Label.EstimatedArrival")
                    .font(.system(size: 9))
                    .foregroundColor(Self.darkInkSecondary)
                Text(state.estimatedArrival.lcdTime)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(Self.darkInk)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }

    // MARK: - Transfer Cue (bottom-left, next stop is a change)

    @ViewBuilder
    private func transferCue(_ transfer: TrainJourneyAttributes.LegLine) -> some View {
        HStack(spacing: 4) {
            Text("Label.NextTransfer")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.orange)
                .lineLimit(1)
            if !transfer.lineSymbol.isEmpty {
                LCDLineSymbolBadge(symbol: transfer.lineSymbol,
                                   color: Color(hex: transfer.lineColorHex))
                    .sized(16)
            }
            Text(transfer.lineName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: transfer.lineColorHex))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Tracking Mode Badge

    @ViewBuilder
    private var trackingModeBadge: some View {
        let mode = state.trackingModeRaw
        if mode == "Timetable" {
            HStack(spacing: 2) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 7))
                Text("Badge.Timetable")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
        } else if mode == "GPS" {
            HStack(spacing: 2) {
                Image(systemName: "location.fill")
                    .font(.system(size: 7))
                Text("Badge.GPS")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.15))
            .clipShape(Capsule())
        } else {
            HStack(spacing: 2) {
                Image(systemName: "location.fill")
                    .font(.system(size: 7))
                Text("Badge.GPSPlusTimetable")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

// MARK: - LCD Line View (Horizontal - for Lock Screen)

struct LCDLineView: View {
    let stationNames: [String]
    let stationCount: Int
    let progress: Double
    let currentStationIndex: Int?
    let lineColor: Color
    var stationStops: [Bool] = []
    var journeyInterval: ClosedRange<Date>? = nil
    var nextStationIndexOverride: Int? = nil
    var onLightBackground: Bool = false
    var transferIndices: [Int] = []
    /// Each station's own line colour; empty falls back to `lineColor`.
    var stationColors: [Color] = []

    /// The colour of the line the station belongs to — a 乗り換え or a 直通
    /// junction puts stations of more than one line on the same journey.
    private func color(at index: Int) -> Color {
        stationColors.indices.contains(index) ? stationColors[index] : lineColor
    }

    /// Last station on the outgoing line at each colour change — a 直通
    /// junction, or a 乗り換え where the rider swaps trains.
    private var junctionIndices: [Int] {
        guard stationColors.count == stationCount else { return [] }
        return (0..<max(stationCount - 1, 0)).filter { stationColors[$0] != stationColors[$0 + 1] }
    }

    /// Riders stay aboard through a 直通 junction; a 乗り換え they don't.
    private func isChangeStop(_ index: Int) -> Bool {
        transferIndices.contains(index) || transferIndices.contains(index + 1)
    }

    /// Runs of one line along the track, in points from the track's leading
    /// edge, changing colour at the junction stop itself.
    private func trackRuns(lineWidth: CGFloat) -> [(color: Color, start: CGFloat, end: CGFloat?)] {
        guard stationCount > 1, stationColors.count == stationCount else {
            return [(lineColor, 0, nil)]
        }
        func center(_ index: Int) -> CGFloat {
            lineWidth * CGFloat(index) / CGFloat(stationCount - 1)
        }
        var runs: [(color: Color, start: CGFloat, end: CGFloat?)] = []
        var runStart = 0
        for index in 1...stationCount where
            index == stationCount || stationColors[index] != stationColors[index - 1] {
            runs.append((stationColors[runStart],
                         runStart == 0 ? 0 : center(runStart - 1),
                         index == stationCount ? nil : center(index - 1)))
            runStart = index
        }
        return runs
    }

    private var trackColor: Color {
        onLightBackground ? Color(white: 0.65) : Color(white: 0.3)
    }
    private var futureDotColor: Color {
        onLightBackground ? Color(white: 0.6) : Color(white: 0.35)
    }
    private var terminalFill: Color { onLightBackground ? .white : .black }
    private var labelColor: Color {
        onLightBackground ? Color(white: 0.3) : Color.secondary
    }
    private func skippedDotColor(isPast: Bool) -> Color {
        if onLightBackground { return Color(white: isPast ? 0.55 : 0.75) }
        return Color(white: isPast ? 0.35 : 0.2)
    }

    private var nextStationIndex: Int? {
        if let next = nextStationIndexOverride, next < stationCount { return next }
        guard let current = currentStationIndex, current + 1 < stationCount else { return nil }
        return current + 1
    }

    private func stopsAt(_ index: Int) -> Bool {
        guard !stationStops.isEmpty, index < stationStops.count else { return true }
        return stationStops[index]
    }

    private static let height: CGFloat = 46

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let baseRadius: CGFloat = stationCount > 10 ? 4 : 5
            let skippedRadius: CGFloat = max(2, baseRadius - 1.5)
            let emphasisRadius: CGFloat = baseRadius + 2
            let padding: CGFloat = emphasisRadius + 3
            let lineWidth = w - padding * 2
            let trackHeight: CGFloat = 2
            let centerY: CGFloat = 20

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(trackColor)
                    .frame(width: lineWidth, height: trackHeight)
                    .offset(x: padding, y: centerY - trackHeight / 2)

                // One fill per line ridden, each masked to its stretch of the
                // track, so the ridden bar changes colour at the junction.
                ZStack(alignment: .leading) {
                    ForEach(Array(trackRuns(lineWidth: lineWidth).enumerated()), id: \.offset) { _, run in
                        Group {
                            if let interval = journeyInterval {
                                ProgressView(timerInterval: interval, countsDown: false) {
                                } currentValueLabel: {
                                }
                                .progressViewStyle(.linear)
                                .tint(run.color)
                                .frame(width: lineWidth, height: trackHeight)
                                .clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(run.color)
                                    .frame(width: max(0, lineWidth * progress), height: trackHeight)
                                    .frame(width: lineWidth, alignment: .leading)
                            }
                        }
                        .mask(alignment: .leading) {
                            HStack(spacing: 0) {
                                Color.clear.frame(width: max(0, run.start))
                                if let end = run.end {
                                    Color.black.frame(width: max(0, end - run.start))
                                    Color.clear.frame(maxWidth: .infinity)
                                } else {
                                    Color.black.frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                .frame(width: lineWidth, height: trackHeight)
                .offset(x: padding, y: centerY - trackHeight / 2)

                ForEach(0..<stationCount, id: \.self) { i in
                    let frac = stationCount > 1 ? Double(i) / Double(stationCount - 1) : 0
                    let x = padding + lineWidth * frac
                    let isPast = frac <= progress + 0.01
                    let isNext = nextStationIndex == i
                    let isTerminal = i == 0 || i == stationCount - 1
                    let isTransfer = transferIndices.contains(i)
                    let isKey = isNext || isTerminal || isTransfer
                    let r = emphasisRadius
                    // The stop the line changes at draws itself; a 直通 keeps
                    // one circle in both colours, a 乗り換え splits into two.
                    let isJunction = junctionIndices.contains(i) && !isNext
                    let nextColor = color(at: min(i + 1, stationCount - 1))

                    if isJunction, !isChangeStop(i) {
                        HStack(spacing: 0) {
                            color(at: i)
                            nextColor
                        }
                        .frame(width: baseRadius * 2, height: baseRadius * 2)
                        .clipShape(Circle())
                        .position(x: x, y: centerY)
                    }

                    if isJunction, isChangeStop(i) {
                        // Pulled apart, with the track punched out between
                        // them: the rider steps off one line and onto the
                        // other. The hole shows the band, whatever it is.
                        // Punched to the rings' own shape, so the track still
                        // runs up to each of them.
                        ForEach([-1.0, 1.0], id: \.self) { side in
                            Circle()
                                .fill(Color.black)
                                .blendMode(.destinationOut)
                                .frame(width: baseRadius * 2, height: baseRadius * 2)
                                .position(x: x + side * (baseRadius + 2), y: centerY)
                        }
                        Rectangle()
                            .fill(Color.black)
                            .blendMode(.destinationOut)
                            .frame(width: 6, height: trackHeight + 1)
                            .position(x: x, y: centerY)
                        Circle()
                            .strokeBorder(color(at: i), lineWidth: 2)
                            .frame(width: baseRadius * 2, height: baseRadius * 2)
                            .position(x: x - baseRadius - 2, y: centerY)
                        Circle()
                            .strokeBorder(nextColor, lineWidth: 2)
                            .frame(width: baseRadius * 2, height: baseRadius * 2)
                            .position(x: x + baseRadius + 2, y: centerY)
                    }

                    if !isKey, !isJunction {
                        let stops = stopsAt(i)
                        let dotR = stops ? baseRadius : skippedRadius
                        Circle()
                            .fill(stops
                                  ? (isPast ? color(at: i) : futureDotColor)
                                  : skippedDotColor(isPast: isPast))
                            .frame(width: dotR * 2, height: dotR * 2)
                            .position(x: x, y: centerY)
                    }

                    if isKey {
                        ZStack {
                            if !isJunction {
                                Circle()
                                    .fill(terminalFill)
                                    .frame(width: r * 2, height: r * 2)
                                Circle()
                                    .strokeBorder(isPast ? color(at: i) : trackColor, lineWidth: 2)
                                    .frame(width: r * 2, height: r * 2)
                            }

                            if isNext {
                                Circle()
                                    .fill(color(at: i))
                                    .frame(width: r, height: r)
                                Circle()
                                    .strokeBorder(color(at: i), lineWidth: 1.5)
                                    .frame(width: r * 2 + 4, height: r * 2 + 4)
                            }
                        }
                        .position(x: x, y: centerY)

                        if (isTerminal || isTransfer) && !isNext {
                            Text(truncatedName(stationNames[i]))
                                .font(.system(size: 8, weight: isTransfer ? .bold : .regular))
                                .foregroundColor(isTransfer ? color(at: i) : labelColor)
                                .lineLimit(1)
                                .frame(width: 40)
                                .position(x: x, y: centerY - r - 9)
                        }

                        if isNext {
                            Text(truncatedName(stationNames[i]))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(color(at: i))
                                .lineLimit(1)
                                .frame(width: 44)
                                .position(x: x, y: centerY + r + 10)
                        }
                    }
                }

            }
            .compositingGroup()
            .frame(height: Self.height)
        }
        .frame(height: Self.height)
    }

    private func truncatedName(_ name: String) -> String {
        if name.count > 3 { return String(name.prefix(3)) }
        return name
    }
}

// MARK: - Island Route Line

/// The current leg across most of the width with the next leg squeezed after
/// it; finished legs drop off the left.
struct IslandRouteLine: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState

    private let pad: CGFloat = 12
    private let trackY: CGFloat = 8
    private let trackHeight: CGFloat = 3
    /// Width the current leg keeps while a 乗換 is ahead.
    private let legShare: CGFloat = 0.64

    private var count: Int { attributes.stationCount }
    private var transfers: [Int] { attributes.legLines.dropFirst().map(\.stationIndex) }
    private var next: Int { min(state.nextStationIndex ?? count - 1, count - 1) }
    /// Where this leg was boarded.
    private var start: Int { transfers.last { $0 < next } ?? 0 }
    /// The 乗換 ending this leg.
    private var transfer: Int? { attributes.upcomingTransfer(nextIndex: state.nextStationIndex)?.stationIndex }
    /// The next leg's far end, or the destination.
    private var end: Int { transfer.flatMap { t in transfers.first { $0 > t } } ?? count - 1 }

    /// Last stop the train has left or is standing at.
    private var from: Int {
        if let current = state.currentStationIndex { return current }
        let stops = attributes.stationStops
        return (start..<next).last { stops.indices.contains($0) ? stops[$0] : true } ?? max(next - 1, 0)
    }

    private func color(_ i: Int) -> Color {
        attributes.stationColors.indices.contains(i)
            ? Color(hex: attributes.stationColors[i]) : Color(hex: attributes.lineColorHex)
    }

    private func x(_ i: Int, in w: CGFloat) -> CGFloat {
        let tw = w - pad * 2
        guard let t = transfer else {
            return pad + tw * CGFloat(i - start) / CGFloat(max(end - start, 1))
        }
        let legEnd = pad + tw * legShare
        if i <= t {
            return pad + (legEnd - pad) * CGFloat(i - start) / CGFloat(max(t - start, 1))
        }
        return legEnd + (w - pad - legEnd) * CGFloat(i - t) / CGFloat(max(end - t, 1))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topLeading) {
                track(in: w)
                ForEach(start...end, id: \.self) { i in
                    dot(i).position(x: x(i, in: w), y: trackY)
                }
                IslandLabelRow {
                    IslandLegInfo(attributes: attributes, state: state)
                        .fixedSize()
                        .layoutValue(key: IslandLabelAnchor.self, value: .init(x: pad - 6, align: .leading))
                    if let transfer {
                        IslandNextLegLabel(attributes: attributes, transferIndex: transfer)
                            .fixedSize()
                            .layoutValue(key: IslandLabelAnchor.self,
                                         value: .init(x: (x(transfer, in: w) + x(end, in: w)) / 2, align: .center))
                    } else {
                        IslandDestinationLabel(attributes: attributes)
                            .fixedSize()
                            .layoutValue(key: IslandLabelAnchor.self, value: .init(x: w, align: .trailing))
                    }
                }
                .frame(width: w)
                .offset(y: trackY + 10)
            }
        }
        .frame(height: 52)
    }

    // MARK: Track

    @ViewBuilder
    private func track(in w: CGFloat) -> some View {
        // A 乗換's two rings sit in a gap in the track.
        let gap: (Int) -> CGFloat = { transfers.contains($0) ? 10 : 0 }
        ForEach(start..<end, id: \.self) { i in
            let left = x(i, in: w) + gap(i)
            let right = x(i + 1, in: w) - (transfers.contains(i + 1) ? 5 : 0)
            Rectangle()
                .fill(color(i + 1).opacity(i < from ? 1 : 0.3))
                .frame(width: max(0, right - left), height: trackHeight)
                .offset(x: left, y: trackY - trackHeight / 2)
        }
        // The current hop fills by itself while the app is suspended.
        if from < next, state.status != .notStarted {
            let left = x(from, in: w) + gap(from)
            let width = max(0, x(next, in: w) - left)
            ProgressView(timerInterval: state.segmentInterval, countsDown: false) {
            } currentValueLabel: {
            }
            .progressViewStyle(.linear)
            .tint(color(next))
            .frame(width: width, height: trackHeight)
            .clipped()
            .position(x: left + width / 2, y: trackY)
        }
    }

    // MARK: Stops

    @ViewBuilder
    private func dot(_ i: Int) -> some View {
        let isPassed = i <= from && state.status != .notStarted
        let isStop = attributes.stationStops.indices.contains(i) ? attributes.stationStops[i] : true
        if transfers.contains(i) {
            HStack(spacing: 1) {
                ring(color(i))
                ring(color(min(i + 1, count - 1)))
            }
        } else if i == next {
            Circle()
                .fill(Color.white)
                .overlay(Circle().strokeBorder(color(i), lineWidth: 3))
                .frame(width: 13, height: 13)
        } else if i == start || i == count - 1 {
            ring(isPassed ? color(i) : Color(white: 0.55))
        } else if i + 1 < count, color(i) != color(i + 1) {
            // 直通 junction: one stop shared by both lines.
            HStack(spacing: 0) {
                color(i)
                color(i + 1)
            }
            .frame(width: 6, height: 6)
            .clipShape(Circle())
        } else {
            let size: CGFloat = isStop ? 6 : 4
            Circle()
                .fill(isPassed ? color(i) : Color(white: isStop ? 0.45 : 0.3))
                .frame(width: size, height: size)
        }
    }

    private func ring(_ color: Color) -> some View {
        Circle()
            .strokeBorder(color, lineWidth: 2)
            .background(Circle().fill(Color.black))
            .frame(width: 11, height: 11)
    }
}

// MARK: - Island Route Labels

/// The leg being ridden: its line and where the train is bound.
struct IslandLegInfo: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState

    var body: some View {
        let leg = attributes.currentLeg(nextIndex: state.nextStationIndex)
        let color = Color(hex: leg?.lineColorHex ?? attributes.lineColorHex)
        HStack(spacing: 6) {
            if let symbol = leg?.lineSymbol, !symbol.isEmpty {
                LCDLineSymbolBadge(symbol: symbol, color: color).sized(26)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(leg?.lineName ?? attributes.lineName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                Text("Destination.Suffix \(attributes.trainType) \(attributes.destinationName)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// 乗換 onto the next leg: which line, and where.
struct IslandNextLegLabel: View {
    let attributes: TrainJourneyAttributes
    let transferIndex: Int

    var body: some View {
        let leg = attributes.legLines.first { $0.stationIndex == transferIndex }
        let color = Color(hex: leg?.lineColorHex ?? attributes.lineColorHex)
        HStack(spacing: 6) {
            Text("Label.Transfer")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.6))
            if let symbol = leg?.lineSymbol, !symbol.isEmpty {
                LCDLineSymbolBadge(symbol: symbol, color: color).sized(26)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(leg?.lineName ?? "")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                Text(attributes.stationNames.indices.contains(transferIndex)
                     ? attributes.stationNames[transferIndex] : "")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

/// 下車 at the destination, on the last leg.
struct IslandDestinationLabel: View {
    let attributes: TrainJourneyAttributes

    var body: some View {
        HStack(spacing: 6) {
            Text("Label.GetOffAt")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.6))
            if !attributes.destinationCode.isEmpty {
                LCDStationNumberBadge(code: attributes.destinationCode,
                                      color: Color(hex: attributes.destinationColorHex),
                                      dimension: 26)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(attributes.destinationName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Text(attributes.destinationNameEn)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct IslandLabelAnchor: LayoutValueKey {
    enum Align { case leading, center, trailing }
    let x: CGFloat
    let align: Align
    static let defaultValue = IslandLabelAnchor(x: 0, align: .center)
}

/// Labels sit at their anchor, then shuffle apart rather than overlap.
struct IslandLabelRow: Layout {
    var gap: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? 0,
               height: subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var minX: [CGFloat] = subviews.indices.map { i in
            let anchor = subviews[i][IslandLabelAnchor.self]
            let w = sizes[i].width
            let raw: CGFloat = switch anchor.align {
            case .leading: anchor.x
            case .center: anchor.x - w / 2
            case .trailing: anchor.x - w
            }
            return min(max(raw, 0), bounds.width - w)
        }
        for i in stride(from: minX.count - 2, through: 0, by: -1) {
            minX[i] = min(minX[i], minX[i + 1] - gap - sizes[i].width)
        }
        for i in minX.indices.dropFirst() {
            minX[i] = max(minX[i], minX[i - 1] + sizes[i - 1].width + gap)
        }
        for i in subviews.indices {
            subviews[i].place(at: CGPoint(x: bounds.minX + minX[i], y: bounds.minY), proposal: .unspecified)
        }
    }
}
