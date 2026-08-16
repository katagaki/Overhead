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
