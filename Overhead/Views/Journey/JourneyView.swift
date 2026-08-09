import SwiftUI
import Backbone

// MARK: - Journey View (In-App, Vertical/Portrait)

struct JourneyView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @AppStorage(TrainLCDStyle.storageKey) private var lcdStyleRaw = TrainLCDStyle.joban.rawValue
    @AppStorage(TrainLCDOrientation.storageKey) private var lcdOrientationRaw = TrainLCDOrientation.left.rawValue

    /// Carried with the presentation; `isPresented` would read a stale index.
    @State private var replanTarget: ReplanTarget?
    /// The tapped stop, held while the rider says what they want to do there.
    @State private var replanChoice: ReplanChoice?

    private struct ReplanTarget: Identifiable {
        let stationIndex: Int
        let mode: ReplanSheet.Mode
        var id: Int { stationIndex }
    }

    private struct ReplanChoice: Identifiable {
        let stationIndex: Int
        let stationName: String
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
                            if state.delayMinutes > 0 {
                                journeyHeader(state: state)
                                    .padding(.top, 12)
                                    .padding(.bottom, 20)
                            }

                            VerticalLCDLine(
                                journey: journey,
                                state: state,
                                lineColor: lineColor,
                                selectableIndices: Set(viewModel.replanAnchors.map(\.stationIndex)),
                                onSelectStation: { index in
                                    let stations = journey.journeyStations
                                    guard stations.indices.contains(index) else { return }
                                    replanChoice = ReplanChoice(
                                        stationIndex: index,
                                        stationName: stations[index].localizedName
                                    )
                                }
                            )
                            .padding(.horizontal, 24)
                            .padding(.top, 12)

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
                        // PiP docks here so restoring animates into the LCD.
                        .overlay {
                            LCDPiPLayerHost()
                                .frame(width: 1, height: 1)
                                .allowsHitTesting(false)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                    .safeAreaInset(edge: .bottom) {
                        if viewModel.trackingMode == .manual {
                            manualStationControl(journey: journey, state: state)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                        }
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
        .alert(
            Text(verbatim: replanChoice?.stationName ?? ""),
            isPresented: Binding(
                get: { replanChoice != nil },
                set: { if !$0 { replanChoice = nil } }
            ),
            presenting: replanChoice
        ) { choice in
            Button("Replan.Mode.Train") {
                replanTarget = ReplanTarget(stationIndex: choice.stationIndex, mode: .train)
            }
            Button("Replan.Mode.Destination") {
                replanTarget = ReplanTarget(stationIndex: choice.stationIndex, mode: .destination)
            }
            Button("Button.Cancel", role: .cancel) {}
        } message: { _ in
            Text("Replan.Choice.Message")
        }
        .sheet(item: $replanTarget) { target in
            ReplanSheet(
                viewModel: viewModel,
                initialAnchorIndex: target.stationIndex,
                initialMode: target.mode
            )
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func journeyHeader(state: TrainPositionState) -> some View {
        VStack(spacing: 10) {
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
}
