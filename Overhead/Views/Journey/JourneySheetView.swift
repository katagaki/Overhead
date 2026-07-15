import SwiftUI
import Backbone

/// Wraps the journey view for sheet presentation: a toolbar with a proper
/// close button (minimizes back into the tab bar accessory) and an
/// end-journey action with confirmation.
struct JourneySheetView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndConfirmation = false
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
                        // Attached to the button so the dialog anchors to it
                        // instead of popping from the middle of the sheet.
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
                        Menu {
                            Picker("Button.LCDStyle", selection: $lcdStyleRaw) {
                                ForEach(TrainLCDStyle.allCases) { style in
                                    Text(verbatim: style.label).tag(style.rawValue)
                                }
                            }
                            Picker("Button.LCDOrientation", selection: $lcdOrientationRaw) {
                                ForEach(TrainLCDOrientation.allCases) { orientation in
                                    Text(verbatim: orientation.label).tag(orientation.rawValue)
                                }
                            }
                        } label: {
                            Label("Button.LCDStyle", systemImage: "ellipsis")
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
    }
}
