import Foundation

enum LineStore {
    private final class BundleToken {}
    private static let bundle = Bundle(for: BundleToken.self)

    /// Loads one operator folder's timetable data: StaticData/Lines/<folder>/Line.json
    static func lines(_ folder: String) -> [StaticTrainLine] {
        guard let url = bundle.url(forResource: "Line", withExtension: "json",
                                   subdirectory: "StaticData/Lines/\(folder)"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Missing line resource: StaticData/Lines/\(folder)/Line.json")
        }
        do { return try JSONDecoder().decode([StaticTrainLine].self, from: data) }
        catch { fatalError("Failed to decode \(folder)/Line.json: \(error)") }
    }
}
