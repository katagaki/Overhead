import SwiftUI
import Backbone

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
                            if let image = viewModel.renderLCDImage() {
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
}
