import EnhancedNavigation
import Foundation

nonisolated enum AppTabPage: Hashable, Codable, TabRoot {
    // Keep former tab roots decodable when restoring saved sessions.
    case home
    case search
    case destination(SearchDestination)

    static var newTabRoot: Self { .home }

    var persistenceToken: String {
        guard let data = try? JSONEncoder().encode(self) else { return "home" }
        return data.base64EncodedString()
    }

    init?(persistenceToken: String) {
        guard let data = Data(base64Encoded: persistenceToken),
              let page = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = page
    }
}

nonisolated struct AppTabIdentity: TabPageIdentity {
    var title: String
    var symbolName: String
    var pathToken: AppPathToken?

    private enum CodingKeys: String, CodingKey {
        case title, symbolName, pathToken
    }

    init(title: String, symbolName: String, pathToken: AppPathToken?) {
        self.title = title
        self.symbolName = symbolName
        self.pathToken = pathToken
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        symbolName = try values.decode(String.self, forKey: .symbolName)
        if let token = try? values.decode(AppPathToken.self, forKey: .pathToken) {
            pathToken = token
        } else if let legacy = try? values.decode(SearchDestination.self, forKey: .pathToken) {
            pathToken = .search(legacy)
        } else {
            pathToken = nil
        }
    }

    func names(_ other: Self) -> Bool {
        if let pathToken, let otherToken = other.pathToken { return pathToken == otherToken }
        return title == other.title
    }
}

nonisolated enum AppPathToken: Hashable, Codable {
    case search(SearchDestination)
    case menu(AppMenuDestination)
    case customLine(CustomLineRoute)
    case journey(UUID)
}

/// The journey in progress, as a page in the tab that started it.
nonisolated struct JourneyDestination: Hashable, Codable {
    let sessionID: UUID
}

nonisolated enum AppMenuDestination: String, Hashable, Codable {
    case attributions
    case lineData
}

typealias AppNavigationStore = TabNavigationStore<AppTabPage, AppTabIdentity>

struct AppTabSearchState: Codable {
    var text = ""
    var scope: SearchScope = .all
}

enum AppTabSessionMigration {
    private struct LegacyTab: Decodable {
        let id: UUID
        let page: AppTabPage
        let searchText: String
        let searchScope: SearchScope
    }

    private struct LegacySession: Decodable {
        let selectedTabID: UUID
        let tabs: [LegacyTab]
    }

    static func makeStore() -> AppNavigationStore {
        let configuration = TabStoreConfiguration(
            persistenceKeyPrefix: "Overhead.Navigation",
            snapshotDirectoryName: "OverheadTabSnapshots"
        )
        if UserDefaults.standard.stringArray(forKey: "Overhead.Navigation.TabTokens") != nil {
            let store = AppNavigationStore.restored(configuration: configuration)
            let oldSearchTabs = store.tabs.filter { $0.root == .search }
            for tab in oldSearchTabs {
                store.updateTab(tab.id) { $0.root = .home }
            }
            if !oldSearchTabs.isEmpty { store.persistTabs() }
            AppTabPlannerSetupStorage.migrateGlobalSetup(to: store.selectedTabID)
            return store
        }
        guard let data = UserDefaults.standard.data(forKey: "browser.tabs.v1"),
              let session = try? JSONDecoder().decode(LegacySession.self, from: data),
              !session.tabs.isEmpty else {
            return .restored(configuration: configuration)
        }
        let tabs = session.tabs.map {
            NavigationTab<AppTabPage, AppTabIdentity>(
                id: $0.id,
                root: $0.page == .search ? .home : $0.page
            )
        }
        let searchStates = Dictionary(uniqueKeysWithValues: session.tabs.map {
            ($0.id, AppTabSearchState(text: $0.searchText, scope: $0.searchScope))
        })
        AppTabSearchStateStorage.save(searchStates)
        let store = AppNavigationStore(configuration: configuration, tabs: tabs, selectedTabID: session.selectedTabID)
        store.persistTabs()
        AppTabPlannerSetupStorage.migrateGlobalSetup(to: store.selectedTabID)
        return store
    }
}

enum AppTabSearchStateStorage {
    private static let key = "Overhead.Navigation.SearchStates"

    static func load() -> [UUID: AppTabSearchState] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let states = try? JSONDecoder().decode([UUID: AppTabSearchState].self, from: data)
        else { return [:] }
        return states
    }

    static func save(_ states: [UUID: AppTabSearchState]) {
        guard let data = try? JSONEncoder().encode(states) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

/// Each tab keeps its own planner From/Via/To.
enum AppTabPlannerSetupStorage {
    private static let key = "Overhead.Navigation.PlannerSetups"
    private static let globalKey = "journey.setup.stations"

    static func load() -> [UUID: String] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let setups = try? JSONDecoder().decode([UUID: String].self, from: data)
        else { return [:] }
        return setups
    }

    static func setup(for tabID: UUID) -> String? {
        load()[tabID]
    }

    static func save(_ setup: String?, for tabID: UUID) {
        var setups = load()
        setups[tabID] = setup
        write(setups)
    }

    static func prune(keeping tabIDs: Set<UUID>) {
        let setups = load()
        let kept = setups.filter { tabIDs.contains($0.key) }
        if kept.count != setups.count { write(kept) }
    }

    static func removeAll() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: globalKey)
    }

    /// The setup used to be shared by every tab; it goes to the tab in front.
    static func migrateGlobalSetup(to tabID: UUID) {
        guard let json = UserDefaults.standard.string(forKey: globalKey) else { return }
        if !json.isEmpty, setup(for: tabID) == nil { save(json, for: tabID) }
        UserDefaults.standard.removeObject(forKey: globalKey)
    }

    private static func write(_ setups: [UUID: String]) {
        guard let data = try? JSONEncoder().encode(setups) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
