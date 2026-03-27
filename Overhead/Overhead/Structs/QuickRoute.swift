import Foundation

// MARK: - Quick Route

struct QuickRoute: Identifiable, Codable, Equatable {
    let id: UUID
    var label: RouteLabel
    var lineId: String
    var fromStationId: String
    var toStationId: String

    enum RouteLabel: String, Codable, CaseIterable {
        case home
        case work
        case school

        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .work: return "briefcase.fill"
            case .school: return "graduationcap.fill"
            }
        }

        var localizationKey: String {
            switch self {
            case .home: return "Route.Home"
            case .work: return "Route.Work"
            case .school: return "Route.School"
            }
        }
    }
}
