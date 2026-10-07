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

/// The island's layout on the lock screen's two bands: times either side of
/// the next station, the current and next leg on the white band.
struct LockScreenLiveActivityView: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState

    private static let sideColumnWidth: CGFloat = 80

    private var nextIndex: Int {
        min(state.nextStationIndex ?? attributes.stationCount - 1, attributes.stationCount - 1)
    }

    private var nextStationCode: String {
        attributes.stationCodes.indices.contains(nextIndex) ? attributes.stationCodes[nextIndex] : ""
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(alignment: .center) {
                    IslandCornerTime(attributes: attributes, state: state, side: .leading)
                        .frame(width: Self.sideColumnWidth, alignment: .leading)
                    Spacer(minLength: 0)
                    IslandCornerTime(attributes: attributes, state: state, side: .trailing)
                        .frame(width: Self.sideColumnWidth, alignment: .trailing)
                }
                VStack(spacing: 1) {
                    HStack(spacing: 6) {
                        if !nextStationCode.isEmpty {
                            LCDStationNumberBadge(code: nextStationCode,
                                                  color: Color(hex: attributes.stationColorHex(at: nextIndex)),
                                                  dimension: 24)
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
                .padding(.horizontal, Self.sideColumnWidth + 4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.black)

            IslandRouteLine(attributes: attributes, state: state, onLight: true)
                .padding(.horizontal, 8)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(Color.white)
        }
    }
}

// MARK: - Island Route Line

/// The current leg across most of the width with the next leg squeezed after
/// it; finished legs drop off the left.
struct IslandRouteLine: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState
    /// Lock screen's white band.
    var onLight = false

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
                    IslandLegInfo(attributes: attributes, state: state, onLight: onLight)
                        .fixedSize()
                        .layoutValue(key: IslandLabelAnchor.self, value: .init(x: pad - 6, align: .leading))
                    if let transfer {
                        IslandNextLegLabel(attributes: attributes, transferIndex: transfer, onLight: onLight)
                            .fixedSize()
                            .layoutValue(key: IslandLabelAnchor.self,
                                         value: .init(x: (x(transfer, in: w) + x(end, in: w)) / 2, align: .center))
                    } else {
                        IslandDestinationLabel(attributes: attributes, onLight: onLight)
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
                .fill(color(i + 1).opacity(i < from ? 1 : (onLight ? 0.25 : 0.3)))
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
            ring(isPassed ? color(i) : Color(white: onLight ? 0.65 : 0.55))
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
                .fill(isPassed ? color(i) : Color(white: onLight ? (isStop ? 0.7 : 0.8) : (isStop ? 0.45 : 0.3)))
                .frame(width: size, height: size)
        }
    }

    private func ring(_ color: Color) -> some View {
        Circle()
            .strokeBorder(color, lineWidth: 2)
            .background(Circle().fill(onLight ? Color.white : Color.black))
            .frame(width: 11, height: 11)
    }
}

// MARK: - Island Route Labels

/// The leg being ridden: its line and where the train is bound.
struct IslandLegInfo: View {
    let attributes: TrainJourneyAttributes
    let state: TrainJourneyAttributes.ContentState
    var onLight = false

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
                    .foregroundColor(IslandInk.secondary(onLight))
            }
        }
    }
}

/// 乗換 onto the next leg: which line, and where.
struct IslandNextLegLabel: View {
    let attributes: TrainJourneyAttributes
    let transferIndex: Int
    var onLight = false

    var body: some View {
        let leg = attributes.legLines.first { $0.stationIndex == transferIndex }
        let color = Color(hex: leg?.lineColorHex ?? attributes.lineColorHex)
        HStack(spacing: 6) {
            Text("Label.Transfer")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(IslandInk.caption(onLight))
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
                    .foregroundColor(IslandInk.primary(onLight))
            }
        }
    }
}

/// 下車 at the destination, on the last leg.
struct IslandDestinationLabel: View {
    let attributes: TrainJourneyAttributes
    var onLight = false

    var body: some View {
        HStack(spacing: 6) {
            Text("Label.GetOffAt")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(IslandInk.caption(onLight))
            if !attributes.destinationCode.isEmpty {
                LCDStationNumberBadge(code: attributes.destinationCode,
                                      color: Color(hex: attributes.destinationColorHex),
                                      dimension: 26)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(attributes.destinationName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(IslandInk.primary(onLight))
                Text(attributes.destinationNameEn)
                    .font(.system(size: 9))
                    .foregroundColor(IslandInk.secondary(onLight))
            }
        }
    }
}

/// Text ink for the island's black or the lock screen's white band.
enum IslandInk {
    static func primary(_ onLight: Bool) -> Color { onLight ? Color.black.opacity(0.9) : .white }
    static func secondary(_ onLight: Bool) -> Color { onLight ? Color.black.opacity(0.6) : .secondary }
    static func caption(_ onLight: Bool) -> Color { onLight ? Color.black.opacity(0.5) : Color(white: 0.6) }
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
