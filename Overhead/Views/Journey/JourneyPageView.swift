import SwiftUI
import Backbone
import EnhancedNavigation

/// The journey, pushed onto the tab it was started from.
struct JourneyPageView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @ObservedObject var session: JourneySession
    @State private var shareImage: ShareableImage?
    @Environment(\.appTabOpenDestination) private var openTabDestination
    @State private var showingStylePicker = false
    @AppStorage(TrainLCDStyle.storageKey) private var lcdStyleRaw = TrainLCDStyle.joban.rawValue
    @Namespace private var styleZoom

    private static let styleTransitionID = "lcdStyle"

    /// Journey lines with a status page; a through-service joins its legs with "+".
    private var statusLines: [(id: String, name: String)] {
        session.journey.line.id
            .split(separator: "+")
            .map(String.init)
            .filter { viewModel.delayCheckInfo(for: $0) != nil }
            .map { ($0, StaticTrainData.line(withId: $0)?.trainLine.localizedName ?? $0) }
    }

    var body: some View {
        JourneyView(viewModel: viewModel, session: session)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    serviceStatusControl
                }

                ToolbarSpacer(.fixed, placement: .topBarTrailing)

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingStylePicker = true
                    } label: {
                        Label("Button.LCDStyle", systemImage: "gearshape")
                    }
                    .matchedTransitionSource(id: Self.styleTransitionID, in: styleZoom)
                }
            }
            .tabOmniboxAccessory {
                Button("Button.ShareImage", systemImage: "square.and.arrow.up") {
                    if let image = session.renderLCDImage() {
                        shareImage = ShareableImage(image: image)
                    }
                }
                .disabled(session.positionState == nil)
            }
            .sheet(isPresented: $showingStylePicker) {
                LCDStylePickerSheet(styleRaw: $lcdStyleRaw)
                    .navigationTransition(.zoom(sourceID: Self.styleTransitionID, in: styleZoom))
            }
            .sheet(item: $shareImage) { shareable in
                ActivityView(items: [shareable.image])
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
    }

    private func presentStatus(lineId: String) {
        openTabDestination?(.serviceStatus(lineId: lineId))
    }
}
