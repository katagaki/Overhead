import Foundation
import Backbone

enum TrainPositionEngine {

    static func computePosition(
        journey: Journey,
        delay: DelayInfo?,
        at now: Date = RailClock.now
    ) -> TrainPositionState {
        let stations = journey.journeyStations
        let timetable = journey.journeyTimetable
        let delayMinutes = delay?.delayMinutes ?? 0
        let delaySec = delayMinutes * 60

        guard stations.count >= 2, !timetable.isEmpty else {
            return defaultState(stations: stations, delayMinutes: delayMinutes, now: now)
        }

        let nowSec = journey.railSeconds(at: now)

        var stationTimes: [(index: Int, seconds: Int)] = []
        for (i, station) in stations.enumerated() {
            if let entry = timetable.first(where: { $0.stationId == station.id }) {
                let sec = (entry.arrivalSeconds() ?? entry.departureSeconds()) ?? 0
                stationTimes.append((i, sec + delaySec))
            }
        }

        guard stationTimes.count >= 2 else {
            return defaultState(stations: stations, delayMinutes: delayMinutes, now: now)
        }

        let firstTime = stationTimes.first!.seconds
        let lastTime = stationTimes.last!.seconds

        if nowSec < firstTime {
            let nextStation = stations[0]
            let eta = journey.railDate(lastTime)
            return TrainPositionState(
                progress: 0.0,
                segmentFrom: 0, segmentTo: 1,
                segmentProgress: 0.0,
                currentStationIndex: nil,
                nextStationName: nextStation.name,
                nextStationNameEn: nextStation.nameEn,
                delayMinutes: delayMinutes,
                estimatedArrival: eta,
                status: delayMinutes > 0 ? .delayed : .notStarted,
                trackingModeRaw: TrackingMode.timetable.rawValue
            )
        }

        if nowSec >= lastTime {
            let lastStation = stations[stations.count - 1]
            return TrainPositionState(
                progress: 1.0,
                segmentFrom: stations.count - 2, segmentTo: stations.count - 1,
                segmentProgress: 1.0,
                currentStationIndex: stations.count - 1,
                nextStationName: lastStation.name,
                nextStationNameEn: lastStation.nameEn,
                delayMinutes: delayMinutes,
                estimatedArrival: journey.railDate(lastTime),
                status: .arrived,
                trackingModeRaw: TrackingMode.timetable.rawValue
            )
        }

        for j in 0..<(stationTimes.count - 1) {
            let fromTime = stationTimes[j].seconds
            let toTime = stationTimes[j + 1].seconds
            let fromIdx = stationTimes[j].index
            let toIdx = stationTimes[j + 1].index

            if nowSec >= fromTime && nowSec < toTime {
                let segDuration = Double(toTime - fromTime)
                let segProgress = segDuration > 0
                    ? Double(nowSec - fromTime) / segDuration
                    : 0.0

                let totalDuration = Double(lastTime - firstTime)
                let overallProgress = totalDuration > 0
                    ? Double(nowSec - firstTime) / totalDuration
                    : 0.0

                // Dwelling detection: within 30s of a station time
                var currentIdx: Int? = nil
                if nowSec - fromTime < 30 {
                    currentIdx = fromIdx
                }

                let nextStation = stations[toIdx]
                let status: TrainPositionState.Status = delayMinutes > 0 ? .delayed : .onTime

                return TrainPositionState(
                    progress: min(1.0, max(0.0, overallProgress)),
                    segmentFrom: fromIdx, segmentTo: toIdx,
                    segmentProgress: min(1.0, max(0.0, segProgress)),
                    currentStationIndex: currentIdx,
                    nextStationName: nextStation.name,
                    nextStationNameEn: nextStation.nameEn,
                    delayMinutes: delayMinutes,
                    estimatedArrival: journey.railDate(lastTime),
                    status: status,
                    trackingModeRaw: TrackingMode.timetable.rawValue
                )
            }
        }

        return defaultState(stations: stations, delayMinutes: delayMinutes, now: now)
    }

    private static func defaultState(stations: [Station], delayMinutes: Int, now: Date) -> TrainPositionState {
        let nextStation = stations.first ?? Station(
            id: "", name: "", nameEn: "", stationCode: "",
            latitude: nil, longitude: nil
        )
        return TrainPositionState(
            progress: 0.0,
            segmentFrom: 0, segmentTo: min(1, stations.count - 1),
            segmentProgress: 0.0,
            currentStationIndex: nil,
            nextStationName: nextStation.name,
            nextStationNameEn: nextStation.nameEn,
            delayMinutes: delayMinutes,
            estimatedArrival: now.addingTimeInterval(600),
            status: .notStarted,
            trackingModeRaw: TrackingMode.timetable.rawValue
        )
    }
}
