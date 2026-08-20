import Foundation
import SwiftUI

public struct TrainLine: Identifiable, Codable, Hashable {
    public let id: String           // e.g. "Railway:JR-East.ChuoRapid"
    public let name: String
    public let nameEn: String
    public let nameKo: String
    public let nameZhHans: String
    public let nameZhHant: String
    public let operatorId: String   // e.g. "Operator:JR-East"
    public let stations: [Station]
    public let colorHex: String     // Primary accent color
    /// Set by user-created (Custom:) lines, whose codes match no operator.
    /// nil lets the badge be resolved from the symbol.
    public var badgeStyleId: String?

    public init(id: String, name: String, nameEn: String, nameKo: String = "", nameZhHans: String = "", nameZhHant: String = "", operatorId: String, stations: [Station], colorHex: String, badgeStyleId: String? = nil) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.nameKo = nameKo
        self.nameZhHans = nameZhHans
        self.nameZhHant = nameZhHant
        self.operatorId = operatorId
        self.stations = stations
        self.colorHex = colorHex
        self.badgeStyleId = badgeStyleId
    }

    /// True for user-created lines. These never enter the static route graph,
    /// so they can't be transferred to/from built-in lines.
    public var isCustom: Bool { id.hasPrefix("Custom:") }

    public var color: Color {
        Color(hex: colorHex)
    }

    public var lineSymbol: String {
        // The line's own Badge.json entry wins: a line whose first station is a
        // junction shared with another operator would otherwise inherit that
        // operator's letters (北総線 → KS).
        if let symbol = BadgeStyles.config(lineId: id)?.symbol, !symbol.isEmpty { return symbol }
        if let station = stations.first(where: { !$0.stationCode.isEmpty }) {
            let letters = station.stationCode.prefix(while: \.isLetter)
            if !letters.isEmpty { return String(letters) }
        }
        return ""
    }

    /// Whether this line uses JR-style badges (rounded rectangle)
    public var isJR: Bool {
        lineSymbol.hasPrefix("J")
    }

    public var localizedName: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        switch lang {
        case "en": return nameEn.isEmpty ? name : nameEn
        case "ko": return nameKo.isEmpty ? name : nameKo
        case "zh":
            let script = Locale.current.language.script?.identifier ?? ""
            if script == "Hant" {
                return nameZhHant.isEmpty ? name : nameZhHant
            }
            return nameZhHans.isEmpty ? name : nameZhHans
        default: return name
        }
    }
}
