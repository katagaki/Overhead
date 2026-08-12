import SwiftUI

/// Alert sound for the journey notifications.
///
/// Raw values are the CAF basenames in `Overhead/Sounds`, deliberately without
/// the numeric prefixes used in `Assets/Melodies`: those numbers are an ordering
/// device for the score file and have been reshuffled more than once, which would
/// invalidate a stored preference every time. The order here is the menu order.
enum NotificationSound: String, CaseIterable, Identifiable {

    /// Whatever the system would play. The default, so an existing install is
    /// unaffected by any of this.
    case system

    /// Alert still appears, it just makes no sound. Distinct from turning
    /// notifications off entirely, which is the オフ entry on the lead time.
    case silent

    // Original melodies
    case asagiri, hasshin, kasukeki, hananoeki, tokoyo
    case kouen, kagerou, rinbu, zankyou, akatsuki

    // Arrangements of public domain works
    case sonata, canon, sakura, kanki, hotaru, minuet, spring

    // Chimes and bells
    case tobira, kane, nobori, hassha

    static let storageKey = "notifications.sound"

    /// Read live, so changing it mid-journey applies to alerts not yet fired.
    static var current: NotificationSound {
        UserDefaults.standard.string(forKey: storageKey)
            .flatMap(NotificationSound.init(rawValue:)) ?? .system
    }

    var id: String { rawValue }

    /// `nil` means the system sound; anything else is a file in the bundle.
    var fileName: String? {
        switch self {
        case .system, .silent: return nil
        default: return "\(rawValue).caf"
        }
    }

    var isSilent: Bool { self == .silent }

    /// Titles are the pieces' own names and stay in Japanese in every locale,
    /// the same way line and station names do elsewhere in the app.
    var title: String {
        switch self {
        case .system, .silent: return ""
        case .asagiri: return "朝霧"
        case .hasshin: return "発進"
        case .kasukeki: return "幽けき軌道"
        case .hananoeki: return "花の駅"
        case .tokoyo: return "常世の路"
        case .kouen: return "紅炎"
        case .kagerou: return "陽炎"
        case .rinbu: return "輪舞"
        case .zankyou: return "残響"
        case .akatsuki: return "暁"
        case .sonata: return "ソナタ"
        case .canon: return "カノン"
        case .sakura: return "さくら"
        case .kanki: return "歓喜の歌"
        case .hotaru: return "蛍の光"
        case .minuet: return "メヌエット"
        case .spring: return "春"
        case .tobira: return "扉"
        case .kane: return "鐘"
        case .nobori: return "昇り"
        case .hassha: return "発車ベル"
        }
    }

    enum Category: String, CaseIterable, Identifiable {
        case system, melody, arrangement, chime

        var id: String { rawValue }

        var label: LocalizedStringKey {
            switch self {
            case .system: return "Settings.Notifications.Sound.System"
            case .melody: return "Settings.Notifications.Sound.Melodies"
            case .arrangement: return "Settings.Notifications.Sound.Arrangements"
            case .chime: return "Settings.Notifications.Sound.Chimes"
            }
        }
    }

    var category: Category {
        switch self {
        case .system, .silent:
            return .system
        case .asagiri, .hasshin, .kasukeki, .hananoeki, .tokoyo,
             .kouen, .kagerou, .rinbu, .zankyou, .akatsuki:
            return .melody
        case .sonata, .canon, .sakura, .kanki, .hotaru, .minuet, .spring:
            return .arrangement
        case .tobira, .kane, .nobori, .hassha:
            return .chime
        }
    }

    static func cases(in category: Category) -> [NotificationSound] {
        allCases.filter { $0.category == category }
    }
}
