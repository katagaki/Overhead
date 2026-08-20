import Foundation
import SwiftUI
import Combine
import Backbone

/// Shared selection state for the onboarding and manager screens.
@MainActor
final class LineDataModel: ObservableObject {

    /// What a first run offers: the JR East urban network and the subways.
    static let baseOperators = ["Operator:JR-East", "Operator:TokyoMetro"]

    @Published var selection: Set<String> = []
    @Published var error: String?
    @Published var isWorking = false

    private let installer = LineDataInstaller.shared

    var orderedOperators: [String] {
        let present = Set(Catalog.current.lines.map(\.operatorId))
        let known = OperatorSections.order.filter { present.contains($0) }
        let rest = present.subtracting(known).sorted {
            OperatorSections.title(for: $0) < OperatorSections.title(for: $1)
        }
        return known + rest
    }

    func lines(for operatorId: String) -> [CatalogLine] {
        Catalog.lines(ofOperator: operatorId)
    }

    func isInstalled(_ line: CatalogLine) -> Bool {
        LineDataStore.isDownloaded(folder: line.folder)
    }

    /// True while the app is still running purely on the bundled seed.
    var hasAnyDownload: Bool {
        Catalog.current.lines.contains { LineDataStore.isDownloaded(folder: $0.folder) }
    }

    func selectBaseSet() {
        selection = Set(Catalog.current.lines
            .filter { Self.baseOperators.contains($0.operatorId) }
            .map(\.id))
    }

    func toggle(_ line: CatalogLine) {
        if selection.contains(line.id) { selection.remove(line.id) }
        else { selection.insert(line.id) }
    }

    func toggleOperator(_ operatorId: String) {
        let ids = lines(for: operatorId).map(\.id)
        if ids.allSatisfy(selection.contains) { ids.forEach { selection.remove($0) } }
        else { ids.forEach { selection.insert($0) } }
    }

    var selectedBytes: Int {
        Catalog.current.lines.filter { selection.contains($0.id) }.reduce(0) { $0 + $1.bytes }
    }

    static func formatted(bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    // MARK: Actions

    func install() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await installer.install(lineIds: Array(selection))
            selection = []
        } catch {
            self.error = error.localizedDescription
        }
    }

    func remove(_ line: CatalogLine) {
        do { try installer.remove(lineIds: [line.id]) }
        catch { self.error = error.localizedDescription }
    }

    func checkForUpdates() async {
        isWorking = true
        defer { isWorking = false }
        do { try await installer.refreshCatalog() }
        catch { self.error = error.localizedDescription }
    }
}
