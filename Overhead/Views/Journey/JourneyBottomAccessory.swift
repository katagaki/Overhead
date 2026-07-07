import SwiftUI
import Backbone

/// Compact always-visible summary of the active journey shown in the tab bar
/// bottom accessory; tapping it re-opens the journey sheet.
@available(iOS 26.0, *)
struct JourneyBottomAccessory: View {
    @ObservedObject var viewModel: JourneyViewModel
    let onTap: () -> Void

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

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
                    if placement == .inline {
                        Text(state.nextStationName)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Label.NextStation")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Text(state.nextStationName)
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(1)
                        }
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
