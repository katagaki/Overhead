import SwiftUI

/// Sheet for the 時刻設定 customization: leave now, or pin a 出発時刻 / 到着時刻.
struct TimeSettingsSheet: View {
    @Binding var timeMode: JourneyPlannerSection.TimeMode
    @Binding var pinnedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Setup.TimeSettings", selection: $timeMode.animation()) {
                    Text("Setup.DepartNow").tag(JourneyPlannerSection.TimeMode.now)
                    Text("Setup.DepartAt").tag(JourneyPlannerSection.TimeMode.departAt)
                    Text("Setup.ArriveBy").tag(JourneyPlannerSection.TimeMode.arriveBy)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer(minLength: 0)

                if timeMode == .now {
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
                } else {
                    VStack(spacing: 4) {
                        DatePicker(
                            timeMode == .arriveBy ? "Setup.ArrivalTime" : "Setup.DepartureTime",
                            selection: $pinnedDate,
                            in: Date().addingTimeInterval(-7 * 86400)...Date().addingTimeInterval(7 * 86400),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.timeZone, TimeZone(identifier: "Asia/Tokyo")!)
                        .frame(maxWidth: .infinity)
                        .clipped()

                        Text(timeMode == .arriveBy ? "Setup.ArriveByHint" : "Setup.DepartAtHint")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("Setup.TimeSettings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
