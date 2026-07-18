import SwiftUI

/// Sheet for the 出発時刻 customization: depart now, or at a chosen date and time.
struct DepartureTimeSheet: View {
    @Binding var departureMode: JourneyPlannerSection.DepartureMode
    @Binding var departureDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Setup.DepartureTime", selection: $departureMode.animation()) {
                    Text("Setup.DepartNow").tag(JourneyPlannerSection.DepartureMode.now)
                    Text("Setup.DepartAt").tag(JourneyPlannerSection.DepartureMode.scheduled)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer(minLength: 0)

                if departureMode == .scheduled {
                    DatePicker(
                        "Setup.DepartureTime",
                        selection: $departureDate,
                        in: Date().addingTimeInterval(-7 * 86400)...Date().addingTimeInterval(7 * 86400),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.timeZone, TimeZone(identifier: "Asia/Tokyo")!)
                    .frame(maxWidth: .infinity)
                    .clipped()
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("Setup.DepartNowHint")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                }

                Spacer(minLength: 0)
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
