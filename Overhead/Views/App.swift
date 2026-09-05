import SwiftUI
import Backbone

@main
struct OverheadApp: App {

    @StateObject private var viewModel = JourneyViewModel(previewMode: false)
    @Environment(\.scenePhase) private var scenePhase
    /// overhead://trackChange — which branch of the data repository to follow.
    @State private var showBranchAlert = false
    @State private var branchField = ""

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
                .alert("Data branch", isPresented: $showBranchAlert) {
                    TextField(LineDataInstaller.defaultBranch, text: $branchField)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Set branch") {
                        LineDataInstaller.shared.switchBranch(to: branchField)
                    }
                    Button("Reset to main") {
                        LineDataInstaller.shared.switchBranch(to: LineDataInstaller.defaultBranch)
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Train data is downloaded from the \(LineDataInstaller.branch) "
                         + "branch of OverheadData. Changing it clears the installed data "
                         + "and downloads the new branch.")
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

        // Foundation may normalise the host's case; match on the lowered form.
        switch url.host?.lowercased() {
        case "refresh-delay":
            viewModel.forceRefresh()
        case "trackchange":
            branchField = LineDataInstaller.branch
            showBranchAlert = true
        default:
            break
        }
    }
}
