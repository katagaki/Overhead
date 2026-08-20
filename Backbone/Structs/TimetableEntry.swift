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

    /// HH can exceed 23 (Japanese rail convention).
    public static func parseRailTime(_ timeStr: String) -> Int? {
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return nil }
        return h * 3600 + m * 60
    }

    /// Minutes on the rail day: before 03:00 counts as 24:00+ so post-midnight sorts last.
    public static func railMinutes(_ timeStr: String) -> Int? {
        guard let secs = parseRailTime(timeStr) else { return nil }
        return railMinutes(fromMinutes: secs / 60)
    }

    public static func railMinutes(fromMinutes minutes: Int) -> Int {
        minutes < 180 ? minutes + 1440 : minutes
    }
}
