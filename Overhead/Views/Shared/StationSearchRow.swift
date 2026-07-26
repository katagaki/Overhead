import SwiftUI
import Backbone

struct StationSearchRow: View {
    let hit: StationSearchHit

    var body: some View {
        HStack(spacing: 10) {
            if !hit.station.stationCode.isEmpty {
                StationNumberBadge(
                    code: hit.station.stationCode,
                    color: hit.line.color,
                    size: .compact,
                    stationName: hit.station.name,
                    styleOverride: hit.line.badgeStyle
                )
            } else if !hit.line.lineSymbol.isEmpty {
                LineSymbolBadge(
                    symbol: hit.line.lineSymbol,
                    color: hit.line.color,
                    styleOverride: hit.line.badgeStyle
                )
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(hit.line.color)
                    .frame(width: 4, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(hit.station.localizedName)
                    .font(.system(size: 16, weight: .semibold))
                Text(hit.line.localizedName)
                    .font(.system(size: 12))
                    .foregroundColor(hit.line.color)
            }
        }
    }
}
