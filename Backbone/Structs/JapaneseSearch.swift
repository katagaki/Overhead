import Foundation

/// Folds kana, romaji and Hepburn/kunrei variants onto one skeleton, so 目黒
/// is reachable via めぐろ, メグロ or meguro.
public enum JapaneseSearch {

    // MARK: - Public

    /// Empty unless the whole input is readable (kana or Latin).
    public static func searchKey(_ text: String) -> String {
        cache.value(for: text) { isFullyPhonetic($0) ? skeleton(of: $0) : "" }
    }

    /// `key` must already be a skeleton.
    public static func matches(_ text: String, key: String) -> Bool {
        guard !key.isEmpty else { return false }
        return searchKey(text).contains(key)
    }

    /// Katakana to hiragana, small vowels grown, ヶ to が, long vowels collapsed.
    public static func kanaFolded(_ text: String) -> String {
        kanaCache.value(for: text) { input in
            var out = ""
            out.reserveCapacity(input.count)
            var previousVowel: Character?
            for character in input {
                if character == "ー" || character == "〜" || character == "・" { continue }
                // 霞ケ関/霞ヶ関/霞が関: the katakana ケ in a station name is always read が.
                let kana = (character == "ケ" || character == "ヶ") ? "が" : hiragana(character)
                let folded = kanaFolds[kana] ?? kana
                let vowel = vowelOfKana(folded)
                if let previousVowel, let vowel, plainVowels.contains(folded) {
                    if vowel == previousVowel || (previousVowel == "o" && vowel == "u") { continue }
                }
                out.append(folded)
                previousVowel = vowel
            }
            return out
        }
    }

    public static func hasPrefix(_ text: String, key: String) -> Bool {
        guard !key.isEmpty else { return false }
        return searchKey(text).hasPrefix(key)
    }

    public static func equals(_ text: String, key: String) -> Bool {
        guard !key.isEmpty else { return false }
        return searchKey(text) == key
    }

    // MARK: - Normalization

    /// Kanji have no derivable reading, so a key containing any is meaningless.
    public static func isFullyPhonetic(_ text: String) -> Bool {
        !text.unicodeScalars.contains { scalar in
            (0x3400...0x4DBF).contains(scalar.value)
                || (0x4E00...0x9FFF).contains(scalar.value)
                || (0xF900...0xFAFF).contains(scalar.value)
                || scalar.value == 0x3005
        }
    }

    private static func skeleton(of text: String) -> String {
        var s = kanaToRomaji(kanaFolded(text))
        s = s.folding(options: [.diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        s = s.lowercased()
        s = foldHepburn(s)
        s = collapse(s)
        return s
    }

    /// shi/si, chi/ti, tsu/tu, fu/hu and ji/zi all land together.
    private static func foldHepburn(_ s: String) -> String {
        var out = s
        for (from, to) in hepburnFolds {
            out = out.replacingOccurrences(of: from, with: to)
        }
        return out
    }

    /// Drops non-alphanumerics, folds n before b/p/m, collapses long vowels.
    private static func collapse(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        var previous: Character?
        for character in s {
            guard character.isLetter || character.isNumber, character.isASCII else { continue }
            if let previous {
                if vowels.contains(character) {
                    if previous == character { continue }
                    if previous == "o" && character == "u" { continue }
                }
                if previous == "m" && (character == "b" || character == "p" || character == "m") {
                    out.removeLast()
                    out.append("n")
                }
            }
            out.append(character)
            previous = character
        }
        return out
    }

    // MARK: - Kana

    private static func kanaToRomaji(_ text: String) -> String {
        var out = ""
        var pendingSokuon = false
        var index = text.startIndex

        func append(_ romaji: String) {
            if pendingSokuon, let first = romaji.first {
                out.append(first)
                pendingSokuon = false
            }
            out += romaji
        }

        while index < text.endIndex {
            let character = hiragana(text[index])

            if character == "っ" {
                pendingSokuon = true
                index = text.index(after: index)
                continue
            }
            if character == "ー" || character == "〜" {
                index = text.index(after: index)
                continue
            }

            let next = text.index(after: index)
            if next < text.endIndex {
                let pair = String([character, hiragana(text[next])])
                if let romaji = digraphs[pair] {
                    append(romaji)
                    index = text.index(after: next)
                    continue
                }
            }

            if let romaji = monographs[character] {
                append(romaji)
            } else {
                pendingSokuon = false
                out.append(text[index])
            }
            index = text.index(after: index)
        }
        return out
    }

    private static func hiragana(_ character: Character) -> Character {
        guard let scalar = character.unicodeScalars.first,
              character.unicodeScalars.count == 1,
              (0x30A1...0x30F6).contains(scalar.value),
              let shifted = Unicode.Scalar(scalar.value - 0x60) else { return character }
        return Character(shifted)
    }

    // MARK: - Tables

    private static let vowels: Set<Character> = ["a", "i", "u", "e", "o"]

    private static let plainVowels: Set<Character> = ["あ", "い", "う", "え", "お"]

    /// Nil for kanji, Latin and ん.
    private static func vowelOfKana(_ kana: Character) -> Character? {
        switch kana {
        case "ゃ": return "a"
        case "ゅ": return "u"
        case "ょ": return "o"
        default:
            guard let romaji = monographs[kana], romaji != "n", let last = romaji.last,
                  vowels.contains(last) else { return nil }
            return last
        }
    }

    private static let kanaFolds: [Character: Character] = [
        "ぁ": "あ", "ぃ": "い", "ぅ": "う", "ぇ": "え", "ぉ": "お",
        "ゖ": "が", "ゕ": "か", "ゎ": "わ", "ゐ": "い", "ゑ": "え"
    ]

    private static let hepburnFolds: [(String, String)] = [
        ("sha", "sya"), ("shu", "syu"), ("sho", "syo"), ("she", "sye"), ("shi", "si"),
        ("cha", "tya"), ("chu", "tyu"), ("cho", "tyo"), ("che", "tye"), ("chi", "ti"),
        ("tsu", "tu"),
        ("ja", "zya"), ("ju", "zyu"), ("jo", "zyo"), ("je", "zye"), ("ji", "zi"),
        ("fu", "hu")
    ]

    private static let monographs: [Character: String] = [
        "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
        "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
        "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko", "ゕ": "ka", "ゖ": "ke",
        "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
        "さ": "sa", "し": "si", "す": "su", "せ": "se", "そ": "so",
        "ざ": "za", "じ": "zi", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
        "た": "ta", "ち": "ti", "つ": "tu", "て": "te", "と": "to",
        "だ": "da", "ぢ": "zi", "づ": "zu", "で": "de", "ど": "do",
        "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
        "は": "ha", "ひ": "hi", "ふ": "hu", "へ": "he", "ほ": "ho",
        "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
        "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
        "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
        "や": "ya", "ゆ": "yu", "よ": "yo", "ゃ": "ya", "ゅ": "yu", "ょ": "yo",
        "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
        "わ": "wa", "ゐ": "i", "ゑ": "e", "を": "o", "ん": "n",
        "ゔ": "bu"
    ]

    private static let digraphs: [String: String] = {
        var table: [String: String] = [:]
        // Consonant stem per kana; small ya/yu/yo append the bare vowel.
        let bases: [Character: String] = [
            "き": "ky", "ぎ": "gy", "し": "sy", "じ": "zy", "ち": "ty", "ぢ": "zy",
            "に": "ny", "ひ": "hy", "び": "by", "ぴ": "py", "み": "my", "り": "ry"
        ]
        for (kana, stem) in bases {
            for (small, vowel) in [("ゃ", "a"), ("ゅ", "u"), ("ょ", "o")] {
                table[String(kana) + small] = stem + vowel
            }
        }
        return table
    }()

    // MARK: - Cache

    private final class Cache: @unchecked Sendable {
        private var storage: [String: String] = [:]
        private let lock = NSLock()

        func value(for key: String, compute: (String) -> String) -> String {
            lock.lock()
            if let cached = storage[key] {
                lock.unlock()
                return cached
            }
            lock.unlock()
            let computed = compute(key)
            lock.lock()
            if storage.count > 8000 { storage.removeAll(keepingCapacity: true) }
            storage[key] = computed
            lock.unlock()
            return computed
        }
    }

    private static let cache = Cache()
    private static let kanaCache = Cache()
}

public extension Station {
    var searchKeys: [String] {
        [JapaneseSearch.searchKey(nameEn), JapaneseSearch.searchKey(name)].filter { !$0.isEmpty }
    }

    /// Matches katakana names typed in hiragana.
    var kanaFoldedName: String {
        JapaneseSearch.kanaFolded(name)
    }
}
