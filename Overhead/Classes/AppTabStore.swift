import Combine
import Foundation

enum AppTabPage: Codable, Hashable {
    case home
    case search
    case destination(SearchDestination)
}

struct AppTab: Codable, Hashable, Identifiable {
    var id = UUID()
    var page: AppTabPage = .home
    var searchText = ""
    var searchScope: SearchScope = .all
    var lastViewedAt = Date()
}

private struct AppTabSession: Codable {
    var version = 1
    var selectedTabID: UUID
    var tabs: [AppTab]
}

@MainActor
final class AppTabStore: ObservableObject {
    @Published private(set) var tabs: [AppTab]
    @Published private(set) var selectedTabID: UUID

    private static let storageKey = "browser.tabs.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let session = try? JSONDecoder().decode(AppTabSession.self, from: data),
           session.version == 1,
           !session.tabs.isEmpty {
            tabs = session.tabs
            selectedTabID = session.tabs.contains(where: { $0.id == session.selectedTabID })
                ? session.selectedTabID
                : session.tabs[0].id
        } else {
            let tab = AppTab()
            tabs = [tab]
            selectedTabID = tab.id
        }
    }

    var selectedTab: AppTab {
        tabs.first(where: { $0.id == selectedTabID }) ?? tabs[0]
    }

    var selectedIndex: Int {
        tabs.firstIndex(where: { $0.id == selectedTabID }) ?? 0
    }

    func select(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[index].lastViewedAt = Date()
        selectedTabID = id
        save()
    }

    @discardableResult
    func add(page: AppTabPage = .home) -> UUID {
        let tab = AppTab(page: page)
        tabs.append(tab)
        selectedTabID = tab.id
        save()
        return tab.id
    }

    func close(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        if tabs.count == 1 {
            let replacement = AppTab()
            tabs = [replacement]
            selectedTabID = replacement.id
        } else {
            tabs.remove(at: index)
            if selectedTabID == id {
                selectedTabID = tabs[min(index, tabs.count - 1)].id
            }
        }
        save()
    }

    func duplicate(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        var copy = tabs[index]
        copy.id = UUID()
        copy.lastViewedAt = Date()
        tabs.insert(copy, at: index + 1)
        selectedTabID = copy.id
        save()
    }

    func move(_ sourceID: UUID, before targetID: UUID) {
        guard sourceID != targetID,
              let source = tabs.firstIndex(where: { $0.id == sourceID }),
              let target = tabs.firstIndex(where: { $0.id == targetID }) else { return }
        let moved = tabs.remove(at: source)
        tabs.insert(moved, at: source < target ? target - 1 : target)
        save()
    }

    @discardableResult
    func selectAdjacent(_ delta: Int) -> Bool {
        let target = selectedIndex + delta
        guard tabs.indices.contains(target) else { return false }
        select(tabs[target].id)
        return true
    }

    func updateSelected(_ mutation: (inout AppTab) -> Void) {
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabID }) else { return }
        mutation(&tabs[index])
        tabs[index].lastViewedAt = Date()
        save()
    }

    private func save() {
        let session = AppTabSession(selectedTabID: selectedTabID, tabs: tabs)
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
