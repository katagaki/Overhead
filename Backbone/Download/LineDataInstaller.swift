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
    /// 0...1 per line while it downloads, for a determinate indicator.
    @Published public private(set) var progress: [String: Double] = [:]
    @Published public private(set) var lastChecked: Date?
    @Published public private(set) var staleLineIds: Set<String> = []

    private let defaults = UserDefaults.standard
    private let etagKey = "lineData.catalogETag"
    private let modifiedKey = "lineData.catalogModified"
    private let checkedKey = "lineData.lastChecked"
    private nonisolated let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        // URLSession's own cache would revalidate behind our back and hand us a
        // 200, hiding the cheap 304. Ours are the conditional headers that count.
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: config)
        lastChecked = defaults.object(forKey: checkedKey) as? Date
    }

    public var isBusy: Bool { !inFlight.isEmpty }

    /// Only claim to hold a copy if one is actually on disk: otherwise a 304
    /// would leave the app with no catalog at all.
    private var hasLocalCatalog: Bool {
        FileManager.default.fileExists(
            atPath: LineDataStore.installedRoot.appendingPathComponent("catalog.json").path)
    }

    // MARK: - Update check

    /// One conditional GET. A 304 costs a few hundred bytes and means there is
    /// nothing to do.
    @discardableResult
    public func refreshCatalog(force: Bool = false) async throws -> Bool {
        var request = URLRequest(url: Self.baseURL.appendingPathComponent("catalog.json"))
        if !force, hasLocalCatalog {
            if let etag = defaults.string(forKey: etagKey) {
                request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            } else if let modified = defaults.string(forKey: modifiedKey) {
                request.setValue(modified, forHTTPHeaderField: "If-Modified-Since")
            }
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
        storeValidator(from: http)
        try await refreshBadgeStyles(styles: catalog.styles, base: Self.baseURL)

        Catalog.reload()
        StaticTrainData.invalidate()
        recomputeStale()
        return true
    }

    private func storeValidator(from http: HTTPURLResponse) {
        if let etag = http.value(forHTTPHeaderField: "Etag") {
            defaults.set(etag, forKey: etagKey)
        } else if let modified = http.value(forHTTPHeaderField: "Last-Modified") {
            defaults.set(modified, forKey: modifiedKey)
        }
    }

    /// Styles ship with the data, so a new operator needs no app release.
    private func refreshBadgeStyles(styles: [String], base: URL) async throws {
        let dir = LineDataStore.installedRoot.appendingPathComponent("BadgeStyles", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for batch in styles.chunked(into: Self.parallelism) {
            let fetched = await withTaskGroup(of: (String, Data?).self) { group in
                for style in batch {
                    group.addTask { [session] in
                        let url = base.appendingPathComponent("BadgeStyles/\(style).json")
                        return (style, try? await Self.fetch(url, using: session))
                    }
                }
                var out: [(String, Data?)] = []
                for await result in group { out.append(result) }
                return out
            }
            for (style, data) in fetched {
                guard let data else { continue }
                try data.write(to: dir.appendingPathComponent("\(style).json"), options: .atomic)
            }
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

    /// A base set is dozens of lines; downloading them one after another is
    /// most of a first launch.
    static let parallelism = 6

    public func install(lineIds: [String]) async throws {
        let lines = try lineIds.map { id -> CatalogLine in
            guard let line = Catalog.line(id: id) else { throw LineDataError.notInCatalog(id) }
            return line
        }
        inFlight.formUnion(lineIds)
        for id in lineIds { progress[id] = 0 }
        defer {
            inFlight.subtract(lineIds)
            for id in lineIds { progress[id] = nil }
            StaticTrainData.invalidate()
            recomputeStale()
        }

        let base = Self.baseURL
        for batch in lines.chunked(into: Self.parallelism) {
            let fetched = try await withThrowingTaskGroup(
                of: (CatalogLine, Data, Data).self
            ) { group -> [(CatalogLine, Data, Data)] in
                for line in batch {
                    group.addTask { [session] in
                        try await Self.download(line, base: base, using: session) { fraction in
                            Task { @MainActor in self.report(fraction, for: line.id) }
                        }
                    }
                }
                var out: [(CatalogLine, Data, Data)] = []
                for try await result in group { out.append(result) }
                return out
            }
            for (line, lineData, badgeData) in fetched {
                try write(line, lineData: lineData, badgeData: badgeData)
            }
            for line in batch { inFlight.remove(line.id); progress[line.id] = nil }
        }
    }

    fileprivate func report(_ fraction: Double, for id: String) {
        progress[id] = min(1, max(0, fraction))
    }

    /// Both files are fetched and verified before either is written.
    private nonisolated static func download(
        _ line: CatalogLine, base: URL, using session: URLSession,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> (CatalogLine, Data, Data) {
        let lineData = try await fetchWithProgress(
            base.appendingPathComponent("Lines/\(line.folder)/Line.json"),
            using: session, onProgress: onProgress)
        guard hash(lineData) == line.sha256 else {
            throw LineDataError.checksumMismatch("\(line.folder)/Line.json")
        }
        let badgeData = try await fetch(
            base.appendingPathComponent("Lines/\(line.folder)/Badge.json"), using: session)
        guard hash(badgeData) == line.badgeSha256 else {
            throw LineDataError.checksumMismatch("\(line.folder)/Badge.json")
        }
        return (line, lineData, badgeData)
    }

    private func write(_ line: CatalogLine, lineData: Data, badgeData: Data) throws {
        let dir = LineDataStore.installedDirectory(folder: line.folder)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try lineData.write(to: dir.appendingPathComponent("Line.json"), options: .atomic)
        try badgeData.write(to: dir.appendingPathComponent("Badge.json"), options: .atomic)
    }

    public func remove(lineIds: [String]) throws {
        for id in lineIds {
            guard let line = Catalog.line(id: id) else { continue }
            try? FileManager.default.removeItem(
                at: LineDataStore.installedDirectory(folder: line.folder))
        }
        StaticTrainData.invalidate()
        recomputeStale()
    }

    public func updateStale() async throws {
        try await install(lineIds: Array(staleLineIds))
    }

    // MARK: - Helpers

    /// Line.json is the bulk of a line, so its byte count is the progress.
    private nonisolated static func fetchWithProgress(
        _ url: URL, using session: URLSession,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> Data {
        let delegate = DownloadProgressDelegate(onProgress: onProgress)
        let (fileURL, response) = try await session.download(from: url, delegate: delegate)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw LineDataError.badResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        defer { try? FileManager.default.removeItem(at: fileURL) }
        return try Data(contentsOf: fileURL)
    }

    private nonisolated static func fetch(_ url: URL, using session: URLSession) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw LineDataError.badResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    private nonisolated static func hash(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}

/// Reports byte progress for a single download.
private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let onProgress: @Sendable (Double) -> Void

    init(onProgress: @escaping @Sendable (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite totalBytesExpected: Int64) {
        guard totalBytesExpected > 0 else { return }
        onProgress(Double(totalBytesWritten) / Double(totalBytesExpected))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {}
}
