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
        return journey.railSeconds(at: now) >= target - approachSeconds ? .approaching : .next
    }
}
