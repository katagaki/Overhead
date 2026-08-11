import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Depart Favorite Control

// The intent can't take location or start a Live Activity from the extension,
// so it opens the app with the place id staged in the App Group.

struct BoardPlaceEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "お気に入り")
    static let defaultQuery = BoardPlaceQuery()

    let id: String  // BoardPlace.id uuidString
    let title: String
    let destName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(destName)")
    }

    static func all() -> [BoardPlaceEntity] {
        (BoardSnapshotStore.load()?.places ?? []).map {
            BoardPlaceEntity(id: $0.id.uuidString, title: $0.title, destName: $0.destName)
        }
    }
}

struct BoardPlaceQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [BoardPlaceEntity] {
        let all = BoardPlaceEntity.all()
        return identifiers.compactMap { id in all.first { $0.id == id } }
    }

    func suggestedEntities() async throws -> [BoardPlaceEntity] {
        BoardPlaceEntity.all()
    }

    func defaultResult() async -> BoardPlaceEntity? {
        BoardPlaceEntity.all().first
    }
}

struct DepartFavoriteIntent: AppIntent {
    static let title: LocalizedStringResource = "お気に入りへ出発"
    static let description = IntentDescription("選んだお気に入りの経路をすぐに開始します。")
    static let openAppWhenRun = true

    @Parameter(title: "お気に入り")
    var place: BoardPlaceEntity?

    init() {}
    init(place: BoardPlaceEntity?) {
        self.place = place
    }

    func perform() async throws -> some IntentResult {
        if let place {
            AppGroup.defaults.set(place.id, forKey: BoardSnapshotStore.pendingPlaceKey)
        }
        return .result()
    }
}

struct DepartFavoriteConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "お気に入りへ出発"

    @Parameter(title: "お気に入り")
    var place: BoardPlaceEntity?
}

struct DepartFavoriteControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: "DepartFavorite",
            intent: DepartFavoriteConfiguration.self
        ) { configuration in
            ControlWidgetButton(action: DepartFavoriteIntent(place: configuration.place)) {
                Label(
                    configuration.place?.title ?? String(localized: "お気に入りへ出発"),
                    systemImage: "tram.fill"
                )
            }
        }
        .displayName("お気に入りへ出発")
        .description("お気に入りの経路をワンタップで開始します。")
    }
}
