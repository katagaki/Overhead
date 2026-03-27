import SwiftUI

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
        .task {
            await viewModel.loadStationTimetable(stationId: station.id)
        }
    }

    // MARK: - Timetable List

    private var timetableList: some View {
        List {
            // Passenger survey badge if available
            if let survey = viewModel.passengerSurveys[station.id] {
                Section {
                    busynessRow(survey: survey)
                }
            }

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
                }
            }
        }
    }

    // MARK: - Departure Row

    @ViewBuilder
    private func departureRow(departure: StationDeparture) -> some View {
        HStack(spacing: 12) {
            // Time
            Text(departure.departureTime)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
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

    // MARK: - Busyness Row

    @ViewBuilder
    private func busynessRow(survey: PassengerSurveyData) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "person.3.fill")
                .foregroundColor(busynessColor(survey.busynessLevel))

            VStack(alignment: .leading, spacing: 2) {
                Text("StationTimetable.Busyness")
                    .font(.system(size: 13, weight: .medium))
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(level <= survey.busynessLevel
                                  ? busynessColor(survey.busynessLevel)
                                  : Color.gray.opacity(0.2))
                            .frame(width: 20, height: 8)
                    }
                }
            }

            Spacer()

            if let journeys = survey.latestJourneys {
                Text(formatJourneys(journeys))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
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

    private func busynessColor(_ level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        default: return .red
        }
    }

    private func formatJourneys(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%dK", count / 1_000)
        }
        return "\(count)"
    }
}
