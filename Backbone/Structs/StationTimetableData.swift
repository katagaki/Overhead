import Foundation

public struct StationTimetableData: Codable {
    public let stationId: String
    public let railDirection: String
    public let railDirectionName: String
    public let railDirectionNameEn: String
    public let departures: [StationDeparture]

    public init(stationId: String, railDirection: String, railDirectionName: String, railDirectionNameEn: String, departures: [StationDeparture]) {
        self.stationId = stationId
        self.railDirection = railDirection
        self.railDirectionName = railDirectionName
        self.railDirectionNameEn = railDirectionNameEn
        self.departures = departures
    }

    public var localizedDirectionName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        switch lang {
        case "en": return railDirectionNameEn.isEmpty ? railDirectionName : railDirectionNameEn
        default: return railDirectionName
        }
    }
}
