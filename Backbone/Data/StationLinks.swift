import Foundation

/// Where a passenger can change trains. Stations join by name *and* distance,
/// so 中野 (東西線) and 中野 (わたらせ渓谷鐵道) stay apart while 押上 and
/// とうきょうスカイツリー get a walk between them.
public struct StationLinks: Sendable {

    public struct Link: Sendable {
        public let stationId: String
        public let meters: Double
    }

    /// Same-named stations at least this close are one place.
    static let sameNameMeters: Double = 1000
    /// Differently named stations at least this close can be walked between.
    static let walkMeters: Double = 400
    /// Distance covered by the plain transfer buffer before walking adds time.
    static let freeWalkMeters: Double = 200
    /// Streets are not straight lines.
    static let detourFactor: Double = 1.3

    /// Other lines' stations reachable from a station, excluding its own line.
    public let links: [String: [Link]]
    /// Station IDs that are the same place as a station, including itself.
    private let groupOf: [String: Int]
    private let groups: [[String]]

    public init(lines: [StaticTrainLine]) {
        struct Entry { let id: String; let name: String; let line: Int; let lat: Double?; let lon: Double? }
        var entries: [Entry] = []
        for (li, line) in lines.enumerated() {
            for station in line.stations {
                entries.append(Entry(id: station.id, name: station.name, line: li,
                                     lat: station.latitude, lon: station.longitude))
            }
        }

        // Union-find over same-place stations.
        var parent = Array(entries.indices)
        func find(_ i: Int) -> Int {
            var i = i
            while parent[i] != i { parent[i] = parent[parent[i]]; i = parent[i] }
            return i
        }
        func union(_ a: Int, _ b: Int) { parent[find(a)] = find(b) }

        var links: [String: [Link]] = [:]
        func link(_ a: Entry, _ b: Entry, _ meters: Double) {
            links[a.id, default: []].append(Link(stationId: b.id, meters: meters))
            links[b.id, default: []].append(Link(stationId: a.id, meters: meters))
        }

        // Bucket by ~1 km cells so the pair scan stays local.
        var buckets: [Int64: [Int]] = [:]
        var byName: [String: [Int]] = [:]
        for (i, e) in entries.enumerated() {
            byName[e.name, default: []].append(i)
            guard let lat = e.lat, let lon = e.lon else { continue }
            buckets[Self.cell(lat, lon), default: []].append(i)
        }

        for indices in byName.values where indices.count > 1 {
            for (n, i) in indices.enumerated() {
                for j in indices[(n + 1)...] {
                    let a = entries[i], b = entries[j]
                    let meters = Self.distance(a.lat, a.lon, b.lat, b.lon) ?? 0
                    guard meters <= Self.sameNameMeters else { continue }
                    union(i, j)
                    if a.line != b.line { link(a, b, meters) }
                }
            }
        }

        for (i, a) in entries.enumerated() {
            guard let lat = a.lat, let lon = a.lon else { continue }
            let (cy, cx) = Self.cellCoordinates(lat, lon)
            for dy in -1...1 {
                for dx in -1...1 {
                    for j in buckets[Self.cell(cy + dy, cx + dx)] ?? [] where j > i {
                        let b = entries[j]
                        guard b.line != a.line, b.name != a.name,
                              let meters = Self.distance(a.lat, a.lon, b.lat, b.lon),
                              meters <= Self.walkMeters
                        else { continue }
                        link(a, b, meters)
                    }
                }
            }
        }

        var groupIndex: [Int: Int] = [:]
        var groups: [[String]] = []
        var groupOf: [String: Int] = [:]
        for (i, e) in entries.enumerated() where groupOf[e.id] == nil {
            let root = find(i)
            let g: Int
            if let existing = groupIndex[root] {
                g = existing
            } else {
                g = groups.count
                groupIndex[root] = g
                groups.append([])
            }
            groups[g].append(e.id)
            groupOf[e.id] = g
        }

        self.links = links
        self.groupOf = groupOf
        self.groups = groups
    }

    /// Every station ID that is the same place as `stationId`.
    public func sameStation(as stationId: String) -> [String] {
        guard let g = groupOf[stationId] else { return [stationId] }
        return groups[g]
    }

    public func isSameStation(_ a: String, _ b: String) -> Bool {
        a == b || (groupOf[a] != nil && groupOf[a] == groupOf[b])
    }

    /// Seconds to change between linked stations: the transfer buffer, plus
    /// the walk beyond what the buffer already covers.
    public static func transferSeconds(meters: Double, transferMinutes: Double, walkPace: Double) -> Int {
        let walk = max(0, meters - freeWalkMeters) * detourFactor / 80 * walkPace
        return Int(((transferMinutes + walk) * 60).rounded())
    }

    /// Seconds to walk between linked stations when no change of train is
    /// involved, as at the start or end of a trip.
    public static func walkSeconds(meters: Double, walkPace: Double) -> Int {
        Int((max(0, meters - freeWalkMeters) * detourFactor / 80 * walkPace * 60).rounded())
    }

    // MARK: Geometry

    private static func cellCoordinates(_ lat: Double, _ lon: Double) -> (Int, Int) {
        (Int((lat * 100).rounded(.down)), Int((lon * 100).rounded(.down)))
    }

    private static func cell(_ lat: Double, _ lon: Double) -> Int64 {
        let (y, x) = cellCoordinates(lat, lon)
        return cell(y, x)
    }

    private static func cell(_ y: Int, _ x: Int) -> Int64 {
        Int64(y) << 32 | Int64(UInt32(bitPattern: Int32(x)))
    }

    private static func distance(_ lat1: Double?, _ lon1: Double?, _ lat2: Double?, _ lon2: Double?) -> Double? {
        guard let lat1, let lon1, let lat2, let lon2 else { return nil }
        let k = Double.pi / 180
        let x = (lon2 - lon1) * k * cos((lat1 + lat2) / 2 * k)
        let y = (lat2 - lat1) * k
        return (x * x + y * y).squareRoot() * 6_371_000
    }
}
