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
                // Keep badges clear of the island's clipping rounded corners.
                DynamicIslandExpandedRegion(.leading) {
                    if !legSymbol.isEmpty {
                        LCDLineSymbolBadge(symbol: legSymbol, color: legColor)
                            .sized(22)
                            .padding(.leading, 8)
                            .padding(.top, 6)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    IslandRideAheadBadge(attributes: attrs, state: state)
                        .padding(.trailing, 8)
                        .padding(.top, 6)
                }

                DynamicIslandExpandedRegion(.center) {
                    ExpandedIslandLineView(attributes: attrs, state: state)
                        .padding(.horizontal, 4)
                        .padding(.top, 10)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedIslandBottomView(attributes: attrs, state: state)
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
            Text(ExpandedIslandBottomView.formatTime(state.estimatedArrival))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Self.darkInk)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}

// MARK: - Expanded Island Bottom View

struct ExpandedIslandBottomView: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState

    private var leg: TrainJourneyAttributes.LegLine? {
        attributes.currentLeg(nextIndex: state.nextStationIndex)
    }

    private var legColor: Color {
        Color(hex: leg?.lineColorHex ?? attributes.lineColorHex)
    }

    private var nextStationCode: String {
        guard let idx = state.nextStationIndex,
              attributes.stationCodes.indices.contains(idx) else { return "" }
        return attributes.stationCodes[idx]
    }

    private var nextStationColor: Color {
        Color(hex: attributes.stationColorHex(at: state.nextStationIndex))
    }

    private static let sideColumnWidth: CGFloat = 92

    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(leg?.lineName ?? attributes.lineName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(legColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Destination.Suffix \(attributes.trainType) \(attributes.destinationName)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    trackingModeBadge
                }
                .frame(width: Self.sideColumnWidth, alignment: .leading)

                Spacer(minLength: 0)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Label.EstimatedArrival")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Text(Self.formatTime(state.estimatedArrival))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .frame(width: Self.sideColumnWidth, alignment: .trailing)
            }

            nextStationDisplay
        }
        .padding(.horizontal, 8)
        .padding(.top, 2)
    }

    private var nextStationDisplay: some View {
        VStack(spacing: 1) {
            HStack(spacing: 5) {
                if !nextStationCode.isEmpty {
                    LCDStationNumberBadge(code: nextStationCode, color: nextStationColor, dimension: 22)
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
        .padding(.horizontal, Self.sideColumnWidth + 2)
    }

    // MARK: - Tracking Mode Badge

    @ViewBuilder
    private var trackingModeBadge: some View {
        let mode = state.trackingModeRaw
        if mode == "Timetable" {
            islandModeBadge("clock.fill", "Badge.Timetable", .orange)
        } else if mode == "GPS" {
            islandModeBadge("location.fill", "Badge.GPS", .green)
        } else {
            islandModeBadge("location.fill", "Badge.GPSPlusTimetable", .blue)
        }
    }

    private func islandModeBadge(_ icon: String, _ key: LocalizedStringKey,
                                 _ color: Color) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 7))
            Text(key)
                .font(.system(size: 8, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundColor(color)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    static func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f.string(from: date)
    }
}

// MARK: - Island Ride-Ahead Badge

struct IslandRideAheadBadge: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState

    var body: some View {
        let nextIndex = state.nextStationIndex

        if let transfer = attributes.upcomingTransfer(nextIndex: nextIndex),
           !transfer.lineSymbol.isEmpty {
            VStack(spacing: 2) {
                LCDLineSymbolBadge(symbol: transfer.lineSymbol,
                                   color: Color(hex: transfer.lineColorHex))
                    .sized(22)
                Text("Label.Transfer")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        } else if !attributes.destinationCode.isEmpty {
            VStack(spacing: 2) {
                LCDStationNumberBadge(
                    code: attributes.destinationCode,
                    color: Color(hex: attributes.destinationColorHex),
                    dimension: 22
                )
                Text("Label.GetOffAt")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        } else {
            VStack(spacing: 2) {
                Text(attributes.destinationName)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Label.GetOffAt")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
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
                    Text("LiveActivity.DepartsAt \(ExpandedIslandBottomView.formatTime(state.departure))")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(Self.darkInk)
                }

                Spacer(minLength: 8)

                Text("Label.EstimatedArrival")
                    .font(.system(size: 9))
                    .foregroundColor(Self.darkInkSecondary)
                Text(ExpandedIslandBottomView.formatTime(state.estimatedArrival))
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
                        .frame(width: (r + 2) * 2, height: (r + 2) * 2)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(terminalFill, lineWidth: 1.5))
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

// MARK: - Expanded Island Line View

struct ExpandedIslandLineView: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState

    private var lineColor: Color { Color(hex: attributes.lineColorHex) }

    private var nextStationIndex: Int? {
        if let next = state.nextStationIndex,
           next < attributes.stationCount { return next }
        guard let current = state.currentStationIndex,
              current + 1 < attributes.stationCount else { return nil }
        return current + 1
    }

    private var transferIndices: [Int] {
        attributes.legLines.dropFirst().map(\.stationIndex)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let count = attributes.stationCount
            let emphR: CGFloat = 5
            let pad: CGFloat = emphR + 2
            let trackHeight: CGFloat = 1.5

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(white: 0.3))
                    .frame(width: w - pad * 2, height: trackHeight)
                    .offset(x: pad)

                ProgressView(timerInterval: state.journeyInterval, countsDown: false) {
                } currentValueLabel: {
                }
                .progressViewStyle(.linear)
                .tint(lineColor)
                .frame(width: w - pad * 2, height: trackHeight)
                .clipped()
                .position(x: pad + (w - pad * 2) / 2, y: 6)

                ForEach(0..<count, id: \.self) { i in
                    let frac = count > 1 ? Double(i) / Double(count - 1) : 0
                    let x = pad + (w - pad * 2) * frac
                    let isPast = frac <= state.progress + 0.01
                    let isNext = nextStationIndex == i
                    let isTerminal = i == 0 || i == count - 1
                    let isTransfer = transferIndices.contains(i)
                    let r = emphR

                    if isNext || isTerminal || isTransfer {
                        ZStack {
                            Circle()
                                .fill(isPast ? lineColor : Color(white: 0.4))
                                .frame(width: r * 2, height: r * 2)

                            if isTerminal || isTransfer {
                                Circle()
                                    .strokeBorder(isPast ? lineColor : Color(white: 0.4), lineWidth: 1.5)
                                    .frame(width: r * 2 + 3, height: r * 2 + 3)
                            }

                            if isNext {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: r, height: r)
                                Circle()
                                    .strokeBorder(lineColor, lineWidth: 1)
                                    .frame(width: r * 2 + 3, height: r * 2 + 3)
                            }
                        }
                        .position(x: x, y: 6)
                    }
                }
            }
            .frame(height: 12)
        }
        .frame(height: 12)
    }
}
