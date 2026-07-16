import Foundation

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
