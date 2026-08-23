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
    /// Stops the rider can still act on; these rows become tappable.
    var selectableIndices: Set<Int> = []
    var onSelectStation: ((Int) -> Void)?

    /// Collapsed runs the rider has opened, keyed by index range.
    @State private var expandedRanges: Set<String> = []

    private let stationSpacing: CGFloat = 72
    private let trackWidth: CGFloat = 3
    private let timeColumnWidth: CGFloat = 44
    // Station number badges are 28pt tall; circles/track center on this so badge and dot line up.
    private let markerHeight: CGFloat = 28
    private let circleRadius: CGFloat = 9
    private let terminalRadius: CGFloat = 12
    private let currentRadius: CGFloat = 12
    // Collapsed folds break the track: solid stub, three dots, solid again.
    private let dotSize: CGFloat = 4.5
    private let dotSpacing: CGFloat = 5
    private let dotBreak: CGFloat = 10
    private let dotResume: CGFloat = 28

    /// Color of the line each station actually belongs to (composite journeys resolve per-leg after a 乗り換え).
    private func stationColor(_ station: Station) -> Color {
        StaticTrainData.line(containingStationId: station.id)?.trainLine.color ?? lineColor
    }

    var body: some View {
        let stations = journey.journeyStations
        let timetable = journey.journeyTimetable
        let transferIds = Set(journey.transferStationIds)

        let items = lineItems(stations: stations, transferIds: transferIds)

        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { position, item in
                let next = position + 1 < items.count ? items[position + 1] : nil
                let nextIsFold = next?.isFold ?? false
                let nextIsCollapsed = next?.isCollapsedFold ?? false
                switch item {
                case .station(let index, let groupID):
                    stationRow(index: index, groupID: groupID, stations: stations,
                               timetable: timetable, transferIds: transferIds,
                               tightBottom: nextIsFold, dottedBelow: nextIsCollapsed)
                case .collapsed(let range):
                    collapsedRow(range: range, stations: stations, isExpanded: false)
                case .expandedHandle(let range):
                    collapsedRow(range: range, stations: stations, isExpanded: true)
                }
            }
        }
    }

    // MARK: - Line Items

    private enum LineItem: Identifiable {
        case station(Int, groupID: String?)
        case collapsed(ClosedRange<Int>)
        case expandedHandle(ClosedRange<Int>)

        var id: String {
            switch self {
            case .station(let index, _): "s\(index)"
            case .collapsed(let range), .expandedHandle(let range):
                "c\(range.lowerBound)-\(range.upperBound)"
            }
        }

        var isFold: Bool {
            switch self {
            case .station: false
            case .collapsed, .expandedHandle: true
            }
        }

        /// Only a folded run draws dots, so only it needs the track broken above.
        var isCollapsedFold: Bool {
            if case .collapsed = self { return true }
            return false
        }
    }

    /// Rows to draw: terminals, 乗り換え, and the active segment stay put;
    /// runs of plain intermediate stops fold into one collapsed row.
    private func lineItems(stations: [Station], transferIds: Set<String>) -> [LineItem] {
        let count = stations.count
        guard count > 2 else { return stations.indices.map { .station($0, groupID: nil) } }

        var keep: Set<Int> = [0, count - 1]
        for (index, station) in stations.enumerated() where transferIds.contains(station.id) {
            keep.insert(index)
        }
        // The LCD above already presents the upcoming station, so only a
        // station the train is dwelling at pins itself open.
        if let current = state.currentStationIndex {
            keep.insert(current)
        }

        var items: [LineItem] = []
        var index = 0
        while index < count {
            if keep.contains(index) {
                items.append(.station(index, groupID: nil))
                index += 1
                continue
            }
            var end = index
            while end + 1 < count && !keep.contains(end + 1) { end += 1 }
            // Even a lone passed-through stop folds, so every run between two
            // kept rows reads the same way.
            let range = index...end
            let id = rangeID(range)
            if expandedRanges.contains(id) {
                // The pill stays put as the handle that folds the run back.
                items.append(.expandedHandle(range))
                items.append(contentsOf: range.map { .station($0, groupID: id) })
            } else {
                items.append(.collapsed(range))
            }
            index = end + 1
        }
        return items
    }

    private func rangeID(_ range: ClosedRange<Int>) -> String {
        "\(range.lowerBound)-\(range.upperBound)"
    }

    // MARK: - Station Row

    @ViewBuilder
    private func stationRow(index: Int, groupID: String?, stations: [Station],
                            timetable: [TimetableEntry], transferIds: Set<String>,
                            tightBottom: Bool, dottedBelow: Bool) -> some View {
        let station = stations[index]
        let isFirst = index == 0
        let isLast = index == stations.count - 1
        let isTerminal = isFirst || isLast
        let frac = stations.count > 1 ? Double(index) / Double(stations.count - 1) : 0
        let isPast = frac <= state.progress + 0.005
        let isCurrent = state.currentStationIndex == index
        let isTransfer = transferIds.contains(station.id)
        let target = isTransfer && index < stations.count - 1
            ? transferTarget(at: station, nextStation: stations[index + 1])
            : nil
        let segFrac = segmentFillFraction(stationIndex: index, totalStations: stations.count)
        let rowColor = stationColor(station)
        // Track below a row runs toward the NEXT station, so it takes that station's color.
        let segColor = index < stations.count - 1 ? stationColor(stations[index + 1]) : rowColor
        let isSelectable = selectableIndices.contains(index)
        // A fold row follows: end at the marker so the fold centers in the gap.
        // With a boarding row in between, that row tightens instead.
        let bottomSpan = tightBottom && target == nil ? markerHeight : stationSpacing

        let row = HStack(alignment: .top, spacing: 0) {
            timeColumn(for: station, timetable: timetable, isPast: isPast, isCurrent: isCurrent,
                       preferArrival: isTransfer)
                // Same height as the marker so the time centers on the dot.
                .frame(width: timeColumnWidth, height: markerHeight)

            stationCircle(
                isPast: isPast,
                isCurrent: isCurrent,
                isTerminal: isTerminal,
                color: rowColor
            )
            .frame(width: 40, height: markerHeight, alignment: .center)

            stationLabel(
                station: station,
                isPast: isPast,
                isCurrent: isCurrent,
                isTerminal: isTerminal,
                isTransfer: isTransfer,
                color: rowColor,
                // Only where the rider boards: at a transfer the platform belongs
                // to the boarding row below, and mid-journey they are already on.
                platform: isFirst && !stations.isEmpty
                    ? boardingPlatform(at: station, next: stations.count > 1 ? stations[1] : nil)
                    : nil
            )
            .padding(.bottom, isLast || bottomSpan == markerHeight ? 0 : 14)

            Spacer()

            if isSelectable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(height: markerHeight)
            }
        }
        .frame(minHeight: isLast ? 0 : bottomSpan, alignment: .top)
        .background(alignment: .topLeading) {
            if !isLast {
                trackSegment(filled: isPast,
                             fillFraction: target == nil ? segFrac : (isCurrent ? 1 : min(1, segFrac * 2)),
                             dashed: isTransfer, color: segColor)
                    // Overrun the next marker so rounded caps never notch at a seam,
                    // except above a folded run, where the track stops short of its dots.
                    .frame(width: trackWidth,
                           height: bottomSpan + trackWidth - (dottedBelow && target == nil ? dotBreak : 0))
                    .padding(.top, markerHeight / 2)
                    .padding(.leading, timeColumnWidth + 20 - trackWidth / 2)
            }
        }
        .overlay(alignment: .topLeading) {
            if let target {
                Image(systemName: target.station.id == station.id ? "hourglass" : "figure.walk")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                    .opacity(isPast ? 0.5 : 1.0)
                    .frame(width: timeColumnWidth, height: markerHeight, alignment: .center)
                    .padding(.top, stationSpacing / 2)
            }
        }

        if isSelectable {
            Button {
                onSelectStation?(index)
            } label: {
                row.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Replan.Station.Hint")
            .id("station_\(index)")
        } else if let groupID {
            // Plain rows in an opened run fold it back when tapped.
            Button {
                withAnimation(.snappy) {
                    _ = expandedRanges.remove(groupID)
                }
            } label: {
                row.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .id("station_\(index)")
        } else {
            row
                .id("station_\(index)")
        }

        // Boarding point after the transfer: own dot and departure time
        if let target {
            transferBoardingRow(
                station: station,
                target: target,
                next: index < stations.count - 1 ? stations[index + 1] : nil,
                timetable: timetable,
                isPast: isPast,
                isCurrent: isCurrent,
                fillFraction: max(0, segFrac * 2 - 1),
                tightBottom: tightBottom,
                dottedBelow: dottedBelow
            )
        }
    }

    // MARK: - Collapsed Row

    @ViewBuilder
    private func collapsedRow(range: ClosedRange<Int>, stations: [Station], isExpanded: Bool) -> some View {
        let count = stations.count
        let startFrac = count > 1 ? Double(range.lowerBound) / Double(count - 1) : 0
        let endFrac = count > 1 ? Double(range.upperBound + 1) / Double(count - 1) : 0
        // The expanded handle occupies no distance; only the folded pill spans the run.
        let fill = !isExpanded && endFrac > startFrac
            ? min(1, max(0, (state.progress - startFrac) / (endFrac - startFrac)))
            : (state.progress + 0.005 >= startFrac ? 1.0 : 0.0)
        let isPast = state.progress + 0.005 >= (isExpanded ? startFrac : endFrac)
        let color = stationColor(stations[range.upperBound])
        // With the tightened row above, the whole gap stays near a normal one.
        let rowHeight = stationSpacing * 2 / 3

        Button {
            withAnimation(.snappy) {
                if isExpanded {
                    _ = expandedRanges.remove(rangeID(range))
                } else {
                    _ = expandedRanges.insert(rangeID(range))
                }
            }
        } label: {
            HStack(alignment: .center, spacing: 0) {
                Color.clear
                    .frame(width: timeColumnWidth, height: markerHeight)

                // Hidden stops read as dots in the break, one per third of the run.
                VStack(spacing: dotSpacing) {
                    if !isExpanded {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(fill >= (Double(i) + 0.5) / 3 ? color : Color(.systemGray3))
                                .frame(width: dotSize, height: dotSize)
                        }
                    }
                }
                .frame(width: 40, height: rowHeight, alignment: .center)

                HStack(spacing: 5) {
                    Text("Journey.CollapsedStops \(range.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.leading, 8)

                Spacer()
            }
            .frame(height: rowHeight)
            .contentShape(Rectangle())
            .background(alignment: .topLeading) {
                // Folded: the track picks back up below the dots; opened: it runs straight through.
                let full = rowHeight + trackWidth
                let skip = isExpanded ? 0 : dotResume
                let span = full - skip
                let lowerFill = min(1, max(0, (fill * full - skip) / span))
                VStack(spacing: 0) {
                    Color.clear.frame(width: trackWidth, height: skip)
                    trackSegment(filled: isPast, fillFraction: lowerFill, color: color)
                        .frame(width: trackWidth, height: span)
                }
                .padding(.top, markerHeight / 2)
                .padding(.leading, timeColumnWidth + 20 - trackWidth / 2)
            }
        }
        .buttonStyle(.plain)
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

    /// The boarding point on the connecting line, rendered as its own stop.
    @ViewBuilder
    private func transferBoardingRow(
        station: Station,
        target: (station: Station, line: TrainLine),
        next: Station?,
        timetable: [TimetableEntry],
        isPast: Bool,
        isCurrent: Bool,
        fillFraction: Double,
        tightBottom: Bool,
        dottedBelow: Bool
    ) -> some View {
        // Full spacing, like any other stop: the ride away from a 乗り換え is a
        // segment like the rest, and a shortened one reads as a shorter hop.
        let bottomSpan = tightBottom ? markerHeight : stationSpacing

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
            .frame(width: timeColumnWidth, height: markerHeight)

            Group {
                if isCurrent {
                    // Transfer-to shares the current-station highlight when the transfer is current.
                    stationCircle(isPast: isPast, isCurrent: true, isTerminal: false,
                                  color: target.line.color)
                } else if isPast {
                    // Once passed, fill the dot like any other passed stop.
                    Circle()
                        .fill(target.line.color)
                        .frame(width: circleRadius * 2, height: circleRadius * 2)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: circleRadius * 2, height: circleRadius * 2)
                        Circle()
                            .strokeBorder(target.line.color.opacity(0.5), lineWidth: 3)
                            .frame(width: circleRadius * 2, height: circleRadius * 2)
                    }
                }
            }
            .frame(width: 40, height: markerHeight, alignment: .center)

            HStack(spacing: 6) {
                if !target.station.stationCode.isEmpty {
                    StationNumberBadge(
                        code: target.station.stationCode,
                        color: target.line.color,
                        opacity: isPast && !isCurrent ? 0.6 : 1.0,
                        size: .regular,
                        stationName: target.station.name,
                        styleOverride: journey.line.badgeStyleId,
                        lineId: journey.line.id
                    )
                }
                Text(target.station.localizedName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isPast && !isCurrent ? .secondary : .primary)
                    .lineLimit(1)

                if let platform = boardingPlatform(at: target.station, next: next) {
                    platformLabel(platform, isPast: isPast && !isCurrent)
                }
            }
            .padding(.leading, 8)
            .padding(.bottom, tightBottom ? 0 : 14)

            Spacer()
        }
        .frame(minHeight: bottomSpan, alignment: .top)
        .background(alignment: .topLeading) {
            trackSegment(filled: isPast, fillFraction: fillFraction, color: target.line.color)
                .frame(width: trackWidth, height: bottomSpan + trackWidth - (dottedBelow ? dotBreak : 0))
                .padding(.top, markerHeight / 2)
                .padding(.leading, timeColumnWidth + 20 - trackWidth / 2)
        }
    }

    // MARK: - Station Circle

    @ViewBuilder
    private func stationCircle(isPast: Bool, isCurrent: Bool, isTerminal: Bool, color: Color? = nil) -> some View {
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
        }
    }

    // MARK: - Station Label

    @ViewBuilder
    private func stationLabel(station: Station, isPast: Bool, isCurrent: Bool, isTerminal: Bool, isTransfer: Bool = false, color: Color? = nil, platform: String? = nil) -> some View {
        let accent = color ?? lineColor
        HStack(spacing: 6) {
            if !station.stationCode.isEmpty {
                StationNumberBadge(
                    code: station.stationCode,
                    color: accent,
                    opacity: isPast && !isCurrent ? 0.4 : 1.0,
                    size: .regular,
                    stationName: station.name,
                    styleOverride: journey.line.badgeStyleId,
                    lineId: journey.line.id
                )
            }

            Text(station.localizedName)
                .font(.system(size: isCurrent || isTerminal || isTransfer ? 18 : 15,
                              weight: isCurrent || isTerminal || isTransfer ? .bold : .medium))
                .foregroundColor(isPast && !isCurrent ? .secondary : .primary)

            if let platform {
                platformLabel(platform, isPast: isPast && !isCurrent)
            }
        }
        .padding(.leading, 8)
    }

    // MARK: - Platform

    /// 番線 for a stop the rider boards at. Most stations have no entry — the
    /// platform varies by train there — so this is absent more often than not.
    @ViewBuilder
    private func platformLabel(_ platform: String, isPast: Bool) -> some View {
        Text("Journey.Platform \(platform)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isPast ? .tertiary : .secondary)
    }

    /// The platform to board at, for a rider carrying on to `next`.
    /// The train's own departure time comes along: where a station's platform
    /// depends on which train turns up, that is what picks it.
    private func boardingPlatform(at station: Station, next: Station?) -> String? {
        guard let next,
              let line = StaticTrainData.line(containingStationId: station.id)
        else { return nil }
        let departure = journey.journeyTimetable
            .first { $0.stationId == station.id }?.departureTime
        return line.boardingPlatform(atStationId: station.id, nextStationId: next.id,
                                     departure: departure,
                                     calendar: .current(at: journey.startedAt))
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
