import Foundation

// MARK: - Station Board Snapshot

nonisolated enum BoardTier: String, Codable {
    case local, rapid, express, limited
}

nonisolated struct BoardDeparture: Codable {
    let time: String
    let typeName: String
    let tier: BoardTier
    let destName: String
    let destCode: String
    /// 当駅始発
    let isOrigin: Bool

    var railMinutes: Int? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }
}

nonisolated struct BoardDirection: Codable {
    let directionId: String
    let name: String
    let isPrimary: Bool
    let departures: [BoardDeparture]
}

nonisolated struct BoardLine: Codable {
    let lineId: String
    let name: String
    let colorHex: String
    let stationCode: String
    let directions: [BoardDirection]
}

nonisolated struct BoardStation: Codable, Identifiable {
    let name: String
    let lines: [BoardLine]

    var id: String { name }
}

/// One favorite, pre-resolved for the control widget.
nonisolated struct BoardPlace: Codable, Identifiable {
    let id: UUID
    let title: String
    let destName: String
    let destCode: String
    let colorHex: String
}

nonisolated struct StationBoardSnapshot: Codable {
    let railDay: String
    let stations: [BoardStation]
    let places: [BoardPlace]
}

// MARK: - App Group Store

nonisolated enum AppGroup {
    static let id = "group.com.tsubuzaki.Overhead"
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }
}

nonisolated enum BoardSnapshotStore {
    static let pendingPlaceKey = "pendingDepartPlaceId"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id)?
            .appendingPathComponent("stationBoard.json")
    }

    static func load() -> StationBoardSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(StationBoardSnapshot.self, from: data)
    }

    static func save(_ snapshot: StationBoardSnapshot) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func railDay(for date: Date = Date()) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let anchored = date.addingTimeInterval(-3 * 3600)
        let c = cal.dateComponents([.year, .month, .day], from: anchored)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func railNowMinutes(at date: Date = Date()) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let c = cal.dateComponents([.hour, .minute], from: date)
        var minutes = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        if minutes < 180 { minutes += 1440 }
        return minutes
    }
}
