import Foundation
import Combine

// MARK: - Demo Data Provider
/// Provides simulated journey data for demo mode.
/// Drives a realistic train journey progression with station dwelling,
/// delay simulation, and tracking mode transitions.

@MainActor
final class DemoDataProvider: ObservableObject {

    @Published var positionState: TrainPositionState?
    @Published var trackingMode: TrackingMode = .timetable
    @Published var currentDelay: DelayInfo?

    private var timer: Timer?
    private var journey: Journey?
    private var progress: Double = 0.0
    private var elapsedSeconds: Double = 0.0
    private var dwellCountdown: Int = 0
    private var currentStationDwellIndex: Int?

    /// Total simulated journey duration in seconds
    private let journeyDuration: Double = 120.0
    /// Tick interval
    private let tickInterval: TimeInterval = 1.0
    /// Seconds to dwell at each intermediate station
    private let dwellDuration: Int = 5

    // MARK: - Demo Lines & Data

    static let demoLines: [TrainLine] = [
        TrainLine(
            id: "odpt.Railway:JR-East.ChuoRapid",
            name: "中央線快速", nameEn: "Chuo Rapid Line",
            operatorId: "odpt.Operator:JR-East",
            stations: chuoRapidStations,
            colorHex: LineColors.chuoRapid
        ),
        TrainLine(
            id: "odpt.Railway:JR-East.Yamanote",
            name: "山手線", nameEn: "Yamanote Line",
            operatorId: "odpt.Operator:JR-East",
            stations: yamanoteStations,
            colorHex: LineColors.yamanote
        ),
        TrainLine(
            id: "odpt.Railway:TokyoMetro.Ginza",
            name: "銀座線", nameEn: "Ginza Line",
            operatorId: "odpt.Operator:TokyoMetro",
            stations: ginzaStations,
            colorHex: LineColors.ginza
        ),
        TrainLine(
            id: "odpt.Railway:TokyoMetro.Marunouchi",
            name: "丸ノ内線", nameEn: "Marunouchi Line",
            operatorId: "odpt.Operator:TokyoMetro",
            stations: marunouchiStations,
            colorHex: LineColors.marunouchi
        ),
    ]

    // MARK: - Station Data

    private static let chuoRapidStations: [Station] = [
        Station(id: "cr_s1", name: "東京", nameEn: "Tokyo", stationCode: "JC01",
                latitude: 35.6812, longitude: 139.7671),
        Station(id: "cr_s2", name: "神田", nameEn: "Kanda", stationCode: "JC02",
                latitude: 35.6918, longitude: 139.7709),
        Station(id: "cr_s3", name: "御茶ノ水", nameEn: "Ochanomizu", stationCode: "JC03",
                latitude: 35.6992, longitude: 139.7651),
        Station(id: "cr_s4", name: "四ツ谷", nameEn: "Yotsuya", stationCode: "JC04",
                latitude: 35.6860, longitude: 139.7340),
        Station(id: "cr_s5", name: "新宿", nameEn: "Shinjuku", stationCode: "JC05",
                latitude: 35.6896, longitude: 139.7006),
        Station(id: "cr_s6", name: "中野", nameEn: "Nakano", stationCode: "JC06",
                latitude: 35.7056, longitude: 139.6659),
        Station(id: "cr_s7", name: "高円寺", nameEn: "Koenji", stationCode: "JC07",
                latitude: 35.7053, longitude: 139.6496),
        Station(id: "cr_s8", name: "阿佐ヶ谷", nameEn: "Asagaya", stationCode: "JC08",
                latitude: 35.7043, longitude: 139.6358),
        Station(id: "cr_s9", name: "荻窪", nameEn: "Ogikubo", stationCode: "JC09",
                latitude: 35.7041, longitude: 139.6200),
        Station(id: "cr_s10", name: "吉祥寺", nameEn: "Kichijoji", stationCode: "JC11",
                latitude: 35.7030, longitude: 139.5796),
    ]

    private static let yamanoteStations: [Station] = [
        Station(id: "ym_s1", name: "渋谷", nameEn: "Shibuya", stationCode: "JY20",
                latitude: 35.6580, longitude: 139.7016),
        Station(id: "ym_s2", name: "原宿", nameEn: "Harajuku", stationCode: "JY19",
                latitude: 35.6702, longitude: 139.7027),
        Station(id: "ym_s3", name: "代々木", nameEn: "Yoyogi", stationCode: "JY18",
                latitude: 35.6832, longitude: 139.7020),
        Station(id: "ym_s4", name: "新宿", nameEn: "Shinjuku", stationCode: "JY17",
                latitude: 35.6896, longitude: 139.7006),
        Station(id: "ym_s5", name: "新大久保", nameEn: "Shin-Okubo", stationCode: "JY16",
                latitude: 35.7011, longitude: 139.7001),
        Station(id: "ym_s6", name: "高田馬場", nameEn: "Takadanobaba", stationCode: "JY15",
                latitude: 35.7126, longitude: 139.7038),
        Station(id: "ym_s7", name: "目白", nameEn: "Mejiro", stationCode: "JY14",
                latitude: 35.7210, longitude: 139.7068),
        Station(id: "ym_s8", name: "池袋", nameEn: "Ikebukuro", stationCode: "JY13",
                latitude: 35.7295, longitude: 139.7109),
    ]

    private static let ginzaStations: [Station] = [
        Station(id: "gz_s1", name: "渋谷", nameEn: "Shibuya", stationCode: "G01",
                latitude: 35.6580, longitude: 139.7016),
        Station(id: "gz_s2", name: "表参道", nameEn: "Omote-sando", stationCode: "G02",
                latitude: 35.6654, longitude: 139.7122),
        Station(id: "gz_s3", name: "外苑前", nameEn: "Gaiemmae", stationCode: "G03",
                latitude: 35.6706, longitude: 139.7178),
        Station(id: "gz_s4", name: "青山一丁目", nameEn: "Aoyama-itchome", stationCode: "G04",
                latitude: 35.6726, longitude: 139.7244),
        Station(id: "gz_s5", name: "赤坂見附", nameEn: "Akasaka-mitsuke", stationCode: "G05",
                latitude: 35.6770, longitude: 139.7370),
        Station(id: "gz_s6", name: "溜池山王", nameEn: "Tameike-sanno", stationCode: "G06",
                latitude: 35.6739, longitude: 139.7413),
        Station(id: "gz_s7", name: "虎ノ門", nameEn: "Toranomon", stationCode: "G07",
                latitude: 35.6693, longitude: 139.7498),
        Station(id: "gz_s8", name: "新橋", nameEn: "Shimbashi", stationCode: "G08",
                latitude: 35.6659, longitude: 139.7587),
        Station(id: "gz_s9", name: "銀座", nameEn: "Ginza", stationCode: "G09",
                latitude: 35.6717, longitude: 139.7639),
    ]

    private static let marunouchiStations: [Station] = [
        Station(id: "mn_s1", name: "荻窪", nameEn: "Ogikubo", stationCode: "M01",
                latitude: 35.7041, longitude: 139.6200),
        Station(id: "mn_s2", name: "南阿佐ヶ谷", nameEn: "Minami-Asagaya", stationCode: "M02",
                latitude: 35.6983, longitude: 139.6363),
        Station(id: "mn_s3", name: "新高円寺", nameEn: "Shin-Koenji", stationCode: "M03",
                latitude: 35.6958, longitude: 139.6494),
        Station(id: "mn_s4", name: "東高円寺", nameEn: "Higashi-Koenji", stationCode: "M04",
                latitude: 35.6960, longitude: 139.6575),
        Station(id: "mn_s5", name: "新中野", nameEn: "Shin-Nakano", stationCode: "M05",
                latitude: 35.6968, longitude: 139.6659),
        Station(id: "mn_s6", name: "中野坂上", nameEn: "Nakano-sakaue", stationCode: "M06",
                latitude: 35.6973, longitude: 139.6772),
        Station(id: "mn_s7", name: "西新宿", nameEn: "Nishi-shinjuku", stationCode: "M07",
                latitude: 35.6937, longitude: 139.6915),
        Station(id: "mn_s8", name: "新宿", nameEn: "Shinjuku", stationCode: "M08",
                latitude: 35.6896, longitude: 139.7006),
    ]

    // MARK: - Build Demo Journey

    func buildJourney(line: TrainLine, from boarding: Station, to alighting: Station) -> Journey {
        let timetable = buildTimetable(line: line, from: boarding, to: alighting)
        let service = TrainService(
            id: "demo_\(Int.random(in: 1000...9999))",
            lineId: line.id,
            trainType: .rapid,
            direction: .outbound,
            timetable: timetable,
            destinationStationId: alighting.id
        )
        return Journey(
            id: UUID(),
            service: service,
            line: line,
            boardingStationId: boarding.id,
            alightingStationId: alighting.id,
            startedAt: Date()
        )
    }

    private func buildTimetable(line: TrainLine, from boarding: Station, to alighting: Station) -> [TimetableEntry] {
        guard let startIdx = line.stations.firstIndex(where: { $0.id == boarding.id }),
              let endIdx = line.stations.firstIndex(where: { $0.id == alighting.id }) else {
            return []
        }

        let stationSlice: [Station]
        if startIdx <= endIdx {
            stationSlice = Array(line.stations[startIdx...endIdx])
        } else {
            stationSlice = Array(line.stations[endIdx...startIdx].reversed())
        }

        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        var entries: [TimetableEntry] = []

        for (i, station) in stationSlice.enumerated() {
            let minutesOffset = i * 3
            let stationTime = cal.date(byAdding: .minute, value: minutesOffset, to: now)!
            let comps = cal.dateComponents(in: TimeZone(identifier: "Asia/Tokyo")!, from: stationTime)
            let timeStr = String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)

            entries.append(TimetableEntry(
                id: "demo_tt_\(i)",
                stationId: station.id,
                arrivalTime: i == 0 ? nil : timeStr,
                departureTime: i == stationSlice.count - 1 ? nil : timeStr
            ))
        }

        return entries
    }

    // MARK: - Simulation Control

    func startSimulation(journey: Journey) {
        self.journey = journey
        self.progress = 0.0
        self.elapsedSeconds = 0.0
        self.dwellCountdown = 0
        self.currentStationDwellIndex = nil

        // Start with a small delay
        currentDelay = DelayInfo(
            lineId: journey.line.id,
            delayMinutes: 2,
            cause: "混雑のため",
            updatedAt: Date()
        )

        trackingMode = .timetable
        updatePositionState()
        startTimer()
    }

    func stopSimulation() {
        timer?.invalidate()
        timer = nil
        journey = nil
        positionState = nil
        currentDelay = nil
        progress = 0.0
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard let journey else { return }

        let stations = journey.journeyStations
        guard stations.count >= 2 else { return }

        // Handle dwelling at a station
        if dwellCountdown > 0 {
            dwellCountdown -= 1
            if dwellCountdown == 0 {
                currentStationDwellIndex = nil
            }
            updatePositionState()
            return
        }

        // Advance progress
        let increment = tickInterval / journeyDuration
        progress = min(1.0, progress + increment)
        elapsedSeconds += tickInterval

        // Check if we've reached a station
        let stationCount = stations.count
        for i in 1..<(stationCount - 1) {
            let stationFrac = Double(i) / Double(stationCount - 1)
            let prevProgress = progress - increment
            if prevProgress < stationFrac && progress >= stationFrac {
                // Arrived at intermediate station — dwell
                currentStationDwellIndex = i
                dwellCountdown = dwellDuration
                progress = stationFrac
                break
            }
        }

        // Simulate tracking mode transitions
        let phase = elapsedSeconds.truncatingRemainder(dividingBy: 40)
        if phase < 15 {
            trackingMode = .gps
        } else if phase < 25 {
            trackingMode = .blended
        } else {
            trackingMode = .timetable
        }

        // Simulate delay changes
        if Int(elapsedSeconds) % 30 == 0 && elapsedSeconds > 0 {
            let delayMins = [0, 1, 2, 3, 5].randomElement() ?? 0
            currentDelay = DelayInfo(
                lineId: journey.line.id,
                delayMinutes: delayMins,
                cause: delayMins > 0 ? ["混雑のため", "信号確認のため", "安全確認のため"].randomElement() : nil,
                updatedAt: Date()
            )
        }

        // Check arrival
        if progress >= 1.0 {
            progress = 1.0
            currentStationDwellIndex = stationCount - 1
            timer?.invalidate()
        }

        updatePositionState()
    }

    private func updatePositionState() {
        guard let journey else { return }

        let stations = journey.journeyStations
        guard stations.count >= 2 else { return }

        let stationCount = stations.count
        let totalSegments = stationCount - 1

        // Determine segment
        let rawSegment = progress * Double(totalSegments)
        let segmentFrom = min(Int(rawSegment), totalSegments - 1)
        let segmentTo = min(segmentFrom + 1, totalSegments)
        let segmentProgress = rawSegment - Double(segmentFrom)

        // Determine next station
        let nextIdx: Int
        if let dwellIdx = currentStationDwellIndex {
            nextIdx = min(dwellIdx + 1, stationCount - 1)
        } else {
            nextIdx = segmentTo
        }

        let delayMins = currentDelay?.delayMinutes ?? 0

        let status: TrainPositionState.Status
        if progress >= 1.0 {
            status = .arrived
        } else if delayMins > 0 {
            status = .delayed
        } else {
            status = .onTime
        }

        let remainingFraction = 1.0 - progress
        let remainingSeconds = remainingFraction * journeyDuration + Double(delayMins * 60)
        let eta = Date().addingTimeInterval(remainingSeconds)

        positionState = TrainPositionState(
            progress: progress,
            segmentFrom: segmentFrom,
            segmentTo: segmentTo,
            segmentProgress: min(1.0, max(0.0, segmentProgress)),
            currentStationIndex: currentStationDwellIndex,
            nextStationName: stations[nextIdx].name,
            nextStationNameEn: stations[nextIdx].nameEn,
            delayMinutes: delayMins,
            estimatedArrival: eta,
            status: status,
            trackingModeRaw: trackingMode.rawValue
        )
    }
}
