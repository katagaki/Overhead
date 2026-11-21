#if DEBUG
import Foundation
import Combine
import SwiftUI
import Backbone

// MARK: - Screenshot Harness (DEBUG only)

/// App Store screenshot staging, driven over `overhead://` deep links.
/// RootView handles the URLs; Assets/App Store/capture.swift is the driver.
///
/// - overhead://seed/favorites[?line=…&from=…&to=…] (the 自宅 favorite's ride)
/// - overhead://seed/custom-line
/// - overhead://import?file=<name in Documents, or absolute path> (opens a .ohl as if from Files)
/// - overhead://lcd?style=<TrainLCDStyle raw value>
/// - overhead://journey?minutesAgo=45[&line=…&from=…&to=…]
/// - overhead://ride?from=…&to=…[&at=<ISO 8601>&arrive=1&dep=HH:mm] (opens a search result as a preview)
/// - overhead://planner?action=search|avoid|departure|arrival|race (race: search, then change To mid-search)
/// - overhead://timetable[?line=…&station=…&hidePast=0&popover=<train type>]
/// - overhead://line[?line=…&status=expanded]
/// - overhead://custom-line (seeds the sample line and opens its editor)
/// - overhead://home?scroll=lines
/// - overhead://place-editor[?edit=first]
/// - overhead://dismiss (closes the journey sheet to expose the home bottom bar)
/// - overhead://tab/new
/// - overhead://tab/root?line=… (roots the selected tab at a line page instead of Home)
/// - overhead://pending-depart?place=first|<uuid> (stages the Control Center control's departure; consumed at launch or on activation)
/// - overhead://tab/switcher
/// - overhead://reset
enum ScreenshotCommand {
    case seedFavorites(lineId: String?, fromId: String?, toId: String?)
    case seedCustomLine
    case importFile(String)
    case lcdStyle(String)
    case journey(lineId: String, fromId: String, toId: String, minutesAgo: Double)
    case ride(fromId: String, toId: String, at: Date?, arrive: Bool, departure: String?)
    case plannerSearch
    case plannerAvoid
    case plannerDeparture
    case plannerArrival
    case plannerRace
    case timetable(ScreenshotTimetableTarget, hidePast: Bool, popoverType: String?)
    case linePage(ScreenshotLineTarget)
    case customLineEditor
    case homeScroll(String)
    case placeEditor(editFirst: Bool)
    case dismissSheet
    case newTab
    case tabSwitcher
    case tabRoot(lineId: String)
    case pendingDeparture(String)
    case reset

    init?(url: URL) {
        guard url.scheme == "overhead" else { return nil }
        let params = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce(into: [String: String]()) { $0[$1.name] = $1.value } ?? [:]

        switch url.host {
        case "seed":
            switch url.path {
            case "/favorites": self = .seedFavorites(lineId: params["line"], fromId: params["from"], toId: params["to"])
            case "/custom-line": self = .seedCustomLine
            default: return nil
            }
        case "import":
            guard let file = params["file"] else { return nil }
            self = .importFile(file)
        case "lcd":
            guard let style = params["style"] else { return nil }
            self = .lcdStyle(style)
        case "journey":
            self = .journey(
                lineId: params["line"] ?? "Railway:JR-East.JobanRapid",
                fromId: params["from"] ?? "Station:JR-East.JobanRapid.Tokyo",
                toId: params["to"] ?? "Station:JR-East.JobanRapid.Toride",
                minutesAgo: params["minutesAgo"].flatMap(Double.init) ?? 45
            )
        case "ride":
            guard let from = params["from"], let to = params["to"] else { return nil }
            self = .ride(
                fromId: from, toId: to,
                at: params["at"].flatMap { ISO8601DateFormatter().date(from: $0) },
                arrive: params["arrive"] == "1",
                departure: params["dep"]
            )
        case "planner":
            switch params["action"] {
            case "avoid": self = .plannerAvoid
            case "departure": self = .plannerDeparture
            case "arrival": self = .plannerArrival
            case "race": self = .plannerRace
            default: self = .plannerSearch
            }
        case "timetable":
            self = .timetable(
                ScreenshotTimetableTarget(
                    lineId: params["line"] ?? "Railway:JR-East.JobanRapid",
                    stationId: params["station"] ?? "Station:JR-East.JobanRapid.Tokyo"
                ),
                hidePast: params["hidePast"] != "0",
                popoverType: params["popover"]
            )
        case "line":
            self = .linePage(
                ScreenshotLineTarget(
                    lineId: params["line"] ?? "Railway:JR-East.JobanRapid",
                    expandStatus: params["status"] == "expanded"
                )
            )
        case "custom-line":
            self = .customLineEditor
        case "home":
            guard let anchor = params["scroll"] else { return nil }
            self = .homeScroll(anchor)
        case "place-editor":
            self = .placeEditor(editFirst: params["edit"] == "first")
        case "dismiss":
            self = .dismissSheet
        case "tab":
            switch url.path {
            case "/new": self = .newTab
            case "/switcher": self = .tabSwitcher
            case "/root": self = .tabRoot(lineId: params["line"] ?? "Railway:JR-East.JobanRapid")
            default: return nil
            }
        case "pending-depart":
            self = .pendingDeparture(params["place"] ?? "first")
        case "reset":
            self = .reset
        default:
            return nil
        }
    }
}

struct ScreenshotTimetableTarget: Identifiable {
    let lineId: String
    let stationId: String
    var id: String { stationId }
}

struct ScreenshotLineTarget: Identifiable, Hashable {
    let lineId: String
    let expandStatus: Bool
    var id: String { lineId }
}

/// Cross-view staging state: RootView receives the URL, other views react.
@MainActor
final class ScreenshotStaging: ObservableObject {
    static let shared = ScreenshotStaging()

    /// Planner action for JourneyPlannerSection to pick up.
    @Published var plannerCommand: PlannerCommand?
    /// Station timetables hide departed rows while staging.
    @Published var hidePastDepartures = false
    /// Opens the departure popover for the first matching train type.
    @Published var timetablePopoverType: String?
    /// Line pages open with the service status sheet expanded.
    @Published var expandServiceStatus = false
    /// Anchor id for RootView's ScrollViewReader.
    @Published var homeScrollTarget: String?
    /// Favorite editor sheet command for FavoritesSection.
    @Published var placeEditorCommand: PlaceEditorCommand?

    enum PlannerCommand {
        case search
        case avoid
        case departure
        case arrival
        case race
    }

    /// `-debugSearchDelay <seconds>` holds planner and replan results back so a search can be overtaken.
    static func holdSearchResults(_ label: String) async {
        let delay = UserDefaults.standard.double(forKey: "debugSearchDelay")
        if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
        NSLog("[OverheadSearch] %@ %@", label, Task.isCancelled ? "cancelled, results dropped" : "results applied")
    }

    enum PlaceEditorCommand {
        case new
        case editFirst
    }
}

// MARK: - Sample data

@MainActor
enum ScreenshotSeeder {
    static let customLineId = "Custom:Line.KivotosM"

    static func seedFavorites(lineId: String? = nil, fromId: String? = nil, toId: String? = nil) {
        SavedPlaceStore.save([
            SavedPlace(
                id: UUID(), kind: .home,
                lineId: lineId ?? "Railway:JR-East.JobanRapid",
                fromStationId: fromId ?? "Station:JR-East.JobanRapid.Tokyo",
                toStationId: toId ?? "Station:JR-East.JobanRapid.Toride"
            ),
            SavedPlace(
                id: UUID(), kind: .work,
                lineId: "Railway:JR-East.JobanRapid",
                fromStationId: "Station:JR-East.JobanRapid.Toride",
                toStationId: "Station:JR-East.JobanRapid.Tokyo"
            )
        ])
    }

    static func seedCustomLine() {
        CustomLineStore.shared.upsert(CustomLine(
            id: customLineId,
            name: "キヴォトスM線",
            nameEn: "Kivotos M-Line",
            symbol: "M",
            colorHex: "#0067C0",
            badgeStyleId: "jr",
            isLoop: false,
            stations: [
                CustomStation(id: "Custom:Station.M01", name: "ミレニアム中央", nameEn: "Millennium Central"),
                CustomStation(id: "Custom:Station.M02", name: "セミナー前", nameEn: "Seminar"),
                CustomStation(id: "Custom:Station.M03", name: "エンジニア部", nameEn: "Engineering Dept."),
                CustomStation(id: "Custom:Station.M04", name: "ヴェリタス", nameEn: "Veritas"),
                CustomStation(id: "Custom:Station.M05", name: "ゲーム開発部", nameEn: "Game Dev Club"),
                CustomStation(id: "Custom:Station.M06", name: "C&C本部", nameEn: "C&C Headquarters"),
                CustomStation(id: "Custom:Station.M07", name: "超現象特務部", nameEn: "Paranormal Task Force"),
                CustomStation(id: "Custom:Station.M08", name: "ミレニアムポート", nameEn: "Millennium Port"),
            ],
            hopMinutes: [3, 2, 2, 3, 2, 2, 3],
            timetable: CustomTimetable(
                weekday: CustomServicePattern(firstDeparture: "05:30", lastDeparture: "24:00", headwayMinutes: 5),
                saturdayHoliday: CustomServicePattern(firstDeparture: "06:00", lastDeparture: "23:30", headwayMinutes: 8)
            )
        ))
    }
}
#endif
