import SwiftUI
import Backbone

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
        case .chuoSobu:
            ChuoSobuLineLCDView(journey: journey, state: state, lineColor: lineColor, orientation: orientation)
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
