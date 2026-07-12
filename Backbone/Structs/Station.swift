import Foundation

public struct Station: Identifiable, Codable, Hashable {
    public let id: String          // e.g. "Station:JR-East.ChuoRapid.Shinjuku"
    public let name: String        // Japanese name
    public let nameEn: String      // English/Romaji name
    public let nameKo: String      // Korean name
    public let nameZhHans: String  // Simplified Chinese name
    public let nameZhHant: String  // Traditional Chinese name
    public let stationCode: String // e.g. "JC05"
    public let latitude: Double?
    public let longitude: Double?

    public init(id: String, name: String, nameEn: String, nameKo: String = "", nameZhHans: String = "", nameZhHant: String = "", stationCode: String, latitude: Double?, longitude: Double?) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.nameKo = nameKo
        self.nameZhHans = nameZhHans
        self.nameZhHant = nameZhHant
        self.stationCode = stationCode
        self.latitude = latitude
        self.longitude = longitude
    }

    public var displayCode: String {
        stationCode.isEmpty ? "" : stationCode
    }

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
