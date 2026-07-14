import SwiftUI
import Backbone

// MARK: - Vertical Dash Line

/// A vertical line through the center of its rect, for dashed stroking.
private struct VerticalDashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - Vertical LCD Line

struct VerticalLCDLine: View {
    let journey: Journey
    let state: TrainPositionState
    let lineColor: Color

    private let stationSpacing: CGFloat = 72
    private let trackWidth: CGFloat = 3
    private let circleRadius: CGFloat = 9
    private let terminalRadius: CGFloat = 12
    private let currentRadius: CGFloat = 12

    /// Color of the line each station actually belongs to. Composite journeys
    /// keep per-leg station ids, so stations after a 乗り換え resolve to the
    /// connecting line's color instead of the whole journey's (first-leg) color.
    private func stationColor(_ station: Station) -> Color {
        StaticTrainData.line(containingStationId: station.id)?.trainLine.color ?? lineColor
    }

    var body: some View {
        let stations = journey.journeyStations
        let timetable = journey.journeyTimetable
        let transferIds = Set(journey.transferStationIds)

        VStack(spacing: 0) {
            ForEach(Array(stations.enumerated()), id: \.element.id) { index, station in
                let isFirst = index == 0
                let isLast = index == stations.count - 1
                let isTerminal = isFirst || isLast
                let frac = stations.count > 1 ? Double(index) / Double(stations.count - 1) : 0
                let isPast = frac <= state.progress + 0.005
                let isCurrent = state.currentStationIndex == index
                let isNext = (!isLast && index == state.segmentTo) ||
                             (state.currentStationIndex != nil && index == (state.currentStationIndex! + 1))
                let isTransfer = transferIds.contains(station.id)
                let target = isTransfer && index < stations.count - 1
                    ? transferTarget(at: station, nextStation: stations[index + 1])
                    : nil
                let segFrac = segmentFillFraction(stationIndex: index, totalStations: stations.count)
                let rowColor = stationColor(station)
                // The track below a row runs toward the NEXT station, so it
                // takes that station's line color (matters right after 乗換).
                let segColor = index < stations.count - 1 ? stationColor(stations[index + 1]) : rowColor

                HStack(alignment: .top, spacing: 0) {
                    timeColumn(for: station, timetable: timetable, isPast: isPast, isCurrent: isCurrent,
                               preferArrival: isTransfer)
                        .frame(width: 56)

                    stationCircle(
                        isPast: isPast,
                        isCurrent: isCurrent,
                        isTerminal: isTerminal,
                        isNext: isNext,
                        color: rowColor
                    )
                    .frame(width: 40)

                    stationLabel(
                        station: station,
                        isPast: isPast,
                        isCurrent: isCurrent,
                        isNext: isNext && !isTransfer,
                        isTerminal: isTerminal,
                        isTransfer: isTransfer,
                        color: rowColor
                    )
                    .padding(.bottom, isLast ? 0 : 14)

                    Spacer()
                }
                // Rows grow when the label stack is tall (transfer/next badges)
                // instead of overflowing into the next station.
                .frame(minHeight: isLast ? 0 : stationSpacing, alignment: .top)
                // The connecting track lives in the background so it always
                // spans the actual row height, whatever the label needed.
                // Walking to the connecting platform is drawn dashed.
                .background(alignment: .topLeading) {
                    if !isLast {
                        trackSegment(filled: isPast, fillFraction: target == nil ? segFrac : min(1, segFrac * 2),
                                     dashed: isTransfer, color: segColor)
                            .frame(width: trackWidth)
                            .padding(.top, stationDotRadius(isTerminal: isTerminal, isCurrent: isCurrent))
                            .padding(.leading, 56 + 20 - trackWidth / 2)
                    }
                }
                .id("station_\(index)")

                // Boarding point after the transfer: own dot and departure time
                if let target {
                    transferBoardingRow(
                        station: station,
                        target: target,
                        timetable: timetable,
                        isPast: isPast,
                        fillFraction: max(0, segFrac * 2 - 1)
                    )
                }
            }
        }
    }

    private func stationDotRadius(isTerminal: Bool, isCurrent: Bool) -> CGFloat {
        if isCurrent { return currentRadius }
        if isTerminal { return terminalRadius }
        return circleRadius
    }

    // MARK: - Time Column

    @ViewBuilder
    private func timeColumn(for station: Station, timetable: [TimetableEntry], isPast: Bool, isCurrent: Bool, preferArrival: Bool = false) -> some View {
        if let entry = timetable.first(where: { $0.stationId == station.id }),
           let timeStr = preferArrival
                ? (entry.arrivalTime ?? entry.departureTime)
                : (entry.departureTime ?? entry.arrivalTime),
           !timeStr.isEmpty {
            let delayMins = state.delayMinutes

            VStack(spacing: 1) {
                Text(timeStr)
                    .font(.system(size: 13, weight: isCurrent ? .bold : .medium, design: .rounded))
                    .foregroundColor(isPast && !isCurrent ? .secondary : .primary)

                if delayMins > 0 {
                    Text(adjustedTime(timeStr, delayMinutes: delayMins))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.red)
                }
            }
        } else {
            Color.clear
        }
    }

    // MARK: - Track Segment

    @ViewBuilder
    private func trackSegment(filled: Bool, fillFraction: Double, dashed: Bool = false, color: Color? = nil) -> some View {
        let strokeColor = color ?? lineColor
        if dashed {
            ZStack(alignment: .top) {
                VerticalDashLine()
                    .stroke(Color(.quaternarySystemFill),
                            style: StrokeStyle(lineWidth: trackWidth, lineCap: .round, dash: [1, 8]))

                GeometryReader { geo in
                    VerticalDashLine()
                        .stroke(strokeColor,
                                style: StrokeStyle(lineWidth: trackWidth, lineCap: .round, dash: [1, 8]))
                        .frame(height: max(0, geo.size.height * fillFraction))
                        .clipped()
                }
            }
        } else {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: trackWidth / 2)
                    .fill(Color(.quaternarySystemFill))

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: trackWidth / 2)
                        .fill(strokeColor)
                        .frame(height: max(0, geo.size.height * fillFraction))
                }
            }
        }
    }

    // MARK: - Transfer Target

    /// The same physical station on the line ridden after the transfer,
    /// resolved via the following station's line (e.g. 北千住 JJ05 → C18).
    private func transferTarget(at station: Station, nextStation: Station) -> (station: Station, line: TrainLine)? {
        guard let nextLine = StaticTrainData.line(containingStationId: nextStation.id),
              let target = nextLine.stations.first(where: { $0.name == station.name })
        else { return nil }
        return (target, nextLine.trainLine)
    }

    // MARK: - Transfer Boarding Row

    /// The boarding point on the connecting line, rendered as its own stop:
    /// departure time in the time column, dot on the track, and the next
    /// line's station badge and name.
    @ViewBuilder
    private func transferBoardingRow(
        station: Station,
        target: (station: Station, line: TrainLine),
        timetable: [TimetableEntry],
        isPast: Bool,
        fillFraction: Double
    ) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Group {
                if let entry = timetable.first(where: { $0.stationId == station.id }),
                   let dep = entry.departureTime, !dep.isEmpty {
                    Text(dep)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(isPast ? .secondary : .primary)
                } else {
                    Color.clear
                }
            }
            .frame(width: 56)

            ZStack {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: circleRadius * 2, height: circleRadius * 2)
                Circle()
                    .strokeBorder(target.line.color.opacity(isPast ? 1.0 : 0.5), lineWidth: 3)
                    .frame(width: circleRadius * 2, height: circleRadius * 2)
            }
            .frame(width: 40)

            HStack(spacing: 6) {
                if !target.station.stationCode.isEmpty {
                    StationNumberBadge(
                        code: target.station.stationCode,
                        color: target.line.color,
                        opacity: isPast ? 0.6 : 1.0,
                        size: .regular,
                        stationName: target.station.name
                    )
                }
                Text(target.station.localizedName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isPast ? .secondary : .primary)
                    .lineLimit(1)
            }
            .padding(.leading, 8)
            .padding(.bottom, 14)

            Spacer()
        }
        .frame(minHeight: stationSpacing * 0.8, alignment: .top)
        .background(alignment: .topLeading) {
            trackSegment(filled: isPast, fillFraction: fillFraction, color: target.line.color)
                .frame(width: trackWidth)
                .padding(.top, circleRadius)
                .padding(.leading, 56 + 20 - trackWidth / 2)
        }
    }

    // MARK: - Station Circle

    @ViewBuilder
    private func stationCircle(isPast: Bool, isCurrent: Bool, isTerminal: Bool, isNext: Bool, color: Color? = nil) -> some View {
        let r = isCurrent ? currentRadius : (isTerminal ? terminalRadius : circleRadius)
        let ringColor = color ?? lineColor

        ZStack {
            if isCurrent {
                Circle()
                    .fill(ringColor)
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .fill(Color.white)
                    .frame(width: r * 0.7, height: r * 0.7)
                    .shadow(color: ringColor, radius: 3)
                Circle()
                    .strokeBorder(ringColor, lineWidth: 2)
                    .frame(width: r * 2 + 10, height: r * 2 + 10)
            } else if isTerminal {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .strokeBorder(isPast ? ringColor : Color(.systemGray3), lineWidth: 3)
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .fill(isPast ? ringColor : Color(.systemGray5))
                    .frame(width: r * 2 - 10, height: r * 2 - 10)
            } else if isPast {
                Circle()
                    .fill(ringColor)
                    .frame(width: r * 2, height: r * 2)
            } else {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .strokeBorder(Color(.systemGray3), lineWidth: 2)
                    .frame(width: r * 2, height: r * 2)
            }

            if isNext && !isCurrent {
                Circle()
                    .strokeBorder(ringColor, lineWidth: 2)
                    .frame(width: r * 2 + 6, height: r * 2 + 6)
            }
        }
    }

    // MARK: - Station Label

    @ViewBuilder
    private func stationLabel(station: Station, isPast: Bool, isCurrent: Bool, isNext: Bool, isTerminal: Bool, isTransfer: Bool = false, color: Color? = nil) -> some View {
        let accent = color ?? lineColor
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                if !station.stationCode.isEmpty {
                    StationNumberBadge(
                        code: station.stationCode,
                        color: accent,
                        opacity: isPast && !isCurrent ? 0.4 : 1.0,
                        size: .regular,
                        stationName: station.name
                    )
                }

                Text(station.localizedName)
                    .font(.system(size: isCurrent || isTerminal || isTransfer ? 18 : 15,
                                  weight: isCurrent || isTerminal || isTransfer ? .bold : .medium))
                    .foregroundColor(isPast && !isCurrent ? .secondary : .primary)
            }

            if isTransfer {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 9, weight: .bold))
                    Text("Label.Transfer")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(isPast && !isCurrent ? 0.08 : 0.15))
                .clipShape(Capsule())
                .padding(.top, 2)
                .opacity(isPast && !isCurrent ? 0.5 : 1.0)
            }

            if isCurrent {
                Text("Label.CurrentLocation")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accent)
                    .clipShape(Capsule())
                    .padding(.top, 2)
            }

            if isNext && !isCurrent {
                Text("Label.NextStop")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accent.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.top, 2)
            }
        }
        .padding(.leading, 8)
    }

    // MARK: - Helpers

    private func segmentFillFraction(stationIndex: Int, totalStations: Int) -> Double {
        let stationFrac = totalStations > 1 ? Double(stationIndex) / Double(totalStations - 1) : 0
        let nextFrac = totalStations > 1 ? Double(stationIndex + 1) / Double(totalStations - 1) : 0

        if state.progress >= nextFrac { return 1.0 }
        if state.progress <= stationFrac { return 0.0 }

        let segRange = nextFrac - stationFrac
        guard segRange > 0 else { return 0 }
        return (state.progress - stationFrac) / segRange
    }

    private func adjustedTime(_ original: String, delayMinutes: Int) -> String {
        guard let secs = TimetableEntry.parseRailTime(original) else { return original }
        let adjusted = secs + delayMinutes * 60
        let h = adjusted / 3600
        let m = (adjusted % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }
}
