import SwiftUI
import Backbone

// MARK: - Service Status Section (運行情報)

/// Where and how to check the operator's live service status for a line.
/// Shown at the top of every line detail view, as a header + card matching
/// the custom inset-grouped layout.
struct ServiceStatusSection: View {
    let delayInfo: DelayCheckInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("StationTimetable.ServiceStatus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 12) {
                // How the operator publishes disruptions (informational)
                Text(delayInfo.localizedCheckMethod)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                if let url = URL(string: delayInfo.localizedStatusPageURL) {
                    Link(destination: url) {
                        Text("StationTimetable.ServiceStatus.Open")
                            .font(.system(size: 13, weight: .medium))
                    }
                }

                if let account = delayInfo.xAccount, let url = xURL(for: account) {
                    Link(destination: url) {
                        Text("StationTimetable.ServiceStatus.OpenX \(account)")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    private func xURL(for account: String) -> URL? {
        let handle = account.hasPrefix("@") ? String(account.dropFirst()) : account
        return URL(string: "https://x.com/\(handle)")
    }
}
