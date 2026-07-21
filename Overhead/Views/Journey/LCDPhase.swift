import Foundation
import Backbone

/// Headline phase of the in-car LCDs: つぎは → まもなく → ただいま.
enum LCDPhase {
    case next, approaching, dwelling

    /// Within this many seconds of the scheduled arrival counts as まもなく.
    static let approachSeconds = 45

    static func of(journey: Journey, state: TrainPositionState, now: Date) -> LCDPhase {
        if state.currentStationIndex != nil { return .dwelling }
        let stations = journey.journeyStations
        guard stations.indices.contains(state.segmentTo) else { return .next }
        let stationId = stations[state.segmentTo].id
        guard let entry = journey.journeyTimetable.first(where: { $0.stationId == stationId }),
              let arrival = entry.arrivalSeconds() ?? entry.departureSeconds()
        else { return .next }
        let target = arrival + state.delayMinutes * 60
        return railSeconds(at: now) >= target - approachSeconds ? .approaching : .next
    }

    /// Seconds since midnight JST; pre-04:00 counts as 24:00+ (rail convention).
    static func railSeconds(at date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let c = cal.dateComponents([.hour, .minute, .second], from: date)
        var s = (c.hour ?? 0) * 3600 + (c.minute ?? 0) * 60 + (c.second ?? 0)
        if s < 4 * 3600 { s += 24 * 3600 }
        return s
    }
}
