import SwiftUI
import Backbone

/// The whole app on one scrolling surface: the journey planner up top, saved
/// favorites below it, then every train line to browse. Settings and the
/// end-journey action live in the top-trailing More menu, and an active
/// journey minimizes into a custom accessory in the bottom toolbar.
struct RootView: View {
    @ObservedObject var viewModel: JourneyViewModel

    @AppStorage(JourneyMode.storageKey) private var journeyMode = JourneyMode.hybrid
    @State private var showJourneySheet = false
    @State private var navigationPath = NavigationPath()
    @Namespace private var journeyZoom

    private static let journeyTransitionID = "activeJourney"

    // Pushed screens reachable from the root.
    private enum Destination: Hashable {
        case attributions
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    JourneyPlannerSection(viewModel: viewModel)
                    FavoritesSection(viewModel: viewModel)
                    LinesSection(viewModel: viewModel)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text(verbatim: "Overhead"))
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    moreMenu
                }
            }
            // The journey accessory lives in a bottom safe-area inset, NOT a
            // .bottomBar toolbar item: with any navigationDestination on this
            // stack, a bottom-bar item inserted after the initial render
            // (like this one, appearing when a journey starts) never shows
            // up (iOS 26). The inset + glass capsule replicates the look.
            .safeAreaInset(edge: .bottom) {
                if viewModel.activeJourney != nil {
                    JourneyToolbarAccessory(viewModel: viewModel) {
                        showJourneySheet = true
                    }
                    .padding(.vertical, 12)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    .matchedTransitionSource(id: Self.journeyTransitionID, in: journeyZoom)
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .attributions:
                    MoreAttributionsView()
                }
            }
            .task {
                await viewModel.loadLines()
            }
        }
        // The app keeps its own purple accent (AccentColor, matching the app
        // icon) everywhere — the selected line's color is deliberately NOT
        // used as a global tint; line colors appear only in line-specific UI.
        .sheet(isPresented: $showJourneySheet) {
            JourneySheetView(viewModel: viewModel)
                .navigationTransition(.zoom(sourceID: Self.journeyTransitionID, in: journeyZoom))
        }
        .onChange(of: viewModel.activeJourney != nil) { _, hasJourney in
            // The journey lives in a sheet; dismissing it minimizes the
            // journey into the bottom toolbar accessory.
            showJourneySheet = hasJourney
        }
    }

    // MARK: - More Menu

    private var moreMenu: some View {
        Menu {
            Section("Settings.Section.JourneyMode") {
                Picker("Settings.Section.JourneyMode", selection: $journeyMode) {
                    ForEach(JourneyMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            }
            .labelsVisibility(.visible)

            if viewModel.activeJourney != nil {
                Section("Settings.Section.CurrentJourney") {
                    Button(role: .destructive) {
                        viewModel.stopJourney()
                    } label: {
                        Label("Button.EndJourney", systemImage: "stop.circle.fill")
                    }
                }
            }

            Section {
                Link(destination: URL(string: "https://github.com/katagaki/Overhead")!) {
                    Label("More.GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Button {
                    navigationPath.append(Destination.attributions)
                } label: {
                    Label("More.Attributions", systemImage: "info.circle")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel("ViewTitle.More")
    }
}
