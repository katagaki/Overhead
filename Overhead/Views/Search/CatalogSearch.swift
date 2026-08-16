import Foundation
import Backbone

// MARK: - Search Destinations

/// What tapping a search result opens on the root stack.
enum SearchDestination: Hashable {
    case operatorLines(String)
    case line(String)
    case station(lineId: String, stationId: String)
}

// MARK: - Scope

enum SearchScope: String, CaseIterable, Identifiable {
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
        let sections = OperatorSections.sections(for: lines)
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

        let hits = lines.filter { rank($0, trimmed: trimmed, lowered: lowered, key: phoneticKey) != nil }
        let orderIndex = Dictionary(
            uniqueKeysWithValues: OperatorSections.order.enumerated().map { ($0.element, $0.offset) }
        )

        return hits.sorted { left, right in
            let leftRank = rank(left, trimmed: trimmed, lowered: lowered, key: phoneticKey) ?? 9
            let rightRank = rank(right, trimmed: trimmed, lowered: lowered, key: phoneticKey) ?? 9
            if leftRank != rightRank { return leftRank < rightRank }
            let leftOrder = orderIndex[left.operatorId] ?? .max
            let rightOrder = orderIndex[right.operatorId] ?? .max
            if leftOrder != rightOrder { return leftOrder < rightOrder }
            if left.lineSymbol != right.lineSymbol { return left.lineSymbol < right.lineSymbol }
            return left.localizedName < right.localizedName
        }
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
