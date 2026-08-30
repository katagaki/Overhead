import Foundation

/// A language the in-car LCDs can cycle through.
enum TrainLCDLanguage: String, CaseIterable, Identifiable {
    case ja
    case en
    case zh

    var id: String { rawValue }

    /// Endonym, shown verbatim.
    var label: String {
        switch self {
        case .ja: return "日本語"
        case .en: return "English"
        case .zh: return "中文"
        }
    }
}

/// Which languages the LCDs rotate through, and which one is showing now.
enum LCDLanguageRotation {
    static let storageKey = "journey.lcdLanguages"
    /// Seconds each language holds the screen.
    static let flipSeconds = 4.0

    static let `default`: [TrainLCDLanguage] = [.ja, .en]

    /// Stored selection, in `allCases` order; never empty.
    static func selected(
        _ defaults: UserDefaults = .standard
    ) -> [TrainLCDLanguage] {
        guard let stored = defaults.string(forKey: storageKey) else { return `default` }
        let picked = Set(stored.split(separator: ",").map(String.init))
        let languages = TrainLCDLanguage.allCases.filter { picked.contains($0.rawValue) }
        return languages.isEmpty ? `default` : languages
    }

    static func store(_ languages: [TrainLCDLanguage],
                      in defaults: UserDefaults = .standard) {
        let ordered = TrainLCDLanguage.allCases.filter { languages.contains($0) }
        guard !ordered.isEmpty else { return }
        defaults.set(ordered.map(\.rawValue).joined(separator: ","), forKey: storageKey)
    }

    /// The language on screen at `date`. A single selection never flips.
    static func current(at date: Date,
                        defaults: UserDefaults = .standard) -> TrainLCDLanguage {
        let languages = selected(defaults)
        guard languages.count > 1 else { return languages[0] }
        let step = Int(date.timeIntervalSinceReferenceDate / flipSeconds)
        return languages[((step % languages.count) + languages.count) % languages.count]
    }
}
