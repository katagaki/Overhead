import Combine
import Foundation

@MainActor
final class PrototypeTabStore: ObservableObject {
    @Published private(set) var tabs: [PrototypeTab]
    @Published private(set) var selectedTabID: UUID
    @Published private(set) var activeJourney: FauxJourney?

    private let persistenceURL: URL

    init(persistenceURL: URL? = nil) {
        self.persistenceURL = persistenceURL ?? Self.defaultPersistenceURL
        if let restored = Self.load(from: self.persistenceURL), !restored.tabs.isEmpty {
            tabs = restored.tabs
            selectedTabID = restored.tabs.contains(where: { $0.id == restored.selectedTabID })
                ? restored.selectedTabID
                : restored.tabs[0].id
            activeJourney = restored.activeJourney ?? restored.tabs.compactMap { tab in
                if case .journey(let journey) = tab.page { return journey }
                return nil
            }.first
        } else {
            let samples = Self.sampleTabs()
            tabs = samples
            selectedTabID = samples[0].id
            activeJourney = samples.compactMap { tab in
                if case .journey(let journey) = tab.page { return journey }
                return nil
            }.first
        }
    }

    var selectedTab: PrototypeTab {
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
    func add(page: PrototypePage = .planner, selecting: Bool = true) -> UUID {
        let tab = PrototypeTab(page: page)
        tabs.append(tab)
        if selecting { selectedTabID = tab.id }
        save()
        return tab.id
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

    func close(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        if tabs.count == 1 {
            let replacement = PrototypeTab(page: .planner)
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

    func closeOthers(keeping id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        tabs = [tab]
        selectedTabID = id
        save()
    }

    func move(_ draggedID: UUID, before targetID: UUID) {
        guard draggedID != targetID,
              let source = tabs.firstIndex(where: { $0.id == draggedID }),
              let target = tabs.firstIndex(where: { $0.id == targetID }) else { return }
        let moved = tabs.remove(at: source)
        let insertion = source < target ? target - 1 : target
        tabs.insert(moved, at: max(0, insertion))
        save()
    }

    func selectAdjacent(_ delta: Int) -> Bool {
        let destination = selectedIndex + delta
        guard tabs.indices.contains(destination) else { return false }
        select(tabs[destination].id)
        return true
    }

    func updateSelected(_ mutation: (inout PrototypeTab) -> Void) {
        guard let index = tabs.firstIndex(where: { $0.id == selectedTabID }) else { return }
        mutation(&tabs[index])
        tabs[index].lastViewedAt = Date()
        save()
    }

    func update(_ id: UUID, _ mutation: (inout PrototypeTab) -> Void) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        mutation(&tabs[index])
        save()
    }

    func setActiveJourney(_ journey: FauxJourney?) {
        activeJourney = journey
        save()
    }

    func reset() {
        let samples = Self.sampleTabs()
        tabs = samples
        selectedTabID = samples[0].id
        activeJourney = samples.compactMap { tab in
            if case .journey(let journey) = tab.page { return journey }
            return nil
        }.first
        save()
    }

    private func save() {
        let session = PrototypeSession(selectedTabID: selectedTabID, tabs: tabs, activeJourney: activeJourney)
        guard let data = try? JSONEncoder.prototype.encode(session) else { return }
        do {
            try FileManager.default.createDirectory(
                at: persistenceURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            assertionFailure("Could not save prototype tabs: \(error)")
        }
    }

    private static func load(from url: URL) -> PrototypeSession? {
        guard let data = try? Data(contentsOf: url),
              let session = try? JSONDecoder.prototype.decode(PrototypeSession.self, from: data),
              (1...2).contains(session.version) else { return nil }
        return session
    }

    private static var defaultPersistenceURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("OverheadTabsHarness", isDirectory: true)
            .appendingPathComponent("tabs-v1.json")
    }

    private static func sampleTabs() -> [PrototypeTab] {
        let journey = PrototypeTab(page: .journey(.sample()))
        let planner = PrototypeTab(
            page: .planner,
            planner: PlannerDraft(
                origin: "Kichijoji",
                destination: "Yokohama",
                departureOffset: 0,
                prefersFirstTrain: true,
                hasSearched: false
            )
        )
        let search = PrototypeTab(page: .search, searchQuery: "Ginza")
        return [journey, planner, search]
    }
}

private extension JSONEncoder {
    static var prototype: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var prototype: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
