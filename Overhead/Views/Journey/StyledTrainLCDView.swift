import SwiftUI
import Backbone

private struct LCDScreenCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat = 6
}

extension EnvironmentValues {
    /// Corner rounding of the LCD screen inside the bezel; PiP bumps it up.
    var lcdScreenCornerRadius: CGFloat {
        get { self[LCDScreenCornerRadiusKey.self] }
        set { self[LCDScreenCornerRadiusKey.self] = newValue }
    }
}

/// The screen clip every LCD style applies inside its bezel.
struct LCDScreenClip: ViewModifier {
    @Environment(\.lcdScreenCornerRadius) private var radius

    func body(content: Content) -> some View {
        content.clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

/// The single switch over `TrainLCDStyle`, shared by every LCD consumer.
struct StyledTrainLCDView: View {
    let style: TrainLCDStyle
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color
    let orientation: TrainLCDOrientation

    var body: some View {
        switch style {
        case .joban:
            TrainLCDView(journey: journey, state: state, lineColor: lineColor, orientation: orientation)
        case .keihinTohoku:
            KeihinTohokuLineLCDView(journey: journey, state: state, lineColor: lineColor, orientation: orientation)
        case .yamanote:
            LoopLCDView(journey: journey, state: state, lineColor: lineColor, orientation: orientation)
        case .tokyoMetro:
            MetroLCDView(journey: journey, state: state, lineColor: lineColor, orientation: orientation)
        case .ledMatrix:
            LEDMatrixView(journey: journey, state: state, lineColor: lineColor)
        case .kivotos:
            MillenniumLCDView(journey: journey, state: state, lineColor: lineColor, orientation: orientation)
        case .shinkansen:
            ShinkansenTickerView(journey: journey, state: state, lineColor: lineColor)
        case .hankyu:
            HankyuLCDView(journey: journey, state: state, lineColor: lineColor, orientation: orientation)
        case .tube:
            TubeLCDView(journey: journey, state: state, lineColor: lineColor)
        case .find:
            FindLCDView(journey: journey, state: state, lineColor: lineColor, orientation: orientation)
        case .neon:
            NeonLCDView(journey: journey, state: state, lineColor: lineColor, orientation: orientation)
        case .galaxy:
            GalaxyLCDView(journey: journey, state: state, lineColor: lineColor, orientation: orientation)
        }
    }
}
