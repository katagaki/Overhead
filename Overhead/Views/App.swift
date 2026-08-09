import SwiftUI
import Backbone

@main
struct OverheadApp: App {

    @StateObject private var viewModel = JourneyViewModel(previewMode: false)
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: SavedPlaceStore.didChangeNotification
                )) { _ in
                    BoardSnapshotWriter.refresh()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                BoardSnapshotWriter.refresh()
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        if url.isFileURL {
            if url.pathExtension.lowercased() == "ohl" {
                CustomLineStore.shared.receiveFile(at: url)
            }
            return
        }

        guard url.scheme == "overhead" else { return }

        switch url.host {
        case "refresh-delay":
            viewModel.forceRefresh()
        default:
            break
        }
    }
}
