import SwiftUI

// MARK: - App Entry Point

@main
struct OverheadApp: App {

    @StateObject private var viewModel = JourneyViewModel(previewMode: false)

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
                .preferredColorScheme(.dark)  // Train LCDs are dark-themed
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    /// Handle deep links from Live Activity buttons
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tokyorail" else { return }

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
        case lines
        case settings
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
                Text("\u{65C5}\u{7A0B}")
            }
            .tag(Tab.journey)

            // Lines tab
            LinePickerView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "map")
                    Text("\u{8DEF}\u{7DDA}")
                }
                .tag(Tab.lines)

            // Settings
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("\u{8A2D}\u{5B9A}")
                }
                .tag(Tab.settings)
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
                Text("\u{6771}\u{4EAC}\u{30EC}\u{30FC}\u{30EB}")
                    .font(.system(size: 28, weight: .bold))

                Text("Tokyo Rail Tracker")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }

            Text("\u{8DEF}\u{7DDA}\u{3068}\u{99C5}\u{3092}\u{9078}\u{3093}\u{3067}\u{3001}\u{30EA}\u{30A2}\u{30EB}\u{30BF}\u{30A4}\u{30E0}\u{3067}\n\u{65C5}\u{7A0B}\u{3092}\u{8FFD}\u{8DE1}\u{3057}\u{307E}\u{3057}\u{3087}\u{3046}")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                onSelectLine()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("\u{65C5}\u{7A0B}\u{3092}\u{958B}\u{59CB} / Start Journey")
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

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: JourneyViewModel

    @AppStorage("odptConsumerKey") private var consumerKey = ""
    @AppStorage("showEnglish") private var showEnglish = true
    @AppStorage("pollingInterval") private var pollingInterval = 30.0

    var body: some View {
        NavigationStack {
            Form {
                Section("ODPT API") {
                    SecureField("Consumer Key", text: $consumerKey)
                        .font(.system(.body, design: .monospaced))

                    Link("\u{958B}\u{767A}\u{8005}\u{767B}\u{9332} / Register", destination: URL(string: "https://developer-dc.odpt.org/")!)
                }

                Section("\u{8868}\u{793A} / Display") {
                    Toggle("\u{82F1}\u{8A9E}\u{540D}\u{3092}\u{8868}\u{793A} / Show English", isOn: $showEnglish)

                    VStack(alignment: .leading) {
                        Text("\u{66F4}\u{65B0}\u{9593}\u{9694} / Polling Interval")
                        Slider(value: $pollingInterval, in: 10...120, step: 10)
                        Text("\(Int(pollingInterval))\u{79D2}")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                if viewModel.activeJourney != nil {
                    Section("\u{73FE}\u{5728}\u{306E}\u{65C5}\u{7A0B} / Current Journey") {
                        Button(role: .destructive) {
                            viewModel.stopJourney()
                        } label: {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("\u{65C5}\u{7A0B}\u{3092}\u{7D42}\u{4E86} / End Journey")
                            }
                        }
                    }
                }

                Section("\u{60C5}\u{5831} / About") {
                    HStack {
                        Text("\u{30C7}\u{30FC}\u{30BF}\u{63D0}\u{4F9B}")
                        Spacer()
                        Text("\u{516C}\u{5171}\u{4EA4}\u{901A}\u{30AA}\u{30FC}\u{30D7}\u{30F3}\u{30C7}\u{30FC}\u{30BF}\u{30BB}\u{30F3}\u{30BF}\u{30FC}")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("\u{8A2D}\u{5B9A}")
        }
    }
}
