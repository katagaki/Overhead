import SwiftUI

// MARK: - Journey View (In-App, Vertical/Portrait)
/// Full-screen vertical route display mimicking the in-train LCD panels
/// but rotated for portrait orientation.

struct JourneyView: View {
    @ObservedObject var viewModel: JourneyViewModel

    private var lineColor: Color {
        viewModel.selectedLine?.color ?? .gray
    }

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            if let journey = viewModel.activeJourney,
               let state = viewModel.positionState {

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Header
                            journeyHeader(journey: journey, state: state)
                                .padding(.bottom, 16)

                            // Vertical LCD line
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
                    .onAppear {
                        // Scroll to approximate current position
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
        VStack(spacing: 8) {
            // Line badge
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(lineColor)
                    .frame(width: 6, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text(journey.line.localizedName)
                        .font(.system(size: 20, weight: .bold))
                    Text(journey.line.nameEn)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Train type pill
                Text(journey.service.trainType.displayNameJa)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(lineColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)

            // Location status
            trackingModeBanner(state: state)

            // Delay banner
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

    // MARK: - Tracking Mode Banner

    @ViewBuilder
    private func trackingModeBanner(state: TrainPositionState) -> some View {
        let mode = viewModel.trackingMode

        HStack(spacing: 8) {
            // Mode icon + label
            HStack(spacing: 4) {
                Image(systemName: modeIcon(mode))
                    .font(.system(size: 11))
                Text(modeLabel(mode))
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(modeColor(mode))

            if mode == .timetable {
                Text("Status.WeakGPSSignal")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Refresh button
            Button {
                Task { await viewModel.forceRefreshDelay() }
            } label: {
                HStack(spacing: 3) {
                    if viewModel.isRefreshing {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    Text("Button.Refresh")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(lineColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(lineColor.opacity(0.1))
                .clipShape(Capsule())
            }
            .disabled(viewModel.isRefreshing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .background(modeColor(mode).opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 24)
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
        HStack {
            // Next station
            VStack(alignment: .leading, spacing: 2) {
                Text("Label.NextStation")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(state.nextStationName)
                    .font(.system(size: 22, weight: .bold))
                Text(state.nextStationNameEn)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // ETA
            VStack(alignment: .trailing, spacing: 2) {
                Text("Label.EstimatedArrival")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(formatTime(state.estimatedArrival))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(state.isDelayed ? .red : lineColor)

                if state.isDelayed {
                    Text("Journey.Delay.Minutes \(state.delayMinutes)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 24)
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

    private var isDelayed: Bool {
        viewModel.positionState?.delayMinutes ?? 0 > 0
    }
}

// MARK: - Vertical LCD Line
/// Portrait-optimized vertical station line inspired by the JR East app.
/// Thin track centered through station dots, hollow future stations,
/// prominent current/next station indicators.

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
                    // Left side: time
                    timeColumn(for: station, timetable: timetable, isPast: isPast, isCurrent: isCurrent)
                        .frame(width: 56)

                    // Track + circle
                    ZStack(alignment: .top) {
                        // Track segment below this station (not for last)
                        if !isLast {
                            let segFrac = segmentFillFraction(stationIndex: index, totalStations: stations.count)
                            trackSegment(filled: isPast, fillFraction: segFrac)
                                .frame(width: trackWidth, height: stationSpacing)
                                .offset(y: stationDotRadius(isTerminal: isTerminal, isCurrent: isCurrent))
                        }

                        // Station circle
                        stationCircle(
                            isPast: isPast,
                            isCurrent: isCurrent,
                            isTerminal: isTerminal,
                            isNext: isNext
                        )
                    }
                    .frame(width: 40)

                    // Right side: station name
                    stationLabel(
                        station: station,
                        isPast: isPast,
                        isCurrent: isCurrent,
                        isNext: isNext,
                        isTerminal: isTerminal
                    )

                    Spacer()
                }
                .frame(height: isLast ? nil : stationSpacing)
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
        if let entry = timetable.first(where: { $0.stationId == station.id }) {
            let timeStr = entry.departureTime ?? entry.arrivalTime ?? ""
            let delayMins = state.delayMinutes

            VStack(spacing: 1) {
                Text(timeStr)
                    .font(.system(size: 13, weight: isCurrent ? .bold : .medium, design: .monospaced))
                    .foregroundColor(isPast && !isCurrent ? .secondary : .primary)

                if delayMins > 0 {
                    Text(adjustedTime(timeStr, delayMinutes: delayMins))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Track Segment

    @ViewBuilder
    private func trackSegment(filled: Bool, fillFraction: Double) -> some View {
        ZStack(alignment: .top) {
            // Background track — thin and subtle
            RoundedRectangle(cornerRadius: trackWidth / 2)
                .fill(Color.gray.opacity(0.2))

            // Filled portion
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
                // Current station: filled colored circle with white inner dot
                Circle()
                    .fill(lineColor)
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .fill(Color.white)
                    .frame(width: r * 0.7, height: r * 0.7)
                    .shadow(color: lineColor.opacity(0.5), radius: 3)
                // Pulse ring
                Circle()
                    .strokeBorder(lineColor.opacity(0.3), lineWidth: 2)
                    .frame(width: r * 2 + 10, height: r * 2 + 10)
            } else if isTerminal {
                // Terminal: double circle (outline with colored/gray border)
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .strokeBorder(isPast ? lineColor : Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .fill(isPast ? lineColor : Color.gray.opacity(0.15))
                    .frame(width: r * 2 - 10, height: r * 2 - 10)
            } else if isPast {
                // Past station: small filled dot
                Circle()
                    .fill(lineColor)
                    .frame(width: r * 2, height: r * 2)
            } else {
                // Future station: hollow circle (white fill, gray outline)
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: r * 2, height: r * 2)
            }

            // Next station: colored ring highlight
            if isNext && !isCurrent {
                Circle()
                    .strokeBorder(lineColor.opacity(0.6), lineWidth: 2)
                    .frame(width: r * 2 + 6, height: r * 2 + 6)
            }
        }
    }

    // MARK: - Station Label

    @ViewBuilder
    private func stationLabel(station: Station, isPast: Bool, isCurrent: Bool, isNext: Bool, isTerminal: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                if !station.stationCode.isEmpty {
                    StationNumberBadge(
                        code: station.stationCode,
                        color: lineColor,
                        opacity: isPast && !isCurrent ? 0.4 : 1.0,
                        size: .regular
                    )
                }

                Text(station.localizedName)
                    .font(.system(size: isCurrent || isTerminal ? 18 : 15,
                                  weight: isCurrent || isTerminal ? .bold : .medium))
                    .foregroundColor(isPast && !isCurrent ? .secondary : .primary)
            }

            Text(station.nameEn)
                .font(.system(size: 11))
                .foregroundColor(isPast && !isCurrent ? .secondary.opacity(0.5) : .secondary)

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

    /// How much of the segment below this station is filled
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
