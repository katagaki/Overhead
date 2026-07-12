import Foundation

public struct TimetableEntry: Identifiable, Codable {
    public let id: String
    public let stationId: String
    public let arrivalTime: String?   // "HH:mm" — may be >24:00
    public let departureTime: String? // "HH:mm"

    public init(id: String, stationId: String, arrivalTime: String?, departureTime: String?) {
        self.id = id
        self.stationId = stationId
        self.arrivalTime = arrivalTime
        self.departureTime = departureTime
    }

    public func arrivalSeconds() -> Int? {
        guard let t = arrivalTime else { return nil }
        return Self.parseRailTime(t)
    }

    public func departureSeconds() -> Int? {
        guard let t = departureTime else { return nil }
        return Self.parseRailTime(t)
    }

    /// Parses "HH:mm" where HH can exceed 23 (Japanese rail convention).
    /// Returns seconds since midnight of the service day.
    public static func parseRailTime(_ timeStr: String) -> Int? {
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return nil }
        return h * 3600 + m * 60
    }
}
