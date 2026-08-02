import Backbone

// MARK: - Operator Sections

enum OperatorSections {
    static let order = [
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
        "Operator:YokohamaSeaside"
    ]

    static let titles: [String: String] = [
        "Operator:JR-East": "JR東",
        "Operator:TokyoMetro": "東京メトロ",
        "Operator:Toei": "都営",
        "Operator:Keisei": "京成",
        "Operator:Tobu": "東武",
        "Operator:Odakyu": "小田急",
        "Operator:Tokyu": "東急",
        "Operator:Keikyu": "京急",
        "Operator:Keio": "京王",
        "Operator:Seibu": "西武",
        "Operator:Sotetsu": "相鉄",
        "Operator:Minatomirai": "みなとみらい線",
        "Operator:SaitamaRailway": "埼玉高速鉄道",
        "Operator:TWR": "りんかい線",
        "Operator:MIR": "つくばエクスプレス",
        "Operator:TokyoMonorail": "東京モノレール",
        "Operator:Yurikamome": "ゆりかもめ",
        "Operator:ToyoRapid": "東葉高速鉄道",
        "Operator:Hokuso": "北総鉄道",
        "Operator:SaitamaTransit": "埼玉新都市交通",
        "Operator:TamaMonorail": "多摩都市モノレール",
        "Operator:YokohamaMunicipal": "横浜市営地下鉄",
        "Operator:YokohamaSeaside": "横浜シーサイドライン"
    ]

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
        let grouped = Dictionary(grouping: lines) { $0.operatorId }
        let sectionOrder = order.filter { grouped[$0] != nil }
            + grouped.keys.filter { !order.contains($0) }.sorted()
        return sectionOrder.compactMap { operatorId in
            guard let lines = grouped[operatorId] else { return nil }
            return (operatorId, titles[operatorId] ?? operatorId, sortedBySymbol(lines))
        }
    }
}
