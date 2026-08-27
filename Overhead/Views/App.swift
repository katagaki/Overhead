import SwiftUI
import Backbone

@main
struct OverheadApp: App {

    @StateObject private var viewModel = JourneyViewModel(previewMode: false)
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Background tasks must be registered before launch finishes, and this
        // app has no AppDelegate to do it in.
        LineDataAutoUpdater.shared.register()
    }

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
            switch phase {
            case .active:
                BoardSnapshotWriter.refresh()
            case .background:
                // The only moment a request can be submitted for a night the
                // app will not be open for.
                LineDataAutoUpdater.shared.schedule()
            default:
                break
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
