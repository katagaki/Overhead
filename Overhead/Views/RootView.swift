import SwiftUI
import Backbone

/// The whole app on one scrolling surface: the journey planner up top, saved
/// favorites below it, then every train line to browse. Settings and the
/// end-journey action live in the top-trailing More menu, and an active
/// journey minimizes into a custom accessory in the bottom toolbar.
struct RootView: View {
    @ObservedObject var viewModel: JourneyViewModel

    @AppStorage("showEnglish") private var showEnglish = true
    @State private var showJourneySheet = false
    @State private var showAttributions = false
    @Namespace private var journeyZoom

    private static let journeyTransitionID = "activeJourney"

    var body: some View {
        NavigationStack {
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
                if viewModel.activeJourney != nil {
                    ToolbarItem(placement: .bottomBar) {
                        JourneyToolbarAccessory(viewModel: viewModel) {
                            showJourneySheet = true
                        }
                        .matchedTransitionSource(id: Self.journeyTransitionID, in: journeyZoom)
                    }
                }
            }
            .navigationDestination(isPresented: $showAttributions) {
                MoreAttributionsView()
            }
            .task {
                await viewModel.loadLines()
            }
        }
        .tint(viewModel.selectedLine?.color ?? Color.accentColor)
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
            Toggle("Settings.Toggle.ShowEnglish", isOn: $showEnglish)

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
                    showAttributions = true
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
