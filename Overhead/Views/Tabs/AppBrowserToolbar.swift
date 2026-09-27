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
        if !searchText.wrappedValue.isEmpty {
            return LocalizedStringKey(searchText.wrappedValue)
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
    let lines: [TrainLine]
    var searchText: Binding<String>
    var searchScope: Binding<SearchScope>
    var isFocused: FocusState<Bool>.Binding
    let dismiss: () -> Void
    let onOpen: (SearchDestination) -> Void
    let onRoute: (StationSearchHit, StationSearchHit) -> Void

    @State private var isKeyboardUp = false

    private static let fieldHeight: CGFloat = 48

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea([.container, .keyboard])
                .contentShape(Rectangle())
                .onTapGesture(perform: dismiss)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                CatalogSearchResultsView(
                    lines: lines,
                    searchText: searchText,
                    scope: searchScope,
                    onOpen: onOpen,
                    onRoute: onRoute
                )
                .frame(maxHeight: 420)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

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
                                .onSubmit { isFocused.wrappedValue = false }
                            if !searchText.wrappedValue.isEmpty {
                                Button {
                                    searchText.wrappedValue = ""
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

    private var bottomInset: CGFloat {
        if isKeyboardUp { return 8 }
        let safeAreaBottom = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.safeAreaInsets.bottom }
            .first ?? 0
        return min(8, 28 - safeAreaBottom)
    }
}
