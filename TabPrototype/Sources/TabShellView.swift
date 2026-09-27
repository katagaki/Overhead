import SwiftUI
import UniformTypeIdentifiers

struct TabShellView: View {
    @ObservedObject var store: PrototypeTabStore
    @State private var showsOverview = false
    @State private var showsJourneySheet = false
    @State private var transitionEdge: Edge = .trailing
    @State private var availableWidth: CGFloat = 0
    @FocusState private var searchIsFocused: Bool
    @Namespace private var tabTransition

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if showsOverview {
                TabOverviewView(store: store, namespace: tabTransition) {
                    withAnimation(.smooth(duration: 0.36)) { showsOverview = false }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.03)))
            } else {
                selectedWorkspace
                    .id(store.selectedTabID)
                    .transition(.asymmetric(
                        insertion: .move(edge: transitionEdge).combined(with: .opacity),
                        removal: .move(edge: transitionEdge == .trailing ? .leading : .trailing)
                            .combined(with: .opacity)
                    ))
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
        .sheet(isPresented: $showsJourneySheet) {
            if let journey = store.activeJourney {
                FauxJourneySheet(journey: journey)
            }
        }
    }

    private var selectedWorkspace: some View {
        NavigationStack {
            Group {
                switch store.selectedTab.page {
                case .planner:
                    FauxPlannerView(store: store)
                case .search:
                    FauxSearchView(store: store)
                case .journey(let journey):
                    FauxJourneyView(journey: journey)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.updateSelected { $0.page = .planner }
                    } label: {
                        Image(systemName: "house")
                    }
                    .accessibilityLabel("Journey planner")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Duplicate Tab", systemImage: "plus.square.on.square") {
                            store.duplicate(store.selectedTabID)
                        }
                        Button("Reset Prototype", systemImage: "arrow.counterclockwise") {
                            store.reset()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }

                if let journey = store.activeJourney {
                    ToolbarItem(placement: .bottomBar) {
                        JourneyStationBadgeButton(journey: journey) {
                            showsJourneySheet = true
                        }
                    }

                    ToolbarSpacer(.fixed, placement: .bottomBar)
                }

                ToolbarItem(placement: .bottomBar) {
                    ToolbarAddressBar(
                        store: store,
                        isFocused: $searchIsFocused,
                        namespace: tabTransition,
                        onSwipe: switchTab
                    )
                    .frame(width: addressBarWidth)
                }

                ToolbarSpacer(.fixed, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        withAnimation(.smooth(duration: 0.36)) { showsOverview = true }
                    } label: {
                        Image(systemName: "square.on.square")
                    }
                    .accessibilityLabel("Show \(store.tabs.count) tabs")
                }
            }
        }
    }

    private var addressBarWidth: CGFloat {
        let reservedWidth: CGFloat = store.activeJourney == nil ? 152 : 208
        return min(max(availableWidth - reservedWidth, 170), 520)
    }

    private func switchTab(_ delta: Int) {
        transitionEdge = delta > 0 ? .trailing : .leading
        withAnimation(.smooth(duration: 0.3)) {
            _ = store.selectAdjacent(delta)
        }
    }
}

private struct JourneyStationBadgeButton: View {
    let journey: FauxJourney
    let action: () -> Void

    var body: some View {
        let now = Date()
        let nextIndex = min(journey.currentStopIndex(at: now) + 1, journey.stops.count - 1)
        Button(action: action) {
            VStack(spacing: -2) {
                Text(journey.lineSymbol)
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                Text("\(nextIndex + 1)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(journey.color, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open journey. Next stop: \(journey.nextStop(at: now))")
    }
}

private struct ToolbarAddressBar: View {
    @ObservedObject var store: PrototypeTabStore
    var isFocused: FocusState<Bool>.Binding
    let namespace: Namespace.ID
    let onSwipe: (Int) -> Void

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        Group {
            if case .search = store.selectedTab.page {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Stations, operators, or lines", text: queryBinding)
                        .textFieldStyle(.plain)
                        .focused(isFocused)
                        .submitLabel(.search)
                    if !store.selectedTab.searchQuery.isEmpty {
                        Button {
                            store.updateSelected { $0.searchQuery = "" }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
            } else {
                Button {
                    store.updateSelected { $0.page = .search }
                    DispatchQueue.main.async { isFocused.wrappedValue = true }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        Text("Search stations, operators, and lines")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .contentShape(.capsule)
                }
            }
        }
        .offset(x: dragOffset * 0.12)
        .simultaneousGesture(tabSwipe)
        .matchedTransitionSource(id: store.selectedTabID, in: namespace)
    }

    private var queryBinding: Binding<String> {
        Binding(get: { store.selectedTab.searchQuery }, set: { value in
            store.updateSelected { $0.searchQuery = value }
        })
    }

    private var tabSwipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($dragOffset) { value, state, _ in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                state = value.translation.width
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) * 1.25 else { return }
                let projected = value.predictedEndTranslation.width
                guard abs(projected) > 60 else { return }
                onSwipe(projected < 0 ? 1 : -1)
            }
    }

}

private struct FauxJourneySheet: View {
    let journey: FauxJourney
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FauxJourneyView(journey: journey)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .presentationDragIndicator(.visible)
    }
}

private struct TabOverviewView: View {
    @ObservedObject var store: PrototypeTabStore
    let namespace: Namespace.ID
    let dismiss: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: horizontalSizeClass == .regular ? 3 : 2)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(store.tabs) { tab in
                        tabCard(tab)
                            .draggable(tab.id.uuidString)
                            .dropDestination(for: String.self) { items, _ in
                                guard let raw = items.first, let sourceID = UUID(uuidString: raw) else { return false }
                                withAnimation(.smooth) { store.move(sourceID, before: tab.id) }
                                return true
                            }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(store.tabs.count) Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        _ = store.add()
                        dismiss()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New tab")
                }

                ToolbarSpacer(.flexible, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Text("Journey Tabs").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                }

                ToolbarSpacer(.flexible, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Button("Done", action: dismiss)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func tabCard(_ tab: PrototypeTab) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: tab.systemImage).foregroundStyle(tab.accent)
                Text(tab.title).font(.caption.weight(.semibold)).lineLimit(1)
                Spacer(minLength: 0)
                Button {
                    withAnimation(.smooth) { store.close(tab.id) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .frame(width: 26, height: 26)
                        .background(.quaternary, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close \(tab.title)")
            }
            .padding(.horizontal, 10)
            .frame(height: 42)

            TabThumbnail(tab: tab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        .aspectRatio(0.68, contentMode: .fit)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    tab.id == store.selectedTabID ? tab.accent : Color(.separator).opacity(0.45),
                    lineWidth: tab.id == store.selectedTabID ? 3 : 1
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            store.select(tab.id)
            dismiss()
        }
        .contextMenu {
            Button("Duplicate", systemImage: "plus.square.on.square") { store.duplicate(tab.id) }
            Button("Close Other Tabs", systemImage: "xmark.square") { store.closeOthers(keeping: tab.id) }
            Button("Close", systemImage: "xmark", role: .destructive) { store.close(tab.id) }
        }
        .matchedTransitionSource(id: tab.id, in: namespace)
    }
}

private struct TabThumbnail: View {
    let tab: PrototypeTab

    var body: some View {
        ZStack {
            Color(.systemBackground)
            switch tab.page {
            case .planner:
                VStack(spacing: 10) {
                    thumbnailHeader("Plan a journey", "arrow.triangle.swap")
                    miniatureField(tab.planner.origin)
                    miniatureField(tab.planner.destination)
                    Capsule().fill(.indigo).frame(height: 24).padding(.horizontal, 16)
                    Spacer()
                }
                .padding(.top, 18)
            case .search:
                VStack(spacing: 10) {
                    thumbnailHeader("Search", "magnifyingglass")
                    miniatureField(tab.searchQuery.isEmpty ? "Station or line" : tab.searchQuery)
                    ForEach(0..<3, id: \.self) { index in
                        HStack {
                            Circle().fill(index == 0 ? .orange : .blue).frame(width: 18, height: 18)
                            RoundedRectangle(cornerRadius: 3).fill(.quaternary).frame(height: 9)
                        }
                        .padding(.horizontal, 16)
                    }
                    Spacer()
                }
                .padding(.top, 18)
            case .journey(let journey):
                VStack(spacing: 12) {
                    Text(journey.lineSymbol)
                        .font(.title2.bold()).foregroundStyle(.white)
                        .frame(width: 46, height: 46).background(journey.color, in: Circle())
                    Text(journey.destination).font(.headline).lineLimit(1)
                    Capsule().fill(journey.color.opacity(0.25)).frame(width: 5)
                        .overlay(alignment: .top) {
                            VStack(spacing: 22) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Circle().fill(journey.color).frame(width: 10, height: 10)
                                }
                            }
                        }
                    Spacer()
                }
                .padding(.top, 20)
            }
        }
    }

    private func thumbnailHeader(_ title: String, _ icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title).font(.caption.bold()).lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private func miniatureField(_ text: String) -> some View {
        HStack {
            Circle().fill(.indigo).frame(width: 7, height: 7)
            Text(text).font(.caption2).lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
        .padding(.horizontal, 16)
    }
}
