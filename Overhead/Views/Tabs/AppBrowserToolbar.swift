import SwiftUI
import Backbone

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
        Button(action: action) {
            if let station = nextStation, !station.stationCode.isEmpty {
                StationNumberBadge(
                    code: station.stationCode,
                    color: viewModel.badgeLineColor(arrivingAt: station.id),
                    size: .regular,
                    stationName: station.name,
                    styleOverride: viewModel.activeJourney?.line.badgeStyleId
                )
                .scaleEffect(36.0 / 28.0)
                .frame(width: 36, height: 36)
            } else {
                Image(systemName: "tram.fill")
                    .frame(width: 24, height: 24)
            }
        }
        .accessibilityLabel(
            nextStation.map { Text("Open journey, next stop \($0.localizedName)") }
                ?? Text("Open journey")
        )
    }
}

struct BrowserAddressToolbarItem: View {
    @ObservedObject var store: AppTabStore
    var isFocused: FocusState<Bool>.Binding
    let onOpenSearch: () -> Void
    let onSwipe: (Int) -> Void

    @GestureState private var dragOffset: CGFloat = 0
    @State private var suppressTap = false

    var body: some View {
        Group {
            if case .search = store.selectedTab.page {
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search.Prompt", text: searchText)
                        .textFieldStyle(.plain)
                        .focused(isFocused)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                    if !store.selectedTab.searchText.isEmpty {
                        Button {
                            store.updateSelected { $0.searchText = "" }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Button.Close")
                    }
                }
                .padding(.horizontal, 10)
            } else {
                Button {
                    guard !suppressTap else { return }
                    onOpenSearch()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        Text("Search.Prompt")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .contentShape(.capsule)
                }
            }
        }
        .offset(x: dragOffset * 0.1)
        .simultaneousGesture(swipeGesture)
    }

    private var searchText: Binding<String> {
        Binding(
            get: { store.selectedTab.searchText },
            set: { value in store.updateSelected { $0.searchText = value } }
        )
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
