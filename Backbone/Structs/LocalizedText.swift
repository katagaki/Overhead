import Foundation

/// A rider-facing string in every language the data carries.
///
/// The data groups translations under one key — `name`, `checkMethod` — so a
/// new language is a key inside the group rather than a new sibling field.
/// Japanese is the language every entry has, so it is what a missing
/// translation falls back to.
public struct LocalizedText: Codable, Hashable, Sendable {
    public var ja: String
    public var en: String
    public var ko: String
    public var zhHans: String
    public var zhHant: String

    enum CodingKeys: String, CodingKey {
        case ja, en, ko
        case zhHans = "zh-Hans"
        case zhHant = "zh-Hant"
    }

    public init(ja: String, en: String = "", ko: String = "",
                zhHans: String = "", zhHant: String = "") {
        self.ja = ja
        self.en = en
        self.ko = ko
        self.zhHans = zhHans
        self.zhHant = zhHant
    }

    public init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        ja = try box.decodeIfPresent(String.self, forKey: .ja) ?? ""
        en = try box.decodeIfPresent(String.self, forKey: .en) ?? ""
        ko = try box.decodeIfPresent(String.self, forKey: .ko) ?? ""
        zhHans = try box.decodeIfPresent(String.self, forKey: .zhHans) ?? ""
        zhHant = try box.decodeIfPresent(String.self, forKey: .zhHant) ?? ""
    }

    /// Only the languages that have text, so the data stays free of blanks.
    public func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        if !ja.isEmpty { try box.encode(ja, forKey: .ja) }
        if !en.isEmpty { try box.encode(en, forKey: .en) }
        if !ko.isEmpty { try box.encode(ko, forKey: .ko) }
        if !zhHans.isEmpty { try box.encode(zhHans, forKey: .zhHans) }
        if !zhHant.isEmpty { try box.encode(zhHant, forKey: .zhHant) }
    }

    /// The running language's text, falling back to Japanese.
    public var localized: String {
        switch Locale.current.language.languageCode?.identifier ?? "ja" {
        case "en": return en.isEmpty ? ja : en
        case "ko": return ko.isEmpty ? ja : ko
        case "zh":
            let script = Locale.current.language.script?.identifier ?? ""
            let text = script == "Hant" ? zhHant : zhHans
            return text.isEmpty ? ja : text
        default: return ja
        }
    }

    /// Joins two names per language, for the composite lines a through
    /// journey is shown as. A language missing on either side falls back to
    /// Japanese, so the joined name never mixes scripts by accident.
    public static func joined(_ first: LocalizedText, _ second: LocalizedText,
                              separator: String, englishSeparator: String) -> LocalizedText {
        func pair(_ lhs: String, _ rhs: String, _ sep: String) -> String {
            let left = lhs.isEmpty ? first.ja : lhs
            let right = rhs.isEmpty ? second.ja : rhs
            return left + sep + right
        }
        return LocalizedText(
            ja: pair(first.ja, second.ja, separator),
            en: first.en.isEmpty || second.en.isEmpty
                ? "" : first.en + englishSeparator + second.en,
            ko: first.ko.isEmpty || second.ko.isEmpty
                ? "" : pair(first.ko, second.ko, separator),
            zhHans: first.zhHans.isEmpty || second.zhHans.isEmpty
                ? "" : pair(first.zhHans, second.zhHans, separator),
            zhHant: first.zhHant.isEmpty || second.zhHant.isEmpty
                ? "" : pair(first.zhHant, second.zhHant, separator))
    }

    /// For the places that still speak in a two-language pair.
    public var localizedJaEn: String {
        (Locale.current.language.languageCode?.identifier ?? "ja") == "ja"
            ? ja
            : (en.isEmpty ? ja : en)
    }
}
