import Foundation
import CryptoKit
import Combine

public enum LineDataError: LocalizedError {
    case notInCatalog(String)
    case badResponse(Int)
    case checksumMismatch(String)
    case schemaTooNew(Int)

    public var errorDescription: String? {
        switch self {
        case .notInCatalog(let id): return "\(id) is not in the catalog"
        case .badResponse(let code): return "Server returned \(code)"
        case .checksumMismatch(let file): return "\(file) did not match its checksum"
        case .schemaTooNew(let v): return "Data format \(v) is newer than this app understands"
        }
    }
}

/// Downloads line data and installs it beside the bundled seed.
@MainActor
public final class LineDataInstaller: ObservableObject {

    public static let shared = LineDataInstaller()

    /// Root of the published data repository.
    public static var baseURL = URL(string: "https://raw.githubusercontent.com/katagaki/OverheadData/main/")!

    @Published public private(set) var inFlight: Set<String> = []
    @Published public private(set) var lastChecked: Date?
    @Published public private(set) var staleLineIds: Set<String> = []

    private let defaults = UserDefaults.standard
    private let etagKey = "lineData.catalogETag"
    private let checkedKey = "lineData.lastChecked"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        lastChecked = defaults.object(forKey: checkedKey) as? Date
    }

    public var isBusy: Bool { !inFlight.isEmpty }

    // MARK: - Update check

    /// One conditional GET. A 304 costs a few hundred bytes and means there is
    /// nothing to do.
    @discardableResult
    public func refreshCatalog(force: Bool = false) async throws -> Bool {
        var request = URLRequest(url: Self.baseURL.appendingPathComponent("catalog.json"))
        if !force, let etag = defaults.string(forKey: etagKey) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw LineDataError.badResponse(0) }

        lastChecked = Date()
        defaults.set(lastChecked, forKey: checkedKey)

        if http.statusCode == 304 {
            recomputeStale()
            return false
        }
        guard http.statusCode == 200 else { throw LineDataError.badResponse(http.statusCode) }

        let catalog = try JSONDecoder().decode(LineCatalog.self, from: data)
        guard catalog.schemaVersion <= Catalog.supportedSchemaVersion else {
            throw LineDataError.schemaTooNew(catalog.schemaVersion)
        }

        try FileManager.default.createDirectory(at: LineDataStore.installedRoot,
                                                withIntermediateDirectories: true)
        try data.write(to: LineDataStore.installedRoot.appendingPathComponent("catalog.json"),
                       options: .atomic)
        if let etag = http.value(forHTTPHeaderField: "Etag") {
            defaults.set(etag, forKey: etagKey)
        }
        try await refreshBadgeStyles(styles: catalog.styles)

        Catalog.reload()
        StaticTrainData.invalidate()
        recomputeStale()
        return true
    }

    /// Styles ship with the data, so a new operator needs no app release.
    private func refreshBadgeStyles(styles: [String]) async throws {
        let dir = LineDataStore.installedRoot.appendingPathComponent("BadgeStyles", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for style in styles {
            let url = Self.baseURL.appendingPathComponent("BadgeStyles/\(style).json")
            guard let data = try? await fetch(url) else { continue }
            try data.write(to: dir.appendingPathComponent("\(style).json"), options: .atomic)
        }
    }

    /// An installed line whose bytes no longer match the catalog is stale.
    public func recomputeStale() {
        var stale: Set<String> = []
        for line in Catalog.current.lines where LineDataStore.isDownloaded(folder: line.folder) {
            let url = LineDataStore.installedURL(folder: line.folder, file: "Line.json")
            guard let data = try? Data(contentsOf: url) else { continue }
            if Self.hash(data) != line.sha256 { stale.insert(line.id) }
        }
        staleLineIds = stale
    }

    // MARK: - Install and remove

    public func install(lineIds: [String]) async throws {
        for id in lineIds {
            guard let line = Catalog.line(id: id) else { throw LineDataError.notInCatalog(id) }
            inFlight.insert(id)
            defer { inFlight.remove(id) }
            try await install(line)
        }
        StaticTrainData.invalidate()
        recomputeStale()
    }

    private func install(_ line: CatalogLine) async throws {
        let lineData = try await fetch(Self.baseURL
            .appendingPathComponent("Lines/\(line.folder)/Line.json"))
        guard Self.hash(lineData) == line.sha256 else {
            throw LineDataError.checksumMismatch("\(line.folder)/Line.json")
        }
        let badgeData = try await fetch(Self.baseURL
            .appendingPathComponent("Lines/\(line.folder)/Badge.json"))
        guard Self.hash(badgeData) == line.badgeSha256 else {
            throw LineDataError.checksumMismatch("\(line.folder)/Badge.json")
        }

        // Nothing lands in place until both files have been verified.
        let dir = LineDataStore.installedURL(folder: line.folder, file: "").deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try lineData.write(to: dir.appendingPathComponent("Line.json"), options: .atomic)
        try badgeData.write(to: dir.appendingPathComponent("Badge.json"), options: .atomic)
    }

    public func remove(lineIds: [String]) throws {
        for id in lineIds {
            guard let line = Catalog.line(id: id) else { continue }
            let dir = LineDataStore.installedURL(folder: line.folder, file: "")
                .deletingLastPathComponent()
            try? FileManager.default.removeItem(at: dir)
        }
        StaticTrainData.invalidate()
        recomputeStale()
    }

    public func updateStale() async throws {
        try await install(lineIds: Array(staleLineIds))
    }

    // MARK: - Helpers

    private func fetch(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw LineDataError.badResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    private static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
