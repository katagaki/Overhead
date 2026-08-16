import Foundation
import Backbone

// MARK: - Operator Sections

enum OperatorSections {
    /// Lines whose positions JR East publishes through どこトレ, not the main
    /// app. Listed apart so the JR東 section stays the urban network.
    static let dokoTrainSectionId = "Section:DokoTrain"
    static let dokoTrainRailways: Set<String> = [
        "Railway:JR-East.Uchibo",
        "Railway:JR-East.Sotobo",
        "Railway:JR-East.Sobu",
        "Railway:JR-East.Narita",
        "Railway:JR-East.NaritaAbikoBranch",
        "Railway:JR-East.NaritaAirportBranch",
        "Railway:JR-East.Togane",
        "Railway:JR-East.Kashima",
        "Railway:JR-East.Kururi",
        "Railway:JR-East.Sagami",
        "Railway:JR-East.Hachiko",
        "Railway:JR-East.Kawagoe",
        "Railway:JR-East.Joetsu",
        "Railway:JR-East.Agatsuma"
    ]

    static let order = [
        "Operator:JR-East",
        dokoTrainSectionId,
        "Operator:TokyoMetro",
        "Operator:Toei",
        "Operator:Keisei",
        "Operator:Tobu",
        "Operator:Odakyu",
        "Operator:Tokyu",
        "Operator:Keikyu",
        "Operator:Keio",
        "Operator:Seibu",
        "Operator:Sotetsu",
        "Operator:Minatomirai",
        "Operator:SaitamaRailway",
        "Operator:TWR",
        "Operator:MIR",
        "Operator:TokyoMonorail",
        "Operator:Yurikamome",
        "Operator:ToyoRapid",
        "Operator:Hokuso",
        "Operator:SaitamaTransit",
        "Operator:TamaMonorail",
        "Operator:YokohamaMunicipal",
        "Operator:YokohamaSeaside",
        "Operator:Enoden",
        "Operator:ShonanMonorail",
        "Operator:Shibayama",
        "Operator:Ryutetsu",
        "Operator:Choshi",
        "Operator:Jomo",
        "Operator:Kantetsu",
        "Operator:Hitachinaka",
        "Operator:Kominato",
        "Operator:Mooka"
    ]

    /// String catalog keys, resolved in `title(for:)`.
    static let titleKeys: [String: String] = [
        "Operator:JR-East": "Operator.JREast",
        dokoTrainSectionId: "Operator.DokoTrain",
        "Operator:TokyoMetro": "Operator.TokyoMetro",
        "Operator:Toei": "Operator.Toei",
        "Operator:Keisei": "Operator.Keisei",
        "Operator:Tobu": "Operator.Tobu",
        "Operator:Odakyu": "Operator.Odakyu",
        "Operator:Tokyu": "Operator.Tokyu",
        "Operator:Keikyu": "Operator.Keikyu",
        "Operator:Keio": "Operator.Keio",
        "Operator:Seibu": "Operator.Seibu",
        "Operator:Sotetsu": "Operator.Sotetsu",
        "Operator:Minatomirai": "Operator.Minatomirai",
        "Operator:SaitamaRailway": "Operator.SaitamaRailway",
        "Operator:TWR": "Operator.TWR",
        "Operator:MIR": "Operator.MIR",
        "Operator:TokyoMonorail": "Operator.TokyoMonorail",
        "Operator:Yurikamome": "Operator.Yurikamome",
        "Operator:ToyoRapid": "Operator.ToyoRapid",
        "Operator:Hokuso": "Operator.Hokuso",
        "Operator:SaitamaTransit": "Operator.SaitamaTransit",
        "Operator:TamaMonorail": "Operator.TamaMonorail",
        "Operator:YokohamaMunicipal": "Operator.YokohamaMunicipal",
        "Operator:YokohamaSeaside": "Operator.YokohamaSeaside",
        "Operator:Enoden": "Operator.Enoden",
        "Operator:ShonanMonorail": "Operator.ShonanMonorail",
        "Operator:Shibayama": "Operator.Shibayama",
        "Operator:Ryutetsu": "Operator.Ryutetsu",
        "Operator:Choshi": "Operator.Choshi",
        "Operator:Jomo": "Operator.Jomo",
        "Operator:Kantetsu": "Operator.Kantetsu",
        "Operator:Hitachinaka": "Operator.Hitachinaka",
        "Operator:Kominato": "Operator.Kominato",
        "Operator:Mooka": "Operator.Mooka"
    ]

    static func title(for operatorId: String) -> String {
        guard let key = titleKeys[operatorId] else { return operatorId }
        return String(localized: String.LocalizationValue(key))
    }

    /// Readings and aliases for search. The titles are kanji-only, so
    /// 「とうきゅう」/「tokyu」 would otherwise match nothing.
    static let searchTerms: [String: [String]] = [
        "Operator:JR-East": ["JR East", "JR東日本", "ジェイアール", "jeiaru"],
        dokoTrainSectionId: ["どこトレ", "dokotore", "doko train"],
        "Operator:TokyoMetro": ["東京メトロ", "とうきょうめとろ", "tokyo metro", "営団"],
        "Operator:Toei": ["都営地下鉄", "とえい", "toei"],
        "Operator:Keisei": ["けいせい", "keisei"],
        "Operator:Tobu": ["とうぶ", "tobu"],
        "Operator:Odakyu": ["おだきゅう", "odakyu"],
        "Operator:Tokyu": ["とうきゅう", "tokyu", "東京急行"],
        "Operator:Keikyu": ["けいきゅう", "keikyu", "京浜急行"],
        "Operator:Keio": ["けいおう", "keio"],
        "Operator:Seibu": ["せいぶ", "seibu"],
        "Operator:Sotetsu": ["そうてつ", "sotetsu", "相模鉄道"],
        "Operator:Minatomirai": ["みなとみらい", "minatomirai", "横浜高速鉄道"],
        "Operator:SaitamaRailway": ["埼玉高速鉄道", "さいたまこうそく", "saitama", "埼玉スタジアム線"],
        "Operator:TWR": ["りんかい", "rinkai", "東京臨海高速鉄道"],
        "Operator:MIR": ["つくばエクスプレス", "つくば", "tsukuba", "tx", "首都圏新都市鉄道"],
        "Operator:TokyoMonorail": ["とうきょうものれーる", "tokyo monorail", "monorail"],
        "Operator:Yurikamome": ["ゆりかもめ", "yurikamome"],
        "Operator:ToyoRapid": ["東葉高速鉄道", "とうよう", "toyo rapid"],
        "Operator:Hokuso": ["ほくそう", "hokuso"],
        "Operator:SaitamaTransit": ["埼玉新都市交通", "ニューシャトル", "new shuttle", "saitama"],
        "Operator:TamaMonorail": ["多摩都市モノレール", "たま", "tama monorail"],
        "Operator:YokohamaMunicipal": ["横浜市営地下鉄", "よこはま", "yokohama", "ブルーライン", "グリーンライン"],
        "Operator:YokohamaSeaside": ["横浜シーサイドライン", "しーさいど", "seaside", "yokohama"],
        "Operator:Enoden": ["江ノ電", "えのでん", "enoden", "enoshima"],
        "Operator:ShonanMonorail": ["湘南モノレール", "しょうなん", "shonan monorail"],
        "Operator:Shibayama": ["しばやま", "shibayama"],
        "Operator:Ryutetsu": ["りゅうてつ", "ryutetsu", "流山"],
        "Operator:Choshi": ["ちょうし", "choshi"],
        "Operator:Jomo": ["じょうもう", "jomo"],
        "Operator:Kantetsu": ["かんてつ", "kantetsu", "kanto railway"],
        "Operator:Hitachinaka": ["ひたちなか", "hitachinaka"],
        "Operator:Kominato": ["こみなと", "kominato"],
        "Operator:Mooka": ["もおか", "mooka"]
    ]

    /// Case-insensitive substring on the localized title and the readings,
    /// plus the phonetic skeleton so romaji and kana find each other.
    static func matches(operatorId: String, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let lowered = trimmed.lowercased()
        let key = JapaneseSearch.searchKey(trimmed)
        let kana = JapaneseSearch.kanaFolded(trimmed)

        for candidate in (searchTerms[operatorId] ?? []) + [title(for: operatorId)] {
            if candidate.lowercased().contains(lowered) { return true }
            if !key.isEmpty, JapaneseSearch.searchKey(candidate).contains(key) { return true }
            if !kana.isEmpty, JapaneseSearch.kanaFolded(candidate).contains(kana) { return true }
        }
        return false
    }

    /// Symbol order (JA, JB, JC… / A, C, E…); symbol-less lines last.
    static func sortedBySymbol(_ lines: [TrainLine]) -> [TrainLine] {
        lines.sorted {
            switch ($0.lineSymbol.isEmpty, $1.lineSymbol.isEmpty) {
            case (false, false):
                return $0.lineSymbol == $1.lineSymbol
                    ? $0.localizedName < $1.localizedName
                    : $0.lineSymbol < $1.lineSymbol
            case (false, true): return true
            case (true, false): return false
            case (true, true): return $0.localizedName < $1.localizedName
            }
        }
    }

    static func sections(
        for lines: [TrainLine]
    ) -> [(operatorId: String, title: String, lines: [TrainLine])] {
        let grouped = Dictionary(grouping: lines) {
            dokoTrainRailways.contains($0.id) ? dokoTrainSectionId : $0.operatorId
        }
        let sectionOrder = order.filter { grouped[$0] != nil }
            + grouped.keys.filter { !order.contains($0) }.sorted()
        return sectionOrder.compactMap { operatorId in
            guard let lines = grouped[operatorId] else { return nil }
            return (operatorId, title(for: operatorId), sortedBySymbol(lines))
        }
    }
}
