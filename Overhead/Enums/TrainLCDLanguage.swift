import Foundation
import Backbone

/// A language the in-car LCDs can cycle through.
enum TrainLCDLanguage: String, CaseIterable, Identifiable {
    case ja
    case en
    case zh
    case ko

    var id: String { rawValue }

    /// Endonym, shown verbatim.
    var label: String {
        switch self {
        case .ja: return "日本語"
        case .en: return "English"
        case .zh: return "中文"
        case .ko: return "한국어"
        }
    }
}

// MARK: - Rider-facing text

extension TrainLCDLanguage {
    /// Latin script: the LCDs switch fonts and spacing on this, not on the
    /// language itself — Chinese and Korean ride the CJK layout Japanese uses,
    /// hangul being square-bodied like kana.
    var isLatin: Bool { self == .en }

    /// This language's text, falling back to Japanese where the data has none.
    func text(_ names: LocalizedText) -> String {
        let text: String
        switch self {
        case .ja: text = names.ja
        case .en: text = names.en
        case .zh: text = names.zhHans
        case .ko: text = names.ko
        }
        return text.isEmpty ? names.ja : text
    }

    /// Station name in this language, falling back to Japanese.
    func name(_ station: Station) -> String { text(station.names) }

    func lineName(_ line: TrainLine) -> String {
        switch self {
        case .ja: return line.name
        case .en: return line.nameEn.isEmpty ? line.name : line.nameEn
        case .zh: return line.nameZhHans.isEmpty ? line.name : line.nameZhHans
        case .ko: return line.nameKo.isEmpty ? line.name : line.nameKo
        }
    }

    /// 行き先 — a through destination where the run has one, else the terminus.
    func destinationName(_ journey: Journey) -> String {
        text(journey.destinationNames)
    }

    /// Train type. The data carries ja/en only; the Japanese kanji read the
    /// same in Chinese (快速, 急行, 特急…), so Chinese reuses them, and Korean
    /// signage sets those same words in hangul.
    func typeName(ja: String, en: String) -> String {
        switch self {
        case .en: return en
        case .ko: return Self.koreanType(ja)
        default: return ja
        }
    }

    /// Word by word, so composites (通勤快速 → 통근쾌속) come out for free.
    private static func koreanType(_ ja: String) -> String {
        let readings = [("各駅停車", "각역정차"), ("各停", "각역정차"), ("区間", "구간"),
                        ("通勤", "통근"), ("特別", "특별"), ("快速", "쾌속"),
                        ("準急", "준급"), ("急行", "급행"), ("快特", "쾌특"),
                        ("特急", "특급"), ("ライナー", "라이너")]
        return readings.reduce(ja) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
    }

    /// 号車
    var carLabel: String {
        switch self {
        case .ja: return "号車"
        case .en: return "Car No."
        case .zh: return "号车"
        case .ko: return "호차"
        }
    }

    /// 現在時刻
    var clockLabel: String {
        switch self {
        case .ja: return "現在時刻"
        case .en: return "Time"
        case .zh: return "当前时间"
        case .ko: return "현재 시각"
        }
    }

    /// The 分 in a travel-time column.
    var minuteLabel: String {
        switch self {
        case .ja: return "分"
        case .en: return "min"
        case .zh: return "分钟"
        case .ko: return "분"
        }
    }

    /// のりかえ
    var transferLabel: String {
        switch self {
        case .ja: return "のりかえ"
        case .en: return "Transfers"
        case .zh: return "换乘"
        case .ko: return "환승"
        }
    }

    /// 〜方面
    func directionLabel(_ name: String) -> String {
        switch self {
        case .ja: return "\(name)方面"
        case .en: return "for \(name)"
        case .zh: return "开往\(name)"
        case .ko: return "\(name) 방면"
        }
    }

    /// 〜行き
    func destinationLabel(_ name: String) -> String {
        switch self {
        case .ja: return "\(name)行"
        case .en: return "for \(name)"
        case .zh: return "开往\(name)"
        case .ko: return "\(name)행"
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
        case .ko:
            switch phase {
            case .next: return "다음역"
            case .approaching: return "잠시 후"
            case .dwelling: return "이번역"
            }
        }
    }

    /// The 方面 riding under a 〜方面 header.
    var directionSuffix: String {
        switch self {
        case .zh: return "方向"
        case .ko: return "방면"
        default: return "方面"
        }
    }

    /// The ゆき / 行 riding under a 行き先; each LCD sets its own Japanese wording.
    func destinationSuffix(japanese: String) -> String {
        switch self {
        case .zh: return "方向"
        case .ko: return "행"
        default: return japanese
        }
    }

    /// 所要時間
    var travelTimesLabel: String {
        switch self {
        case .ja: return "所要時間"
        case .en: return "Travel Times"
        case .zh: return "所需时间"
        case .ko: return "소요 시간"
        }
    }

    /// 〜の次は〜にとまります。, split either side of the following stop.
    var nextStopConnector: String {
        switch self {
        case .zh: return "的下一站是"
        case .ko: return "의 다음은"
        default: return "の次は"
        }
    }

    var nextStopSuffix: String {
        switch self {
        case .zh: return "。"
        case .ko: return "에 정차합니다."
        default: return "にとまります。"
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
