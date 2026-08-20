#if DEBUG
import Foundation
import Combine
import SwiftUI
import Backbone

// MARK: - Screenshot Harness (DEBUG only)

/// App Store screenshot staging, driven over `overtrain://` deep links.
/// RootView handles the URLs; Assets/App Store/capture.swift is the driver.
///
/// - overtrain://seed/favorites
/// - overtrain://seed/custom-line
/// - overtrain://lcd?style=<TrainLCDStyle raw value>
/// - overtrain://journey?minutesAgo=45[&line=…&from=…&to=…]
/// - overtrain://planner?action=search|avoid|departure|arrival
/// - overtrain://timetable[?line=…&station=…&hidePast=0]
/// - overtrain://line[?line=…&status=expanded]
/// - overtrain://custom-line (seeds the sample line and opens its editor)
/// - overtrain://home?scroll=lines
/// - overtrain://place-editor[?edit=first]
/// - overtrain://dismiss (closes the journey sheet to expose the home bottom bar)
/// - overtrain://reset
enum ScreenshotCommand {
    case seedFavorites
    case seedCustomLine
    case lcdStyle(String)
    case journey(lineId: String, fromId: String, toId: String, minutesAgo: Double)
    case plannerSearch
    case plannerAvoid
    case plannerDeparture
    case plannerArrival
    case timetable(ScreenshotTimetableTarget, hidePast: Bool)
    case linePage(ScreenshotLineTarget)
    case customLineEditor
    case homeScroll(String)
    case placeEditor(editFirst: Bool)
    case dismissSheet
    case reset

    init?(url: URL) {
        guard url.scheme == "overtrain" else { return nil }
        let params = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce(into: [String: String]()) { $0[$1.name] = $1.value } ?? [:]

        switch url.host {
        case "seed":
            switch url.path {
            case "/favorites": self = .seedFavorites
            case "/custom-line": self = .seedCustomLine
            default: return nil
            }
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
        case "planner":
            switch params["action"] {
            case "avoid": self = .plannerAvoid
            case "departure": self = .plannerDeparture
            case "arrival": self = .plannerArrival
            default: self = .plannerSearch
            }
        case "timetable":
            self = .timetable(
                ScreenshotTimetableTarget(
                    lineId: params["line"] ?? "Railway:JR-East.JobanRapid",
                    stationId: params["station"] ?? "Station:JR-East.JobanRapid.Tokyo"
                ),
                hidePast: params["hidePast"] != "0"
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

    static func seedFavorites() {
        SavedPlaceStore.save([
            SavedPlace(
                id: UUID(), kind: .home,
                lineId: "Railway:JR-East.JobanRapid",
                fromStationId: "Station:JR-East.JobanRapid.Tokyo",
                toStationId: "Station:JR-East.JobanRapid.Toride"
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
