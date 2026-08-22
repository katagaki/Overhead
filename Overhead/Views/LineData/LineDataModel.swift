import Foundation
import SwiftUI
import Combine
import Backbone

/// Shared plumbing for the first-run and manager screens. The app carries the
/// whole catalog, so there is nothing to select — only work to start.
@MainActor
final class LineDataModel: ObservableObject {

    @Published var error: String?

    private let installer = LineDataInstaller.shared

    static func formatted(bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    // MARK: Actions

    func download() async {
        do { try await installer.sync() }
        catch { self.error = error.localizedDescription }
    }

    /// A schema change makes the installed catalog unusable, so the catalog
    /// itself is refetched before the lines it now describes.
    func upgrade() async {
        do {
            try await installer.refreshCatalog(force: true)
            try await installer.sync()
        } catch { self.error = error.localizedDescription }
    }

    /// Wipes the downloaded data and the marks derived from it, leaving the
    /// app as it was before its first download.
    func deleteAllData() async {
        await installer.removeAllData()
        OperatorFavicons.shared.reset()
    }

    func checkForUpdates() async {
        do { try await installer.refreshCatalog() }
        catch { self.error = error.localizedDescription }
    }
}
