import Foundation
import CryptoKit
import Combine

public enum LineDataError: LocalizedError {
    case badResponse(Int)
    case checksumMismatch(String)
    case schemaTooNew(Int)

    public var errorDescription: String? {
        switch self {
        case .badResponse(let code): return "Server returned \(code)"
        case .checksumMismatch(let file): return "\(file) did not match its checksum"
        case .schemaTooNew(let v): return "Data format \(v) is newer than this app understands"
        }
    }
}

/// A file the device does not have, or has an outdated copy of.
public struct PendingLine: Identifiable, Sendable, Equatable {
    public let line: CatalogLine
    public let needsLine: Bool
    public let needsBadge: Bool

    public var id: String { line.id }

    /// Line.json is the bulk of a line; a badge-only patch is a few kilobytes.
    var weight: Int { needsLine ? line.bytes : 2_048 }
}

/// What a running download has done so far.
public struct LineDataProgress: Sendable, Equatable {
    public var totalLines: Int
    public var completedLines: Int
    public var totalBytes: Int
    public var completedBytes: Int
    /// The line being written, for a caption.
    public var currentLine: String?

    public var fraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, max(0, Double(completedBytes) / Double(totalBytes)))
    }
}

/// Keeps the device's copy of the data repository in step with the catalog.
///
/// The app carries every line, so there is nothing to choose: one download
/// brings the device up to the catalog, and later checks re-fetch only the
/// lines whose hashes moved.
@MainActor
public final class LineDataInstaller: ObservableObject {

    public static let shared = LineDataInstaller()

    /// Root of the published data repository.
    public static var baseURL = URL(string: "https://raw.githubusercontent.com/katagaki/OverheadData/main/")!

    /// Outstanding work: missing lines on a fresh install, changed ones after.
    @Published public private(set) var pending: [PendingLine] = []
    /// Non-nil only while a download is running.
    @Published public private(set) var progress: LineDataProgress?
    @Published public private(set) var isChecking = false
    /// The published data has moved to a format this build cannot read.
    @Published public private(set) var needsAppUpdate = false
    @Published public private(set) var lastChecked: Date?
    /// How many of the catalog's lines are on the device.
    @Published public private(set) var installedCount = 0
    /// The version the data on disk answers to. The catalog file lands during
    /// the check, ahead of the lines it describes, so its own version runs on
    /// in front of what the device actually holds.
    @Published public private(set) var installedVersion: String = Catalog.current.version

    private let defaults = UserDefaults.standard
    private let etagKey = "lineData.catalogETag"
    private let modifiedKey = "lineData.catalogModified"
    private let checkedKey = "lineData.lastChecked"
    private let pinnedKey = "lineData.pinnedToLegacy"
    /// The schema the pin was taken for, so a later build can drop it.
    private let pinnedSchemaKey = "lineData.pinnedSchema"
    private let installedVersionKey = "lineData.installedVersion"
    private nonisolated let session: URLSession

    /// Bytes of finished lines, plus the fraction each in-flight one has read.
    private var settledBytes = 0
    private var partialBytes: [String: Int] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        // URLSession's own cache would revalidate behind our back and hand us a
        // 200, hiding the cheap 304. Ours are the conditional headers that count.
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: config)
        lastChecked = defaults.object(forKey: checkedKey) as? Date
        installedVersion = defaults.string(forKey: installedVersionKey) ?? Catalog.current.version
        needsAppUpdate = defaults.bool(forKey: pinnedKey)
        // The pin belongs to the build that took it: once the app understands
        // a newer schema, it follows the live catalog again.
        if needsAppUpdate,
           defaults.integer(forKey: pinnedSchemaKey) < Catalog.supportedSchemaVersion {
            pin(toLegacy: false)
        }
    }

    /// The catalog this build should read. Once the repository moves to a
    /// newer schema, an old build keeps reading the snapshot frozen for it.
    private var catalogURL: URL {
        needsAppUpdate
            ? Self.baseURL.appendingPathComponent(
                "legacy/v\(Catalog.supportedSchemaVersion)/catalog.json")
            : Self.baseURL.appendingPathComponent("catalog.json")
    }

    // MARK: - State

    public var isDownloading: Bool { progress != nil }
    public var isBusy: Bool { isDownloading || isChecking }
    /// A wipe in flight; a download started meanwhile waits for it.
    private var wipeTask: Task<Void, Never>?
    /// Nothing on the device yet, so the next download is the first one.
    public var isFirstDownload: Bool { installedCount == 0 }
    public var hasPendingWork: Bool { !pending.isEmpty }
    /// Worth badging: data the device is missing or has fallen behind on.
    public var hasUpdate: Bool { hasPendingWork && !isDownloading }
    public var pendingBytes: Int { pending.reduce(0) { $0 + $1.weight } }
    /// Everything the catalog lists, for the first-run offer.
    public var catalogBytes: Int { Catalog.current.lines.reduce(0) { $0 + $1.bytes } }

    // MARK: - Update check

    /// One conditional GET. A 304 costs a few hundred bytes and means the
    /// catalog is unchanged, so the pending set cannot have moved either.
    @discardableResult
    public func refreshCatalog(force: Bool = false) async throws -> Bool {
        isChecking = true
        defer { isChecking = false }

        var request = URLRequest(url: catalogURL)
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
            await recomputePending()
            return false
        }
        guard http.statusCode == 200 else { throw LineDataError.badResponse(http.statusCode) }

        let catalog = try JSONDecoder().decode(LineCatalog.self, from: data)
        guard catalog.schemaVersion <= Catalog.supportedSchemaVersion else {
            // The repository has moved on. Pin to the snapshot kept for this
            // schema if there is one, and say so either way — silently serving
            // stale timetables forever is worse than an honest row.
            pin(toLegacy: true)
            if try await adoptLegacyCatalog() { return true }
            throw LineDataError.schemaTooNew(catalog.schemaVersion)
        }
        if !needsAppUpdate { pin(toLegacy: false) }

        try FileManager.default.createDirectory(at: LineDataStore.installedRoot,
                                                withIntermediateDirectories: true)
        try data.write(to: LineDataStore.installedRoot.appendingPathComponent("catalog.json"),
                       options: .atomic)
        storeValidator(from: http)
        Catalog.reload()
        StaticTrainData.invalidate()
        try await refreshBadgeStyles(styles: catalog.styles, base: Self.baseURL)
        try await refreshOperatorIcons(icons: catalog.operatorIcons ?? [], base: Self.baseURL)
        await recomputePending()
        return true
    }

    /// Fetches the catalog frozen for this build's schema. False when the
    /// repository publishes no snapshot for it.
    private func adoptLegacyCatalog() async throws -> Bool {
        var request = URLRequest(url: catalogURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let catalog = try? JSONDecoder().decode(LineCatalog.self, from: data),
              catalog.schemaVersion <= Catalog.supportedSchemaVersion
        else { return false }

        try FileManager.default.createDirectory(at: LineDataStore.installedRoot,
                                                withIntermediateDirectories: true)
        try data.write(to: LineDataStore.installedRoot.appendingPathComponent("catalog.json"),
                       options: .atomic)
        storeValidator(from: http)
        Catalog.reload()
        StaticTrainData.invalidate()
        try await refreshBadgeStyles(styles: catalog.styles, base: Self.baseURL)
        try await refreshOperatorIcons(icons: catalog.operatorIcons ?? [], base: Self.baseURL)
        await recomputePending()
        return true
    }

    /// Validators belong to whichever catalog we are following.
    private func pin(toLegacy pinned: Bool) {
        guard pinned != needsAppUpdate else { return }
        needsAppUpdate = pinned
        defaults.set(pinned, forKey: pinnedKey)
        defaults.set(pinned ? Catalog.supportedSchemaVersion : 0, forKey: pinnedSchemaKey)
        defaults.removeObject(forKey: etagKey)
        defaults.removeObject(forKey: modifiedKey)
    }

    /// Only claim to hold a copy if one is actually on disk: otherwise a 304
    /// would leave the app with no catalog at all.
    private var hasLocalCatalog: Bool {
        FileManager.default.fileExists(
            atPath: LineDataStore.installedRoot.appendingPathComponent("catalog.json").path)
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
                        let url = base.appendingPathComponent(
                            "\(Catalog.dataPath)BadgeStyles/\(style).json")
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

    /// The curated operator marks, for the operators whose own sites serve no
    /// usable favicon. Data, like the styles, so a new mark needs no release.
    private func refreshOperatorIcons(icons: [String], base: URL) async throws {
        guard !icons.isEmpty else { return }
        let dir = LineDataStore.installedRoot.appendingPathComponent("OperatorIcons",
                                                                    isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for batch in icons.chunked(into: Self.parallelism) {
            let fetched = await withTaskGroup(of: (String, Data?).self) { group in
                for icon in batch {
                    group.addTask { [session] in
                        let url = base.appendingPathComponent(
                            "\(Catalog.dataPath)OperatorIcons/\(icon).png")
                        return (icon, try? await Self.fetch(url, using: session))
                    }
                }
                var out: [(String, Data?)] = []
                for await result in group { out.append(result) }
                return out
            }
            for (icon, data) in fetched {
                guard let data else { continue }
                try data.write(to: dir.appendingPathComponent("\(icon).png"), options: .atomic)
            }
        }
    }

    // MARK: - Pending work

    /// Compares what is on disk against the catalog's hashes. Hashing 18 MB is
    /// not main-thread work, and the file per line is the patch unit: a line
    /// whose hash still matches is not fetched again.
    public func recomputePending() async {
        let lines = Catalog.current.lines
        let result = await Task.detached(priority: .utility) { () -> ([PendingLine], Int) in
            var work: [PendingLine] = []
            var installed = 0
            for line in lines {
                let lineURL = LineDataStore.installedURL(folder: line.folder, file: "Line.json")
                let badgeURL = LineDataStore.installedURL(folder: line.folder, file: "Badge.json")
                let lineData = try? Data(contentsOf: lineURL)
                let badgeData = try? Data(contentsOf: badgeURL)
                if lineData != nil { installed += 1 }
                let needsLine = lineData.map { Self.hash($0) != line.sha256 } ?? true
                let needsBadge = badgeData.map { Self.hash($0) != line.badgeSha256 } ?? true
                if needsLine || needsBadge {
                    work.append(PendingLine(line: line, needsLine: needsLine, needsBadge: needsBadge))
                }
            }
            return (work, installed)
        }.value
        pending = result.0
        installedCount = result.1
        // Nothing outstanding means the disk matches the catalog, so the
        // catalog's version is now the installed one.
        if result.0.isEmpty {
            installedVersion = Catalog.current.version
            defaults.set(installedVersion, forKey: installedVersionKey)
        }
    }

    // MARK: - Download

    /// A first run is 136 lines; downloading them one after another is most of
    /// a first launch.
    static let parallelism = 6

    /// Brings the device up to the catalog. Everything the catalog lists ends
    /// up on disk; lines it no longer lists are dropped.
    public func sync() async throws {
        await wipeTask?.value
        guard !isDownloading else { return }
        if pending.isEmpty { await recomputePending() }
        let work = pending
        guard !work.isEmpty else {
            pruneObsoleteFolders()
            return
        }

        settledBytes = 0
        partialBytes = [:]
        progress = LineDataProgress(totalLines: work.count, completedLines: 0,
                                    totalBytes: work.reduce(0) { $0 + $1.weight },
                                    completedBytes: 0, currentLine: nil)
        defer {
            progress = nil
            partialBytes = [:]
        }

        do {
            try await download(work, base: Self.baseURL)
        } catch {
            // Whatever landed before the failure still counts as installed.
            await recomputePending()
            throw error
        }
        pruneObsoleteFolders()
        await recomputePending()
    }

    private func download(_ work: [PendingLine], base: URL) async throws {
        // One bad file should not cost the user the other 135 lines: each
        // failure is set aside, the rest install, and the first one is raised
        // at the end so the screen still says something went wrong.
        var failures: [Error] = []

        for batch in work.chunked(into: Self.parallelism) {
            let fetched = await withTaskGroup(
                of: (PendingLine, Result<(Data?, Data?), Error>).self
            ) { group -> [(PendingLine, Result<(Data?, Data?), Error>)] in
                for item in batch {
                    group.addTask { [session] in
                        do {
                            let (_, lineData, badgeData) = try await Self.download(
                                item, base: base, using: session
                            ) { fraction in
                                Task { @MainActor in self.report(fraction, for: item) }
                            }
                            return (item, .success((lineData, badgeData)))
                        } catch {
                            return (item, .failure(error))
                        }
                    }
                }
                var out: [(PendingLine, Result<(Data?, Data?), Error>)] = []
                for await result in group { out.append(result) }
                return out
            }

            var installed: [StaticTrainLine] = []
            var badgesChanged = false
            for (item, result) in fetched {
                switch result {
                case .success(let (lineData, badgeData)):
                    try write(item.line, lineData: lineData, badgeData: badgeData)
                    if badgeData != nil { badgesChanged = true }
                    if let lineData {
                        installed.append(contentsOf:
                            (try? JSONDecoder().decode([StaticTrainLine].self, from: lineData)) ?? [])
                    }
                case .failure(let error):
                    failures.append(error)
                }
                settledBytes += item.weight
                partialBytes[item.id] = nil
                progress?.completedLines += 1
                progress?.currentLine = item.line.localizedName
            }
            progress?.completedBytes = settledBytes
            // A badge-only patch never reaches `absorb`, so its plate would
            // stay stale until the next launch.
            if badgesChanged, installed.isEmpty {
                BadgeStyles.invalidate()
                NotificationCenter.default.post(name: StaticTrainData.didChangeNotification,
                                                object: nil)
            }
            // Each batch shows up as soon as it lands, rather than at the end.
            StaticTrainData.absorb(installed)
        }

        if let first = failures.first { throw first }
    }

    /// Throws away everything that was downloaded — lines, the catalog, the
    /// badge styles and the operator marks — leaving the app on the seed it
    /// shipped with. The repair path for a copy that will not decode, and for
    /// data that has gone stale in a way a patch cannot reach.
    public func removeAllData() async {
        guard !isDownloading else { return }
        try? FileManager.default.removeItem(at: LineDataStore.installedRoot)
        defaults.removeObject(forKey: etagKey)
        defaults.removeObject(forKey: modifiedKey)
        defaults.removeObject(forKey: checkedKey)
        defaults.removeObject(forKey: installedVersionKey)
        lastChecked = nil
        StaticTrainData.invalidate()
        installedVersion = Catalog.current.version
        await recomputePending()
    }

    /// Started without waiting, so a screen can move on while the disk
    /// catches up; anything that downloads next lands behind it.
    public func beginRemoveAllData() {
        wipeTask = Task { [weak self] in await self?.removeAllData() }
    }

    /// A line dropped from the catalog is data the app can no longer describe.
    private func pruneObsoleteFolders() {
        let root = LineDataStore.installedRoot.appendingPathComponent("Lines", isDirectory: true)
        guard let folders = try? FileManager.default.contentsOfDirectory(
            atPath: root.path) else { return }
        let known = Set(Catalog.current.lines.map(\.folder))
        for folder in folders where !known.contains(folder) {
            try? FileManager.default.removeItem(at: root.appendingPathComponent(folder))
        }
    }

    fileprivate func report(_ fraction: Double, for item: PendingLine) {
        guard progress != nil else { return }
        partialBytes[item.id] = Int(Double(item.weight) * min(1, max(0, fraction)))
        progress?.completedBytes = settledBytes + partialBytes.values.reduce(0, +)
    }

    /// Only the files whose hashes moved are fetched, and both are verified
    /// before either is written.
    private nonisolated static func download(
        _ item: PendingLine, base: URL, using session: URLSession,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> (PendingLine, Data?, Data?) {
        let folder = item.line.folder
        let root = Catalog.dataPath
        var lineData: Data?
        var badgeData: Data?
        if item.needsLine {
            let data = try await fetchWithProgress(
                base.appendingPathComponent("\(root)Lines/\(folder)/Line.json"),
                using: session, onProgress: onProgress)
            guard hash(data) == item.line.sha256 else {
                throw LineDataError.checksumMismatch("\(folder)/Line.json")
            }
            lineData = data
        }
        if item.needsBadge {
            let data = try await fetch(
                base.appendingPathComponent("\(root)Lines/\(folder)/Badge.json"), using: session)
            guard hash(data) == item.line.badgeSha256 else {
                throw LineDataError.checksumMismatch("\(folder)/Badge.json")
            }
            badgeData = data
        }
        return (item, lineData, badgeData)
    }

    private func write(_ line: CatalogLine, lineData: Data?, badgeData: Data?) throws {
        let dir = LineDataStore.installedDirectory(folder: line.folder)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let lineData {
            try lineData.write(to: dir.appendingPathComponent("Line.json"), options: .atomic)
        }
        if let badgeData {
            try badgeData.write(to: dir.appendingPathComponent("Badge.json"), options: .atomic)
        }
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
