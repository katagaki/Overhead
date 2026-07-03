import SwiftUI
import Backbone

// MARK: - Station Timetable View
/// Shows upcoming departures from a station, grouped by direction.

struct StationTimetableView: View {
    let station: Station
    let line: TrainLine
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
        .onAppear {
            viewModel.loadStationTimetable(stationId: station.id)
        }
    }

    // MARK: - Timetable List

    private var timetableList: some View {
        List {
            ForEach(viewModel.stationTimetable, id: \.railDirection) { timetable in
                Section {
                    // Show upcoming departures (from now onwards, limited)
                    let upcoming = upcomingDepartures(from: timetable.departures)
                    if upcoming.isEmpty {
                        Text("StationTimetable.NoMoreTrains")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    } else {
                        ForEach(upcoming) { departure in
                            departureRow(departure: departure)
                        }
                    }
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

            if let delayInfo = viewModel.delayCheckInfo(for: line.id) {
                serviceStatusSection(delayInfo: delayInfo)
            }
        }
    }

    // MARK: - Through Services

    @ViewBuilder
    private func throughServiceFooter(for timetable: StationTimetableData) -> some View {
        let throughs = throughServices(for: timetable)
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

    // MARK: - Service Status

    @ViewBuilder
    private func serviceStatusSection(delayInfo: DelayCheckInfo) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(delayInfo.localizedCheckMethod)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                if let url = URL(string: delayInfo.localizedStatusPageURL) {
                    Link(destination: url) {
                        Label("StationTimetable.ServiceStatus.Open", systemImage: "arrow.up.right.square")
                            .font(.system(size: 13, weight: .medium))
                    }
                }

                if let account = delayInfo.xAccount {
                    HStack(spacing: 4) {
                        Image(systemName: "at")
                            .font(.system(size: 11))
                        Text(account)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 2)
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("StationTimetable.ServiceStatus")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
    }

    // MARK: - Departure Row

    @ViewBuilder
    private func departureRow(departure: StationDeparture) -> some View {
        HStack(spacing: 12) {
            // Time
            Text(departure.departureTime)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(departure.isLast ? .red : .primary)

            // Train type pill
            Text(departure.trainType.displayNameJa)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(line.color)
                .clipShape(Capsule())

            Spacer()

            // Destination
            if !departure.localizedDestination.isEmpty {
                Text(departure.localizedDestination)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            // Last train badge
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

    private func upcomingDepartures(from departures: [StationDeparture]) -> [StationDeparture] {
        let tz = TimeZone(identifier: "Asia/Tokyo")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let comps = cal.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        let upcoming = departures.filter { dep in
            guard let secs = TimetableEntry.parseRailTime(dep.departureTime) else { return false }
            return secs / 60 >= nowMinutes - 1
        }

        return Array(upcoming.prefix(20))
    }
}
