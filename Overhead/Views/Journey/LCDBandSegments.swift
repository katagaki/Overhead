import SwiftUI
import Backbone

// MARK: - LCD Band Segments

/// One line's stretch of a progression band, in points from the band's leading edge.
struct LCDBandSegment: Identifiable {
    let id: Int
    let color: Color
    let start: CGFloat
    /// nil runs on to the band's trailing edge.
    let end: CGFloat?
}

enum LCDBandSegments {
    /// The colour of the line a station actually belongs to; a 乗り換え or a
    /// 直通 junction puts stations of more than one line on the same journey.
    static func color(_ station: Station, fallback: Color) -> Color {
        guard let line = StaticTrainData.line(containingStationId: station.id)?.trainLine
        else { return fallback }
        return JourneyViewModel.lcdColor(line)
    }

    /// Runs of one line across `stations`, laid left to right on equal columns
    /// of `columnWidth` starting `origin` from the band's leading edge. The
    /// colour changes at the junction stop itself — the last one on the line
    /// being left — not in the gap after it.
    /// `travelsForward` when the array reads past → future; the junction stop
    /// sits on the other side of the break when it reads future → past.
    static func of(_ stations: [Station], fallback: Color,
                   columnWidth: CGFloat, origin: CGFloat = 0,
                   travelsForward: Bool = false) -> [LCDBandSegment] {
        guard !stations.isEmpty else { return [] }
        let anchor: CGFloat = travelsForward ? -0.5 : 0.5
        let lines = stations.map { StaticTrainData.line(containingStationId: $0.id)?.trainLine }
        var segments: [LCDBandSegment] = []
        var runStart = 0
        for index in 1...stations.count where
            index == stations.count || lines[index]?.id != lines[index - 1]?.id {
            segments.append(LCDBandSegment(
                id: segments.count,
                color: lines[runStart].map(JourneyViewModel.lcdColor) ?? fallback,
                start: runStart == 0 ? 0 : origin + (CGFloat(runStart) + anchor) * columnWidth,
                end: index == stations.count ? nil : origin + (CGFloat(index) + anchor) * columnWidth
            ))
            runStart = index
        }
        return segments
    }

    /// Fractions of `total` at which the colour changes, for bands drawn along
    /// a path rather than laid out in points.
    static func runs(_ stations: [Station], fallback: Color) -> [(color: Color, range: ClosedRange<Int>)] {
        guard !stations.isEmpty else { return [] }
        let lines = stations.map { StaticTrainData.line(containingStationId: $0.id)?.trainLine }
        var runs: [(color: Color, range: ClosedRange<Int>)] = []
        var runStart = 0
        for index in 1...stations.count where
            index == stations.count || lines[index]?.id != lines[index - 1]?.id {
            runs.append((lines[runStart].map(JourneyViewModel.lcdColor) ?? fallback, runStart...(index - 1)))
            runStart = index
        }
        return runs
    }
}

/// Paints `band` once per line the journey runs over, so the band changes
/// colour where the train changes line.
struct SegmentedBand<Content: View>: View {
    let segments: [LCDBandSegment]
    let fallback: Color
    @ViewBuilder var band: (Color) -> Content

    var body: some View {
        if segments.count <= 1 {
            band(segments.first?.color ?? fallback)
        } else {
            ZStack {
                ForEach(segments) { segment in
                    band(segment.color)
                        .mask(alignment: .leading) { window(segment) }
                }
            }
        }
    }

    /// The stretch of band a segment owns; the outer two run off to the edges.
    private func window(_ segment: LCDBandSegment) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: max(0, segment.start))
            if let end = segment.end {
                Color.black.frame(width: max(0, end - segment.start))
                Color.clear.frame(maxWidth: .infinity)
            } else {
                Color.black.frame(maxWidth: .infinity)
            }
        }
    }
}
