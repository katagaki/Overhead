import Backbone

// MARK: - Operator Sections

enum OperatorSections {
    /// Lines whose live train positions JR East publishes through どこトレ rather
    /// than the main JR East app. Listed apart so the JR東 section stays the
    /// urban network.
    static let dokoTrainSectionId = "Section:DokoTrain"
    static let dokoTrainRailways: Set<String> = [
        "Railway:JR-East.Uchibo", "Railway:JR-East.Sotobo", "Railway:JR-East.Sobu",
        "Railway:JR-East.Narita", "Railway:JR-East.NaritaAbikoBranch",
        "Railway:JR-East.NaritaAirportBranch", "Railway:JR-East.Togane",
        "Railway:JR-East.Kashima", "Railway:JR-East.Kururi", "Railway:JR-East.Sagami",
        "Railway:JR-East.Hachiko", "Railway:JR-East.Kawagoe", "Railway:JR-East.Joetsu",
        "Railway:JR-East.Agatsuma",
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
        "Operator:YokohamaSeaside"
    ]

    static let titles: [String: String] = [
        "Operator:JR-East": "JR東",
        dokoTrainSectionId: "どこトレ",
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
        let grouped = Dictionary(grouping: lines) {
            dokoTrainRailways.contains($0.id) ? dokoTrainSectionId : $0.operatorId
        }
        let sectionOrder = order.filter { grouped[$0] != nil }
            + grouped.keys.filter { !order.contains($0) }.sorted()
        return sectionOrder.compactMap { operatorId in
            guard let lines = grouped[operatorId] else { return nil }
            return (operatorId, titles[operatorId] ?? operatorId, sortedBySymbol(lines))
        }
    }
}
