import SwiftUI

/// Sheet for the 出発時刻 customization: depart now, or at a chosen date and time.
struct DepartureTimeSheet: View {
    @Binding var departureMode: JourneyPlannerSection.DepartureMode
    @Binding var departureDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Picker("Setup.DepartureTime", selection: $departureMode) {
                    Text("Setup.DepartNow").tag(JourneyPlannerSection.DepartureMode.now)
                    Text("Setup.DepartAt").tag(JourneyPlannerSection.DepartureMode.scheduled)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                if departureMode == .scheduled {
                    DatePicker(
                        "Setup.DepartureTime",
                        selection: $departureDate,
                        in: Date().addingTimeInterval(-7 * 86400)...Date().addingTimeInterval(7 * 86400),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .environment(\.timeZone, TimeZone(identifier: "Asia/Tokyo")!)
                }
            }
            .navigationTitle("Setup.DepartureTime")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
