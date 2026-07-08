import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Live Activity Widget

struct TrainJourneyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrainJourneyAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .containerBackground(.clear, for: .widget)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    EmptyView()
                }

                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }

                DynamicIslandExpandedRegion(.center) {
                    ExpandedIslandLineView(context: context)
                        .padding(.horizontal, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                if !context.attributes.lineSymbol.isEmpty {
                                    LCDLineSymbolBadge(
                                        symbol: context.attributes.lineSymbol,
                                        color: Color(hex: context.attributes.lineColorHex)
                                    )
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(context.attributes.lineName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(hex: context.attributes.lineColorHex))
                                    HStack(spacing: 4) {
                                        Text(context.attributes.trainType)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                        if context.state.isTimetableMode {
                                            Text("Badge.Timetable")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.orange.opacity(0.2))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 1) {
                                if context.state.isDelayed {
                                    Text("LiveActivity.Delay.Minutes \(context.state.delayMinutes)")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.red)
                                } else {
                                    Text("Status.OnTime")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                HStack(spacing: 3) {
                                    Text(formatTime(context.state.estimatedArrival))
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundColor(.secondary)
                                    if context.state.status != .arrived && context.state.status != .notStarted {
                                        Text(timerInterval: context.state.journeyInterval, countsDown: true)
                                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                                            .monospacedDigit()
                                            .multilineTextAlignment(.trailing)
                                            .frame(maxWidth: 48)
                                    }
                                }
                            }
                        }

                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text("LiveActivity.NextIs \(context.state.nextStationName)")
                                    .font(.system(size: 13, weight: .semibold))
                            }

                            Spacer()

                            Link(destination: URL(string: context.attributes.refreshURLString)!) {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text(refreshAgeText(context.state.lastRefresh))
                                        .font(.system(size: 9))
                                }
                                .foregroundColor(Color(hex: context.attributes.lineColorHex))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: context.attributes.lineColorHex).opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }

            } compactLeading: {
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color(hex: context.attributes.lineColorHex))
                        .frame(width: 8, height: 8)
                    Text(context.state.nextStationName.prefix(3))
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                }

            } compactTrailing: {
                if context.state.isDelayed {
                    Text("+\(context.state.delayMinutes)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                } else {
                    Text(formatTime(context.state.estimatedArrival))
                        .font(.system(size: 12, design: .rounded))
                }

            } minimal: {
                // Timer-driven ring keeps filling while the app is suspended.
                ProgressView(timerInterval: context.state.journeyInterval, countsDown: false) {
                } currentValueLabel: {
                    Circle()
                        .fill(Color(hex: context.attributes.lineColorHex))
                        .frame(width: 6, height: 6)
                }
                .progressViewStyle(.circular)
                .tint(Color(hex: context.attributes.lineColorHex))
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f.string(from: date)
    }

    private func refreshAgeText(_ lastRefresh: Date) -> String {
        let seconds = Int(-lastRefresh.timeIntervalSinceNow)
        if seconds < 30 { return String(localized: "Time.Now") }
        let minutes = seconds / 60
        if minutes < 1 { return String(localized: "Time.LessThanOneMinuteAgo") }
        return String(localized: "Time.MinutesAgo \(minutes)")
    }
}

// MARK: - Lock Screen Live Activity View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TrainJourneyAttributes>

    private var lineColor: Color { Color(hex: context.attributes.lineColorHex) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    if !context.attributes.lineSymbol.isEmpty {
                        LCDLineSymbolBadge(
                            symbol: context.attributes.lineSymbol,
                            color: lineColor
                        )
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Text(context.attributes.lineName)
                                .font(.system(size: 14, weight: .bold))
                            trackingModeBadge
                        }
                        Text("Destination.Suffix \(context.attributes.trainType) \(context.attributes.destinationName)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if context.state.isDelayed {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("LiveActivity.Delay.Badge \(context.state.delayMinutes)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.9))
                    .clipShape(Capsule())
                } else {
                    Text("Status.OnTimeOperation")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            LCDLineView(
                stationNames: context.attributes.stationNames,
                stationCount: context.attributes.stationCount,
                progress: context.state.progress,
                currentStationIndex: context.state.currentStationIndex,
                lineColor: lineColor,
                stationStops: context.attributes.stationStops,
                journeyInterval: context.state.journeyInterval
            )
            .padding(.horizontal, 16)

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Label.NextStation")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(context.state.nextStationName)
                        .font(.system(size: 16, weight: .bold))
                    Text(context.state.nextStationNameEn)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Label.EstimatedArrival")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(formatTime(context.state.estimatedArrival))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(context.state.isDelayed ? .red : .primary)

                        // Self-updating even while the app is suspended
                        if context.state.status == .notStarted {
                            Text("LiveActivity.DepartsAt \(formatTime(context.state.departure))")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.orange)
                        } else if context.state.status != .arrived {
                            HStack(spacing: 3) {
                                Text("Label.TimeRemaining")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                Text(timerInterval: context.state.journeyInterval, countsDown: true)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .monospacedDigit()
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 56)
                            }
                        }
                    }

                    Link(destination: URL(string: context.attributes.refreshURLString)!) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9, weight: .semibold))
                            Text("Button.RefreshDelayInfo")
                                .font(.system(size: 9, weight: .medium))
                            Text("(\(refreshAgeText(context.state.lastRefresh)))")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(lineColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(lineColor.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(.clear)
    }

    // MARK: - Tracking Mode Badge

    @ViewBuilder
    private var trackingModeBadge: some View {
        let mode = context.state.trackingModeRaw
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

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f.string(from: date)
    }

    private func refreshAgeText(_ lastRefresh: Date) -> String {
        let seconds = Int(-lastRefresh.timeIntervalSinceNow)
        if seconds < 30 { return String(localized: "Time.Now") }
        let minutes = seconds / 60
        if minutes < 1 { return String(localized: "Time.LessThanOneMinuteAgo") }
        return String(localized: "Time.MinutesAgo \(minutes)")
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

    /// Next station index derived from current
    private var nextStationIndex: Int? {
        guard let current = currentStationIndex, current + 1 < stationCount else { return nil }
        return current + 1
    }

    private func stopsAt(_ index: Int) -> Bool {
        guard !stationStops.isEmpty, index < stationStops.count else { return true }
        return stationStops[index]
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h: CGFloat = 44
            let baseRadius: CGFloat = stationCount > 10 ? 4 : 5
            let skippedRadius: CGFloat = max(2, baseRadius - 1.5)
            let emphasisRadius: CGFloat = baseRadius + 2
            let padding: CGFloat = emphasisRadius + 3
            let lineWidth = w - padding * 2
            let trackHeight: CGFloat = 2
            let centerY: CGFloat = h / 2 + 4 // offset down to leave room for labels above

            ZStack(alignment: .topLeading) {
                // Background track — thin line centered through circles
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(white: 0.3))
                    .frame(width: lineWidth, height: trackHeight)
                    .offset(x: padding, y: centerY - trackHeight / 2)

                // Filled progress track — timer-driven when an interval is
                // available so it advances even without app updates.
                if let interval = journeyInterval {
                    ProgressView(timerInterval: interval, countsDown: false) {
                    } currentValueLabel: {
                    }
                    .progressViewStyle(.linear)
                    .tint(lineColor)
                    .frame(width: lineWidth)
                    .offset(x: padding, y: centerY - 2)
                } else {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(lineColor)
                        .frame(width: max(0, lineWidth * progress), height: trackHeight)
                        .offset(x: padding, y: centerY - trackHeight / 2)
                }

                // Station circles + labels (positioned independently so circles stay centered on track)
                ForEach(0..<stationCount, id: \.self) { i in
                    let frac = stationCount > 1 ? Double(i) / Double(stationCount - 1) : 0
                    let x = padding + lineWidth * frac
                    let isPast = frac <= progress + 0.01
                    let isCurrent = currentStationIndex == i
                    let isNext = nextStationIndex == i
                    let isTerminal = i == 0 || i == stationCount - 1
                    let stops = stopsAt(i)
                    let isEmphasized = isCurrent || isNext || isTerminal
                    let r = isEmphasized ? emphasisRadius : (stops ? baseRadius : skippedRadius)

                    Group {
                        // Station circle — centered on track
                        ZStack {
                            if isTerminal {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: r * 2, height: r * 2)
                                Circle()
                                    .strokeBorder(isPast ? lineColor : Color(white: 0.4), lineWidth: 2)
                                    .frame(width: r * 2, height: r * 2)
                            } else if !stops {
                                // Skipped station: small solid dot
                                Circle()
                                    .fill(isPast ? Color(white: 0.35) : Color(white: 0.2))
                                    .frame(width: r * 2, height: r * 2)
                            } else {
                                Circle()
                                    .fill(isPast ? lineColor : Color(white: 0.35))
                                    .frame(width: r * 2, height: r * 2)
                            }

                            if isCurrent {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: r, height: r)
                                Circle()
                                    .strokeBorder(lineColor, lineWidth: 1.5)
                                    .frame(width: r * 2 + 6, height: r * 2 + 6)
                            }

                            if isNext && !isCurrent {
                                Circle()
                                    .strokeBorder(lineColor, lineWidth: 1.5)
                                    .frame(width: r * 2 + 4, height: r * 2 + 4)
                            }
                        }
                        .position(x: x, y: centerY)

                        // Station label — positioned above the circle (only for stopping stations)
                        if stops, shouldShowLabel(index: i, isCurrent: isCurrent, isNext: isNext) {
                            Text(truncatedName(stationNames[i]))
                                .font(.system(size: isCurrent || isNext ? 9 : 8,
                                              weight: isCurrent || isNext ? .bold : .regular))
                                .foregroundColor(isCurrent ? lineColor : isNext ? lineColor : .secondary)
                                .lineLimit(1)
                                .frame(width: 40)
                                .position(x: x, y: centerY - r - 9)
                        }
                    }
                }

                // Train indicator
                let trainX = padding + lineWidth * progress
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 7))
                    .foregroundColor(lineColor)
                    .position(x: trainX, y: centerY + emphasisRadius + 8)
            }
            .frame(height: h)
        }
        .frame(height: 44)
    }

    private func shouldShowLabel(index: Int, isCurrent: Bool, isNext: Bool) -> Bool {
        if index == 0 || index == stationCount - 1 { return true }
        if isCurrent || isNext { return true }
        if stationCount <= 6 { return true }
        let step = max(2, stationCount / 5)
        return index % step == 0
    }

    private func truncatedName(_ name: String) -> String {
        if name.count > 3 { return String(name.prefix(3)) }
        return name
    }
}

// MARK: - Expanded Island Line View

struct ExpandedIslandLineView: View {
    let context: ActivityViewContext<TrainJourneyAttributes>

    private var lineColor: Color { Color(hex: context.attributes.lineColorHex) }

    /// Next station index derived from current
    private var nextStationIndex: Int? {
        guard let current = context.state.currentStationIndex,
              current + 1 < context.attributes.stationCount else { return nil }
        return current + 1
    }

    private func stopsAt(_ index: Int) -> Bool {
        let stops = context.attributes.stationStops
        guard !stops.isEmpty, index < stops.count else { return true }
        return stops[index]
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let count = context.attributes.stationCount
            let baseR: CGFloat = count > 8 ? 2.5 : 3.5
            let skippedR: CGFloat = max(1.5, baseR - 1)
            let emphR: CGFloat = baseR + 1.5
            let pad: CGFloat = emphR + 2
            let trackHeight: CGFloat = 1.5

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color(white: 0.3))
                    .frame(width: w - pad * 2, height: trackHeight)
                    .offset(x: pad)

                // Filled track — timer-driven so it advances while the app is suspended
                ProgressView(timerInterval: context.state.journeyInterval, countsDown: false) {
                } currentValueLabel: {
                }
                .progressViewStyle(.linear)
                .tint(lineColor)
                .frame(width: w - pad * 2)
                .offset(x: pad)

                // Station dots
                ForEach(0..<count, id: \.self) { i in
                    let frac = count > 1 ? Double(i) / Double(count - 1) : 0
                    let x = pad + (w - pad * 2) * frac
                    let isPast = frac <= context.state.progress + 0.01
                    let isCurrent = context.state.currentStationIndex == i
                    let isNext = nextStationIndex == i
                    let isTerminal = i == 0 || i == count - 1
                    let stops = stopsAt(i)
                    let r = (isCurrent || isNext || isTerminal) ? emphR : (stops ? baseR : skippedR)

                    ZStack {
                        if !stops && !isTerminal && !isCurrent && !isNext {
                            // Skipped station: small solid dot
                            Circle()
                                .fill(isPast ? Color(white: 0.35) : Color(white: 0.2))
                                .frame(width: r * 2, height: r * 2)
                        } else {
                            Circle()
                                .fill(isPast ? lineColor : Color(white: 0.4))
                                .frame(width: r * 2, height: r * 2)
                        }

                        if isTerminal {
                            Circle()
                                .strokeBorder(isPast ? lineColor : Color(white: 0.4), lineWidth: 1.5)
                                .frame(width: r * 2 + 3, height: r * 2 + 3)
                        }

                        if isCurrent {
                            Circle()
                                .fill(Color.white)
                                .frame(width: r, height: r)
                        }

                        if isNext && !isCurrent {
                            Circle()
                                .strokeBorder(lineColor, lineWidth: 1)
                                .frame(width: r * 2 + 3, height: r * 2 + 3)
                        }
                    }
                    .position(x: x, y: 6)
                }
            }
            .frame(height: 12)
        }
        .frame(height: 12)
    }
}

// MARK: - LCD Line Symbol Badge

/// Compact line symbol badge for Live Activity (self-contained, no dependency on main app target).
/// Mirrors the operator styles of the app's LineSymbolBadge at 24pt.
struct LCDLineSymbolBadge: View {
    let symbol: String
    let color: Color

    private static let tobuSymbols: Set<String> = ["TS", "TI", "TN", "TD", "TJ"]
    private static let tokyuStyleSymbols: Set<String> = ["TY", "DT", "MG", "OM", "IK", "SG", "TM", "KD"]
    private static let seibuSymbols: Set<String> = ["SI", "SS", "SK", "ST", "SW", "SY"]
    private static let keioSymbols: Set<String> = ["KO", "IN"]
    private static let keikyuRingBlue = Color(hex: "#00A7E1")
    private static let keikyuLetterBlue = Color(hex: "#1E50A2")
    private static let seibuLetterColor = Color(hex: "#414D66")

    var body: some View {
        switch symbol {
        case "KS":
            circleBadge(ringWidth: 2.4, textColor: color, hind: true)
        case "KK":
            circleBadge(ringWidth: 2.0, textColor: Self.keikyuLetterBlue, hind: true,
                        ringColor: Self.keikyuRingBlue)
        case "SO":
            sotetsuBadge
        case "MM":
            minatomiraiBadge
        case _ where Self.keioSymbols.contains(symbol):
            // Keio KO logo: white circle, thick ring, line-color letters
            circleBadge(ringWidth: 3.0, textColor: color, hind: true)
        case _ where Self.tokyuStyleSymbols.contains(symbol):
            filledBadge(in: AnyShape(RoundedRectangle(cornerRadius: 6)))
        case _ where Self.seibuSymbols.contains(symbol):
            squareBadge(cornerRadius: 5.5, borderWidth: 2.6, textColor: Self.seibuLetterColor)
        case _ where Self.tobuSymbols.contains(symbol):
            squareBadge(cornerRadius: 5.5, borderWidth: 2.6)
        case _ where symbol.hasPrefix("J"):
            squareBadge(cornerRadius: 3, borderWidth: 2.6)
        default:
            // Metro/Toei symbols use Futura like the real signage
            circleBadge(ringWidth: 3.8, textColor: .black, hind: false)
        }
    }

    private func circleBadge(ringWidth: CGFloat, textColor: Color, hind: Bool,
                             ringColor: Color? = nil) -> some View {
        symbolText(color: textColor, inset: ringWidth + 1, hind: hind)
            .frame(width: 24, height: 24)
            .background(Color.white, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(ringColor ?? color, lineWidth: ringWidth)
            )
    }

    private func squareBadge(cornerRadius: CGFloat, borderWidth: CGFloat,
                             textColor: Color = .black) -> some View {
        symbolText(color: textColor, inset: borderWidth + 1, hind: true)
            .frame(width: 24, height: 24)
            .background(Color.white, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(color, lineWidth: borderWidth)
            )
    }

    /// Tokyu: line-color fill, white letters
    private func filledBadge(in shape: AnyShape) -> some View {
        symbolText(color: .white, inset: 3, hind: true)
            .frame(width: 24, height: 24)
            .background(color, in: shape)
    }

    /// Minatomirai: line-color fill, white Helvetica letters
    private var minatomiraiBadge: some View {
        Text(symbol)
            .font(.custom("Helvetica-Bold", fixedSize: 10.5))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(.white)
            .padding(.horizontal, 3.5)
            .frame(width: 24, height: 24)
            .background(color, in: RoundedRectangle(cornerRadius: 4))
    }

    /// Sotetsu: navy fill, flat wide white letters over an orange rule
    /// (signage face approximated by expanded-width SF)
    private var sotetsuBadge: some View {
        VStack(spacing: 1.5) {
            Text(symbol)
                .font(.system(size: 8.5, weight: .bold))
                .fontWidth(.expanded)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.white)
            Rectangle()
                .fill(Color(hex: "#EE7B01"))
                .frame(width: 13.5, height: 1.4)
        }
        .frame(width: 24, height: 24)
        .background(color, in: RoundedRectangle(cornerRadius: 5))
    }

    private func symbolText(color: Color, inset: CGFloat, hind: Bool) -> some View {
        let size: CGFloat = symbol.count > 1 ? 11.5 : 14
        return Text(symbol)
            .font(hind
                  ? .custom("Hind-Bold", fixedSize: size)
                  : .custom("Futura-Bold", fixedSize: symbol.count > 1 ? 9 : 11.5))
            .kerning(symbol.count > 1 ? -0.4 : 0)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundColor(color)
            // Hind's tall metrics leave caps 0.085em above the box center
            .offset(y: hind ? size * 0.085 : 0)
            .padding(.horizontal, inset)
    }
}
