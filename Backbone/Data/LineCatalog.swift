import Foundation

// MARK: - Catalog

/// What the app knows about a line it may not have downloaded.
public struct CatalogLine: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    public let folder: String
    public let nameJa: String
    public let nameEn: String
    public let operatorId: String
    public let colorHex: String
    public let isLoop: Bool
    public let symbol: String
    public let badgeStyle: String
    public let stationCount: Int
    public let bytes: Int
    public let sha256: String
    public let badgeSha256: String
    /// Lines this one runs through to.
    public let connects: [String]

    public var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "en" && !nameEn.isEmpty ? nameEn : nameJa
    }
}

/// Every station in the network, so search and 付近の駅 cover lines that are
/// not installed.
public struct CatalogStation: Decodable, Hashable, Sendable {
    public let id: String
    public let lineId: String
    public let index: Int
    public let nameJa: String
    public let nameEn: String
    public let code: String
    public let lat: Double?
    public let lon: Double?

    public var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "en" && !nameEn.isEmpty ? nameEn : nameJa
    }
}

public struct LineCatalog: Decodable, Sendable {
    public let schemaVersion: Int
    /// Release version, shown in the app.
    public let version: String
    public let styles: [String]
    public let lines: [CatalogLine]
    public let stations: [CatalogStation]

    static let empty = LineCatalog(schemaVersion: Catalog.supportedSchemaVersion,
                                   version: "none", styles: [], lines: [], stations: [])

    init(schemaVersion: Int, version: String, styles: [String],
         lines: [CatalogLine], stations: [CatalogStation]) {
        self.schemaVersion = schemaVersion
        self.version = version
        self.styles = styles
        self.lines = lines
        self.stations = stations
    }
}

public enum Catalog {

    /// A catalog claiming a newer schema is ignored rather than half-read.
    public static let supportedSchemaVersion = 1

    private static let lock = NSLock()
    private static var loaded: LineCatalog?

    public static var current: LineCatalog {
        lock.lock(); defer { lock.unlock() }
        if let loaded { return loaded }
        let catalog = load() ?? .empty
        loaded = catalog
        return catalog
    }

    private static func load() -> LineCatalog? {
        guard let data = LineDataStore.catalogData() else { return nil }
        guard let catalog = try? JSONDecoder().decode(LineCatalog.self, from: data) else { return nil }
        guard catalog.schemaVersion <= supportedSchemaVersion else { return nil }
        return catalog
    }

    public static func reload() {
        lock.lock(); loaded = nil; lock.unlock()
        indexLock.lock(); cachedIndex = nil; indexLock.unlock()
    }

    // MARK: Lookups

    private struct Index {
        let byId: [String: CatalogLine]
        let byFolder: [String: CatalogLine]
        let stationsByLine: [String: [CatalogStation]]
    }

    private static let indexLock = NSLock()
    private static var cachedIndex: Index?

    private static var index: Index {
        indexLock.lock(); defer { indexLock.unlock() }
        if let cachedIndex { return cachedIndex }
        let catalog = current
        let built = Index(
            byId: Dictionary(catalog.lines.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }),
            byFolder: Dictionary(catalog.lines.map { ($0.folder, $0) }, uniquingKeysWith: { a, _ in a }),
            stationsByLine: Dictionary(grouping: catalog.stations, by: \.lineId)
        )
        cachedIndex = built
        return built
    }

    public static func line(id: String) -> CatalogLine? { index.byId[id] }
    public static func line(folder: String) -> CatalogLine? { index.byFolder[folder] }
    public static func stations(ofLine id: String) -> [CatalogStation] {
        (index.stationsByLine[id] ?? []).sorted { $0.index < $1.index }
    }

    public static var operators: [String] {
        Array(Set(current.lines.map(\.operatorId))).sorted()
    }

    public static func lines(ofOperator operatorId: String) -> [CatalogLine] {
        current.lines.filter { $0.operatorId == operatorId }.sorted { $0.id < $1.id }
    }
}
