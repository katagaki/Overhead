import Foundation
import SwiftUI
import Backbone

// MARK: - Operator Sections

enum OperatorSections {
    /// Sections that are not operators: an operator's own extra segments,
    /// named in the data (`Segments.json`). `Section:` keeps them apart from
    /// operator ids in the same section-id namespace.
    static let segmentPrefix = "Section:"

    /// Which section a line belongs to: its operator, or that operator's
    /// segment when the data puts it in one.
    static func sectionId(for line: TrainLine) -> String {
        guard let segment = line.segmentId else { return line.operatorId }
        return segmentPrefix + segment
    }

    static func segment(forSectionId sectionId: String) -> CatalogSegment? {
        guard sectionId.hasPrefix(segmentPrefix) else { return nil }
        return Catalog.segment(id: String(sectionId.dropFirst(segmentPrefix.count)))
    }

    /// Section order comes from the catalog's operator data; the list below
    /// is a fallback for catalogs published before operators moved into it.
    static var order: [String] {
        let ids = Catalog.catalogOperators.map(\.id)
        return ids.isEmpty ? fallbackOrder : ids
    }

    private static let fallbackOrder = [
        "Operator:JR-East",
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


    /// Names live in the data, in every language the app ships, so a new
    /// operator needs no app release.
    static func title(for operatorId: String) -> String {
        if let segment = segment(forSectionId: operatorId) { return segment.localizedName }
        return Catalog.operatorInfo(id: operatorId)?.localizedName ?? operatorId
    }

    /// Readings and aliases for search. The titles are kanji-only, so
    /// 「とうきゅう」/「tokyu」 would otherwise match nothing.
    static let searchTerms: [String: [String]] = [
        // どこトレ is JR東's own position service, so it finds JR東.
        "Operator:JR-East": ["JR East", "JR東日本", "ジェイアール", "jeiaru", "どこトレ", "dokotore"],
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

    /// Logo-mark primary colours for companies whose brand colour differs
    /// from their lines' route colours. Everyone else falls back to the first
    /// line's colour, which for single-line operators is the brand colour.
    private static let brandColorHex: [String: String] = [
        "Operator:JR-East": "#008803",      // JR mark green
        "Operator:TokyoMetro": "#109ED4",   // heart-M metro blue
        "Operator:Toei": "#39A869",         // 東京都 symbol green
        "Operator:Keisei": "#005AAB",
        "Operator:Tobu": "#00479D",
        "Operator:Odakyu": "#018BD3",
        "Operator:Tokyu": "#EE0011",
        "Operator:Keikyu": "#C7000B",
        "Operator:Keio": "#DD0077",
        "Operator:Seibu": "#036EB8",
        "Operator:Sotetsu": "#0068B7",
        "Operator:YokohamaMunicipal": "#0075C2"
    ]

    static func brandColor(for operatorId: String, lines: [TrainLine]) -> Color {
        // A segment wears its operator's colours.
        let operatorId = segment(forSectionId: operatorId)?.operatorId ?? operatorId
        if let hex = Catalog.operatorInfo(id: operatorId)?.brandColorHex ?? brandColorHex[operatorId] {
            return Color(hex: hex)
        }
        return lines.first?.color ?? .secondary
    }

    /// Case-insensitive substring on the localized title and the readings,
    /// plus the phonetic skeleton so romaji and kana find each other.
    static func matches(operatorId: String, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        let lowered = trimmed.lowercased()
        let key = JapaneseSearch.searchKey(trimmed)
        let kana = JapaneseSearch.kanaFolded(trimmed)

        let terms = segment(forSectionId: operatorId)?.searchTerms
            ?? Catalog.operatorInfo(id: operatorId)?.searchTerms
            ?? searchTerms[operatorId] ?? []
        for candidate in terms + [title(for: operatorId)] {
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
        let grouped = Dictionary(grouping: lines, by: sectionId(for:))
        // Each operator is followed by its own segments.
        var sectionOrder: [String] = []
        for operatorId in order {
            if grouped[operatorId] != nil { sectionOrder.append(operatorId) }
            for segment in Catalog.segments(ofOperator: operatorId) {
                let id = segmentPrefix + segment.id
                if grouped[id] != nil { sectionOrder.append(id) }
            }
        }
        sectionOrder += grouped.keys.filter { !sectionOrder.contains($0) }.sorted()
        return sectionOrder.compactMap { operatorId in
            guard let lines = grouped[operatorId] else { return nil }
            return (operatorId, title(for: operatorId), sortedBySymbol(lines))
        }
    }

    /// One operator's lines, split into its own and each of its segments.
    /// The default group has no title — the screen is already named for it.
    static func groups(
        forOperator operatorId: String, lines: [TrainLine]
    ) -> [(id: String, title: String?, lines: [TrainLine])] {
        let mine = lines.filter { $0.operatorId == operatorId }
        var out: [(id: String, title: String?, lines: [TrainLine])] = []
        let ownLines = mine.filter { $0.segmentId == nil }
        if !ownLines.isEmpty {
            out.append((operatorId, nil, sortedBySymbol(ownLines)))
        }
        for segment in Catalog.segments(ofOperator: operatorId) {
            let segmentLines = mine.filter { $0.segmentId == segment.id }
            guard !segmentLines.isEmpty else { continue }
            out.append((segmentPrefix + segment.id, segment.localizedName,
                        sortedBySymbol(segmentLines)))
        }
        // A segment the catalog no longer names still has to go somewhere.
        let placed = Set(out.flatMap { $0.lines.map(\.id) })
        let orphans = mine.filter { !placed.contains($0.id) }
        if !orphans.isEmpty {
            out.append((operatorId + ".other", nil, sortedBySymbol(orphans)))
        }
        return out
    }

    /// Grouped by the company that actually runs the lines: どこトレ is a
    /// position-data source inside JR東, not an operator of its own.
    static func companies(
        for lines: [TrainLine]
    ) -> [(operatorId: String, title: String, lines: [TrainLine])] {
        let grouped = Dictionary(grouping: lines, by: \.operatorId)
        let companyOrder = order.filter { grouped[$0] != nil }
            + grouped.keys.filter { !order.contains($0) }.sorted()
        return companyOrder.compactMap { operatorId in
            guard let lines = grouped[operatorId] else { return nil }
            return (operatorId, title(for: operatorId), sortedBySymbol(lines))
        }
    }
}
