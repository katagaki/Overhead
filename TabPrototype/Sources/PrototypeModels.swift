import Foundation
import SwiftUI

struct FauxJourney: Codable, Hashable, Identifiable {
    var id = UUID()
    var lineName: String
    var lineSymbol: String
    var colorHex: String
    var origin: String
    var destination: String
    var stops: [String]
    var startedAt: Date
    var durationMinutes: Int

    var color: Color { Color(hex: colorHex) }

    func progress(at date: Date) -> Double {
        guard durationMinutes > 0 else { return 1 }
        return min(max(date.timeIntervalSince(startedAt) / Double(durationMinutes * 60), 0), 1)
    }

    func currentStopIndex(at date: Date) -> Int {
        guard !stops.isEmpty else { return 0 }
        return min(Int(progress(at: date) * Double(max(stops.count - 1, 1))), stops.count - 1)
    }

    func nextStop(at date: Date) -> String {
        guard !stops.isEmpty else { return destination }
        return stops[min(currentStopIndex(at: date) + 1, stops.count - 1)]
    }

    static func sample(
        lineName: String = "Yamanote Line",
        lineSymbol: String = "JY",
        colorHex: String = "84BD00",
        origin: String = "Shibuya",
        destination: String = "Tokyo"
    ) -> FauxJourney {
        FauxJourney(
            lineName: lineName,
            lineSymbol: lineSymbol,
            colorHex: colorHex,
            origin: origin,
            destination: destination,
            stops: [origin, "Ebisu", "Shinagawa", "Shimbashi", destination],
            startedAt: Date().addingTimeInterval(-8 * 60),
            durationMinutes: 27
        )
    }
}

struct PlannerDraft: Codable, Hashable {
    var origin = "Kichijoji"
    var destination = "Yokohama"
    var departureOffset = 0
    var prefersFirstTrain = false
    var hasSearched = false
}

enum PrototypePage: Codable, Hashable {
    case planner
    case search
    case journey(FauxJourney)
}

struct PrototypeTab: Codable, Hashable, Identifiable {
    var id = UUID()
    var page: PrototypePage
    var planner = PlannerDraft()
    var searchQuery = ""
    var lastViewedAt = Date()

    var title: String {
        switch page {
        case .planner:
            return planner.hasSearched ? "\(planner.origin) to \(planner.destination)" : "Journey Planner"
        case .search:
            return searchQuery.isEmpty ? "Search" : searchQuery
        case .journey(let journey):
            return "\(journey.origin) to \(journey.destination)"
        }
    }

    var systemImage: String {
        switch page {
        case .planner: "point.topleft.down.to.point.bottomright.curvepath"
        case .search: "magnifyingglass"
        case .journey: "tram.fill"
        }
    }

    var accent: Color {
        if case .journey(let journey) = page { return journey.color }
        return .indigo
    }
}

struct PrototypeSession: Codable {
    var version = 2
    var selectedTabID: UUID
    var tabs: [PrototypeTab]
    var activeJourney: FauxJourney?
}

struct FauxSearchResult: Identifiable, Hashable {
    let id: String
    let station: String
    let line: String
    let operatorName: String
    let symbol: String
    let colorHex: String

    var color: Color { Color(hex: colorHex) }

    static let samples = [
        FauxSearchResult(id: "ginza-g", station: "Ginza", line: "Ginza Line", operatorName: "Tokyo Metro", symbol: "G", colorHex: "F39700"),
        FauxSearchResult(id: "tokyo-m", station: "Tokyo", line: "Marunouchi Line", operatorName: "Tokyo Metro", symbol: "M", colorHex: "E60012"),
        FauxSearchResult(id: "shibuya-jy", station: "Shibuya", line: "Yamanote Line", operatorName: "JR East", symbol: "JY", colorHex: "84BD00"),
        FauxSearchResult(id: "shinjuku-jc", station: "Shinjuku", line: "Chuo Line", operatorName: "JR East", symbol: "JC", colorHex: "F15A22"),
        FauxSearchResult(id: "yokohama-jk", station: "Yokohama", line: "Keihin-Tohoku Line", operatorName: "JR East", symbol: "JK", colorHex: "00A7DB"),
        FauxSearchResult(id: "asakusa-a", station: "Asakusa", line: "Asakusa Line", operatorName: "Toei Subway", symbol: "A", colorHex: "E85298"),
        FauxSearchResult(id: "kichijoji-jb", station: "Kichijoji", line: "Chuo-Sobu Line", operatorName: "JR East", symbol: "JB", colorHex: "FFD400")
    ]
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(cleaned, radix: 16) ?? 0x666666
        self.init(
            red: Double((value >> 16) & 0xff) / 255,
            green: Double((value >> 8) & 0xff) / 255,
            blue: Double(value & 0xff) / 255
        )
    }
}
