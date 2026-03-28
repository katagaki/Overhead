import Foundation

// MARK: - Train Line Disk Cache

struct TrainLineCache {

    private static let cacheFileName = "train_lines_cache.json"
    private static let refreshInterval: TimeInterval = 7 * 24 * 60 * 60 // 1 week

    private struct CacheEnvelope: Codable {
        let lines: [TrainLine]
        let includesJR: Bool
        let cachedAt: Date
    }

    // MARK: - Cache Directory

    private static var cacheFileURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(cacheFileName)
    }

    // MARK: - Read

    /// Returns cached lines if they exist and match the `includesJR` flag, or nil.
    static func load(includesJR: Bool) -> [TrainLine]? {
        guard let data = try? Data(contentsOf: cacheFileURL),
              let envelope = try? JSONDecoder().decode(CacheEnvelope.self, from: data),
              envelope.includesJR == includesJR else {
            return nil
        }
        return envelope.lines
    }

    /// Returns true when the cache exists, matches `includesJR`, and is less than one week old.
    static func isFresh(includesJR: Bool) -> Bool {
        guard let data = try? Data(contentsOf: cacheFileURL),
              let envelope = try? JSONDecoder().decode(CacheEnvelope.self, from: data),
              envelope.includesJR == includesJR else {
            return false
        }
        return Date().timeIntervalSince(envelope.cachedAt) < refreshInterval
    }

    // MARK: - Write

    static func save(lines: [TrainLine], includesJR: Bool) {
        let envelope = CacheEnvelope(lines: lines, includesJR: includesJR, cachedAt: Date())
        if let data = try? JSONEncoder().encode(envelope) {
            try? data.write(to: cacheFileURL, options: .atomic)
        }
    }
}
