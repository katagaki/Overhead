import SwiftUI
import Backbone

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
