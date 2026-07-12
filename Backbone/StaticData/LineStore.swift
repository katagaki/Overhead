import Foundation

// All static line data (stations, directions, service patterns, real
// timetables) lives in bundled JSON under StaticData/Lines/*.json — one file
// per operator, holding fully-assembled StaticTrainLine values. Keeping this as
// Swift literals made the type checker spend seconds and gigabytes per file.
// Decoded lazily on first access.
enum LineStore {
    private final class BundleToken {}
    private static let bundle = Bundle(for: BundleToken.self)

    static func lines(_ name: String) -> [StaticTrainLine] {
        guard let url = bundle.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Missing line resource: \(name).json")
        }
        do {
            return try JSONDecoder().decode([StaticTrainLine].self, from: data)
        } catch {
            fatalError("Failed to decode \(name).json: \(error)")
        }
    }
}
