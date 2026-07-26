import SwiftUI
import Backbone

// MARK: - Journey View (In-App, Vertical/Portrait)

struct JourneyView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @AppStorage(TrainLCDStyle.storageKey) private var lcdStyleRaw = TrainLCDStyle.joban.rawValue
    @AppStorage(TrainLCDOrientation.storageKey) private var lcdOrientationRaw = TrainLCDOrientation.left.rawValue

    /// Carried with the presentation; `isPresented` would read a stale index.
    @State private var replanTarget: ReplanTarget?

    private struct ReplanTarget: Identifiable {
        let stationIndex: Int
        var id: Int { stationIndex }
    }

    private var lineColor: Color {
        viewModel.currentLineColor
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
                                lineColor: lineColor,
                                selectableIndices: Set(viewModel.replanAnchors.map(\.stationIndex)),
                                onSelectStation: { index in
                                    replanTarget = ReplanTarget(stationIndex: index)
                                }
                            )
                            .padding(.horizontal, 24)

                            Spacer(minLength: 40)
                        }
                    }
                    .safeAreaInset(edge: .top) {
                        StyledTrainLCDView(
                            style: TrainLCDStyle(stored: lcdStyleRaw),
                            journey: journey,
                            state: state,
                            lineColor: lineColor,
                            orientation: TrainLCDOrientation(rawValue: lcdOrientationRaw) ?? .left
                        )
                        // PiP docks here so returning to the app animates
                        // the PiP window into the LCD.
                        .overlay {
                            LCDPiPLayerHost()
                                .frame(width: 1, height: 1)
                                .allowsHitTesting(false)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Group {
                            if viewModel.trackingMode == .manual {
                                manualStationControl(journey: journey, state: state)
                            } else {
                                trackingModeCapsule
                            }
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
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
        .sheet(item: $replanTarget) { target in
            ReplanSheet(viewModel: viewModel, initialAnchorIndex: target.stationIndex)
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

                if let origin = journey.journeyStations.first,
                   let destination = journey.journeyStations.last {
                    HStack(spacing: 6) {
                        Text(origin.localizedName)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(destination.localizedName)
                    }
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                } else {
                    Text(lineDisplayName(for: journey))
                        .font(.system(size: 20, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer()
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

    /// Glass capsule summarizing the tracking mode; tap to refresh position.
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
            content
                .glassEffect(.regular.tint(modeColor(mode).opacity(0.2)).interactive())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Button.Refresh")
    }

    private func modeIcon(_ mode: TrackingMode) -> String {
        switch mode {
        case .gps: return "location.fill"
        case .timetable: return "clock.fill"
        case .blended: return "location.circle"
        case .manual: return "hand.draw.fill"
        }
    }

    private func modeLabel(_ mode: TrackingMode) -> LocalizedStringKey {
        switch mode {
        case .gps: return "TrackingMode.GPS"
        case .timetable: return "TrackingMode.Timetable"
        case .blended: return "TrackingMode.Blended"
        case .manual: return "TrackingMode.Manual"
        }
    }

    private func modeColor(_ mode: TrackingMode) -> Color {
        switch mode {
        case .gps: return .green
        case .timetable: return .orange
        case .blended: return .blue
        case .manual: return .purple
        }
    }

    // MARK: - Manual Station Flipper (schedule-less journeys)

    /// Manual station flipper for journeys with no schedule and no usable GPS.
    @ViewBuilder
    private func manualStationControl(journey: Journey, state: TrainPositionState) -> some View {
        let stations = journey.journeyStations
        let index = min(max(state.currentStationIndex ?? state.segmentFrom, 0),
                        max(stations.count - 1, 0))

        let content = HStack(spacing: 14) {
            Button {
                viewModel.stepManualStation(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
            }
            .disabled(index <= 0)
            .accessibilityLabel("Journey.PreviousStation")

            VStack(spacing: 1) {
                Text("TrackingMode.Manual")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(stations.isEmpty ? "" : stations[index].localizedName)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
            }
            .frame(minWidth: 100)

            Button {
                viewModel.stepManualStation(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
            }
            .disabled(index >= stations.count - 1)
            .accessibilityLabel("Journey.NextStation")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        
        content
            .glassEffect(.regular.interactive())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "train.side.front.car")
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

    /// Line name without train-type qualifiers, cleaned per 〜-joined segment.
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
}
