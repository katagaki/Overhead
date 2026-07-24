import Foundation

public struct TrainService: Identifiable, Codable {
    public let id: String              // Train number / service ID
    public let lineId: String
    public let trainType: TrainType
    public let direction: Direction
    public let timetable: [TimetableEntry]
    public let destinationStationId: String
    // 当駅始発; false for through-runs entering from a connecting line.
    public let originatesAtStart: Bool
    // Off-line terminus for through-runs continuing past the line's end.
    public var throughDestinationName: String? = nil
    public var throughDestinationNameEn: String? = nil

    public init(
        id: String,
        lineId: String,
        trainType: TrainType,
        direction: Direction,
        timetable: [TimetableEntry],
        destinationStationId: String,
        originatesAtStart: Bool = true,
        throughDestinationName: String? = nil,
        throughDestinationNameEn: String? = nil
    ) {
        self.id = id
        self.lineId = lineId
        self.trainType = trainType
        self.direction = direction
        self.timetable = timetable
        self.destinationStationId = destinationStationId
        self.originatesAtStart = originatesAtStart
        self.throughDestinationName = throughDestinationName
        self.throughDestinationNameEn = throughDestinationNameEn
    }

    public enum TrainType: String, Codable, Sendable, CaseIterable {
        case local = "Local"
        case semiExpress = "SemiExpress"
        case sectionSemiExpress = "SectionSemiExpress"
        case rapid = "Rapid"
        case sectionRapid = "SectionRapid"
        case commuterRapid = "CommuterRapid"
        case specialRapid = "SpecialRapid"
        case express = "Express"
        case sectionExpress = "SectionExpress"
        case rapidExpress = "RapidExpress"
        case commuterExpress = "CommuterExpress"
        case commuterSemiExpress = "CommuterSemiExpress"
        case liner = "Liner"
        case rapidLimitedExpress = "RapidLimitedExpress"
        case limitedExpress = "LimitedExpress"
        case commuterLimitedExpress = "CommuterLimitedExpress"

        public var displayName: String { rawValue }
        public var displayNameJa: String {
            switch self {
            case .local: return "各停"
            case .semiExpress: return "準急"
            case .sectionSemiExpress: return "区間準急"
            case .rapid: return "快速"
            case .sectionRapid: return "区間快速"
            case .commuterRapid: return "通勤快速"
            case .specialRapid: return "特別快速"
            case .express: return "急行"
            case .sectionExpress: return "区間急行"
            case .rapidExpress: return "快速急行"
            case .commuterExpress: return "通勤急行"
            case .commuterSemiExpress: return "通勤準急"
            case .liner: return "ライナー"
            case .rapidLimitedExpress: return "快特"
            case .limitedExpress: return "特急"
            case .commuterLimitedExpress: return "通勤特急"
            }
        }

        public var skipsStations: Bool { self != .local }
    }

    public enum Direction: String, Codable {
        case inbound = "Inbound"
        case outbound = "Outbound"
    }
}
