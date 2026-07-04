import SwiftUI
import Backbone

// MARK: - App Entry Point

@main
struct OverheadApp: App {

    @StateObject private var viewModel = JourneyViewModel(previewMode: false)

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "overhead" else { return }

        switch url.host {
        case "refresh-delay":
            viewModel.forceRefresh()
        default:
            break
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var selectedTab: Tab = .journey

    enum Tab: Hashable {
        case journey
        case routes
        case lines
        case more
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Group {
                if viewModel.activeJourney != nil {
                    JourneyView(viewModel: viewModel)
                } else {
                    JourneySetupView(viewModel: viewModel)
                }
            }
            .tabItem {
                Image(systemName: "tram.fill")
                Text("Tab.Journey")
            }
            .tag(Tab.journey)

            RoutesView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Tab.Routes")
                }
                .tag(Tab.routes)

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
        .tint(viewModel.selectedLine?.color ?? Color.accentColor)
        .onChange(of: viewModel.activeJourney != nil) { _, hasJourney in
            if hasJourney {
                selectedTab = .journey
            }
        }
    }
}

// MARK: - View Path

enum ViewPath: Hashable {
    case attributions
}

// MARK: - More View

struct MoreView: View {
    @ObservedObject var viewModel: JourneyViewModel

    @AppStorage("showEnglish") private var showEnglish = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Settings.Section.Display") {
                    Toggle("Settings.Toggle.ShowEnglish", isOn: $showEnglish)
                }

                if viewModel.activeJourney != nil {
                    Section("Settings.Section.CurrentJourney") {
                        Button(role: .destructive) {
                            viewModel.stopJourney()
                        } label: {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Button.EndJourney")
                            }
                        }
                    }
                }

                Section("Settings.Section.Demo") {
                    Toggle("Settings.Toggle.DemoMode", isOn: Binding(
                        get: { viewModel.isDemoMode },
                        set: { newValue in
                            if newValue {
                                viewModel.startDemoMode()
                            } else {
                                viewModel.stopDemoMode()
                            }
                        }
                    ))

                    if viewModel.isDemoMode {
                        Text("Settings.Label.RunningSimulation")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }

                Section {
                    Link(destination: URL(string: "https://github.com/katagaki/Overhead")!) {
                        HStack {
                            Text(String(localized: "More.GitHub"))
                            Spacer()
                            Text("katagaki/Overhead")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                    NavigationLink("More.Attributions", value: ViewPath.attributions)
                }
            }
            .navigationTitle("ViewTitle.More")
            .navigationDestination(for: ViewPath.self) { path in
                switch path {
                case .attributions:
                    MoreAttributionsView()
                }
            }
        }
    }
}

// MARK: - Attributions View

struct MoreAttributionsView: View {
    var body: some View {
        List {
            Section {
                Text("More.Attributions.Placeholder")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("More.Attributions")
    }
}
