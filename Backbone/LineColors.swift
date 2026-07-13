import Foundation

// MARK: - Line Color Constants

public enum LineColors {
    public static let yamanote       = "#9ACD32"
    public static let chuoRapid      = "#F15A22"
    public static let keihinTohoku   = "#00B2E5"
    public static let ginza          = "#F7931D"
    public static let marunouchi     = "#E60012"
    public static let hibiya         = "#B5B5AC"
    public static let tozai          = "#00A7DB"
    public static let chiyoda        = "#00A854"
    public static let hanzomon       = "#8B76D0"
    public static let fukutoshin     = "#9C5E31"
    public static let toeiAsakusa    = "#E85298"
    public static let toeiOedo       = "#B6007A"

    /// LCD-display-only line colors. Badges and everything else keep the data
    /// color (the Joban Local's wayfinding gray); the in-car LCD uses the
    /// train's emerald identity.
    public static let lcdOverrides: [String: String] = [
        "Railway:JR-East.JobanLocal": "#33A385",
    ]
}
