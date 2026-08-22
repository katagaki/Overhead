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
    /// Section within the operator, when it publishes more than one.
    public let segment: String?

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

/// An extra section inside an operator — JR East lists its どこトレ lines apart
/// from the urban network. Data, so a new one needs no app release.
public struct CatalogSegment: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    public let operatorId: String
    public let nameJa: String
    public let nameEn: String
    /// Position among that operator's segments.
    public let order: Int
    /// Readings and aliases, since the names are kanji/kana only.
    public let searchTerms: [String]?

    public var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        return lang == "en" && !nameEn.isEmpty ? nameEn : nameJa
    }
}

/// An operator's name, ordering, and search aliases. Data, so a new
/// company needs no app release.
public struct CatalogOperator: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    public let nameJa: String
    public let nameEn: String
    /// Position among the operator sections.
    public let order: Int
    /// Readings and aliases, since the names are kanji/kana only.
    public let searchTerms: [String]?
    /// Logo-mark colour, when it differs from the lines' route colours.
    public let brandColorHex: String?
    /// Official website, the source for the operator's favicon.
    public let website: String?

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
    /// Curated operator marks, for operators whose sites have no usable
    /// favicon. Optional: catalogs published before the icons existed omit it.
    public let operatorIcons: [String]?
    /// Where this catalog's line files live under the repository root. Empty
    /// for the current generation; a snapshot frozen for older apps sets it.
    public let dataPath: String?
    /// Optional: catalogs published before segments existed omit the key.
    public let segments: [CatalogSegment]?
    /// Optional: catalogs published before operator data existed omit the key.
    public let operators: [CatalogOperator]?
    public let lines: [CatalogLine]
    public let stations: [CatalogStation]

    static let empty = LineCatalog(schemaVersion: Catalog.supportedSchemaVersion,
                                   version: "none", styles: [], segments: [],
                                   operators: [], lines: [], stations: [])

    init(schemaVersion: Int, version: String, styles: [String], segments: [CatalogSegment],
         operators: [CatalogOperator], lines: [CatalogLine], stations: [CatalogStation]) {
        self.dataPath = nil
        self.segments = segments
        self.operators = operators
        self.schemaVersion = schemaVersion
        self.version = version
        self.styles = styles
        self.operatorIcons = []
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
        if let data = LineDataStore.catalogData(), let catalog = decode(data) { return catalog }
        // An installed catalog this build cannot read — a newer schema, or a
        // truncated file — must not leave the app with no network at all: the
        // bundled seed is always readable by the build that shipped it.
        if let seed = LineDataStore.bundledCatalogData(), let catalog = decode(seed) { return catalog }
        return nil
    }

    private static func decode(_ data: Data) -> LineCatalog? {
        guard let catalog = try? JSONDecoder().decode(LineCatalog.self, from: data) else { return nil }
        guard catalog.schemaVersion <= supportedSchemaVersion else { return nil }
        return catalog
    }

    /// The installed copy was written for an older schema, so the app has
    /// moved past its own data and the catalog has to come down again.
    public static var needsSchemaUpgrade: Bool {
        current.schemaVersion < supportedSchemaVersion
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

    /// Prefix for line downloads, so an app pinned to an older generation
    /// keeps fetching the snapshot its catalog describes.
    public static var dataPath: String { current.dataPath ?? "" }

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

    // MARK: Operators

    /// Operator data, in section order. Empty for catalogs published before
    /// operators moved into the data.
    public static var catalogOperators: [CatalogOperator] {
        (current.operators ?? []).sorted { $0.order < $1.order }
    }

    public static func operatorInfo(id: String) -> CatalogOperator? {
        current.operators?.first { $0.id == id }
    }

    // MARK: Segments

    public static var segments: [CatalogSegment] { current.segments ?? [] }

    public static func segment(id: String) -> CatalogSegment? {
        segments.first { $0.id == id }
    }

    /// That operator's extra sections, in the order the data gives them.
    public static func segments(ofOperator operatorId: String) -> [CatalogSegment] {
        segments.filter { $0.operatorId == operatorId }.sorted { $0.order < $1.order }
    }
}
