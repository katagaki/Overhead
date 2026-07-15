import SwiftUI
import Backbone

/// Wraps the journey view for sheet presentation.
struct JourneySheetView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndConfirmation = false
    @State private var shareImage: ShareableImage?
    @AppStorage(TrainLCDStyle.storageKey) private var lcdStyleRaw = TrainLCDStyle.joban.rawValue
    @AppStorage(TrainLCDOrientation.storageKey) private var lcdOrientationRaw = TrainLCDOrientation.left.rawValue

    var body: some View {
        NavigationStack {
            JourneyView(viewModel: viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingEndConfirmation = true
                        } label: {
                            Label("Button.EndJourney", systemImage: "stop.circle")
                        }
                        .tint(.red)
                        // Attached to the button so the dialog anchors to it.
                        .confirmationDialog(
                            "Journey.End.ConfirmTitle",
                            isPresented: $showingEndConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Button.EndJourney", role: .destructive) {
                                viewModel.stopJourney()
                            }
                            Button("Button.KeepJourney", role: .cancel) {}
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if let image = renderLCDImage() {
                                shareImage = ShareableImage(image: image)
                            }
                        } label: {
                            Label("Button.ShareImage", systemImage: "square.and.arrow.up")
                        }
                        .disabled(viewModel.activeJourney == nil || viewModel.positionState == nil)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(TrainLCDStyleCategory.allCases) { category in
                                Section(category.label) {
                                    Picker("Button.LCDStyle", selection: $lcdStyleRaw) {
                                        ForEach(category.styles) { style in
                                            Text(verbatim: style.label).tag(style.rawValue)
                                        }
                                    }
                                    .pickerStyle(.inline)
                                }
                            }
                            Picker("Button.LCDOrientation", selection: $lcdOrientationRaw) {
                                ForEach(TrainLCDOrientation.allCases) { orientation in
                                    Text(verbatim: orientation.label).tag(orientation.rawValue)
                                }
                            }
                        } label: {
                            Label("Button.LCDStyle", systemImage: "widget.medium")
                        }
                    }

                    ToolbarSpacer(.fixed, placement: .topBarTrailing)

                    ToolbarItem(placement: .topBarTrailing) {
                        if #available(iOS 26.0, *) {
                            Button(role: .close) {
                                dismiss()
                            }
                        } else {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .tint(.secondary)
                            .accessibilityLabel("Button.Close")
                        }
                    }
                }
        }
        .presentationDragIndicator(.visible)
        .sheet(item: $shareImage) { shareable in
            ActivityView(items: [shareable.image])
        }
    }

    // MARK: - LCD snapshot

    /// Renders the current LCD to a @3x image for sharing.
    @MainActor
    private func renderLCDImage() -> UIImage? {
        guard let journey = viewModel.activeJourney,
              let state = viewModel.positionState else { return nil }
        let color = viewModel.selectedLine?.color ?? .gray
        let orientation = TrainLCDOrientation(rawValue: lcdOrientationRaw) ?? .left

        let lcd = Group {
            switch TrainLCDStyle(rawValue: lcdStyleRaw) ?? .joban {
            case .joban:
                TrainLCDView(journey: journey, state: state, lineColor: color, orientation: orientation)
            case .chuoSobu:
                ChuoSobuLineLCDView(journey: journey, state: state, lineColor: color, orientation: orientation)
            case .yamanote:
                LoopLCDView(journey: journey, state: state, lineColor: color, orientation: orientation)
            case .tokyoMetro:
                MetroLCDView(journey: journey, state: state, lineColor: color, orientation: orientation)
            case .ledMatrix:
                LEDMatrixView(journey: journey, state: state, lineColor: color)
            case .kivotos:
                MillenniumLCDView(journey: journey, state: state, lineColor: color, orientation: orientation)
            case .shinkansen:
                ShinkansenTickerView(journey: journey, state: state, lineColor: color)
            case .hankyu:
                HankyuLCDView(journey: journey, state: state, lineColor: color, orientation: orientation)
            case .tube:
                TubeLCDView(journey: journey, state: state, lineColor: color)
            case .find:
                FindLCDView(journey: journey, state: state, lineColor: color, orientation: orientation)
            case .neon:
                NeonLCDView(journey: journey, state: state, lineColor: color, orientation: orientation)
            case .galaxy:
                GalaxyLCDView(journey: journey, state: state, lineColor: color, orientation: orientation)
            }
        }
        .frame(width: 360)
        .padding(12)
        .background(Color(.systemBackground))

        let renderer = ImageRenderer(content: lcd)
        renderer.scale = 3
        return renderer.uiImage
    }
}
