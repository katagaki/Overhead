import Foundation
import CoreLocation
import Combine
import Backbone

// MARK: - Tracking Mode

enum TrackingMode: String, Codable {
    case gps = "GPS"                     // GPS is good — using snapped location
    case timetable = "Timetable"         // GPS unreliable — using schedule + delay
    case blended = "Blended"             // Mixing both signals with confidence weights
}

// MARK: - Location-Based Train Tracker
/// Dual-mode tracker: GPS when above ground and accurate, timetable+delay
/// when underground or GPS is unreliable. Designed for Tokyo's mix of
/// above-ground JR lines and underground Metro/Toei lines.

final class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Published State

    @Published var currentLocation: CLLocation?
    @Published var positionState: TrainPositionState?
    @Published var trackingMode: TrackingMode = .timetable
    @Published var isTracking = false
    @Published var locationError: String?

    // MARK: - Config

    // User preference: GPS only, GPS + timetable, or timetable only.
    // Read live so switching modes mid-journey takes effect on the next tick.
    private var journeyMode: JourneyMode { .current }
    private var gpsStarted = false

    private let locationManager = CLLocationManager()
    private var journey: Journey?
    private var delay: DelayInfo?
    private var stationCoordinates: [(station: Station, coordinate: CLLocationCoordinate2D)] = []

    // Meters moved before recalculating
    private let distanceFilter: CLLocationDistance = 20

    // GPS accuracy thresholds (meters)
    private let excellentAccuracy: Double = 30      // Full GPS trust
    private let acceptableAccuracy: Double = 100    // Blend GPS + timetable
    private let poorAccuracy: Double = 250          // Timetable wins

    // Snap distance thresholds (meters from rail line)
    private let closeSnapDistance: Double = 150      // Clearly on the line
    private let farSnapDistance: Double = 500         // Probably underground or drifting
    // An ACCURATE fix beyond this distance from the line means the user has
    // genuinely strayed off the journey's route (e.g. standing in 東京 while
    // the journey runs 新宿→秋葉原) — not GPS noise. Snapping would produce a
    // confidently wrong position, so the timetable takes over instead.
    private let offRouteDistance: Double = 500

    // How long since last good GPS fix before falling back (seconds)
    private let gpsStalenessThreshold: TimeInterval = 45

    // Timetable tick timer — drives updates even when GPS is silent
    private var timetableTimer: Timer?

    private var lastGoodGPSTime: Date?

    private var recentAccuracies: [Double] = []
    private let accuracyWindowSize = 5

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = distanceFilter
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .otherNavigation
    }

    // MARK: - Start / Stop

    func startTracking(journey: Journey, delay: DelayInfo?) {
        self.journey = journey
        self.delay = delay
        self.recentAccuracies = []
        self.lastGoodGPSTime = nil

        stationCoordinates = buildStationCoordinates(for: journey)

        // Always start the timetable tick — it's the baseline
        startTimetableTick()

        if journeyMode == .timetable {
            trackingMode = .timetable
        } else {
            requestGPSIfAuthorized()
        }

        isTracking = true

        // Compute initial position immediately from timetable
        tickTimetable()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        gpsStarted = false
        currentLocation = nil
        timetableTimer?.invalidate()
        timetableTimer = nil
        isTracking = false
        journey = nil
        stationCoordinates = []
        recentAccuracies = []
        lastGoodGPSTime = nil
    }

    private func requestGPSIfAuthorized() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            beginGPSUpdates()
        default:
            locationError = "\(String(localized: "LocationError.NotAuthorized"))"
            trackingMode = .timetable
        }
    }

    /// Starts or stops GPS updates to match the journey mode preference —
    /// called on every tick so mid-journey changes take effect.
    private func syncGPSToJourneyMode() {
        if journeyMode == .timetable {
            guard gpsStarted else { return }
            locationManager.stopUpdatingLocation()
            gpsStarted = false
            currentLocation = nil
            lastGoodGPSTime = nil
        } else if !gpsStarted {
            requestGPSIfAuthorized()
        }
    }

    func updateDelay(_ delay: DelayInfo?) {
        self.delay = delay
        // Immediately recompute — delay changes affect both modes
        recalculate()
    }

    // Called from the Live Activity refresh button
    func forceRefresh() {
        tickTimetable()
    }

    // MARK: - Timetable Tick

    // Runs every 10 seconds regardless of GPS state — this is the heartbeat
    private func startTimetableTick() {
        timetableTimer?.invalidate()
        timetableTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.tickTimetable()
        }
    }

    private func tickTimetable() {
        guard let journey else { return }

        syncGPSToJourneyMode()

        let timetableState = TrainPositionEngine.computePosition(
            journey: journey, delay: delay
        )

        switch journeyMode {
        case .timetable:
            if trackingMode != .timetable {
                trackingMode = .timetable
            }
            positionState = timetableState
            updateLiveActivity()

        case .gps:
            // GPS drives once a fix exists — the timetable only bootstraps
            if currentLocation == nil {
                positionState = timetableState
                updateLiveActivity()
            }

        case .hybrid:
            // If GPS is stale, the timetable becomes the source of truth
            let gpsFresh = isGPSFresh()
            if !gpsFresh || trackingMode == .timetable {
                if gpsFresh == false && trackingMode == .gps {
                    trackingMode = .timetable
                }
                positionState = timetableState
                updateLiveActivity()
            }
            // If GPS is active and fresh, the GPS path handles updates — don't override
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if journey != nil, journeyMode != .timetable { beginGPSUpdates() }
        case .denied, .restricted:
            locationError = "\(String(localized: "LocationError.NotAuthorized"))"
            trackingMode = .timetable
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, journey != nil else { return }

        let age = -location.timestamp.timeIntervalSinceNow
        guard age < 20 else { return }

        currentLocation = location
        recordAccuracy(location.horizontalAccuracy)
        recalculate()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            locationError = "\(String(localized: "LocationError.Denied"))"
            trackingMode = .timetable
        }
    }

    // MARK: - Core Calculation

    private func recalculate() {
        guard journeyMode != .timetable else { return }
        guard let journey, let location = currentLocation else { return }

        let stations = journey.journeyStations
        guard stations.count >= 2 else {
            tickTimetable()
            return
        }

        let timetableState = TrainPositionEngine.computePosition(
            journey: journey, delay: delay
        )

        guard stationCoordinates.count >= 2 else {
            trackingMode = .timetable
            positionState = timetableState
            updateLiveActivity()
            return
        }

        let snapResult = snapToLine(location: location.coordinate)

        // GPS-only mode trusts the fix outright — no blending, no fallback
        if journeyMode == .gps {
            trackingMode = .gps
            lastGoodGPSTime = Date()
            positionState = buildGPSState(
                snapResult: snapResult,
                location: location.coordinate,
                journey: journey,
                stations: stations
            )
            updateLiveActivity()
            return
        }

        // Off-route check: the GPS fix is trustworthy AND clearly far from
        // the line — the user isn't on this train. Don't blend the snapped
        // position (it would be confidently wrong); fall back to timetable.
        if location.horizontalAccuracy <= acceptableAccuracy,
           snapResult.distance > offRouteDistance {
            trackingMode = .timetable
            lastGoodGPSTime = nil
            positionState = timetableState
            updateLiveActivity()
            return
        }

        let gpsConfidence = computeGPSConfidence(
            accuracy: location.horizontalAccuracy,
            snapDistance: snapResult.distance,
            age: -location.timestamp.timeIntervalSinceNow
        )

        if gpsConfidence >= 0.7 {
            trackingMode = .gps
            lastGoodGPSTime = Date()

            let gpsState = buildGPSState(
                snapResult: snapResult,
                location: location.coordinate,
                journey: journey,
                stations: stations
            )
            positionState = gpsState
            updateLiveActivity()

        } else if gpsConfidence >= 0.3 {
            trackingMode = .blended

            let gpsState = buildGPSState(
                snapResult: snapResult,
                location: location.coordinate,
                journey: journey,
                stations: stations
            )

            let blendedProgress = gpsState.progress * gpsConfidence
                                + timetableState.progress * (1.0 - gpsConfidence)

            // Use whichever source has more precise station detection
            let currentIdx = gpsState.currentStationIndex ?? timetableState.currentStationIndex
            let nextName = gpsConfidence > 0.5 ? gpsState.nextStationName : timetableState.nextStationName
            let nextNameEn = gpsConfidence > 0.5 ? gpsState.nextStationNameEn : timetableState.nextStationNameEn

            // ETA always comes from timetable (more reliable than GPS extrapolation)
            positionState = TrainPositionState(
                progress: blendedProgress,
                segmentFrom: gpsState.segmentFrom,
                segmentTo: gpsState.segmentTo,
                segmentProgress: gpsState.segmentProgress,
                currentStationIndex: currentIdx,
                nextStationName: nextName,
                nextStationNameEn: nextNameEn,
                delayMinutes: timetableState.delayMinutes,
                estimatedArrival: timetableState.estimatedArrival,
                status: timetableState.status,
                trackingModeRaw: TrackingMode.blended.rawValue
            )
            updateLiveActivity()

        } else {
            trackingMode = .timetable
            positionState = timetableState
            updateLiveActivity()
        }
    }

    // MARK: - GPS Confidence Scoring

    // 0.0 = useless, 1.0 = perfect
    private func computeGPSConfidence(
        accuracy: Double,
        snapDistance: Double,
        age: TimeInterval
    ) -> Double {
        let accuracyScore: Double
        if accuracy <= excellentAccuracy {
            accuracyScore = 1.0
        } else if accuracy <= acceptableAccuracy {
            accuracyScore = 1.0 - (accuracy - excellentAccuracy) / (acceptableAccuracy - excellentAccuracy) * 0.5
        } else if accuracy <= poorAccuracy {
            accuracyScore = 0.5 - (accuracy - acceptableAccuracy) / (poorAccuracy - acceptableAccuracy) * 0.4
        } else {
            accuracyScore = 0.1
        }

        let snapScore: Double
        if snapDistance <= closeSnapDistance {
            snapScore = 1.0
        } else if snapDistance <= farSnapDistance {
            snapScore = 1.0 - (snapDistance - closeSnapDistance) / (farSnapDistance - closeSnapDistance) * 0.7
        } else {
            snapScore = 0.1
        }

        let freshScore: Double
        if age < 5 { freshScore = 1.0 }
        else if age < 15 { freshScore = 0.8 }
        else if age < 30 { freshScore = 0.5 }
        else { freshScore = 0.2 }

        let trendScore: Double
        if recentAccuracies.count >= 3 {
            let avg = recentAccuracies.reduce(0, +) / Double(recentAccuracies.count)
            trendScore = avg <= acceptableAccuracy ? 1.0 : max(0.2, 1.0 - avg / 500)
        } else {
            trendScore = 0.5  // Not enough data yet
        }

        let confidence = accuracyScore * 0.3
                       + snapScore * 0.35
                       + freshScore * 0.15
                       + trendScore * 0.2

        return min(1.0, max(0.0, confidence))
    }

    private func recordAccuracy(_ accuracy: Double) {
        recentAccuracies.append(accuracy)
        if recentAccuracies.count > accuracyWindowSize {
            recentAccuracies.removeFirst()
        }
    }

    private func isGPSFresh() -> Bool {
        guard let lastGood = lastGoodGPSTime else { return false }
        return Date().timeIntervalSince(lastGood) < gpsStalenessThreshold
    }

    // MARK: - Build GPS-derived State

    private func buildGPSState(
        snapResult: SnapResult,
        location: CLLocationCoordinate2D,
        journey: Journey,
        stations: [Station]
    ) -> TrainPositionState {
        let currentStationIdx = detectDwelling(
            location: location,
            stations: stationCoordinates,
            threshold: 80
        )

        let nextIdx: Int
        if let current = currentStationIdx {
            nextIdx = min(current + 1, stations.count - 1)
        } else {
            nextIdx = snapResult.segmentTo
        }

        let eta = estimateArrival(
            journey: journey,
            currentProgress: snapResult.progress,
            delay: delay
        )

        let delayMins = delay?.delayMinutes ?? 0
        let status: TrainPositionState.Status
        if snapResult.progress >= 0.99 {
            status = .arrived
        } else if delayMins > 0 {
            status = .delayed
        } else {
            status = .onTime
        }

        return TrainPositionState(
            progress: snapResult.progress,
            segmentFrom: snapResult.segmentFrom,
            segmentTo: snapResult.segmentTo,
            segmentProgress: snapResult.segmentProgress,
            currentStationIndex: currentStationIdx,
            nextStationName: stations[nextIdx].name,
            nextStationNameEn: stations[nextIdx].nameEn,
            delayMinutes: delayMins,
            estimatedArrival: eta,
            status: status,
            trackingModeRaw: TrackingMode.gps.rawValue
        )
    }

    // MARK: - Line Snapping

    private struct SnapResult {
        let progress: Double
        let segmentFrom: Int
        let segmentTo: Int
        let segmentProgress: Double
        let distance: Double
    }

    private func snapToLine(location: CLLocationCoordinate2D) -> SnapResult {
        let coords = stationCoordinates
        guard coords.count >= 2 else {
            return SnapResult(progress: 0, segmentFrom: 0, segmentTo: 0,
                              segmentProgress: 0, distance: .infinity)
        }

        var bestDistance = Double.infinity
        var bestSegment = 0
        var bestT: Double = 0

        for i in 0..<(coords.count - 1) {
            let a = coords[i].coordinate
            let b = coords[i + 1].coordinate
            let (dist, t) = perpendicularDistance(
                point: location, lineStart: a, lineEnd: b
            )
            if dist < bestDistance {
                bestDistance = dist
                bestSegment = i
                bestT = t
            }
        }

        let totalSegments = Double(coords.count - 1)
        let progress = (Double(bestSegment) + bestT) / totalSegments

        return SnapResult(
            progress: min(1, max(0, progress)),
            segmentFrom: bestSegment,
            segmentTo: min(bestSegment + 1, coords.count - 1),
            segmentProgress: bestT,
            distance: bestDistance
        )
    }

    private func perpendicularDistance(
        point: CLLocationCoordinate2D,
        lineStart: CLLocationCoordinate2D,
        lineEnd: CLLocationCoordinate2D
    ) -> (distance: Double, t: Double) {
        let pLoc = CLLocation(latitude: point.latitude, longitude: point.longitude)
        let aLoc = CLLocation(latitude: lineStart.latitude, longitude: lineStart.longitude)

        let ab = segmentLength(a: lineStart, b: lineEnd)
        if ab < 1.0 {
            return (pLoc.distance(from: aLoc), 0)
        }

        let dx = lineEnd.longitude - lineStart.longitude
        let dy = lineEnd.latitude - lineStart.latitude
        let px = point.longitude - lineStart.longitude
        let py = point.latitude - lineStart.latitude

        let dot = px * dx + py * dy
        let lenSq = dx * dx + dy * dy
        var t = dot / lenSq
        t = max(0, min(1, t))

        let closestLat = lineStart.latitude + t * dy
        let closestLon = lineStart.longitude + t * dx
        let closestLoc = CLLocation(latitude: closestLat, longitude: closestLon)

        return (pLoc.distance(from: closestLoc), t)
    }

    private func segmentLength(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    // MARK: - Station Dwelling Detection

    private func detectDwelling(
        location: CLLocationCoordinate2D,
        stations: [(station: Station, coordinate: CLLocationCoordinate2D)],
        threshold: Double
    ) -> Int? {
        let userLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        for (i, entry) in stations.enumerated() {
            let stationLoc = CLLocation(latitude: entry.coordinate.latitude,
                                        longitude: entry.coordinate.longitude)
            if userLoc.distance(from: stationLoc) < threshold {
                return i
            }
        }
        return nil
    }

    // MARK: - ETA Estimation

    private func estimateArrival(
        journey: Journey,
        currentProgress: Double,
        delay: DelayInfo?
    ) -> Date {
        let timetable = journey.journeyTimetable
        let delaySeconds = (delay?.delayMinutes ?? 0) * 60

        if let lastEntry = timetable.last,
           let arrSec = lastEntry.arrivalSeconds() ?? lastEntry.departureSeconds() {
            return dateFromRailSeconds(arrSec + delaySeconds)
        }

        if let firstDep = timetable.first?.departureSeconds(),
           let lastArr = timetable.last?.arrivalSeconds() {
            let totalDuration = Double(lastArr - firstDep)
            let remaining = totalDuration * (1.0 - currentProgress)
            return Date().addingTimeInterval(remaining + Double(delaySeconds))
        }

        return Date().addingTimeInterval(600)
    }

    private func dateFromRailSeconds(_ seconds: Int) -> Date {
        let tz = TimeZone(identifier: "Asia/Tokyo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = seconds / 3600
        comps.minute = (seconds % 3600) / 60
        comps.second = seconds % 60
        if comps.hour! >= 24 {
            comps.hour! -= 24
            if let d = cal.date(from: comps) {
                return cal.date(byAdding: .day, value: 1, to: d) ?? d
            }
        }
        return cal.date(from: comps) ?? Date()
    }

    // MARK: - Station Coordinates Builder

    private func buildStationCoordinates(
        for journey: Journey
    ) -> [(station: Station, coordinate: CLLocationCoordinate2D)] {
        let stations = journey.journeyStations

        var coords: [(station: Station, coordinate: CLLocationCoordinate2D?)] =
            stations.map { station in
                if let lat = station.latitude, let lon = station.longitude {
                    return (station, CLLocationCoordinate2D(latitude: lat, longitude: lon))
                }
                return (station, nil)
            }

        for i in 0..<coords.count where coords[i].coordinate == nil {
            var beforeIdx: Int?
            var afterIdx: Int?
            for j in stride(from: i - 1, through: 0, by: -1) {
                if coords[j].coordinate != nil { beforeIdx = j; break }
            }
            for j in (i + 1)..<coords.count {
                if coords[j].coordinate != nil { afterIdx = j; break }
            }

            if let b = beforeIdx, let a = afterIdx,
               let bCoord = coords[b].coordinate,
               let aCoord = coords[a].coordinate {
                let t = Double(i - b) / Double(a - b)
                coords[i].coordinate = CLLocationCoordinate2D(
                    latitude: bCoord.latitude + t * (aCoord.latitude - bCoord.latitude),
                    longitude: bCoord.longitude + t * (aCoord.longitude - bCoord.longitude)
                )
            } else if let b = beforeIdx, let bCoord = coords[b].coordinate {
                coords[i].coordinate = bCoord
            } else if let a = afterIdx, let aCoord = coords[a].coordinate {
                coords[i].coordinate = aCoord
            }
        }

        return coords.compactMap { entry in
            guard let coord = entry.coordinate else { return nil }
            return (entry.station, coord)
        }
    }

    // MARK: - Helpers

    private func beginGPSUpdates() {
        locationManager.startUpdatingLocation()
        gpsStarted = true
        locationError = nil
    }

    private func updateLiveActivity() {
        guard let state = positionState else { return }
        LiveActivityManager.shared.updateActivity(positionState: state)
    }
}
