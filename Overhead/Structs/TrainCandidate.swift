import Foundation
import Backbone

// MARK: - Candidate Leg

struct CandidateLeg {
    let service: TrainService
    let line: TrainLine
    let fromStation: Station
    let toStation: Station
    let departureSeconds: Int   // seconds since service-day midnight (may exceed 24h)
    let arrivalSeconds: Int

    var departureTime: String { CandidateLeg.railTimeString(departureSeconds) }
    var arrivalTime: String { CandidateLeg.railTimeString(arrivalSeconds) }

    static func railTimeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 3600, (seconds % 3600) / 60)
    }
}

// MARK: - Train Candidate

struct TrainCandidate: Identifiable {
    let id: String
    let legs: [CandidateLeg]
    let isThrough: Bool
    let journeyLine: TrainLine
    let journeyService: TrainService
    let fromStation: Station
    let toStation: Station
    /// False for timetable-ignoring searches: leg seconds are hop-time
    /// estimates from 0, not clock times.
    var hasSchedule: Bool = true

    var transferCount: Int { legs.count - 1 }

    /// IDs are valid on `journeyLine` (the transfer station keeps the arriving leg's ID).
    var transferStationIds: [String] {
        legs.dropLast().map { $0.toStation.id }
    }
    var departureSeconds: Int { legs.first?.departureSeconds ?? 0 }
    var arrivalSeconds: Int { legs.last?.arrivalSeconds ?? 0 }
    var departureTime: String { legs.first?.departureTime ?? "" }
    var arrivalTime: String { legs.last?.arrivalTime ?? "" }

    var durationMinutes: Int {
        max(0, (arrivalSeconds - departureSeconds) / 60)
    }

    func departureDate(reference: Date = Date()) -> Date {
        Self.dateFromRailSeconds(departureSeconds, reference: reference)
    }

    func arrivalDate(reference: Date = Date()) -> Date {
        Self.dateFromRailSeconds(arrivalSeconds, reference: reference)
    }

    private static func dateFromRailSeconds(_ seconds: Int, reference: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var comps = cal.dateComponents([.year, .month, .day], from: reference)
        comps.hour = seconds / 3600
        comps.minute = (seconds % 3600) / 60
        comps.second = 0
        if comps.hour! >= 24 {
            comps.hour! -= 24
            if let d = cal.date(from: comps) {
                return cal.date(byAdding: .day, value: 1, to: d) ?? d
            }
        }
        return cal.date(from: comps) ?? reference
    }
}
