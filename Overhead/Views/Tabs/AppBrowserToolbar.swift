import SwiftUI
import Backbone
import EnhancedNavigation

struct JourneyStationToolbarButton: View {
    @ObservedObject var viewModel: JourneyViewModel
    let action: () -> Void

    private var nextStation: Station? {
        guard let journey = viewModel.activeJourney,
              let state = viewModel.positionState,
              !journey.journeyStations.isEmpty else { return nil }
        let current = state.currentStationIndex
            ?? (state.status == .notStarted ? state.segmentFrom : state.segmentTo)
        let next = state.status == .notStarted ? current : current + 1
        return journey.journeyStations[max(0, min(next, journey.journeyStations.count - 1))]
    }

    var body: some View {
        if viewModel.activeJourney != nil {
            Button(action: action) {
                if let station = nextStation, !station.stationCode.isEmpty {
                    StationNumberBadge(
                        code: station.stationCode,
                        color: viewModel.badgeLineColor(arrivingAt: station.id),
                        size: .regular,
                        stationName: station.name,
                        styleOverride: viewModel.activeJourney?.line.badgeStyleId
                    )
                    .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "tram.fill")
                        .frame(width: 24, height: 24)
                }
            }
            .frame(width: TabBottomBarMetrics.itemHeight, height: TabBottomBarMetrics.itemHeight)
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel(
                nextStation.map { Text("Open journey, next stop \($0.localizedName)") }
                    ?? Text("Open journey")
            )
        }
    }
}

struct BrowserAddressToolbarItem: View {
    @ObservedObject var viewModel: JourneyViewModel
    var searchText: Binding<String>
    let onOpenSearch: () -> Void
    let onSwipe: (Int) -> Void

    @GestureState private var dragOffset: CGFloat = 0
    @State private var suppressTap = false

    var body: some View {
        Button {
            guard !suppressTap else { return }
            onOpenSearch()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                addressLabel
                    .foregroundStyle(.secondary)
            }
            .contentShape(.capsule)
        }
        .accessibilityLabel("Search.Prompt")
        .offset(x: dragOffset * 0.1)
        .simultaneousGesture(swipeGesture)
    }

    @ViewBuilder
    private var addressLabel: some View {
        if !searchText.wrappedValue.isEmpty {
            Text(searchText.wrappedValue)
                .lineLimit(1)
        } else if viewModel.activeJourney != nil {
            Text("Search.Title")
        } else {
            ViewThatFits(in: .horizontal) {
                Text("Search.Prompt")
                    .fixedSize(horizontal: true, vertical: false)
                Text("Search.Title")
            }
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($dragOffset) { value, state, _ in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                state = value.translation.width
            }
            .onChanged { value in
                if abs(value.translation.width) > abs(value.translation.height) * 1.25 {
                    suppressTap = true
                }
            }
            .onEnded { value in
                defer { DispatchQueue.main.async { suppressTap = false } }
                guard abs(value.translation.width) > abs(value.translation.height) * 1.25,
                      abs(value.predictedEndTranslation.width) > 60 else { return }
                onSwipe(value.predictedEndTranslation.width < 0 ? 1 : -1)
            }
    }
}
