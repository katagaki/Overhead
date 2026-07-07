import SwiftUI
import Backbone

// MARK: - Journey View (In-App, Vertical/Portrait)

struct JourneyView: View {
    @ObservedObject var viewModel: JourneyViewModel
    /// Whether to show the in-bar end-journey button. Off when presented in
    /// the journey sheet, whose toolbar provides the actions instead.
    var showsEndButton: Bool = true
    @State private var showingEndConfirmation = false

    private var lineColor: Color {
        viewModel.selectedLine?.color ?? .gray
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            if let journey = viewModel.activeJourney,
               let state = viewModel.positionState {

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            journeyHeader(journey: journey, state: state)
                                .padding(.top, 12)
                                .padding(.bottom, 20)

                            VerticalLCDLine(
                                journey: journey,
                                state: state,
                                lineColor: lineColor
                            )
                            .padding(.horizontal, 24)

                            Spacer(minLength: 40)
                        }
                    }
                    .safeAreaInset(edge: .top) {
                        nextStationBar(state: state, journey: journey)
                    }
                    .safeAreaInset(edge: .bottom) {
                        trackingModeCapsule
                            .padding(.vertical, 8)
                    }
                    .onAppear {
                        if let idx = state.currentStationIndex {
                            withAnimation {
                                proxy.scrollTo("station_\(idx)", anchor: .center)
                            }
                        }
                    }
                }
            } else {
                emptyState
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func journeyHeader(journey: Journey, state: TrainPositionState) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(lineColor)
                    .frame(width: 6, height: 32)

                Text(lineDisplayName(for: journey))
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Text(journey.service.trainType.displayNameJa)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(lineColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)

            if state.delayMinutes > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text("Journey.Delay.Banner \(state.delayMinutes)")
                        .font(.system(size: 14, weight: .bold))
                    if let cause = viewModel.currentDelay?.cause {
                        Text("(\(cause))")
                            .font(.system(size: 12))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Tracking Mode Capsule (bottom safe area)

    /// Floating glass capsule summarizing the tracking mode; tapping it
    /// refreshes the position.
    @ViewBuilder
    private var trackingModeCapsule: some View {
        let mode = viewModel.trackingMode

        let content = HStack(spacing: 8) {
            Image(systemName: modeIcon(mode))
                .font(.system(size: 12, weight: .semibold))
            Text(modeLabel(mode))
                .font(.system(size: 13, weight: .bold))

            if mode == .timetable {
                Text("Status.WeakGPSSignal")
                    .font(.system(size: 11))
                    .opacity(0.7)
                    .lineLimit(1)
            }

            Image(systemName: "arrow.clockwise")
                .font(.system(size: 11, weight: .semibold))
                .opacity(0.8)
        }
        .foregroundColor(modeColor(mode))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)

        Button {
            viewModel.forceRefresh()
        } label: {
            if #available(iOS 26.0, *) {
                content
                    .glassEffect(.regular.tint(modeColor(mode).opacity(0.2)).interactive())
            } else {
                content
                    .background {
                        ZStack {
                            Capsule().fill(.ultraThinMaterial)
                            Capsule().fill(modeColor(mode).opacity(0.12))
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Button.Refresh")
    }

    private func modeIcon(_ mode: TrackingMode) -> String {
        switch mode {
        case .gps: return "location.fill"
        case .timetable: return "clock.fill"
        case .blended: return "location.circle"
        }
    }

    private func modeLabel(_ mode: TrackingMode) -> LocalizedStringKey {
        switch mode {
        case .gps: return "TrackingMode.GPS"
        case .timetable: return "TrackingMode.Timetable"
        case .blended: return "TrackingMode.Blended"
        }
    }

    private func modeColor(_ mode: TrackingMode) -> Color {
        switch mode {
        case .gps: return .green
        case .timetable: return .orange
        case .blended: return .blue
        }
    }

    // MARK: - Next Station Bar (Top)

    @ViewBuilder
    private func nextStationBar(state: TrainPositionState, journey: Journey) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Label.NextStation")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(state.nextStationName)
                        .font(.system(size: 26, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(state.nextStationNameEn)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Label.EstimatedArrival")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(formatTime(state.estimatedArrival))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(state.isDelayed ? .red : lineColor)

                    if state.isDelayed {
                        Text("Journey.Delay.Minutes \(state.delayMinutes)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    }
                }

                if showsEndButton {
                    Button {
                        showingEndConfirmation = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.secondary, Color(.tertiarySystemFill))
                    }
                    .accessibilityLabel("Button.EndJourney")
                    .confirmationDialog(
                        "Journey.End.ConfirmTitle",
                        isPresented: $showingEndConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Button.EndJourney", role: .destructive) {
                            viewModel.stopJourney()
                        }
                        Button("Button.KeepJourney", role: .cancel) {}
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            lineColor.frame(height: 2).opacity(0.6)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Status.NoJourneySelected")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            Text("Status.NoActiveJourney")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f.string(from: date)
    }

    /// Line name without train-type qualifiers — the type is shown in its own
    /// pill, so 中央線快速 renders as 中央線 + [快速]. Composite itineraries
    /// (legs joined with 〜) are cleaned per segment, so
    /// 常磐線快速〜千代田線 renders as 常磐線〜千代田線.
    private func lineDisplayName(for journey: Journey) -> String {
        // Longest first so 特別快速 strips before 快速
        let suffixes = ["通勤快速", "特別快速", "各駅停車", "快速", "急行", "特急"]

        func stripped(_ component: String) -> String {
            for suffix in suffixes where component.hasSuffix(suffix) && component.count > suffix.count {
                return String(component.dropLast(suffix.count))
            }
            return component
        }

        return journey.line.localizedName
            .components(separatedBy: "〜")
            .map(stripped)
            .joined(separator: "〜")
    }

    private var isDelayed: Bool {
        viewModel.positionState?.delayMinutes ?? 0 > 0
    }
}

// MARK: - Vertical LCD Line

struct VerticalLCDLine: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color

    private let stationSpacing: CGFloat = 72
    private let trackWidth: CGFloat = 3
    private let circleRadius: CGFloat = 9
    private let terminalRadius: CGFloat = 12
    private let currentRadius: CGFloat = 12

    var body: some View {
        let stations = journey.journeyStations
        let timetable = journey.journeyTimetable
        let transferIds = Set(journey.transferStationIds)

        VStack(spacing: 0) {
            ForEach(Array(stations.enumerated()), id: \.element.id) { index, station in
                let isFirst = index == 0
                let isLast = index == stations.count - 1
                let isTerminal = isFirst || isLast
                let frac = stations.count > 1 ? Double(index) / Double(stations.count - 1) : 0
                let isPast = frac <= state.progress + 0.005
                let isCurrent = state.currentStationIndex == index
                let isNext = (!isLast && index == state.segmentTo) ||
                             (state.currentStationIndex != nil && index == (state.currentStationIndex! + 1))

                HStack(alignment: .top, spacing: 0) {
                    timeColumn(for: station, timetable: timetable, isPast: isPast, isCurrent: isCurrent)
                        .frame(width: 56)

                    stationCircle(
                        isPast: isPast,
                        isCurrent: isCurrent,
                        isTerminal: isTerminal,
                        isNext: isNext
                    )
                    .frame(width: 40)

                    stationLabel(
                        station: station,
                        isPast: isPast,
                        isCurrent: isCurrent,
                        isNext: isNext,
                        isTerminal: isTerminal,
                        isTransfer: transferIds.contains(station.id)
                    )
                    .padding(.bottom, isLast ? 0 : 14)

                    Spacer()
                }
                // Rows grow when the label stack is tall (transfer/next badges)
                // instead of overflowing into the next station.
                .frame(minHeight: isLast ? 0 : stationSpacing, alignment: .top)
                // The connecting track lives in the background so it always
                // spans the actual row height, whatever the label needed.
                .background(alignment: .topLeading) {
                    if !isLast {
                        let segFrac = segmentFillFraction(stationIndex: index, totalStations: stations.count)
                        trackSegment(filled: isPast, fillFraction: segFrac)
                            .frame(width: trackWidth)
                            .padding(.top, stationDotRadius(isTerminal: isTerminal, isCurrent: isCurrent))
                            .padding(.leading, 56 + 20 - trackWidth / 2)
                    }
                }
                .id("station_\(index)")
            }
        }
    }

    private func stationDotRadius(isTerminal: Bool, isCurrent: Bool) -> CGFloat {
        if isCurrent { return currentRadius }
        if isTerminal { return terminalRadius }
        return circleRadius
    }

    // MARK: - Time Column

    @ViewBuilder
    private func timeColumn(for station: Station, timetable: [TimetableEntry], isPast: Bool, isCurrent: Bool) -> some View {
        if let entry = timetable.first(where: { $0.stationId == station.id }),
           let timeStr = entry.departureTime ?? entry.arrivalTime, !timeStr.isEmpty {
            let delayMins = state.delayMinutes

            VStack(spacing: 1) {
                Text(timeStr)
                    .font(.system(size: 13, weight: isCurrent ? .bold : .medium, design: .rounded))
                    .foregroundColor(isPast && !isCurrent ? .secondary : .primary)

                if delayMins > 0 {
                    Text(adjustedTime(timeStr, delayMinutes: delayMins))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.red)
                }
            }
        } else {
            Color.clear
        }
    }

    // MARK: - Track Segment

    @ViewBuilder
    private func trackSegment(filled: Bool, fillFraction: Double) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: trackWidth / 2)
                .fill(Color(.quaternarySystemFill))

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: trackWidth / 2)
                    .fill(lineColor)
                    .frame(height: max(0, geo.size.height * fillFraction))
            }
        }
    }

    // MARK: - Station Circle

    @ViewBuilder
    private func stationCircle(isPast: Bool, isCurrent: Bool, isTerminal: Bool, isNext: Bool) -> some View {
        let r = isCurrent ? currentRadius : (isTerminal ? terminalRadius : circleRadius)

        ZStack {
            if isCurrent {
                Circle()
                    .fill(lineColor)
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .fill(Color.white)
                    .frame(width: r * 0.7, height: r * 0.7)
                    .shadow(color: lineColor, radius: 3)
                Circle()
                    .strokeBorder(lineColor, lineWidth: 2)
                    .frame(width: r * 2 + 10, height: r * 2 + 10)
            } else if isTerminal {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .strokeBorder(isPast ? lineColor : Color(.systemGray3), lineWidth: 3)
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .fill(isPast ? lineColor : Color(.systemGray5))
                    .frame(width: r * 2 - 10, height: r * 2 - 10)
            } else if isPast {
                Circle()
                    .fill(lineColor)
                    .frame(width: r * 2, height: r * 2)
            } else {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .strokeBorder(Color(.systemGray3), lineWidth: 2)
                    .frame(width: r * 2, height: r * 2)
            }

            if isNext && !isCurrent {
                Circle()
                    .strokeBorder(lineColor, lineWidth: 2)
                    .frame(width: r * 2 + 6, height: r * 2 + 6)
            }
        }
    }

    // MARK: - Station Label

    @ViewBuilder
    private func stationLabel(station: Station, isPast: Bool, isCurrent: Bool, isNext: Bool, isTerminal: Bool, isTransfer: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                if !station.stationCode.isEmpty {
                    StationNumberBadge(
                        code: station.stationCode,
                        color: lineColor,
                        opacity: isPast && !isCurrent ? 0.4 : 1.0,
                        size: .regular,
                        stationName: station.name
                    )
                }

                Text(station.localizedName)
                    .font(.system(size: isCurrent || isTerminal || isTransfer ? 18 : 15,
                                  weight: isCurrent || isTerminal || isTransfer ? .bold : .medium))
                    .foregroundColor(isPast && !isCurrent ? .secondary : .primary)
            }

            Text(station.nameEn)
                .font(.system(size: 11))
                .foregroundColor(isPast && !isCurrent ? .secondary.opacity(0.5) : .secondary)

            if isTransfer {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 9, weight: .bold))
                    Text("Label.Transfer")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(isPast && !isCurrent ? 0.08 : 0.15))
                .clipShape(Capsule())
                .padding(.top, 2)
                .opacity(isPast && !isCurrent ? 0.5 : 1.0)
            }

            if isCurrent {
                Text("Label.CurrentLocation")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(lineColor)
                    .clipShape(Capsule())
                    .padding(.top, 2)
            }

            if isNext && !isCurrent {
                Text("Label.NextStop")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(lineColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(lineColor.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.top, 2)
            }
        }
        .padding(.leading, 8)
    }

    // MARK: - Helpers

    private func segmentFillFraction(stationIndex: Int, totalStations: Int) -> Double {
        let stationFrac = totalStations > 1 ? Double(stationIndex) / Double(totalStations - 1) : 0
        let nextFrac = totalStations > 1 ? Double(stationIndex + 1) / Double(totalStations - 1) : 0

        if state.progress >= nextFrac { return 1.0 }
        if state.progress <= stationFrac { return 0.0 }

        let segRange = nextFrac - stationFrac
        guard segRange > 0 else { return 0 }
        return (state.progress - stationFrac) / segRange
    }

    private func adjustedTime(_ original: String, delayMinutes: Int) -> String {
        guard let secs = TimetableEntry.parseRailTime(original) else { return original }
        let adjusted = secs + delayMinutes * 60
        let h = adjusted / 3600
        let m = (adjusted % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }
}

// MARK: - TrainPositionState convenience

extension TrainPositionState {
    var isDelayed: Bool { delayMinutes > 0 }
}
