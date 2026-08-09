import SwiftUI
import Backbone

struct JourneyToolbarAccessory: View {
    @ObservedObject var viewModel: JourneyViewModel
    let availableWidth: CGFloat
    let onTap: () -> Void

    private static let badgeDimension: CGFloat = 24
    private static let slotSpacing: CGFloat = 10
    private static let horizontalPadding: CGFloat = 10
    private static let barHeight: CGFloat = 40

    private var lineColor: Color {
        viewModel.selectedLine?.color ?? .accentColor
    }

    private var originStation: Station? {
        viewModel.activeJourney?.journeyStations.first
    }

    /// Nil at the alighting station, which 降車 already holds.
    private var nextStation: Station? {
        guard let journey = viewModel.activeJourney, let state = viewModel.positionState else { return nil }
        let stations = journey.journeyStations
        guard !stations.isEmpty else { return nil }
        let index = state.currentStationIndex
            ?? (state.status == .notStarted ? state.segmentFrom : state.segmentTo)
        let station = stations[max(0, min(index, stations.count - 1))]
        return station.id == journey.alightingStationId ? nil : station
    }

    private var finalStation: Station? {
        viewModel.activeJourney?.journeyStations.last
    }

    /// Once true, 乗車 gives up its slot to the changes ahead.
    private var hasLeftOrigin: Bool {
        guard let state = viewModel.positionState else { return false }
        let index = state.currentStationIndex
            ?? (state.status == .notStarted ? state.segmentFrom : state.segmentTo)
        return index > 0
    }

    private var showsOrigin: Bool {
        !hasLeftOrigin && originStation != nil
    }

    /// Three slots at most, one of which 降車 always holds.
    private var shownTransfers: [JourneyViewModel.UpcomingTransfer] {
        Array(viewModel.upcomingTransfers.prefix(showsOrigin ? 1 : 2))
    }

    private var hiddenTransferCount: Int {
        max(0, viewModel.upcomingTransfers.count - shownTransfers.count)
    }

    /// Two badges per change don't fit alongside a third slot and the count.
    private var showsOnwardBadge: Bool {
        !(hiddenTransferCount > 0 && slotCount >= 3)
    }

    private var slotCount: Int {
        let leading = showsOrigin || (shownTransfers.isEmpty && nextStation != nil) ? 1 : 0
        return leading + shownTransfers.count + (finalStation != nil ? 1 : 0)
    }

    private var connectorCount: Int { max(0, slotCount - 1) }

    private var slotWidth: CGFloat {
        let forSlots = contentWidth - connectorWidth * CGFloat(connectorCount) - countWidth
        return max(56, forSlots / CGFloat(max(1, slotCount)))
    }

    private func nameBudget(badges: Int) -> CGFloat {
        max(24, slotWidth - CGFloat(badges) * (Self.badgeDimension + 7))
    }

    private var contentWidth: CGFloat {
        let children = CGFloat(max(1, 2 * slotCount - 1))
        return availableWidth - 2 * Self.horizontalPadding - (children - 1) * Self.slotSpacing
    }

    private var connectorWidth: CGFloat {
        slotCount > 1 ? max(20, contentWidth * 0.10) : 0
    }

    private var countWidth: CGFloat { hiddenTransferCount > 0 ? 52 : 0 }

    var body: some View {
        Button(action: onTap) {
            row
                .frame(width: availableWidth, height: Self.barHeight)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private struct Stop: Identifiable {
        let id: Int
        let label: LocalizedStringKey
        let station: Station
        let trailing: Station?
        let onwardColor: Color
    }

    private var stops: [Stop] {
        guard viewModel.positionState != nil else { return [] }
        var built: [Stop] = []

        // Boarding stop until it is behind, then the stop ahead — never nothing.
        if let leading = showsOrigin ? originStation : (shownTransfers.isEmpty ? nextStation : nil) {
            built.append(Stop(id: built.count, label: showsOrigin ? "Label.Origin" : "Label.NextStation",
                              station: leading, trailing: nil, onwardColor: lineColor))
        }
        for transfer in shownTransfers {
            built.append(Stop(id: built.count, label: "Label.Transfer", station: transfer.station,
                              trailing: showsOnwardBadge ? onwardStation(for: transfer) : nil,
                              onwardColor: transfer.line?.color ?? lineColor))
        }
        if let finalStation {
            built.append(Stop(id: built.count, label: "Label.Alighting", station: finalStation,
                              trailing: nil, onwardColor: lineColor))
        }
        return built
    }

    private var row: some View {
        HStack(spacing: Self.slotSpacing) {
                if !stops.isEmpty {
                    let last = stops.count - 1
                    ForEach(stops) { stop in
                        if stop.id > 0 {
                            connector(stops[stop.id - 1].onwardColor,
                                      remaining: stop.id == last ? hiddenTransferCount : 0)
                        }
                        slot(stop.label, station: stop.station, trailing: stop.trailing)
                    }
                } else if let journey = viewModel.activeJourney {
                    Circle()
                        .fill(lineColor)
                        .frame(width: 9, height: 9)
                    Text(journey.line.localizedName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                }
        }
        .padding(.horizontal, Self.horizontalPadding)
    }

    /// Soaks up the width the slots' names leave, so the dots meet both ends.
    private func connector(_ color: Color, remaining: Int = 0) -> some View {
        HStack(spacing: 5) {
            rule(color)
            if remaining > 0 {
                Text("Label.RemainingTransfers \(remaining)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .fixedSize()
                rule(color)
            }
        }
        .frame(minWidth: connectorWidth, maxWidth: .infinity)
    }

    private func rule(_ color: Color) -> some View {
        DottedRule()
            .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [0.5, 5]))
            .frame(maxWidth: .infinity)
            .frame(height: 2.5)
    }

    /// A shared station carries a different code on each operator's line.
    private func onwardStation(for transfer: (station: Station, time: Date, line: TrainLine?)) -> Station? {
        guard let line = transfer.line else { return nil }
        let onward = line.stations.first { $0.name == transfer.station.name }
        return onward?.stationCode == transfer.station.stationCode ? nil : onward
    }

    private func slot(
        _ label: LocalizedStringKey, station: Station, trailing: Station? = nil
    ) -> some View {
        let badges = (station.stationCode.isEmpty ? 0 : 1) + (trailing == nil ? 0 : 1)
        let budget = nameBudget(badges: badges)
        return HStack(spacing: 7) {
            if !station.stationCode.isEmpty {
                stationBadge(station, dimension: 24)
            }
            VStack(alignment: .leading, spacing: 0) {
                // At its natural width the caption is what pushes a slot past its share.
                HorizontallySquashed(maxWidth: budget, alignment: .leading) {
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .fixedSize()
                }
                // Squash long Latin names instead of shrinking or truncating.
                HorizontallySquashed(maxWidth: budget, alignment: .leading) {
                    Text(station.localizedName)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                }
            }
            if let trailing, !trailing.stationCode.isEmpty {
                stationBadge(trailing, dimension: 24)
            }
        }
        // Leftover width belongs to the connectors.
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func stationBadge(_ station: Station, dimension: CGFloat) -> some View {
        StationNumberBadge(
            code: station.stationCode,
            color: StaticTrainData.line(containingStationId: station.id)?.trainLine.color ?? lineColor,
            size: .regular,
            stationName: station.name,
            styleOverride: viewModel.activeJourney?.line.badgeStyle
        )
        .scaleEffect(dimension / 28)
        .frame(width: dimension, height: dimension)
    }
}

private struct DottedRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
