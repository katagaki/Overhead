import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers
import Backbone

// MARK: - Custom (DIY) Line Models

struct CustomStation: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var nameEn: String = ""
    var latitude: Double?
    var longitude: Double?

    var hasCoordinates: Bool { latitude != nil && longitude != nil }

    static func new() -> CustomStation {
        CustomStation(id: "Custom:Station.\(UUID().uuidString)", name: "", nameEn: "")
    }
}

/// First/last/headway for one calendar. Times are "HH:mm" and may exceed 24:00.
struct CustomServicePattern: Codable, Hashable {
    var firstDeparture: String = "05:00"
    var lastDeparture: String = "24:00"
    var headwayMinutes: Int = 6
}

struct CustomTimetable: Codable, Hashable {
    var weekday = CustomServicePattern()
    var saturdayHoliday = CustomServicePattern()

    func pattern(for calendar: ScheduleCalendar) -> CustomServicePattern {
        calendar == .weekday ? weekday : saturdayHoliday
    }
}

struct CustomLine: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var nameEn: String = ""
    /// Line symbol / badge prefix, e.g. "YH". Uppercased, ≤2 chars.
    var symbol: String
    var colorHex: String
    /// Optional so lines saved before style ids still decode.
    var badgeStyleId: String?
    /// Mirror of the chosen style in the old four-shape vocabulary, so a build
    /// that predates style ids can still open a shared .ohl.
    var badgeStyle: BadgeStyle = .rounded

    var styleId: String { badgeStyleId ?? badgeStyle.styleId }

    mutating func setStyleId(_ id: String) {
        badgeStyleId = id
        badgeStyle = BadgeStyle.allCases.first { $0.styleId == id } ?? .rounded
    }
    var isLoop: Bool = false
    var stations: [CustomStation] = []
    /// Minutes between consecutive stations; count == max(0, stations.count - 1).
    var hopMinutes: [Double] = []
    /// nil when the user hasn't attached a schedule (manual / GPS-only riding).
    var timetable: CustomTimetable?

    var hasSchedule: Bool { timetable != nil }
    var hasAllCoordinates: Bool { !stations.isEmpty && stations.allSatisfy(\.hasCoordinates) }

    static func new() -> CustomLine {
        CustomLine(
            id: "Custom:Line.\(UUID().uuidString)",
            name: "",
            symbol: "",
            colorHex: CustomLinePalette.colors.first ?? "#F15A22"
        )
    }

    // MARK: Bridging to Backbone display types

    /// Two-digit signage code for the station at `index`, e.g. "YH01".
    func stationCode(at index: Int) -> String {
        let prefix = symbol.uppercased()
        return prefix.isEmpty ? String(format: "%02d", index + 1)
                              : prefix + String(format: "%02d", index + 1)
    }

    /// Station in travel-order-agnostic array order, as a Backbone `Station`.
    /// A blank English name falls back to the Japanese one (single-language lines).
    func backboneStations() -> [Station] {
        stations.enumerated().map { index, station in
            Station(
                id: station.id,
                name: station.name,
                nameEn: station.nameEn.isEmpty ? station.name : station.nameEn,
                stationCode: stationCode(at: index),
                latitude: station.latitude,
                longitude: station.longitude
            )
        }
    }

    var trainLine: TrainLine {
        TrainLine(
            id: id,
            name: name,
            nameEn: nameEn.isEmpty ? name : nameEn,
            operatorId: "Operator:Custom",
            stations: backboneStations(),
            colorHex: colorHex,
            badgeStyleId: styleId
        )
    }

    var color: Color { Color(hex: colorHex) }
    var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        if lang == "en", !nameEn.isEmpty { return nameEn }
        return name
    }

    /// Keeps `hopMinutes` sized to the station count (2 min default per new gap).
    mutating func normalizeHopMinutes() {
        let needed = max(0, stations.count - 1)
        if hopMinutes.count < needed {
            hopMinutes.append(contentsOf: Array(repeating: 2, count: needed - hopMinutes.count))
        } else if hopMinutes.count > needed {
            hopMinutes = Array(hopMinutes.prefix(needed))
        }
    }
}

// MARK: - Import validation

extension CustomLine {
    static let hopMinutesRange: ClosedRange<Double> = 0...720
    static let headwayRange = 1...720
    static let maxStations = 500

    static func isValidHop(_ minutes: Double) -> Bool {
        minutes.isFinite && hopMinutesRange.contains(minutes)
    }

    /// "H:mm" rail time up to 47:59, in minutes; nil when malformed or out of range.
    static func railMinutes(_ hhmm: String) -> Int? {
        let parts = hhmm.trimmingCharacters(in: .whitespaces).split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, (1...2).contains(parts[0].count), parts[1].count == 2,
              let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0...47).contains(hour), (0...59).contains(minute)
        else { return nil }
        return hour * 60 + minute
    }

    var isImportable: Bool {
        guard stations.count <= Self.maxStations,
              hopMinutes.count <= Self.maxStations,
              hopMinutes.allSatisfy(Self.isValidHop),
              stations.allSatisfy(\.hasValidCoordinates)
        else { return false }
        guard let timetable else { return true }
        return [timetable.weekday, timetable.saturdayHoliday].allSatisfy { pattern in
            Self.railMinutes(pattern.firstDeparture) != nil
                && Self.railMinutes(pattern.lastDeparture) != nil
                && Self.headwayRange.contains(pattern.headwayMinutes)
        }
    }

    static let idPrefix = "Custom:"
}

extension CustomStation {
    var hasValidCoordinates: Bool {
        switch (latitude, longitude) {
        case (nil, nil): true
        case let (lat?, lon?): lat.isFinite && lon.isFinite && abs(lat) <= 90 && abs(lon) <= 180
        default: false
        }
    }
}

struct CustomLineImportError: LocalizedError {
    var errorDescription: String? { String(localized: "CustomLine.ImportInvalid") }
}

extension CustomLinePackage {
    static func decodeValidated(from data: Data) throws -> CustomLinePackage {
        let package = try JSONDecoder().decode(CustomLinePackage.self, from: data)
        guard !package.lines.isEmpty, package.lines.allSatisfy(\.isImportable) else {
            throw CustomLineImportError()
        }
        return package
    }
}

// MARK: - Color palette

enum CustomLinePalette {
    /// Same swatch set as the design prototype.
    static let colors = [
        "#F15A22", "#E60012", "#F5A200", "#009944", "#00A5B3", "#0067C0",
        "#003686", "#8250DF", "#E85298", "#9B7CB6", "#6E3219", "#535B63",
    ]
}

// MARK: - .ohl package

struct CustomLinePackage: Codable {
    var formatVersion = 1
    var author: String?
    var lines: [CustomLine]
}

extension UTType {
    /// The `.ohl` document type, a JSON payload of custom lines.
    static let overheadLine = UTType(exportedAs: "com.katagaki.overhead.line",
                                     conformingTo: .json)
}

// MARK: - Persistence

@MainActor
final class CustomLineStore: ObservableObject {
    static let shared = CustomLineStore()

    @Published private(set) var lines: [CustomLine]
    @Published var incomingPackage: CustomLinePackage?
    @Published var incomingError: String?

    private static let storageKey = "customLines"

    init() {
        lines = Self.loadFromDisk()
    }

    private static func loadFromDisk() -> [CustomLine] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([CustomLine].self, from: data)
        else { return [] }
        return decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(lines) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    func line(withId id: String) -> CustomLine? {
        lines.first { $0.id == id }
    }

    /// Inserts a new line or replaces the existing one with the same id.
    func upsert(_ line: CustomLine) {
        var line = line
        line.normalizeHopMinutes()
        if let index = lines.firstIndex(where: { $0.id == line.id }) {
            lines[index] = line
        } else {
            lines.append(line)
        }
        persist()
    }

    func delete(id: String) {
        lines.removeAll { $0.id == id }
        persist()
    }

    /// Adds imported lines; one whose id is taken (or isn't a custom id) is added as a new line, never replacing the user's.
    func importLines(_ imported: [CustomLine]) {
        for var line in imported {
            let takenStationIds = Set(lines.flatMap { $0.stations.map(\.id) })
            if !line.id.hasPrefix(CustomLine.idPrefix) || lines.contains(where: { $0.id == line.id }) {
                line.id = CustomLine.new().id
                for index in line.stations.indices {
                    line.stations[index].id = CustomStation.new().id
                }
            }
            for index in line.stations.indices
            where !line.stations[index].id.hasPrefix(CustomLine.idPrefix)
                || takenStationIds.contains(line.stations[index].id) {
                line.stations[index].id = CustomStation.new().id
            }
            upsert(line)
        }
    }

    // MARK: Export / import documents

    func package(for ids: [String], author: String? = nil) -> CustomLinePackage {
        let set = Set(ids)
        return CustomLinePackage(author: author, lines: lines.filter { set.contains($0.id) })
    }

    func packageForAll(author: String? = nil) -> CustomLinePackage {
        CustomLinePackage(author: author, lines: lines)
    }

    @discardableResult
    func receiveFile(at url: URL) -> Bool {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            incomingPackage = try CustomLinePackage.decodeValidated(from: Data(contentsOf: url))
            return true
        } catch {
            incomingError = error.localizedDescription
            return false
        }
    }
}
