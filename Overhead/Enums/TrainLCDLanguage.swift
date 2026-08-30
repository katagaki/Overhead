import Foundation
import Backbone

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

// MARK: - Rider-facing text

extension TrainLCDLanguage {
    /// Latin script: the LCDs switch fonts and spacing on this, not on the
    /// language itself — Chinese rides the CJK layout Japanese uses.
    var isLatin: Bool { self == .en }

    /// Station name in this language, falling back to Japanese.
    func name(_ station: Station) -> String {
        switch self {
        case .ja: return station.name
        case .en: return station.nameEn.isEmpty ? station.name : station.nameEn
        case .zh: return station.nameZhHans.isEmpty ? station.name : station.nameZhHans
        }
    }

    func lineName(_ line: TrainLine) -> String {
        switch self {
        case .ja: return line.name
        case .en: return line.nameEn.isEmpty ? line.name : line.nameEn
        case .zh: return line.nameZhHans.isEmpty ? line.name : line.nameZhHans
        }
    }

    /// 行き先. A through destination is only carried in ja/en, so Chinese
    /// falls back to the Japanese spelling rather than to the on-line terminus.
    func destinationName(_ journey: Journey) -> String {
        switch self {
        case .ja: return journey.destinationNameJa
        case .en: return journey.destinationNameEn
        case .zh:
            guard journey.service.throughDestinationName == nil else {
                return journey.destinationNameJa
            }
            return journey.destinationStation.map { name($0) } ?? journey.destinationNameJa
        }
    }

    /// Train type. The data carries ja/en only; the Japanese kanji read the
    /// same in Chinese (快速, 急行, 特急…), so Chinese reuses them.
    func typeName(ja: String, en: String) -> String {
        isLatin ? en : ja
    }

    /// 号車
    var carLabel: String {
        switch self {
        case .ja: return "号車"
        case .en: return "Car No."
        case .zh: return "号车"
        }
    }

    /// 現在時刻
    var clockLabel: String {
        switch self {
        case .ja: return "現在時刻"
        case .en: return "Time"
        case .zh: return "当前时间"
        }
    }

    /// The 分 in a travel-time column.
    var minuteLabel: String {
        switch self {
        case .ja: return "分"
        case .en: return "min"
        case .zh: return "分钟"
        }
    }

    /// のりかえ
    var transferLabel: String {
        switch self {
        case .ja: return "のりかえ"
        case .en: return "Transfers"
        case .zh: return "换乘"
        }
    }

    /// 〜方面
    func directionLabel(_ name: String) -> String {
        switch self {
        case .ja: return "\(name)方面"
        case .en: return "for \(name)"
        case .zh: return "开往\(name)"
        }
    }

    /// 〜行き
    func destinationLabel(_ name: String) -> String {
        switch self {
        case .ja: return "\(name)行"
        case .en: return "for \(name)"
        case .zh: return "开往\(name)"
        }
    }

    /// つぎは / まもなく / ただいま, in this LCD's own Japanese wording.
    func headline(_ phase: LCDPhase, japanese: (LCDPhase) -> String) -> String {
        switch self {
        case .ja: return japanese(phase)
        case .en:
            switch phase {
            case .next: return "Next"
            case .approaching: return "Soon"
            case .dwelling: return "Now at"
            }
        case .zh:
            switch phase {
            case .next: return "下一站"
            case .approaching: return "即将到达"
            case .dwelling: return "本站"
            }
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
