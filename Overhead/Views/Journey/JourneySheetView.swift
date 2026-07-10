import SwiftUI
import Backbone

/// Wraps the journey view for sheet presentation: a toolbar with a proper
/// close button (minimizes back into the tab bar accessory) and an
/// end-journey action with confirmation.
struct JourneySheetView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEndConfirmation = false

    var body: some View {
        NavigationStack {
            JourneyView(viewModel: viewModel, showsEndButton: false)
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
