import SwiftUI
import Backbone

// MARK: - Journey View (In-App, Vertical/Portrait)

struct JourneyView: View {
    @ObservedObject var viewModel: JourneyViewModel

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
                        TrainLCDView(journey: journey, state: state, lineColor: lineColor)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
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
}
