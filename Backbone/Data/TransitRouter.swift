import Foundation

/// Timetable-aware route search (RAPTOR) over every generated train of a
/// service day. Round k settles the earliest arrival using at most k trains,
/// so one query yields the fastest trip for each number of changes.
public enum TransitRouter {

    // MARK: Results

    /// One train between two of its stops.
    public struct Ride: Sendable {
        public let lineId: String
        public let serviceId: String
        public let fromStationId: String
        public let toStationId: String
        public let departure: Int   // rail seconds
        public let arrival: Int
    }

    /// Time spent aboard without changing: several rides when the train runs
    /// through onto another line (直通) or on into a loop's next run.
    public struct Leg: Sendable {
        public let rides: [Ride]
        public var fromStationId: String { rides[0].fromStationId }
        public var toStationId: String { rides[rides.count - 1].toStationId }
        public var departure: Int { rides[0].departure }
        public var arrival: Int { rides[rides.count - 1].arrival }
    }

    public struct Itinerary: Sendable {
        public let legs: [Leg]
        public var departure: Int { legs[0].departure }
        public var arrival: Int { legs[legs.count - 1].arrival }
        public var transfers: Int { legs.count - 1 }
        var key: String { legs.flatMap { $0.rides.map(\.serviceId) }.joined(separator: "|") }
    }

    public enum Anchor: Sendable {
        case departAtOrAfter(Int)
        case arriveAtOrBefore(Int)
    }

    public struct Preferences: Sendable {
        public var transferMinutes: Double
        /// Multiplies the 80 m/min walking pace; 0 ignores walking.
        public var walkPace: Double
        /// Minutes of travel one fewer change is worth.
        public var transferAversionMinutes: Double
        public var avoidingLineIds: Set<String>
        public var maxTrains: Int

        public init(transferMinutes: Double, walkPace: Double = 1,
                    transferAversionMinutes: Double, avoidingLineIds: Set<String> = [],
                    maxTrains: Int = 5) {
            self.transferMinutes = transferMinutes
            self.walkPace = walkPace
            self.transferAversionMinutes = transferAversionMinutes
            self.avoidingLineIds = avoidingLineIds
            self.maxTrains = maxTrains
        }
    }

    // MARK: Search

    /// Itineraries through `stationIds` in order, nearest the anchor first.
    public static func search(
        through stationIds: [String],
        anchor: Anchor,
        on date: Date,
        preferences: Preferences,
        notDepartingBefore floor: Int? = nil,
        limit: Int
    ) -> [Itinerary] {
        guard stationIds.count >= 2 else { return [] }
        let query = Query(net: network(on: date), preferences: preferences)
        guard stationIds.allSatisfy({ !query.stops(at: $0).isEmpty }) else { return [] }

        switch anchor {
        case .departAtOrAfter(let time):
            return query.forwardChain(stationIds, from: max(time, floor ?? time), limit: limit)
        case .arriveAtOrBefore(let time):
            return query.backwardChain(stationIds, by: time, floor: floor, limit: limit)
        }
    }

    /// Builds the day's network ahead of the first search.
    public static func prepare(on date: Date) {
        _ = network(on: date).reversed
    }

    /// Rides that skip stations, timed by the day's fastest train making them,
    /// so planning without a timetable still knows an 急行 beats a 各停.
    public struct ExpressHops: Sendable {
        /// Line ID → station index → (station index, minutes).
        let byLine: [String: [Int: [(to: Int, minutes: Double)]]]

        func hops(onLine lineId: String, from index: Int) -> [(to: Int, minutes: Double)] {
            byLine[lineId]?[index] ?? []
        }
    }

    public static func expressHops(on date: Date) -> ExpressHops {
        network(on: date).expressHops
    }

    // MARK: Network Cache

    private static let cacheLock = NSLock()
    private static var cache: [(key: String, net: Network)] = []
    private static let buildLock = NSLock()

    static func network(on date: Date) -> Network {
        let calendar = ScheduleCalendar.current(at: date)
        let key = "\(StaticTrainData.dayKey(for: date))|\(calendar.rawValue)|\(StaticTrainData.generation)"
        if let hit = cached(key) { return hit }
        // One build at a time; a second caller waits and takes the result.
        buildLock.lock(); defer { buildLock.unlock() }
        if let hit = cached(key) { return hit }
        let built = Network(lines: StaticTrainData.lines(on: date), calendar: calendar,
                            links: StaticTrainData.stationLinks(on: date))
        cacheLock.lock()
        cache.removeAll { $0.key == key }
        cache.append((key, built))
        if cache.count > 2 { cache.removeFirst() }
        cacheLock.unlock()
        return built
    }

    private static func cached(_ key: String) -> Network? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        return cache.first { $0.key == key }?.net
    }
}

// MARK: - Network

extension TransitRouter {

    /// Every train of one service day, grouped into routes of identical stop
    /// sequences. Each line's station is its own stop. A train that runs on
    /// past the end of its timetable run is one trip across all its runs, so
    /// a later through train can beat an earlier one that terminates.
    final class Network: @unchecked Sendable {
        struct Route {
            let stops: [Int32]
            /// The line serving each position.
            let lines: [Int32]
            /// Trip indices, earliest first.
            let trips: [Int32]
        }

        struct Trip {
            let route: Int32
            let arrivals: [Int32]
            let departures: [Int32]
            /// Which generated service covers each run of positions.
            let segments: [Segment]
        }

        struct Segment {
            let service: Int32
            let start: Int32
            let end: Int32
        }

        struct Transfer {
            let stop: Int32
            let meters: Double
        }

        let lineIds: [String]
        let serviceIds: [String]
        let stopStation: [String]
        let stopIndex: [String: Int32]
        let routes: [Route]
        let trips: [Trip]
        let stopRoutes: [[(route: Int32, position: Int32)]]
        let transfers: [[Transfer]]
        let links: StationLinks
        private let reversedLock = NSLock()
        private var reversedNetwork: Network?
        private let expressLock = NSLock()
        private var builtExpressHops: ExpressHops?
        private let stationIndex: [String: Int]

        var expressHops: ExpressHops {
            expressLock.lock(); defer { expressLock.unlock() }
            if let builtExpressHops { return builtExpressHops }
            var fastest: [String: [Int: [Int: Int32]]] = [:]
            for route in routes {
                for p in 0..<(route.stops.count - 1) where route.lines[p] == route.lines[p + 1] {
                    guard let from = stationIndex[stopStation[Int(route.stops[p])]],
                          let to = stationIndex[stopStation[Int(route.stops[p + 1])]],
                          abs(to - from) > 1
                    else { continue }
                    let ride = route.trips.map { trips[Int($0)].arrivals[p + 1] - trips[Int($0)].departures[p] }.min() ?? 0
                    guard ride > 0 else { continue }
                    let lineId = lineIds[Int(route.lines[p])]
                    let existing = fastest[lineId]?[from]?[to] ?? .max
                    fastest[lineId, default: [:]][from, default: [:]][to] = min(existing, ride)
                }
            }
            let hops = ExpressHops(byLine: fastest.mapValues { byFrom in
                byFrom.mapValues { byTo in byTo.map { (to: $0.key, minutes: Double($0.value) / 60) } }
            })
            builtExpressHops = hops
            return hops
        }

        /// The same trains run backwards in negated time, for latest-departure searches.
        var reversed: Network {
            reversedLock.lock(); defer { reversedLock.unlock() }
            if let reversedNetwork { return reversedNetwork }
            let built = Network(reversing: self)
            reversedNetwork = built
            return built
        }

        convenience init(lines: [StaticTrainLine], calendar: ScheduleCalendar, links: StationLinks) {
            // Generated services run to megabytes; keep only what routing reads.
            struct Run {
                let line: Int
                let serviceId: String
                let ascending: Bool
                let originatesAtStart: Bool
                let stops: [Int32]
                let arrivals: [Int32]
                let departures: [Int32]
                /// Known to end here rather than run on; only run-based lines say so.
                let terminates: Bool
            }

            var stopStation: [String] = []
            var stopIndex: [String: Int32] = [:]
            for line in lines {
                for station in line.stations where stopIndex[station.id] == nil {
                    stopIndex[station.id] = Int32(stopStation.count)
                    stopStation.append(station.id)
                }
            }

            // Generation dominates the build; lines are independent.
            var perLine = [[Run]](repeating: [], count: lines.count)
            let lock = NSLock()
            DispatchQueue.concurrentPerform(iterations: lines.count) { li in
                let services = StaticTimetableGenerator.services(for: lines[li], calendar: calendar)
                let runBased = lines[li].timetableRuns != nil
                var built: [Run] = []
                built.reserveCapacity(services.count)
                for service in services {
                    var stops: [Int32] = [], arrivals: [Int32] = [], departures: [Int32] = []
                    for entry in service.timetable {
                        guard let stop = stopIndex[entry.stationId],
                              let a = entry.arrivalSeconds() ?? entry.departureSeconds(),
                              let d = entry.departureSeconds() ?? entry.arrivalSeconds()
                        else { continue }
                        stops.append(stop)
                        arrivals.append(Int32(a))
                        departures.append(Int32(max(a, d)))
                    }
                    guard stops.count >= 2 else { continue }
                    built.append(Run(line: li, serviceId: service.id, ascending: service.direction == .outbound,
                                     originatesAtStart: service.originatesAtStart, stops: stops,
                                     arrivals: arrivals, departures: departures,
                                     terminates: runBased && service.timetable.last?.departureTime == nil))
                }
                lock.lock(); perLine[li] = built; lock.unlock()
            }
            let runs = perLine.flatMap { $0 }

            var next = [Int](repeating: -1, count: runs.count)
            var previous = [Int](repeating: -1, count: runs.count)
            // Closest connections pair up first, so a train terminating just
            // before another can't steal its continuation.
            func pair(_ arriving: [Int], _ departing: [Int], within window: Int32 = 5 * 60) {
                var pairs: [(wait: Int32, from: Int, to: Int)] = []
                for t in arriving {
                    let arrival = runs[t].arrivals[runs[t].arrivals.count - 1]
                    for c in departing where c != t {
                        let wait = runs[c].departures[0] - arrival
                        if wait >= 0 && wait <= window { pairs.append((wait, t, c)) }
                    }
                }
                for pair in pairs.sorted(by: { $0.wait < $1.wait })
                where next[pair.from] < 0 && previous[pair.to] < 0 {
                    next[pair.from] = pair.to
                    previous[pair.to] = pair.from
                }
            }

            var runsByLine = [[Int]](repeating: [], count: lines.count)
            for (r, run) in runs.enumerated() { runsByLine[run.line].append(r) }

            // A loop's timetable splits its endless circuit into runs (山手線 at
            // 大崎 and 池袋); riders stay aboard from one run into the next.
            for (li, line) in lines.enumerated() where line.isLoop {
                var starting: [String: [Int]] = [:]
                var ending: [String: [Int]] = [:]
                for r in runsByLine[li] {
                    let direction = runs[r].ascending
                    starting["\(runs[r].stops[0])|\(direction)", default: []].append(r)
                    ending["\(runs[r].stops[runs[r].stops.count - 1])|\(direction)", default: []].append(r)
                }
                for (key, arriving) in ending {
                    if let departing = starting[key] { pair(arriving, departing) }
                }
            }

            // 直通: a run ending at a junction continues as the partner line's
            // run that enters there within a few minutes.
            let lineIndex = Dictionary(lines.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
            var starting: [Int32: [Int]] = [:]
            for (r, run) in runs.enumerated() {
                starting[run.stops[0], default: []].append(r)
            }
            for (li, line) in lines.enumerated() {
                for through in line.throughServices {
                    guard let partnerId = through.connectingLineId,
                          let partner = lineIndex[partnerId],
                          let junction = line.stations.first(where: { $0.id == through.junctionStationId }),
                          let partnerJunction = lines[partner].stations.first(where: { $0.name == junction.name }),
                          let fromStop = stopIndex[junction.id],
                          let toStop = stopIndex[partnerJunction.id],
                          let departing = starting[toStop]?.filter({ runs[$0].line == partner })
                    else { continue }
                    let towardEnd = through.end == .ascending
                    let arriving = runsByLine[li].filter { r in
                        let run = runs[r]
                        guard run.stops.last == fromStop, !run.terminates else { return false }
                        return run.ascending == towardEnd
                    }
                    let entering = departing.filter { !runs[$0].originatesAtStart }
                    if entering.isEmpty {
                        // Headway-only partners mark every train 当駅始発; fall
                        // back on a tight time match, as 直通 composites do.
                        pair(arriving, departing, within: 2 * 60)
                    } else {
                        pair(arriving, entering)
                    }
                }
            }

            // Trips: each run on its own, then joined to the runs it continues
            // into. A loop's chain runs all day, so it joins one circuit on.
            var trips: [Trip] = []
            var tripStops: [[Int32]] = []
            var tripLines: [[Int32]] = []
            func addTrip(_ chain: [Int]) {
                var stops: [Int32] = [], lineOf: [Int32] = []
                var arrivals: [Int32] = [], departures: [Int32] = []
                var segments: [Segment] = []
                for r in chain {
                    let run = runs[r]
                    let start = Int32(stops.count)
                    stops += run.stops
                    lineOf += [Int32](repeating: Int32(run.line), count: run.stops.count)
                    arrivals += run.arrivals
                    departures += run.departures
                    segments.append(Segment(service: Int32(r), start: start, end: Int32(stops.count - 1)))
                }
                trips.append(Trip(route: 0, arrivals: arrivals, departures: departures, segments: segments))
                tripStops.append(stops)
                tripLines.append(lineOf)
            }
            for r in runs.indices {
                let isLoop = lines[runs[r].line].isLoop
                if next[r] >= 0 {
                    var chain = [r]
                    while let last = chain.last, next[last] >= 0, chain.count < (isLoop ? 2 : 6) {
                        chain.append(next[last])
                    }
                    // Through chains start at their first run; every loop run starts one.
                    if previous[r] < 0 || isLoop { addTrip(chain) }
                } else if previous[r] < 0 {
                    addTrip([r])
                }
            }

            // Routes: one per exact stop sequence.
            var routeIndex: [[Int32]: Int] = [:]
            var routeStops: [[Int32]] = []
            var routeLines: [[Int32]] = []
            var routeTrips: [[Int32]] = []
            for t in trips.indices {
                let r: Int
                if let existing = routeIndex[tripStops[t]] {
                    r = existing
                } else {
                    r = routeStops.count
                    routeIndex[tripStops[t]] = r
                    routeStops.append(tripStops[t])
                    routeLines.append(tripLines[t])
                    routeTrips.append([])
                }
                routeTrips[r].append(Int32(t))
                trips[t] = Trip(route: Int32(r), arrivals: trips[t].arrivals,
                                departures: trips[t].departures, segments: trips[t].segments)
            }
            let routes = routeStops.indices.map { r in
                Route(stops: routeStops[r], lines: routeLines[r],
                      trips: routeTrips[r].sorted { trips[Int($0)].departures[0] < trips[Int($1)].departures[0] })
            }

            let transfers: [[Transfer]] = stopStation.map { id in
                (links.links[id] ?? []).compactMap { link in
                    stopIndex[link.stationId].map { Transfer(stop: $0, meters: link.meters) }
                }
            }

            var stationIndex: [String: Int] = [:]
            for line in lines {
                for (i, station) in line.stations.enumerated() where stationIndex[station.id] == nil {
                    stationIndex[station.id] = i
                }
            }

            self.init(lineIds: lines.map(\.id), serviceIds: runs.map(\.serviceId),
                      stopStation: stopStation, stopIndex: stopIndex,
                      routes: routes, trips: trips, transfers: transfers, links: links,
                      stationIndex: stationIndex)
        }

        private init(lineIds: [String], serviceIds: [String], stopStation: [String],
                     stopIndex: [String: Int32], routes: [Route], trips: [Trip],
                     transfers: [[Transfer]], links: StationLinks, stationIndex: [String: Int]) {
            self.stationIndex = stationIndex
            self.lineIds = lineIds
            self.serviceIds = serviceIds
            self.stopStation = stopStation
            self.stopIndex = stopIndex
            self.routes = routes
            self.trips = trips
            self.transfers = transfers
            self.links = links
            var stopRoutes = [[(route: Int32, position: Int32)]](repeating: [], count: stopStation.count)
            for (r, route) in routes.enumerated() {
                for (p, stop) in route.stops.enumerated() {
                    stopRoutes[Int(stop)].append((Int32(r), Int32(p)))
                }
            }
            self.stopRoutes = stopRoutes
        }

        /// Arrivals become departures and the clock runs negative, so a
        /// forward search here is a backward search on the original.
        private convenience init(reversing net: Network) {
            let trips = net.trips.map { trip in
                let last = Int32(trip.arrivals.count - 1)
                return Trip(route: trip.route,
                            arrivals: trip.departures.reversed().map { -$0 },
                            departures: trip.arrivals.reversed().map { -$0 },
                            segments: trip.segments.reversed().map {
                                Segment(service: $0.service, start: last - $0.end, end: last - $0.start)
                            })
            }
            let routes = net.routes.map { route in
                Route(stops: route.stops.reversed(), lines: route.lines.reversed(),
                      trips: route.trips.sorted { trips[Int($0)].departures[0] < trips[Int($1)].departures[0] })
            }
            self.init(lineIds: net.lineIds, serviceIds: net.serviceIds, stopStation: net.stopStation,
                      stopIndex: net.stopIndex, routes: routes, trips: trips,
                      transfers: net.transfers, links: net.links, stationIndex: net.stationIndex)
        }
    }
}

// MARK: - Query

extension TransitRouter {

    /// A leg as found by one RAPTOR pass, in that pass's direction.
    private struct RawLeg {
        let trip: Int32
        let board: Int32
        let alight: Int32
    }

    private struct Option {
        let trains: Int
        let arrival: Int32
        let legs: [RawLeg]
    }

    private struct Query {
        let net: Network
        let preferences: Preferences
        let avoided: [Bool]

        init(net: Network, preferences: Preferences) {
            self.net = net
            self.preferences = preferences
            self.avoided = net.lineIds.map { preferences.avoidingLineIds.contains($0) }
        }

        var transferSeconds: Int32 { Int32(preferences.transferMinutes * 60) }
        /// Changing trains without leaving the platform, e.g. 各停 to 急行.
        var sameStopSeconds: Int32 { min(60, transferSeconds) }

        func transferSeconds(_ transfer: Network.Transfer) -> Int32 {
            Int32(StationLinks.transferSeconds(meters: transfer.meters,
                                               transferMinutes: preferences.transferMinutes,
                                               walkPace: preferences.walkPace))
        }

        /// Stops that count as `stationId`, with the walk to reach each.
        func stops(at stationId: String) -> [(stop: Int32, seconds: Int32)] {
            let group = net.links.sameStation(as: stationId).compactMap { net.stopIndex[$0] }
            var result = Dictionary(group.map { ($0, Int32(0)) }, uniquingKeysWith: { a, _ in a })
            for stop in group {
                for transfer in net.transfers[Int(stop)] where result[transfer.stop] != 0 {
                    result[transfer.stop] = min(result[transfer.stop] ?? .max, transferSeconds(transfer))
                }
            }
            return result.map { ($0.key, $0.value) }
        }

        // MARK: Chains through via stations

        func forwardChain(_ ids: [String], from start: Int, limit: Int) -> [Itinerary] {
            let first = trips(from: ids[0], to: ids[1], departingAtOrAfter: start, limit: limit)
            guard ids.count > 2 else { return first }
            return first.compactMap { head in
                var legs = head.legs
                for (from, to) in zip(ids.dropFirst(), ids.dropFirst(2)) {
                    guard let onward = trips(from: from, to: to, departingAtOrAfter: legs.last!.arrival,
                                             limit: 1, arrivedOn: legs.last).first
                    else { return nil }
                    legs = Self.joined(legs, onward.legs)
                }
                return Itinerary(legs: legs)
            }
        }

        func backwardChain(_ ids: [String], by deadline: Int, floor: Int?, limit: Int) -> [Itinerary] {
            let last = trips(from: ids[ids.count - 2], to: ids[ids.count - 1],
                             arrivingAtOrBefore: deadline, floor: ids.count == 2 ? floor : nil, limit: limit)
            guard ids.count > 2 else { return last }
            return last.compactMap { tail in
                var legs = tail.legs
                let pairs = Array(zip(ids, ids.dropFirst()).dropLast().reversed())
                for (index, (from, to)) in pairs.enumerated() {
                    guard let earlier = trips(from: from, to: to, arrivingAtOrBefore: legs[0].departure,
                                              floor: index == pairs.count - 1 ? floor : nil,
                                              limit: 1, leavingOn: legs.first).first
                    else { return nil }
                    legs = Self.joined(earlier.legs, legs)
                }
                return Itinerary(legs: legs)
            }
        }

        /// Merges the boundary legs when the same train carries on through a via station.
        private static func joined(_ a: [Leg], _ b: [Leg]) -> [Leg] {
            guard let last = a.last, let first = b.first,
                  let tail = last.rides.last, let head = first.rides.first,
                  tail.serviceId == head.serviceId
            else { return a + b }
            let bridged = Ride(lineId: tail.lineId, serviceId: tail.serviceId,
                               fromStationId: tail.fromStationId, toStationId: head.toStationId,
                               departure: tail.departure, arrival: head.arrival)
            let merged = Leg(rides: last.rides.dropLast() + [bridged] + first.rides.dropFirst())
            return a.dropLast() + [merged] + b.dropFirst()
        }

        // MARK: Single segment

        /// `arrivedOn`: the leg that reached the origin, which can be stayed aboard.
        func trips(from origin: String, to destination: String, departingAtOrAfter start: Int,
                   limit: Int, arrivedOn: Leg? = nil) -> [Itinerary] {
            let sources = stops(at: origin)
            let targets = stops(at: destination)
            let aboard = arrivedOn.flatMap { net.stopIndex[$0.toStationId] }
            var results: [Itinerary] = []
            var seen = Set<String>()
            var time = Int32(start)
            for _ in 0..<(limit + 4) {
                // A change at a via station costs the same as any other.
                let ready = sources.map { source in
                    (source.stop, time + source.seconds + (arrivedOn == nil || source.stop == aboard ? 0 : transferSeconds))
                }
                let options = run(net, sources: ready, targets: targets, maxTrains: preferences.maxTrains)
                guard !options.isEmpty else { break }
                var latestDeparture = Int32.max
                for option in preferred(options) {
                    // Leave as late as still makes the same arrival.
                    let back = run(net.reversed, sources: targets.map { ($0.stop, -option.arrival + $0.seconds) },
                                   targets: sources, maxTrains: option.trains)
                    guard let tight = back.last else { continue }
                    let itinerary = itinerary(tight.legs, reversed: true)
                    latestDeparture = min(latestDeparture, Int32(itinerary.departure))
                    if seen.insert(itinerary.key).inserted { results.append(itinerary) }
                }
                if results.count >= limit || latestDeparture == .max { break }
                time = latestDeparture + 60
            }
            return Array(results.prefix(limit))
        }

        /// `leavingOn`: the leg departing the destination, which can be boarded early.
        func trips(from origin: String, to destination: String, arrivingAtOrBefore deadline: Int,
                   floor: Int?, limit: Int, leavingOn: Leg? = nil) -> [Itinerary] {
            let sources = stops(at: origin)
            let targets = stops(at: destination)
            let aboard = leavingOn.flatMap { net.stopIndex[$0.fromStationId] }
            var results: [Itinerary] = []
            var seen = Set<String>()
            var time = Int32(deadline)
            for _ in 0..<(limit + 4) {
                let ready = targets.map { target in
                    (target.stop, -time + target.seconds + (leavingOn == nil || target.stop == aboard ? 0 : transferSeconds))
                }
                let options = run(net.reversed, sources: ready, targets: sources, maxTrains: preferences.maxTrains)
                guard !options.isEmpty else { break }
                var earliestArrival = Int32.min
                for option in preferred(options) {
                    // Arrive as early as the same departure allows.
                    let departure = -option.arrival
                    if let floor, departure < floor { continue }
                    let forward = run(net, sources: sources.map { ($0.stop, departure + $0.seconds) },
                                      targets: targets, maxTrains: option.trains)
                    guard let tight = forward.last else { continue }
                    let itinerary = itinerary(tight.legs, reversed: false)
                    earliestArrival = max(earliestArrival, Int32(itinerary.arrival))
                    if seen.insert(itinerary.key).inserted { results.append(itinerary) }
                }
                if results.count >= limit || earliestArrival == .min { break }
                time = earliestArrival - 60
            }
            return Array(results.prefix(limit))
        }

        /// Drops options whose extra changes don't buy enough time; the
        /// cheapest of the rest comes first.
        private func preferred(_ options: [Option]) -> [Option] {
            let aversion = Int32(preferences.transferAversionMinutes * 60)
            return options
                .filter { option in
                    options.allSatisfy { other in
                        other.trains >= option.trains
                            || option.arrival + aversion * Int32(option.trains - other.trains) < other.arrival
                    }
                }
                .sorted { $0.arrival + aversion * Int32($0.trains) < $1.arrival + aversion * Int32($1.trains) }
        }

        // MARK: Itinerary building

        /// Turns raw legs into rides on the forward network, splitting each
        /// trip back into the generated services it joins.
        private func itinerary(_ legs: [RawLeg], reversed: Bool) -> Itinerary {
            let ordered = reversed ? legs.reversed() : legs
            return Itinerary(legs: ordered.map { raw in
                let trip = net.trips[Int(raw.trip)]
                let last = Int32(trip.arrivals.count - 1)
                let board = reversed ? last - raw.alight : raw.board
                let alight = reversed ? last - raw.board : raw.alight
                let stops = net.routes[Int(trip.route)].stops
                let rides = trip.segments.compactMap { segment -> Ride? in
                    let from = max(board, segment.start), to = min(alight, segment.end)
                    guard from < to else { return nil }
                    return Ride(
                        lineId: net.lineIds[Int(net.routes[Int(trip.route)].lines[Int(from)])],
                        serviceId: net.serviceIds[Int(segment.service)],
                        fromStationId: net.stopStation[Int(stops[Int(from)])],
                        toStationId: net.stopStation[Int(stops[Int(to)])],
                        departure: Int(trip.departures[Int(from)]),
                        arrival: Int(trip.arrivals[Int(to)])
                    )
                }
                return Leg(rides: rides)
            })
        }

        // MARK: RAPTOR

        /// Best arrival for each number of trains that improves on fewer.
        private func run(_ net: Network, sources: [(Int32, Int32)],
                         targets: [(stop: Int32, seconds: Int32)], maxTrains: Int) -> [Option] {
            let n = net.stopStation.count
            let rounds = maxTrains + 1
            let inf = Int32.max

            // Round k: arrival by train, and the earliest moment a train can be boarded.
            var arrival = [[Int32]](repeating: [Int32](repeating: inf, count: n), count: rounds)
            var boardable = [[Int32]](repeating: [Int32](repeating: inf, count: n), count: rounds)
            var boardableFrom = [[Int32]](repeating: [Int32](repeating: -1, count: n), count: rounds)
            var rideTrip = [[Int32]](repeating: [Int32](repeating: -1, count: n), count: rounds)
            var rideBoard = [[Int32]](repeating: [Int32](repeating: -1, count: n), count: rounds)
            var rideAlight = [[Int32]](repeating: [Int32](repeating: -1, count: n), count: rounds)
            var bestArrival = [Int32](repeating: inf, count: n)
            var bestBoardable = [Int32](repeating: inf, count: n)

            var marked: [Int32] = []
            for (stop, time) in sources where time < boardable[0][Int(stop)] {
                if boardable[0][Int(stop)] == inf { marked.append(stop) }
                boardable[0][Int(stop)] = time
                bestBoardable[Int(stop)] = time
            }

            var targetBound = inf
            var options: [Option] = []

            for k in 1..<rounds {
                // Earliest marked position per route.
                var routeStart: [Int32: Int32] = [:]
                for stop in marked {
                    for (route, position) in net.stopRoutes[Int(stop)] {
                        if let existing = routeStart[route], existing <= position { continue }
                        routeStart[route] = position
                    }
                }

                var improved: [Int32] = []
                for (r, start) in routeStart {
                    let route = net.routes[Int(r)]
                    var current = -1          // index into route.trips
                    var board: Int32 = -1
                    for position in Int(start)..<route.stops.count {
                        let stop = route.stops[position]
                        let s = Int(stop)
                        if avoided[Int(route.lines[position])] {
                            current = -1
                            continue
                        }
                        if current >= 0 {
                            let t = route.trips[current]
                            let time = net.trips[Int(t)].arrivals[position]
                            if time < bestArrival[s], time < targetBound {
                                if arrival[k][s] == inf { improved.append(stop) }
                                arrival[k][s] = time
                                bestArrival[s] = time
                                rideTrip[k][s] = t
                                rideBoard[k][s] = board
                                rideAlight[k][s] = Int32(position)
                            }
                        }
                        let ready = boardable[k - 1][s]
                        guard ready != inf, position < route.stops.count - 1 else { continue }
                        if current >= 0, net.trips[Int(route.trips[current])].departures[position] < ready { continue }
                        // Earliest trip leaving here at or after `ready`.
                        var lo = 0, hi = current >= 0 ? current : route.trips.count
                        while lo < hi {
                            let mid = (lo + hi) / 2
                            if net.trips[Int(route.trips[mid])].departures[position] < ready { lo = mid + 1 } else { hi = mid }
                        }
                        if lo < route.trips.count, lo != current,
                           net.trips[Int(route.trips[lo])].departures[position] >= ready {
                            current = lo
                            board = Int32(position)
                        }
                    }
                }

                if let best = targets.compactMap({ target -> (Int32, Int32)? in
                    let a = arrival[k][Int(target.stop)]
                    return a == inf ? nil : (target.stop, a + target.seconds)
                }).min(by: { $0.1 < $1.1 }), options.last.map({ best.1 < $0.arrival }) ?? true {
                    targetBound = min(targetBound, best.1)
                    options.append(Option(trains: k, arrival: best.1,
                                          legs: reconstruct(round: k, at: best.0, boardableFrom: boardableFrom,
                                                            rideTrip: rideTrip, rideBoard: rideBoard,
                                                            rideAlight: rideAlight, in: net)))
                }

                // Changes of train, ready for the next round.
                marked = []
                for stop in improved {
                    let s = Int(stop)
                    let time = arrival[k][s]
                    func offer(_ to: Int32, _ ready: Int32) {
                        let i = Int(to)
                        guard ready < bestBoardable[i], ready < targetBound else { return }
                        if boardable[k][i] == inf { marked.append(to) }
                        boardable[k][i] = ready
                        bestBoardable[i] = ready
                        boardableFrom[k][i] = stop
                    }
                    offer(stop, time + sameStopSeconds)
                    for transfer in net.transfers[s] {
                        offer(transfer.stop, time + transferSeconds(transfer))
                    }
                }
                guard !marked.isEmpty else { break }
            }
            return options
        }

        private func reconstruct(round: Int, at target: Int32, boardableFrom: [[Int32]],
                                 rideTrip: [[Int32]], rideBoard: [[Int32]], rideAlight: [[Int32]],
                                 in net: Network) -> [RawLeg] {
            var legs: [RawLeg] = []
            var stop = target
            var k = round
            while k > 0 {
                let s = Int(stop)
                let trip = rideTrip[k][s]
                guard trip >= 0 else { break }
                let board = rideBoard[k][s]
                legs.insert(RawLeg(trip: trip, board: board, alight: rideAlight[k][s]), at: 0)
                k -= 1
                guard k > 0 else { break }
                let boardStop = net.routes[Int(net.trips[Int(trip)].route)].stops[Int(board)]
                stop = boardableFrom[k][Int(boardStop)]
                guard stop >= 0 else { break }
            }
            return legs
        }
    }
}
