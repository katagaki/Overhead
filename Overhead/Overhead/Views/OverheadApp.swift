import SwiftUI

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

    /// Handle deep links from Live Activity buttons
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "overhead" else { return }

        switch url.host {
        case "refresh-delay":
            // Force refresh delay data and recalculate position
            Task {
                await viewModel.forceRefreshDelay()
            }
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
            // Journey tab
            Group {
                if viewModel.activeJourney != nil {
                    JourneyView(viewModel: viewModel)
                } else {
                    NoJourneyView {
                        selectedTab = .lines
                    }
                }
            }
            .tabItem {
                Image(systemName: "tram.fill")
                Text("Tab.Journey")
            }
            .tag(Tab.journey)

            // Routes tab
            RoutesView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Tab.Routes")
                }
                .tag(Tab.routes)

            // Lines tab
            LinePickerView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "map")
                    Text("Tab.Lines")
                }
                .tag(Tab.lines)

            // More
            MoreView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("Tab.More")
                }
                .tag(Tab.more)
        }
        .tint(viewModel.selectedLine?.color ?? .blue)
        .onChange(of: viewModel.activeJourney != nil) { _, hasJourney in
            if hasJourney {
                selectedTab = .journey
            }
        }
    }
}

// MARK: - No Journey View

struct NoJourneyView: View {
    let onSelectLine: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "tram.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }

            VStack(spacing: 8) {
                Text("App.Title")
                    .font(.system(size: 28, weight: .bold))

                Text("App.Subtitle")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }

            Text("Onboarding.Description")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                onSelectLine()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Button.StartJourney")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 48)

            Spacer()
            Spacer()
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
    @AppStorage("pollingInterval") private var pollingInterval = 30.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Settings.Section.Display") {
                    Toggle("Settings.Toggle.ShowEnglish", isOn: $showEnglish)

                    VStack(alignment: .leading) {
                        Text("Settings.Label.PollingInterval")
                        Slider(value: $pollingInterval, in: 10...120, step: 10)
                        Text("Settings.Unit.Seconds \(Int(pollingInterval))")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
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

                Section("Settings.Section.About") {
                    HStack {
                        Text("Settings.Label.DataProvider")
                        Spacer()
                        Text("Settings.Label.ODPTCenter")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
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
