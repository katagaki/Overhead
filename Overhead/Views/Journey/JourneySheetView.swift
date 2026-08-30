import SwiftUI
import Backbone

struct JourneySheetView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndConfirmation = false
    @State private var shareImage: ShareableImage?
    @State private var statusTarget: ServiceStatusTarget?
    @State private var showingStylePicker = false
    @AppStorage(TrainLCDStyle.storageKey) private var lcdStyleRaw = TrainLCDStyle.joban.rawValue
    @Namespace private var statusZoom

    private static let statusTransitionID = "serviceStatus"
    private static let styleTransitionID = "lcdStyle"

    /// Journey lines with a status page; a through-service joins its legs with "+".
    private var statusLines: [(id: String, name: String)] {
        guard let journey = viewModel.activeJourney else { return [] }
        return journey.line.id
            .split(separator: "+")
            .map(String.init)
            .filter { viewModel.delayCheckInfo(for: $0) != nil }
            .map { ($0, StaticTrainData.line(withId: $0)?.trainLine.localizedName ?? $0) }
    }

    var body: some View {
        NavigationStack {
            JourneyView(viewModel: viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if let image = viewModel.renderLCDImage() {
                                shareImage = ShareableImage(image: image)
                            }
                        } label: {
                            Label("Button.ShareImage", systemImage: "square.and.arrow.up")
                        }
                        .disabled(viewModel.activeJourney == nil || viewModel.positionState == nil)
                    }

                    // A chevron, not a close glyph: the journey keeps running.
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Label("Button.Close", systemImage: "chevron.down")
                        }
                    }

                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            showingEndConfirmation = true
                        } label: {
                            Label("Button.EndJourney", systemImage: "stop.fill")
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

                    ToolbarSpacer(.flexible, placement: .bottomBar)

                    ToolbarItem(placement: .bottomBar) {
                        serviceStatusControl
                    }

                    ToolbarSpacer(.flexible, placement: .bottomBar)

                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            showingStylePicker = true
                        } label: {
                            Label("Button.LCDStyle", systemImage: "gearshape")
                        }
                        .matchedTransitionSource(id: Self.styleTransitionID, in: statusZoom)
                    }

                }
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingStylePicker) {
            LCDStylePickerSheet(styleRaw: $lcdStyleRaw)
                .navigationTransition(.zoom(sourceID: Self.styleTransitionID, in: statusZoom))
        }
        .sheet(item: $shareImage) { shareable in
            ActivityView(items: [shareable.image])
        }
        .sheet(item: $statusTarget) { target in
            ServiceStatusSheet(
                lineId: target.lineId,
                delayInfo: target.delayInfo,
                web: target.web
            )
            .navigationTransition(.zoom(sourceID: Self.statusTransitionID, in: statusZoom))
        }
    }

    // MARK: - 運行情報

    /// One button for a single-line journey, a line picker for a composite one.
    @ViewBuilder
    private var serviceStatusControl: some View {
        let lines = statusLines
        Group {
            if lines.count > 1 {
                Menu {
                    ForEach(lines, id: \.id) { line in
                        Button(line.name) { presentStatus(lineId: line.id) }
                    }
                } label: {
                    Text("StationTimetable.ServiceStatus")
                }
                .menuOrder(.fixed)
            } else {
                Button {
                    if let line = lines.first { presentStatus(lineId: line.id) }
                } label: {
                    Text("StationTimetable.ServiceStatus")
                }
                .disabled(lines.isEmpty)
            }
        }
        .matchedTransitionSource(id: Self.statusTransitionID, in: statusZoom)
    }

    private func presentStatus(lineId: String) {
        guard let delayInfo = viewModel.delayCheckInfo(for: lineId) else { return }
        statusTarget = ServiceStatusTarget(lineId: lineId, delayInfo: delayInfo)
    }
}
