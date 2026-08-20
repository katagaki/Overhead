import SwiftUI
import Backbone

// MARK: - Merged Station Row

/// One row per physical station: name on the left edge, every line's badge on the right.
struct MergedStationRow: View {
    let primary: StationSearchHit
    let hits: [StationSearchHit]
    /// Secondary text under the name (e.g. distance for nearby rows).
    var subtitle: String? = nil

    private static let maxBadges = 4

    /// Numbered lines first, in station-code order, like station signage.
    private var orderedHits: [StationSearchHit] {
        hits.sorted {
            switch ($0.station.stationCode.isEmpty, $1.station.stationCode.isEmpty) {
            case (false, true): return true
            case (true, false): return false
            default: return $0.station.stationCode < $1.station.stationCode
            }
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(primary.station.localizedName)
                    .font(.system(size: 16, weight: .semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                } else if primary.station.nameEn != primary.station.localizedName {
                    Text(primary.station.nameEn)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                let ordered = orderedHits
                ForEach(ordered.prefix(Self.maxBadges)) { hit in
                    badge(for: hit)
                }
                if ordered.count > Self.maxBadges {
                    Text(verbatim: "+\(ordered.count - Self.maxBadges)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func badge(for hit: StationSearchHit) -> some View {
        if !hit.station.stationCode.isEmpty {
            StationNumberBadge(
                code: hit.station.stationCode,
                color: hit.line.color,
                size: .compact,
                stationName: hit.station.name,
                styleOverride: hit.line.badgeStyleId
            )
        } else if !hit.line.lineSymbol.isEmpty {
            LineSymbolBadge(
                symbol: hit.line.lineSymbol,
                color: hit.line.color,
                styleOverride: hit.line.badgeStyleId
            )
        } else {
            RoundedRectangle(cornerRadius: 3)
                .fill(hit.line.color)
                .frame(width: 8, height: 32)
        }
    }
}
