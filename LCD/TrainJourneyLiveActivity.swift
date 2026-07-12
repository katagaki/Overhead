import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Live Activity Widget

struct TrainJourneyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainJourneyAttributes.self) { context in
            LockScreenLiveActivityView(attributes: context.attributes, state: context.state)
                .containerBackground(.clear, for: .widget)

        } dynamicIsland: { context in
            let attrs = context.attributes
            let state = context.state
            let nextIndex = state.nextStationIndex
            let leg = attrs.currentLeg(nextIndex: nextIndex)
            let legSymbol = leg?.lineSymbol ?? attrs.lineSymbol
            let legColor = Color(hex: leg?.lineColorHex ?? attrs.lineColorHex)

            return DynamicIsland {
                // The island's rounded corners clip anything hugging its
                // edges, so the badges keep clear of them.
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
                                          color: Color(hex: attrs.legLines.last?.lineColorHex ?? attrs.lineColorHex),
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

    /// Fixed so the station name stays optically centered between the columns.
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
                    LCDStationNumberBadge(code: nextStationCode, color: legColor, dimension: 22)
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

/// The next line to transfer to, or the station to get off at on a straight ride.
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
                    color: Color(hex: attributes.legLines.last?.lineColorHex ?? attributes.lineColorHex),
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

    /// The leg boundaries (transfer/change stations) along the journey.
    private var transferIndices: [Int] {
        attributes.legLines.dropFirst().map(\.stationIndex)
    }

    /// The transfer at the immediate next stop, if the next station is a
    /// change point — used to surface 乗換 info on the bottom-left.
    private var transferAtNextStop: TrainJourneyAttributes.LegLine? {
        guard let next = state.nextStationIndex else { return nil }
        return attributes.legLines.first { $0.stationIndex == next && $0.stationIndex > 0 }
    }

    /// Fixed so the station name stays optically centered between the columns.
    private static let topSideColumnWidth: CGFloat = 96

    /// Ink for the white band. The bands are opaque enough that the text
    /// cannot follow the system color scheme.
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
                    LCDStationNumberBadge(code: nextStationCode, color: legColor, dimension: 24)
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
                transferIndices: transferIndices
            )

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                // Bottom-left: a 乗換 cue when the next stop is a change point,
                // otherwise the pre-departure countdown (or nothing mid-ride).
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
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.orange)
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
    // When set, the progress fill is timer-driven so it keeps advancing while
    // the app is suspended (no GPS or background updates required).
    var journeyInterval: ClosedRange<Date>? = nil
    // Valid mid-segment, unlike the dwell-only currentStationIndex.
    var nextStationIndexOverride: Int? = nil
    // Flips the ink for the lock screen's white band.
    var onLightBackground: Bool = false
    // Transfer stations (leg boundaries): labeled above the line alongside
    // the terminals. All other stations render as unlabeled dots.
    var transferIndices: [Int] = []

    // Solid greys so dots don't double-darken where they overlap the track.
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

    /// Next station index: explicit when provided, else derived from current
    private var nextStationIndex: Int? {
        if let next = nextStationIndexOverride, next < stationCount { return next }
        guard let current = currentStationIndex, current + 1 < stationCount else { return nil }
        return current + 1
    }

    private func stopsAt(_ index: Int) -> Bool {
        guard !stationStops.isEmpty, index < stationStops.count else { return true }
        return stationStops[index]
    }

    /// Tall enough for the terminal/transfer labels above the track, the
    /// emphasized circles on it, and the next-station label below it.
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
            let centerY: CGFloat = 20 // room for labels above AND below

            ZStack(alignment: .topLeading) {
                // Background track — thin line centered through circles
                RoundedRectangle(cornerRadius: 1)
                    .fill(trackColor)
                    .frame(width: lineWidth, height: trackHeight)
                    .offset(x: padding, y: centerY - trackHeight / 2)

                // Timer-driven so it advances without app updates. The linear
                // style is a fixed 4pt capsule with its own unfilled track, so
                // clip it to the band or that track sits proud of this one.
                if let interval = journeyInterval {
                    ProgressView(timerInterval: interval, countsDown: false) {
                    } currentValueLabel: {
                    }
                    .progressViewStyle(.linear)
                    .tint(lineColor)
                    .frame(width: lineWidth, height: trackHeight)
                    .clipped()
                    .position(x: padding + lineWidth / 2, y: centerY)
                } else {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(lineColor)
                        .frame(width: max(0, lineWidth * progress), height: trackHeight)
                        .offset(x: padding, y: centerY - trackHeight / 2)
                }

                // Only key stations are drawn on the line: the start, each
                // transfer (change) point, and the end — labeled above the
                // track. The next stop is marked and labeled BELOW the track.
                // The current station is intentionally omitted; it is already
                // shown in the panel above.
                ForEach(0..<stationCount, id: \.self) { i in
                    let frac = stationCount > 1 ? Double(i) / Double(stationCount - 1) : 0
                    let x = padding + lineWidth * frac
                    let isPast = frac <= progress + 0.01
                    let isNext = nextStationIndex == i
                    let isTerminal = i == 0 || i == stationCount - 1
                    let isTransfer = transferIndices.contains(i)
                    let isKey = isNext || isTerminal || isTransfer
                    let r = emphasisRadius

                    if isKey {
                        // Station circle — centered on track
                        ZStack {
                            Circle()
                                .fill(terminalFill)
                                .frame(width: r * 2, height: r * 2)
                            Circle()
                                .strokeBorder(isPast ? lineColor : trackColor, lineWidth: 2)
                                .frame(width: r * 2, height: r * 2)

                            if isNext {
                                Circle()
                                    .fill(lineColor)
                                    .frame(width: r, height: r)
                                Circle()
                                    .strokeBorder(lineColor, lineWidth: 1.5)
                                    .frame(width: r * 2 + 4, height: r * 2 + 4)
                            }
                        }
                        .position(x: x, y: centerY)

                        // Terminal/transfer labels above the track (skipped
                        // when the station is the next stop — it is labeled
                        // below the track instead).
                        if (isTerminal || isTransfer) && !isNext {
                            Text(truncatedName(stationNames[i]))
                                .font(.system(size: 8, weight: isTransfer ? .bold : .regular))
                                .foregroundColor(isTransfer ? lineColor : labelColor)
                                .lineLimit(1)
                                .frame(width: 40)
                                .position(x: x, y: centerY - r - 9)
                        }

                        // Next station labeled below the track
                        if isNext {
                            Text(truncatedName(stationNames[i]))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(lineColor)
                                .lineLimit(1)
                                .frame(width: 44)
                                .position(x: x, y: centerY + r + 10)
                        }
                    }
                }

            }
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

    /// Next station index: from the content state when valid, else derived
    private var nextStationIndex: Int? {
        if let next = state.nextStationIndex,
           next < attributes.stationCount { return next }
        guard let current = state.currentStationIndex,
              current + 1 < attributes.stationCount else { return nil }
        return current + 1
    }

    /// Leg boundaries (transfer/change stations) along the journey.
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
                // Background track
                Capsule()
                    .fill(Color(white: 0.3))
                    .frame(width: w - pad * 2, height: trackHeight)
                    .offset(x: pad)

                // Clipped to the band so the linear style's own 4pt unfilled
                // track doesn't show around this one.
                ProgressView(timerInterval: state.journeyInterval, countsDown: false) {
                } currentValueLabel: {
                }
                .progressViewStyle(.linear)
                .tint(lineColor)
                .frame(width: w - pad * 2, height: trackHeight)
                .clipped()
                .position(x: pad + (w - pad * 2) / 2, y: 6)

                // Only the start, transfers (change points), end, and the next
                // stop are marked — the current station is omitted (it is shown
                // in the panel above).
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
