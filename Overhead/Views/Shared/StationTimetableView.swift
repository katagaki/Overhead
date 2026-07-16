import SwiftUI
import Backbone

// MARK: - Station Timetable View

struct StationTimetableView: View {
    let station: Station
    let line: TrainLine
    var preferredDirectionId: String? = nil
    @ObservedObject var viewModel: JourneyViewModel

    var body: some View {
        Group {
            if viewModel.isLoadingTimetable {
                ProgressView("StationTimetable.Loading")
            } else if viewModel.stationTimetable.isEmpty {
                noDataView
            } else {
                timetableList
            }
        }
        .navigationTitle(station.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadStationTimetable(stationId: station.id)
        }
    }

    // MARK: - Timetable List

    private var timetableList: some View {
        TimelineView(.everyMinute) { context in
            let nowMinutes = railNowMinutes(at: context.date)
            ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.stationTimetable, id: \.railDirection) { timetable in
                        Section {
                            if timetable.departures.isEmpty {
                                Text("StationTimetable.NoMoreTrains")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            } else {
                                ForEach(timetable.departures) { departure in
                                    departureRow(
                                        departure: departure,
                                        isPast: isPast(departure, nowMinutes: nowMinutes)
                                    )
                                    .id(rowId(timetable, departure))
                                }
                            }
                            connectingThroughServiceRows(for: timetable)
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(line.color)
                                Text(timetable.localizedDirectionName)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        } footer: {
                            throughServiceFooter(for: timetable)
                        }
                    }
                }
                .onAppear {
                    scrollToNextDeparture(proxy: proxy)
                }
                .onChange(of: viewModel.stationTimetable.count) {
                    scrollToNextDeparture(proxy: proxy)
                }
            }
        }
    }

    // MARK: - Through Services

    @ViewBuilder
    private func connectingThroughServiceRows(for timetable: StationTimetableData) -> some View {
        ForEach(throughServices(for: timetable), id: \.self) { through in
            if let connecting = connectingLine(for: through) {
                NavigationLink {
                    StationPickerView(line: connecting, viewModel: viewModel)
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 12))
                            .foregroundColor(connecting.color)
                        Text("StationTimetable.ThroughService \(junctionName(for: through)) \(through.localizedLineName) \(through.localizedToward)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func throughServiceFooter(for timetable: StationTimetableData) -> some View {
        let throughs = throughServices(for: timetable).filter { connectingLine(for: $0) == nil }
        if !throughs.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(throughs, id: \.self) { through in
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 10))
                        Text("StationTimetable.ThroughService \(junctionName(for: through)) \(through.localizedLineName) \(through.localizedToward)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private func connectingLine(for through: ThroughService) -> TrainLine? {
        guard let id = through.connectingLineId else { return nil }
        return StaticTrainData.line(withId: id)?.trainLine
    }

    private func throughServices(for timetable: StationTimetableData) -> [ThroughService] {
        guard let staticLine = StaticTrainData.line(withId: line.id),
              let direction = staticLine.directions.first(where: { $0.id == timetable.railDirection })
        else { return [] }

        return staticLine.throughServices.filter {
            ($0.end == .ascending) == direction.isAscending
        }
    }

    private func junctionName(for through: ThroughService) -> String {
        line.stations.first(where: { $0.id == through.junctionStationId })?.localizedName
            ?? through.junctionStationId.components(separatedBy: ".").last
            ?? through.junctionStationId
    }

    // MARK: - Departure Row

    @ViewBuilder
    private func departureRow(departure: StationDeparture, isPast: Bool) -> some View {
        HStack(spacing: 12) {
            Text(departure.departureTime)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(departure.isLast ? .red : .primary)

            Text(departure.trainType.displayNameJa)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(line.color)
                .clipShape(Capsule())

            Spacer()

            if !departure.localizedDestination.isEmpty {
                Text(departure.localizedDestination)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            if departure.isFirst {
                Text("StationTimetable.FirstTrain")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .clipShape(Capsule())
            }

            if departure.isLast {
                Text("StationTimetable.LastTrain")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
        .opacity(isPast ? 0.6 : 1)
    }

    // MARK: - No Data

    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("StationTimetable.NoData")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    /// Before 03:00 the clock reads as 24+ so post-midnight departures compare correctly.
    private func railNowMinutes(at date: Date) -> Int {
        let tz = TimeZone(identifier: "Asia/Tokyo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let comps = cal.dateComponents([.hour, .minute], from: date)
        var nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        if nowMinutes < 180 {
            nowMinutes += 1440
        }
        return nowMinutes
    }

    private func isPast(_ departure: StationDeparture, nowMinutes: Int) -> Bool {
        guard let secs = TimetableEntry.parseRailTime(departure.departureTime) else { return false }
        return secs / 60 < nowMinutes - 1
    }

    private func rowId(_ timetable: StationTimetableData, _ departure: StationDeparture) -> String {
        "\(timetable.railDirection)#\(departure.id)"
    }

    private func scrollToNextDeparture(proxy: ScrollViewProxy) {
        let nowMinutes = railNowMinutes(at: Date())
        let ordered = orderedTimetablesByPreferredDirection()
        for timetable in ordered {
            if let next = timetable.departures.first(where: { !isPast($0, nowMinutes: nowMinutes) }) {
                let target = rowId(timetable, next)
                DispatchQueue.main.async {
                    proxy.scrollTo(target, anchor: .top)
                }
                return
            }
        }
    }

    private func orderedTimetablesByPreferredDirection() -> [StationTimetableData] {
        guard let preferredDirectionId else { return viewModel.stationTimetable }
        guard let preferred = viewModel.stationTimetable.first(where: {
            matchesPreferredDirection($0, preferredDirectionId: preferredDirectionId)
        }) else {
            return viewModel.stationTimetable
        }
        return [preferred] + viewModel.stationTimetable.filter { $0.railDirection != preferred.railDirection }
    }

    /// Matches on the shared `isAscending` axis since the picker merges same-direction options.
    private func matchesPreferredDirection(
        _ timetable: StationTimetableData,
        preferredDirectionId: String
    ) -> Bool {
        if timetable.railDirection == preferredDirectionId { return true }
        guard let staticLine = StaticTrainData.line(withId: line.id),
              let preferred = staticLine.directions.first(where: { $0.id == preferredDirectionId }),
              let sectionDir = staticLine.directions.first(where: { $0.id == timetable.railDirection })
        else { return false }
        return preferred.isAscending == sectionDir.isAscending
    }
}
