import Foundation
import SwiftUI

public struct TrainLine: Identifiable, Codable, Hashable {
    public let id: String           // e.g. "Railway:JR-East.ChuoRapid"
    public let name: String
    public let nameEn: String
    public let nameKo: String
    public let nameZhHans: String
    public let nameZhHant: String
    public let operatorId: String   // e.g. "Operator:JR-East"
    public let stations: [Station]
    public let colorHex: String     // Primary accent color

    public init(id: String, name: String, nameEn: String, nameKo: String = "", nameZhHans: String = "", nameZhHant: String = "", operatorId: String, stations: [Station], colorHex: String) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.nameKo = nameKo
        self.nameZhHans = nameZhHans
        self.nameZhHant = nameZhHant
        self.operatorId = operatorId
        self.stations = stations
        self.colorHex = colorHex
    }

    public var color: Color {
        Color(hex: colorHex)
    }

    public var lineSymbol: String {
        if let station = stations.first(where: { !$0.stationCode.isEmpty }) {
            let letters = station.stationCode.prefix(while: \.isLetter)
            if !letters.isEmpty { return String(letters) }
        }
        return Self.symbolForRailwayId[id] ?? ""
    }

    /// Whether this line uses JR-style badges (rounded rectangle)
    public var isJR: Bool {
        lineSymbol.hasPrefix("J")
    }

    private static let symbolForRailwayId: [String: String] = [
        // JR East
        "Railway:JR-East.Yamanote": "JY",
        "Railway:JR-East.KeihinTohoku": "JK",
        "Railway:JR-East.ChuoRapid": "JC",
        "Railway:JR-East.ChuoSobuLocal": "JB",
        "Railway:JR-East.SaikyoKawagoe": "JA",
        "Railway:JR-East.Keiyo": "JE",
        "Railway:JR-East.Yokohama": "JH",
        "Railway:JR-East.Nambu": "JN",
        "Railway:JR-East.YokosukaSobu": "JO",
        "Railway:JR-East.Tokaido": "JT",
        "Railway:JR-East.Utsunomiya": "JU",
        "Railway:JR-East.Takasaki": "JU",
        "Railway:JR-East.ShonanShinjuku": "JS",
        "Railway:JR-East.JobanRapid": "JJ",
        "Railway:JR-East.JobanLocal": "JL",
        "Railway:JR-East.Musashino": "JM",
        "Railway:JR-East.Tsurumi": "JI",
        "Railway:JR-East.Ome": "JC",
        "Railway:JR-East.Itsukaichi": "JC",
        "Railway:JR-East.NaritaExpress": "JO",
        "Railway:JR-East.Uchibo": "JR",
        "Railway:JR-East.Sotobo": "JR",
        "Railway:JR-East.Sagami": "JR",
        // Tokyo Metro
        "Railway:TokyoMetro.Ginza": "G",
        "Railway:TokyoMetro.Marunouchi": "M",
        "Railway:TokyoMetro.MarunouchiBranch": "Mb",
        "Railway:TokyoMetro.Hibiya": "H",
        "Railway:TokyoMetro.Tozai": "T",
        "Railway:TokyoMetro.Chiyoda": "C",
        "Railway:TokyoMetro.Yurakucho": "Y",
        "Railway:TokyoMetro.Hanzomon": "Z",
        "Railway:TokyoMetro.Namboku": "N",
        "Railway:TokyoMetro.Fukutoshin": "F",
        // Toei
        "Railway:Toei.Asakusa": "A",
        "Railway:Toei.Mita": "I",
        "Railway:Toei.Shinjuku": "S",
        "Railway:Toei.Oedo": "E",
        "Railway:Toei.NipporiToneri": "NT",
        "Railway:Toei.Toden": "SA",
    ]

    public var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        switch lang {
        case "en": return nameEn.isEmpty ? name : nameEn
        case "ko": return nameKo.isEmpty ? name : nameKo
        case "zh":
            let script = Locale.current.language.script?.identifier ?? ""
            if script == "Hant" {
                return nameZhHant.isEmpty ? name : nameZhHant
            }
            return nameZhHans.isEmpty ? name : nameZhHans
        default: return name
        }
    }
}
