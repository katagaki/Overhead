import Foundation
import Backbone
import SwiftUI

// MARK: - Search Destinations

/// Catalog pages pushed onto a tab's navigation stack.
nonisolated enum SearchDestination: Hashable, Codable {
    case operatorLines(String)
    case line(String)
    case station(lineId: String, stationId: String)
    case stationWithDirection(lineId: String, stationId: String, directionId: String?)
    case serviceStatus(lineId: String)
}

private struct AppTabOpenDestinationKey: EnvironmentKey {
    static let defaultValue: ((SearchDestination) -> Void)? = nil
}

extension EnvironmentValues {
    /// Routes catalog links through the active tab when one owns this stack.
    var appTabOpenDestination: ((SearchDestination) -> Void)? {
        get { self[AppTabOpenDestinationKey.self] }
        set { self[AppTabOpenDestinationKey.self] = newValue }
    }
}

// MARK: - Scope

enum SearchScope: String, CaseIterable, Identifiable, Codable {
    case all
    case operators
    case lines
    case stations

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return String(localized: "Search.Scope.All")
        case .operators: return String(localized: "Search.Scope.Operators")
        case .lines: return String(localized: "Search.Scope.Lines")
        case .stations: return String(localized: "Search.Scope.Stations")
        }
    }

    var icon: String {
        switch self {
        case .all: return "magnifyingglass"
        case .operators: return "building.2.fill"
        case .lines: return "tram.fill"
        case .stations: return "mappin.and.ellipse"
        }
    }
}

// MARK: - Hits

struct OperatorSearchHit: Identifiable {
    let operatorId: String
    let title: String
    let lines: [TrainLine]

    var id: String { operatorId }
}

// MARK: - Catalog Search

/// Operator and line matching. Station matching stays in `StationSearch`.
enum CatalogSearch {

    static func operators(in lines: [TrainLine], query: String) -> [OperatorSearchHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let sections = OperatorSections.companies(for: lines)
        return sections.compactMap { section in
            guard trimmed.isEmpty || OperatorSections.matches(operatorId: section.operatorId, query: trimmed)
            else { return nil }
            return OperatorSearchHit(
                operatorId: section.operatorId,
                title: section.title,
                lines: section.lines
            )
        }
    }

    static func lines(in lines: [TrainLine], query: String) -> [TrainLine] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lowered = trimmed.lowercased()
        let phoneticKey = JapaneseSearch.searchKey(trimmed)

        let orderIndex = Dictionary(
            uniqueKeysWithValues: OperatorSections.order.enumerated().map { ($0.element, $0.offset) }
        )

        // Ranked once per line, not once per comparison.
        return lines
            .compactMap { line -> (rank: Int, line: TrainLine)? in
                guard let rank = rank(line, trimmed: trimmed, lowered: lowered, key: phoneticKey)
                else { return nil }
                return (rank, line)
            }
            .sorted { left, right in
                if left.rank != right.rank { return left.rank < right.rank }
                let leftOrder = orderIndex[left.line.operatorId] ?? .max
                let rightOrder = orderIndex[right.line.operatorId] ?? .max
                if leftOrder != rightOrder { return leftOrder < rightOrder }
                if left.line.lineSymbol != right.line.lineSymbol {
                    return left.line.lineSymbol < right.line.lineSymbol
                }
                return left.line.localizedName < right.line.localizedName
            }
            .map(\.line)
    }

    /// Nil when the line doesn't match at all; lower is a closer match.
    /// Operator-only matches rank last, so 東急東横線 beats the rest of 東急.
    private static func rank(_ line: TrainLine, trimmed: String, lowered: String, key: String) -> Int? {
        let names = [line.name, line.nameEn, line.localizedName]
        let symbol = line.lineSymbol.lowercased()

        if names.contains(where: { $0.lowercased() == lowered }) || symbol == lowered {
            return 0
        }
        if names.contains(where: { $0.lowercased().hasPrefix(lowered) }) || symbol.hasPrefix(lowered) {
            return 1
        }
        if names.contains(where: { $0.lowercased().contains(lowered) }) {
            return 2
        }
        if !key.isEmpty, JapaneseSearch.searchKey(line.nameEn).contains(key) {
            return 3
        }
        // Typing an operator lists everything it runs.
        if OperatorSections.matches(operatorId: line.operatorId, query: trimmed) {
            return 4
        }
        return nil
    }
}
