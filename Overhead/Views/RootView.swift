import SwiftUI
import Backbone

struct RootView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var selectedTab: Tab = .journey
    @State private var showJourneySheet = false

    enum Tab: Hashable {
        case journey
        case places
        case lines
        case more
    }

    var body: some View {
        Group {
            if #available(iOS 26.0, *), viewModel.activeJourney != nil {
                tabView
                    .tabViewBottomAccessory {
                        JourneyBottomAccessory(viewModel: viewModel) {
                            showJourneySheet = true
                        }
                    }
                    .tabBarMinimizeBehavior(.onScrollDown)
            } else {
                tabView
            }
        }
        .tint(viewModel.selectedLine?.color ?? Color.accentColor)
        .sheet(isPresented: $showJourneySheet) {
            JourneySheetView(viewModel: viewModel)
        }
        .onChange(of: viewModel.activeJourney != nil) { _, hasJourney in
            if #available(iOS 26.0, *) {
                // The journey lives in a sheet; dismissing it minimizes the
                // journey into the tab bar bottom accessory.
                showJourneySheet = hasJourney
            } else if hasJourney {
                selectedTab = .journey
            } else {
                showJourneySheet = false
            }
        }
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            journeyTabContent
                .tabItem {
                    Image(systemName: "tram.fill")
                    Text("Tab.Journey")
                }
                .tag(Tab.journey)

            PlacesView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Tab.Places")
                }
                .tag(Tab.places)

            LinePickerView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "map")
                    Text("Tab.Lines")
                }
                .tag(Tab.lines)

            MoreView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("Tab.More")
                }
                .tag(Tab.more)
        }
    }

    @ViewBuilder
    private var journeyTabContent: some View {
        if #available(iOS 26.0, *) {
            JourneySetupView(viewModel: viewModel)
        } else if viewModel.activeJourney != nil {
            // Pre-26 fallback: no bottom accessory, so keep the journey inline.
            JourneyView(viewModel: viewModel)
        } else {
            JourneySetupView(viewModel: viewModel)
        }
    }
}
