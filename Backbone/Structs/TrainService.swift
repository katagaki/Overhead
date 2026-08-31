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
    // Off-line terminus for through-runs continuing past the line's end,
    // in every language the data carries it in.
    public var throughDestination: LocalizedText? = nil

    public var throughDestinationName: String? { throughDestination?.ja }
    public var throughDestinationNameEn: String? {
        throughDestination.map { $0.en.isEmpty ? $0.ja : $0.en }
    }

    public init(
        id: String,
        lineId: String,
        trainType: TrainType,
        direction: Direction,
        timetable: [TimetableEntry],
        destinationStationId: String,
        originatesAtStart: Bool = true,
        throughDestination: LocalizedText? = nil
    ) {
        self.id = id
        self.lineId = lineId
        self.trainType = trainType
        self.direction = direction
        self.timetable = timetable
        self.destinationStationId = destinationStationId
        self.originatesAtStart = originatesAtStart
        self.throughDestination = throughDestination
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

        public var displayNameEn: String {
            switch self {
            case .local: return "Local"
            case .semiExpress: return "Semi Express"
            case .sectionSemiExpress: return "Section Semi Exp."
            case .rapid: return "Rapid"
            case .sectionRapid: return "Section Rapid"
            case .commuterRapid: return "Commuter Rapid"
            case .specialRapid: return "Special Rapid"
            case .express: return "Express"
            case .sectionExpress: return "Section Express"
            case .rapidExpress: return "Rapid Express"
            case .commuterExpress: return "Commuter Exp."
            case .commuterSemiExpress: return "Commuter Semi Exp."
            case .liner: return "Liner"
            case .rapidLimitedExpress: return "Rapid Ltd. Exp."
            case .limitedExpress: return "Limited Express"
            case .commuterLimitedExpress: return "Commuter Ltd. Exp."
            }
        }

        public var localizedDisplayName: String {
            let lang = Locale.current.language.languageCode?.identifier ?? "ja"
            return lang == "en" ? displayNameEn : displayNameJa
        }

        public var skipsStations: Bool { self != .local }
    }

    public enum Direction: String, Codable {
        case inbound = "Inbound"
        case outbound = "Outbound"
    }
}
