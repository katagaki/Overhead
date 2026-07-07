import SwiftUI

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
