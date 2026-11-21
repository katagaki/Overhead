import Foundation

enum LineStore {
    private static let failuresLock = NSLock()
    private static var failures: Set<String> = []

    /// Folders whose Line.json is on disk but did not decode the last time it was read.
    static var failedFolders: Set<String> {
        failuresLock.lock(); defer { failuresLock.unlock() }
        return failures
    }

    /// A line that will not load is skipped, not fatal: with downloadable data,
    /// "not there yet" is an ordinary state.
    static func lines(_ folder: String) -> [StaticTrainLine] {
        guard let data = LineDataStore.data(folder: folder, file: "Line.json") else { return [] }
        return decode(data, folder: folder) ?? []
    }

    static func decode(_ data: Data, folder: String) -> [StaticTrainLine]? {
        let lines = try? JSONDecoder().decode([StaticTrainLine].self, from: data)
        failuresLock.lock()
        if lines == nil { failures.insert(folder) } else { failures.remove(folder) }
        failuresLock.unlock()
        return lines
    }
}
