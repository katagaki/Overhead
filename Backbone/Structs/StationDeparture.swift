import Foundation

public struct StationDeparture: Identifiable, Codable {
    public let id: String
    public let departureTime: String       // "HH:mm"
    public let trainType: TrainService.TrainType
    public let destinationName: String     // Localized destination name
    public let destinationNameEn: String
    public let trainNumber: String
    public let isFirst: Bool
    public let isLast: Bool

    public init(id: String, departureTime: String, trainType: TrainService.TrainType, destinationName: String, destinationNameEn: String, trainNumber: String, isFirst: Bool = false, isLast: Bool) {
        self.id = id
        self.departureTime = departureTime
        self.trainType = trainType
        self.destinationName = destinationName
        self.destinationNameEn = destinationNameEn
        self.trainNumber = trainNumber
        self.isFirst = isFirst
        self.isLast = isLast
    }

    public var localizedDestination: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        switch lang {
        case "en": return destinationNameEn.isEmpty ? destinationName : destinationNameEn
        default: return destinationName
        }
    }
}
