import Foundation

/// Resolves line data from the downloaded copy first, then the bundled seed,
/// so an installed line and a shipped one look the same to every caller.
public enum LineDataStore {

    private final class BundleToken {}
    static let bundle = Bundle(for: BundleToken.self)

    /// Downloads land here, one folder per line, mirroring the bundle layout.
    public static let installedRoot: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        return base.appendingPathComponent("LineData", isDirectory: true)
    }()

    public static func installedDirectory(folder: String) -> URL {
        installedRoot
            .appendingPathComponent("Lines", isDirectory: true)
            .appendingPathComponent(folder, isDirectory: true)
    }

    static func installedURL(folder: String, file: String) -> URL {
        installedDirectory(folder: folder).appendingPathComponent(file)
    }

    /// Curated operator mark shipped with the seed, when the data has one.
    public static func operatorIconURL(operatorId: String) -> URL? {
        let name = operatorId.replacingOccurrences(of: ":", with: "_")
        return bundle.url(forResource: name, withExtension: "png",
                          subdirectory: "StaticData/OperatorIcons")
    }

    static func bundleURL(folder: String, file: String) -> URL? {
        let name = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension
        return bundle.url(forResource: name, withExtension: ext,
                          subdirectory: "StaticData/Lines/\(folder)")
    }

    /// Installed copy wins; the bundled seed is the fallback.
    public static func data(folder: String, file: String) -> Data? {
        let installed = installedURL(folder: folder, file: file)
        if let data = try? Data(contentsOf: installed) { return data }
        guard let url = bundleURL(folder: folder, file: file) else { return nil }
        return try? Data(contentsOf: url)
    }

    public static func isPresent(folder: String) -> Bool {
        data(folder: folder, file: "Line.json") != nil
    }

    public static func isDownloaded(folder: String) -> Bool {
        FileManager.default.fileExists(
            atPath: installedURL(folder: folder, file: "Line.json").path)
    }

    /// Folders the app can actually read right now, downloaded or bundled.
    public static var availableFolders: Set<String> {
        Set(Catalog.current.lines.map(\.folder).filter(isPresent))
    }

    // MARK: Catalog and styles

    static func catalogData() -> Data? {
        let installed = installedRoot.appendingPathComponent("catalog.json")
        if let data = try? Data(contentsOf: installed) { return data }
        return bundledCatalogData()
    }

    /// The catalog that shipped with this build, ignoring anything installed.
    static func bundledCatalogData() -> Data? {
        guard let url = bundle.url(forResource: "catalog", withExtension: "json",
                                   subdirectory: "StaticData") else { return nil }
        return try? Data(contentsOf: url)
    }

    static func badgeStyleData() -> [Data] {
        let installedStyles = installedRoot.appendingPathComponent("BadgeStyles", isDirectory: true)
        if let files = try? FileManager.default.contentsOfDirectory(
            at: installedStyles, includingPropertiesForKeys: nil),
           !files.isEmpty {
            return files.filter { $0.pathExtension == "json" }.compactMap { try? Data(contentsOf: $0) }
        }
        let urls = bundle.urls(forResourcesWithExtension: "json",
                               subdirectory: "StaticData/BadgeStyles") ?? []
        return urls.compactMap { try? Data(contentsOf: $0) }
    }
}
