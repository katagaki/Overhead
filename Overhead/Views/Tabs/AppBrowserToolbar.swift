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
                Text(addressText)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .contentShape(.capsule)
        }
        .accessibilityLabel("Search.Prompt")
        .offset(x: dragOffset * 0.1)
        .simultaneousGesture(swipeGesture)
    }

    private var addressText: LocalizedStringKey {
        if case .search = store.selectedTab.page,
           !store.selectedTab.searchText.isEmpty {
            return LocalizedStringKey(store.selectedTab.searchText)
        }
        return "Search.Prompt"
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

struct BrowserSearchOverlay: View {
    @ObservedObject var store: AppTabStore
    var isFocused: FocusState<Bool>.Binding
    let dismiss: () -> Void

    @State private var isKeyboardUp = false

    private static let fieldHeight: CGFloat = 48

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .contentShape(Rectangle())
                .allowsHitTesting(false)

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search.Prompt", text: searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .focused(isFocused)
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
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.fieldHeight)
                    .glassEffect(.regular.interactive(), in: .capsule)

                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .frame(width: Self.fieldHeight, height: Self.fieldHeight)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .accessibilityLabel("Button.Close")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, bottomInset)
        }
        .task {
            try? await Task.sleep(for: .milliseconds(80))
            isFocused.wrappedValue = true
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        ) { _ in
            isKeyboardUp = true
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { _ in
            isKeyboardUp = false
        }
    }

    private var searchText: Binding<String> {
        Binding(
            get: { store.selectedTab.searchText },
            set: { value in store.updateSelected { $0.searchText = value } }
        )
    }

    private var bottomInset: CGFloat {
        if isKeyboardUp { return 8 }
        return max(8, 28 - AppTabDeviceMetrics.safeAreaInsets.bottom)
    }
}
