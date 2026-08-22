import Foundation

public struct Station: Identifiable, Codable, Hashable {
    public let id: String          // e.g. "Station:JR-East.ChuoRapid.Shinjuku"
    /// Every language the data carries, under the data's `name` key.
    public let names: LocalizedText
    public let stationCode: String // e.g. "JC05"
    public let latitude: Double?
    public let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, stationCode, latitude, longitude
        case names = "name"
    }

    public var name: String { names.ja }
    public var nameEn: String { names.en }
    public var nameKo: String { names.ko }
    public var nameZhHans: String { names.zhHans }
    public var nameZhHant: String { names.zhHant }

    public init(id: String, name: String, nameEn: String, nameKo: String = "", nameZhHans: String = "", nameZhHant: String = "", stationCode: String, latitude: Double?, longitude: Double?) {
        self.id = id
        self.names = LocalizedText(ja: name, en: nameEn, ko: nameKo,
                                   zhHans: nameZhHans, zhHant: nameZhHant)
        self.stationCode = stationCode
        self.latitude = latitude
        self.longitude = longitude
    }

    public var displayCode: String {
        stationCode.isEmpty ? "" : stationCode
    }

    public var localizedName: String { names.localized }
}
