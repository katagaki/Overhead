import SwiftUI
import Backbone

/// The whole app on one scrolling surface: planner, favorites, and lines to browse.
struct RootView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @ObservedObject private var customStore = CustomLineStore.shared

    @AppStorage(JourneyMode.storageKey) private var journeyMode = JourneyMode.hybrid
    @State private var showJourneySheet = false
    @State private var showTimetableModeNotice = false
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
                    CustomLinesSection(viewModel: viewModel)
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
            // Safe-area inset, not .bottomBar: late-inserted bottom-bar items don't show with a navigationDestination on the stack (iOS 26).
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
            .navigationDestination(for: CustomLineRoute.self) { route in
                CustomLineEditorView(route: route)
            }
            .task {
                await viewModel.loadLines()
            }
        }
        .sheet(isPresented: $showJourneySheet) {
            JourneySheetView(viewModel: viewModel)
                .navigationTransition(.zoom(sourceID: Self.journeyTransitionID, in: journeyZoom))
        }
        .sheet(item: $customStore.incomingPackage) { package in
            CustomLineImportView(package: package)
        }
        .onChange(of: viewModel.activeJourney != nil) { _, hasJourney in
            guard hasJourney else { showJourneySheet = false; return }
            DispatchQueue.main.async { showJourneySheet = true }
        }
        // Overwriting keeps activeJourney non-nil, so onChange won't fire — open here.
        .alert(
            "Journey.Overwrite.ConfirmTitle",
            isPresented: $viewModel.showOverwriteConfirmation
        ) {
            Button("Button.Overwrite", role: .destructive) {
                viewModel.confirmOverwrite()
                showJourneySheet = true
            }
            Button("Button.Cancel", role: .cancel) {
                viewModel.cancelOverwrite()
            }
        } message: {
            Text("Journey.Overwrite.ConfirmMessage")
        }
        // Timetable mode keeps a low-power location session so the app isn't suspended.
        .onChange(of: journeyMode) { _, newMode in
            if newMode == .timetable { showTimetableModeNotice = true }
        }
        .alert(
            "JourneyMode.TimetableNotice.Title",
            isPresented: $showTimetableModeNotice
        ) {} message: {
            Text("JourneyMode.TimetableNotice.Message")
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
