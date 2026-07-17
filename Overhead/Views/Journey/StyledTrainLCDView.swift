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

private struct LCDBezelCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat = 12
}

extension EnvironmentValues {
    /// Corner rounding of the glass bezel around the LCD; PiP squares it off.
    var lcdBezelCornerRadius: CGFloat {
        get { self[LCDBezelCornerRadiusKey.self] }
        set { self[LCDBezelCornerRadiusKey.self] = newValue }
    }
}

/// The screen clip every LCD style applies inside its bezel.
struct LCDScreenClip: ViewModifier {
    @Environment(\.lcdScreenCornerRadius) private var radius

    func body(content: Content) -> some View {
        content.clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

/// The glass bezel every LCD style wraps itself in.
struct LCDBezel: ViewModifier {
    @Environment(\.lcdBezelCornerRadius) private var radius

    func body(content: Content) -> some View {
        content.glassEffect(
            .regular.tint(Color(red: 0.2, green: 0.26, blue: 0.33).opacity(0.4)),
            in: RoundedRectangle(cornerRadius: radius)
        )
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
