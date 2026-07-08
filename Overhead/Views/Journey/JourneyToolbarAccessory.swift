import SwiftUI
import Backbone

/// Compact always-visible summary of the active journey shown in the bottom
/// toolbar; tapping it re-opens the journey sheet.
struct JourneyToolbarAccessory: View {
    @ObservedObject var viewModel: JourneyViewModel
    let onTap: () -> Void

    private var lineColor: Color {
        viewModel.selectedLine?.color ?? .accentColor
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Circle()
                    .fill(lineColor)
                    .frame(width: 9, height: 9)

                if let state = viewModel.positionState {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Label.NextStation")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(state.nextStationName)
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Label.EstimatedArrival")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(Self.timeString(state.estimatedArrival))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(state.delayMinutes > 0 ? .red : .primary)
                    }
                } else if let journey = viewModel.activeJourney {
                    Text(journey.line.localizedName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private static func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f.string(from: date)
    }
}
