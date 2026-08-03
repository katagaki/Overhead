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
    /// Set only by user-created (Custom:) lines, whose station codes match no
    /// operator; nil leaves badge shape to the code-prefix dispatch.
    public var badgeStyle: BadgeStyle?

    public init(id: String, name: String, nameEn: String, nameKo: String = "", nameZhHans: String = "", nameZhHant: String = "", operatorId: String, stations: [Station], colorHex: String, badgeStyle: BadgeStyle? = nil) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.nameKo = nameKo
        self.nameZhHans = nameZhHans
        self.nameZhHant = nameZhHant
        self.operatorId = operatorId
        self.stations = stations
        self.colorHex = colorHex
        self.badgeStyle = badgeStyle
    }

    /// True for user-created lines. These never enter the static route graph,
    /// so they can't be transferred to/from built-in lines.
    public var isCustom: Bool { id.hasPrefix("Custom:") }

    public var color: Color {
        Color(hex: colorHex)
    }

    public var lineSymbol: String {
        // An explicit mapping wins: a line whose first station is a junction shared with
        // another operator would otherwise inherit that operator's letters (北総線 → KS).
        if let symbol = Self.symbolForRailwayId[id] { return symbol }
        if let station = stations.first(where: { !$0.stationCode.isEmpty }) {
            let letters = station.stationCode.prefix(while: \.isLetter)
            if !letters.isEmpty { return String(letters) }
        }
        return ""
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
        // Lines with no station numbering carry the JR mark instead, as JR East's
        // own app does.
        "Railway:JR-East.Uchibo": "JR",
        "Railway:JR-East.Sotobo": "JR",
        "Railway:JR-East.Sagami": "JR",
        "Railway:JR-East.Hachiko": "JR",
        "Railway:JR-East.Kawagoe": "JR",
        "Railway:JR-East.Togane": "JR",
        "Railway:JR-East.Kashima": "JR",
        "Railway:JR-East.Kururi": "JR",
        "Railway:JR-East.Agatsuma": "JR",
        "Railway:JR-East.Joetsu": "JR",
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
        // Lines starting at a junction owned by another line
        "Railway:Hokuso.Hokuso": "HS",        // starts at 京成高砂 (KS10)
        "Railway:Tobu.Isesaki": "TI",         // starts at 東武動物公園 (TS30 / TI01)
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
