import Foundation

enum LineStore {
    /// A line that will not load is skipped, not fatal: with downloadable data,
    /// "not there yet" is an ordinary state.
    static func lines(_ folder: String) -> [StaticTrainLine] {
        guard let data = LineDataStore.data(folder: folder, file: "Line.json") else { return [] }
        do { return try JSONDecoder().decode([StaticTrainLine].self, from: data) }
        catch {
            assertionFailure("Failed to decode \(folder)/Line.json: \(error)")
            return []
        }
    }
}
