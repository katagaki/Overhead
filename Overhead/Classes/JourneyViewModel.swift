import Foundation
import SwiftUI
import Combine
import Backbone

// MARK: - Journey View Model (Location-Driven)

@MainActor
final class JourneyViewModel: ObservableObject {

    // Published state
    @Published var availableLines: [TrainLine] = []
    @Published var selectedLine: TrainLine?
    @Published var activeJourney: Journey?
    @Published var positionState: TrainPositionState?
    @Published var currentDelay: DelayInfo?
    @Published var trackingMode: TrackingMode = .timetable
    @Published var isLoading = false
    @Published var isStartingJourney = false
    @Published var errorMessage: String?
    @Published var locationError: String?
    @Published var isDemoMode = false
    @Published var stationTimetable: [StationTimetableData] = []
    @Published var isLoadingTimetable = false
    @Published var railDirections: [String: (ja: String, en: String)] = [:]

    // Services
    private let locationTracker = LocationTracker()
    private let demoProvider = DemoDataProvider()
    private var cancellables = Set<AnyCancellable>()
    private var timetableCache: [String: [TrainService]] = [:]
    private var linesLoaded = false

    init(previewMode: Bool = false) {
        bindLocationTracker()
        bindDemoProvider()
        if previewMode {
            loadPreviewData()
        }
    }

    /// Subscribe to LocationTracker's published position state
    private func bindLocationTracker() {
        locationTracker.$positionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, let state, !self.isDemoMode else { return }
                self.positionState = state
            }
            .store(in: &cancellables)

        locationTracker.$trackingMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                guard let self, !self.isDemoMode else { return }
                self.trackingMode = mode
            }
            .store(in: &cancellables)

        locationTracker.$locationError
            .receive(on: DispatchQueue.main)
            .assign(to: &$locationError)
    }

    /// Subscribe to DemoDataProvider's published state
    private func bindDemoProvider() {
        demoProvider.$positionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, self.isDemoMode, let state else { return }
                self.positionState = state

                // Drive Live Activity from demo state
                if let journey = self.activeJourney {
                    if LiveActivityManager.shared.hasActiveActivity {
                        LiveActivityManager.shared.updateActivity(positionState: state)
                    } else {
                        LiveActivityManager.shared.startActivity(
                            journey: journey,
                            positionState: state,
                            lineColorHex: journey.line.colorHex
                        )
                    }
                }
            }
            .store(in: &cancellables)

        demoProvider.$trackingMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                guard let self, self.isDemoMode else { return }
                self.trackingMode = mode
            }
            .store(in: &cancellables)

        demoProvider.$currentDelay
            .receive(on: DispatchQueue.main)
            .sink { [weak self] delay in
                guard let self, self.isDemoMode else { return }
                self.currentDelay = delay
            }
            .store(in: &cancellables)
    }

    // MARK: - Demo Mode

    func startDemoMode() {
        isDemoMode = true
        let demoLines = DemoDataProvider.demoLines
        availableLines = demoLines
        let line = demoLines[0]
        let stations = line.stations
        guard let from = stations.first, let to = stations.last else { return }

        selectedLine = line
        let journey = demoProvider.buildJourney(line: line, from: from, to: to)
        activeJourney = journey
        demoProvider.startSimulation(journey: journey)
    }

    func stopDemoMode() {
        demoProvider.stopSimulation()
        LiveActivityManager.shared.endActivity()
        isDemoMode = false
        activeJourney = nil
        positionState = nil
        currentDelay = nil
        selectedLine = nil
        availableLines = []
        linesLoaded = false
    }

    func startDemoJourney(
        line: TrainLine,
        from boardingStation: Station,
        to alightingStation: Station
    ) {
        // End any existing Live Activity before starting a new one
        LiveActivityManager.shared.endActivity()

        selectedLine = line
        let journey = demoProvider.buildJourney(line: line, from: boardingStation, to: alightingStation)
        activeJourney = journey
        demoProvider.startSimulation(journey: journey)
    }

    // MARK: - Load Lines

    func loadLines() async {
        if isDemoMode {
            availableLines = DemoDataProvider.demoLines
            linesLoaded = true
            return
        }

        guard !linesLoaded else { return }

        availableLines = StaticTrainData.trainLines()
        linesLoaded = true
        errorMessage = nil
        loadRailDirections()
    }

    func forceRefreshLines() async {
        guard !isDemoMode else { return }
        linesLoaded = false
        await loadLines()
    }

    // MARK: - Start Journey

    func startJourney(
        line: TrainLine,
        from boardingStation: Station,
        to alightingStation: Station
    ) async {
        isStartingJourney = true

        // Resolve the line to ride — this may span a through-service (直通)
        // junction onto a connecting line when the alighting station is past it.
        guard let resolved = StaticTrainData.resolveJourneyLine(
            lineId: line.id,
            fromStationId: boardingStation.id,
            toStationId: alightingStation.id
        ) else {
            errorMessage = "No timetable data available"
            isStartingJourney = false
            return
        }

        let journeyStaticLine = resolved.staticLine
        let journeyLine = journeyStaticLine.trainLine

        if timetableCache[journeyStaticLine.id] == nil {
            timetableCache[journeyStaticLine.id] = StaticTimetableGenerator.services(
                for: journeyStaticLine, calendar: .current()
            )
        }

        guard let services = timetableCache[journeyStaticLine.id] else {
            errorMessage = "No timetable data available"
            isStartingJourney = false
            return
        }

        // Find the best matching service
        let service = findBestService(
            services: services,
            from: boardingStation.id,
            to: alightingStation.id,
            at: Date()
        )

        guard let service else {
            errorMessage = "No matching train found for this time"
            isStartingJourney = false
            return
        }

        let journey = Journey(
            id: UUID(),
            service: service,
            line: journeyLine,
            boardingStationId: boardingStation.id,
            alightingStationId: alightingStation.id,
            startedAt: Date()
        )

        activeJourney = journey
        selectedLine = journeyLine

        // Start location-based tracking — this drives everything
        locationTracker.startTracking(journey: journey, delay: nil)

        // Compute initial position from timetable while GPS locks on
        positionState = TrainPositionEngine.computePosition(
            journey: journey, delay: nil
        )

        // Start Live Activity
        if let state = positionState {
            LiveActivityManager.shared.startActivity(
                journey: journey,
                positionState: state,
                lineColorHex: line.colorHex
            )
        }

        isStartingJourney = false
    }

    // MARK: - Stop Journey

    func stopJourney() {
        if isDemoMode {
            demoProvider.stopSimulation()
        } else {
            locationTracker.stopTracking()
            LiveActivityManager.shared.endActivity()
        }
        activeJourney = nil
        positionState = nil
        currentDelay = nil
    }

    // MARK: - Force Refresh (from Live Activity button)

    /// Triggered by the Live Activity refresh deep link.
    /// Recomputes the position and re-pushes to Live Activity.
    func forceRefresh() {
        guard activeJourney != nil else { return }
        locationTracker.forceRefresh()
        LiveActivityManager.shared.markDelayRefreshed()
    }

    // MARK: - Station Timetable

    func loadStationTimetable(stationId: String) {
        guard !isDemoMode else { return }
        isLoadingTimetable = true
        stationTimetable = []

        // Generate from bundled data whenever the station is covered
        if let staticLine = StaticTrainData.line(containingStationId: stationId) {
            stationTimetable = StaticTimetableGenerator.stationTimetables(
                for: staticLine,
                stationId: stationId,
                calendar: .current()
            )
        }

        isLoadingTimetable = false
    }

    // MARK: - Rail Directions

    func loadRailDirections() {
        guard railDirections.isEmpty else { return }
        railDirections = StaticTrainData.railDirections
    }

    // MARK: - Delay Check Sources

    /// Where and how to check for delays on a line (from bundled data).
    /// Composite through-journey line IDs ("A+B") fall back to the origin line.
    func delayCheckInfo(for lineId: String) -> DelayCheckInfo? {
        if let info = StaticTrainData.delayCheckInfo(forLineId: lineId) {
            return info
        }
        guard let originId = lineId.split(separator: "+").first else { return nil }
        return StaticTrainData.delayCheckInfo(forLineId: String(originId))
    }

    /// Returns a localized direction name for a rail direction ID
    func directionName(for directionId: String) -> String {
        guard let names = railDirections[directionId] else {
            return directionId
        }
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        switch lang {
        case "en": return names.en.isEmpty ? names.ja : names.en
        default: return names.ja
        }
    }

    // MARK: - Train Matching

    private func findBestService(
        services: [TrainService],
        from: String, to: String,
        at date: Date
    ) -> TrainService? {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents(in: TimeZone(identifier: "Asia/Tokyo")!, from: date)
        let nowSec = (comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60

        let candidates = services.filter { svc in
            let stationIds = svc.timetable.map(\.stationId)
            guard let fromIdx = stationIds.firstIndex(of: from),
                  let toIdx = stationIds.firstIndex(of: to),
                  fromIdx < toIdx else { return false }
            return true
        }

        let sorted = candidates.compactMap { svc -> (TrainService, Int)? in
            guard let entry = svc.timetable.first(where: { $0.stationId == from }),
                  let dep = entry.departureSeconds() else { return nil }
            return (svc, dep)
        }.sorted { $0.1 < $1.1 }

        return sorted.first(where: { $0.1 >= nowSec })?.0 ?? sorted.first?.0
    }

    // MARK: - Preview Data

    private func loadPreviewData() {
        let stations = [
            Station(id: "s1", name: "新宿", nameEn: "Shinjuku", stationCode: "JC05",
                    latitude: 35.6896, longitude: 139.7006),
            Station(id: "s2", name: "中野", nameEn: "Nakano", stationCode: "JC06",
                    latitude: 35.7056, longitude: 139.6659),
            Station(id: "s3", name: "高円寺", nameEn: "Koenji", stationCode: "JC07",
                    latitude: 35.7053, longitude: 139.6496),
            Station(id: "s4", name: "阿佐ヶ谷", nameEn: "Asagaya", stationCode: "JC08",
                    latitude: 35.7043, longitude: 139.6358),
            Station(id: "s5", name: "荻窪", nameEn: "Ogikubo", stationCode: "JC09",
                    latitude: 35.7041, longitude: 139.6200),
            Station(id: "s6", name: "西荻窪", nameEn: "Nishi-Ogikubo", stationCode: "JC10",
                    latitude: 35.7032, longitude: 139.5993),
            Station(id: "s7", name: "吉祥寺", nameEn: "Kichijoji", stationCode: "JC11",
                    latitude: 35.7030, longitude: 139.5796),
            Station(id: "s8", name: "三鷹", nameEn: "Mitaka", stationCode: "JC12",
                    latitude: 35.7027, longitude: 139.5607),
        ]

        let line = TrainLine(
            id: "odpt.Railway:JR-East.ChuoRapid",
            name: "中央線快速", nameEn: "Chuo Rapid Line",
            operatorId: "odpt.Operator:JR-East",
            stations: stations,
            colorHex: LineColors.chuoRapid
        )

        let timetable = [
            TimetableEntry(id: "t1", stationId: "s1", arrivalTime: nil, departureTime: "08:00"),
            TimetableEntry(id: "t2", stationId: "s2", arrivalTime: "08:04", departureTime: "08:05"),
            TimetableEntry(id: "t3", stationId: "s3", arrivalTime: "08:07", departureTime: "08:08"),
            TimetableEntry(id: "t4", stationId: "s4", arrivalTime: "08:10", departureTime: "08:11"),
            TimetableEntry(id: "t5", stationId: "s5", arrivalTime: "08:13", departureTime: "08:14"),
            TimetableEntry(id: "t6", stationId: "s6", arrivalTime: "08:16", departureTime: "08:17"),
            TimetableEntry(id: "t7", stationId: "s7", arrivalTime: "08:19", departureTime: "08:20"),
            TimetableEntry(id: "t8", stationId: "s8", arrivalTime: "08:23", departureTime: nil),
        ]

        let service = TrainService(
            id: "preview_001", lineId: line.id,
            trainType: .rapid, direction: .outbound,
            timetable: timetable, destinationStationId: "s8"
        )

        selectedLine = line
        activeJourney = Journey(
            id: UUID(), service: service, line: line,
            boardingStationId: "s1", alightingStationId: "s8", startedAt: Date()
        )
        currentDelay = DelayInfo(lineId: line.id, delayMinutes: 3, cause: "混雑のため", updatedAt: Date())
        positionState = TrainPositionState(
            progress: 0.35, segmentFrom: 2, segmentTo: 3,
            segmentProgress: 0.6, currentStationIndex: nil,
            nextStationName: "阿佐ヶ谷", nextStationNameEn: "Asagaya",
            delayMinutes: 3, estimatedArrival: Date().addingTimeInterval(1200),
            status: .delayed,
            trackingModeRaw: "Timetable"
        )
    }
}
