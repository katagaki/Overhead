import SwiftUI
import Backbone

// MARK: - Station Search

struct StationSearchHit: Identifiable {
    let line: TrainLine
    let station: Station

    var id: String { "\(line.id)|\(station.id)" }
}

enum StationSearch {

    static func search(lines: [TrainLine], query: String) -> [StationSearchHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lowered = trimmed.lowercased()

        var hits: [StationSearchHit] = []
        for line in lines {
            for station in line.stations {
                if station.name.contains(trimmed)
                    || station.nameEn.lowercased().contains(lowered)
                    || station.localizedName.lowercased().contains(lowered)
                    || (!station.stationCode.isEmpty && station.stationCode.lowercased().hasPrefix(lowered)) {
                    hits.append(StationSearchHit(line: line, station: station))
                }
            }
        }

        func rank(_ hit: StationSearchHit) -> Int {
            if hit.station.name == trimmed || hit.station.nameEn.lowercased() == lowered {
                return 0
            }
            if hit.station.name.hasPrefix(trimmed) || hit.station.nameEn.lowercased().hasPrefix(lowered) {
                return 1
            }
            return 2
        }

        return hits.sorted {
            let l = rank($0)
            let r = rank($1)
            if l != r { return l < r }
            if $0.station.name != $1.station.name { return $0.station.name < $1.station.name }
            return $0.line.nameEn < $1.line.nameEn
        }
    }
}

// MARK: - Station Picker

struct StationPickerView: View {
    let line: TrainLine
    @ObservedObject var viewModel: JourneyViewModel
    @State private var selectedDirectionIndex = 0
    @State private var statusOwner = UUID()
    @Environment(\.serviceStatusPresenter) private var serviceStatusPresenter

    private let trackWidth: CGFloat = 4
    private let dotColumnWidth: CGFloat = 24
    private let cardPadding: CGFloat = 16

    private var staticLine: StaticTrainLine? {
        StaticTrainData.line(withId: line.id)
    }

    private var directionOptions: [StaticLineDirection] {
        guard let staticLine else { return [] }
        var seenAscending = Set<Bool>()
        return staticLine.directions.filter { seenAscending.insert($0.isAscending).inserted }
    }

    private var selectedDirection: StaticLineDirection? {
        guard !directionOptions.isEmpty else { return nil }
        return directionOptions[min(selectedDirectionIndex, directionOptions.count - 1)]
    }

    private var orderedStations: [Station] {
        guard let direction = selectedDirection, !direction.isAscending else {
            return line.stations
        }
        return line.stations.reversed()
    }

    private var throughServicesForDirection: [ThroughService] {
        guard let staticLine, let direction = selectedDirection else { return [] }
        return staticLine.throughServices.filter {
            ($0.end == .ascending) == direction.isAscending
        }
    }

    private func connectingLine(for through: ThroughService) -> TrainLine? {
        guard let id = through.connectingLineId else { return nil }
        return StaticTrainData.line(withId: id)?.trainLine
    }

    private func junctionName(for through: ThroughService) -> String {
        line.stations.first(where: { $0.id == through.junctionStationId })?.localizedName
            ?? through.junctionStationId.components(separatedBy: ".").last
            ?? through.junctionStationId
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                stationsHeader

                stationsCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .contentMargins(.bottom, ServiceStatusSheet.peekHeight + 12, for: .scrollContent)
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top) {
            if directionOptions.count > 1 {
                directionPicker
                    .padding(12)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .onAppear {
            serviceStatusPresenter?.activate(
                owner: statusOwner,
                lineId: line.id,
                delayInfo: viewModel.delayCheckInfo(for: line.id)
            )
        }
        .onDisappear {
            serviceStatusPresenter?.deactivate(owner: statusOwner)
        }
        .navigationTitle(line.localizedName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Direction Picker

    private var directionPicker: some View {
        Picker("Label.Direction", selection: $selectedDirectionIndex) {
            ForEach(Array(directionOptions.enumerated()), id: \.offset) { index, direction in
                Text(shortDirectionName(of: direction)).tag(index)
            }
        }
        .pickerStyle(.segmented)
    }

    private func shortDirectionName(of direction: StaticLineDirection) -> String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        if lang == "ja" {
            return direction.nameJa.components(separatedBy: "（")[0]
        }
        let name = direction.nameEn.isEmpty ? direction.nameJa : direction.nameEn
        return name.components(separatedBy: " (")[0]
    }

    private func fullDirectionName(of direction: StaticLineDirection) -> String {
        let lang = Locale.current.language.languageCode?.identifier ?? "ja"
        if lang == "ja" || direction.nameEn.isEmpty {
            return direction.nameJa
        }
        return direction.nameEn
    }

    @ViewBuilder
    private var stationsHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(line.color)
            if let direction = selectedDirection {
                Text(fullDirectionName(of: direction))
                    .font(.system(size: 14, weight: .semibold))
            } else {
                Text("Section.Stations")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .foregroundColor(.secondary)
        .padding(.leading, 4)
    }

    // MARK: - Stations Card (train map)

    private var stationsCard: some View {
        TimelineView(.everyMinute) { context in
            let stations = orderedStations
            let nextArrivals = nextArrivalsByStation(at: context.date)
            let branches = throughServicesForDirection

            VStack(spacing: 0) {
                ForEach(Array(stations.enumerated()), id: \.element.id) { index, station in
                    NavigationLink {
                        StationTimetableView(
                            station: station,
                            line: line,
                            preferredDirectionId: selectedDirection?.id,
                            viewModel: viewModel
                        )
                    } label: {
                        stationMapRow(
                            station: station,
                            isFirst: index == 0,
                            isLast: index == stations.count - 1,
                            continuesBelow: index == stations.count - 1 && !branches.isEmpty,
                            next: nextArrivals[station.id]
                        )
                    }
                    .buttonStyle(.plain)
                }
                ForEach(Array(branches.enumerated()), id: \.offset) { index, through in
                    throughBranchRow(through: through, isLast: index == branches.count - 1)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    // MARK: - Station Row

    @ViewBuilder
    private func stationMapRow(station: Station, isFirst: Bool, isLast: Bool, continuesBelow: Bool = false, next: NextArrival?) -> some View {
        HStack(spacing: 12) {
            stationDot(isTerminal: isFirst || isLast)
                .frame(width: dotColumnWidth)

            if !station.stationCode.isEmpty {
                StationNumberBadge(
                    code: station.stationCode,
                    color: line.color,
                    size: .compact,
                    stationName: station.name,
                    styleOverride: line.badgeStyle
                )
            } else if !line.lineSymbol.isEmpty {
                LineSymbolBadge(
                    symbol: line.lineSymbol,
                    color: line.color,
                    styleOverride: line.badgeStyle
                )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(station.localizedName)
                    .font(.system(size: 16, weight: isFirst || isLast ? .bold : .medium))
                    .foregroundColor(.primary)
            }

            Spacer(minLength: 8)

            nextArrivalView(next)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, cardPadding)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .background(alignment: .leading) {
            trackSegment(isFirst: isFirst, isLast: isLast && !continuesBelow)
        }
    }

    @ViewBuilder
    private func trackSegment(isFirst: Bool, isLast: Bool) -> some View {
        GeometryReader { geo in
            let top = isFirst ? geo.size.height / 2 : 0
            let bottom = isLast ? geo.size.height / 2 : 0
            Rectangle()
                .fill(line.color)
                .frame(width: trackWidth, height: max(0, geo.size.height - top - bottom))
                .offset(x: cardPadding + (dotColumnWidth - trackWidth) / 2, y: top)
        }
    }

    @ViewBuilder
    private func stationDot(isTerminal: Bool) -> some View {
        let diameter: CGFloat = isTerminal ? 18 : 13
        ZStack {
            Circle()
                .fill(Color(.secondarySystemGroupedBackground))
            Circle()
                .strokeBorder(line.color, lineWidth: isTerminal ? 4 : 3)
        }
        .frame(width: diameter, height: diameter)
    }

    // MARK: - Through-Service Branch Row

    @ViewBuilder
    private func throughBranchRow(through: ThroughService, isLast: Bool) -> some View {
        if let connecting = connectingLine(for: through) {
            NavigationLink {
                StationPickerView(line: connecting, viewModel: viewModel)
            } label: {
                throughBranchLabel(through: through, isLast: isLast, navigable: true)
            }
            .buttonStyle(.plain)
        } else {
            throughBranchLabel(through: through, isLast: isLast, navigable: false)
        }
    }

    @ViewBuilder
    private func throughBranchLabel(
        through: ThroughService, isLast: Bool, navigable: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Text("StationTimetable.ThroughService \(junctionName(for: through)) \(through.localizedLineName) \(through.localizedToward)")
                .padding(.leading, dotColumnWidth + 12)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            if navigable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.horizontal, cardPadding)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .background(alignment: .leading) {
            GeometryReader { geo in
                Rectangle()
                    .fill(line.color)
                    .frame(width: trackWidth, height: isLast ? geo.size.height / 2 : geo.size.height)
                    .offset(x: cardPadding + (dotColumnWidth - trackWidth) / 2, y: 0)
            }
        }
    }

    // MARK: - Next Arriving Train

    private struct NextArrival {
        let time: String
        let trainType: TrainService.TrainType
        let minutes: Int
        let isFirstTrain: Bool
    }

    @ViewBuilder
    private func nextArrivalView(_ next: NextArrival?) -> some View {
        if let next {
            VStack(alignment: .trailing, spacing: 3) {
                Text(next.time)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                HStack(spacing: 4) {
                    if next.isFirstTrain {
                        Text("StationTimetable.FirstTrain")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    Text(next.trainType.displayNameJa)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(line.color)
                        .clipShape(Capsule())
                }
            }
        } else {
            Text(verbatim: "–")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color(.tertiaryLabel))
        }
    }

    private func nextArrivalsByStation(at now: Date) -> [String: NextArrival] {
        guard let staticLine, let direction = selectedDirection else { return [:] }

        let calendar = ScheduleCalendar.current(at: now.addingTimeInterval(-3 * 3600))
        var jst = Calendar(identifier: .gregorian)
        jst.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let comps = jst.dateComponents([.hour, .minute], from: now)
        var nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        if nowMinutes < 3 * 60 {
            nowMinutes += 24 * 60
        }

        let services = StaticTimetableGenerator.services(for: staticLine, calendar: calendar)
            .filter { ($0.direction == .outbound) == direction.isAscending }

        var best: [String: NextArrival] = [:]
        for service in services {
            let serviceOrigin = service.timetable.first?.stationId
            for entry in service.timetable {
                guard let timeStr = entry.arrivalTime ?? entry.departureTime,
                      let secs = TimetableEntry.parseRailTime(timeStr) else { continue }
                let minutes = secs / 60
                guard minutes >= nowMinutes else { continue }
                if let current = best[entry.stationId], current.minutes <= minutes { continue }
                best[entry.stationId] = NextArrival(
                    time: timeStr,
                    trainType: service.trainType,
                    minutes: minutes,
                    isFirstTrain: entry.stationId == serviceOrigin
                )
            }
        }

        let tomorrow = ScheduleCalendar.current(at: now.addingTimeInterval(21 * 3600))
        var tomorrowFirst: [String: NextArrival] = [:]
        let tomorrowServices = tomorrow == calendar
            ? services
            : StaticTimetableGenerator.services(for: staticLine, calendar: tomorrow)
                .filter { ($0.direction == .outbound) == direction.isAscending }
        for service in tomorrowServices {
            let serviceOrigin = service.timetable.first?.stationId
            for entry in service.timetable {
                guard best[entry.stationId] == nil,
                      let timeStr = entry.arrivalTime ?? entry.departureTime,
                      let secs = TimetableEntry.parseRailTime(timeStr) else { continue }
                let minutes = secs / 60
                if let current = tomorrowFirst[entry.stationId], current.minutes <= minutes { continue }
                tomorrowFirst[entry.stationId] = NextArrival(
                    time: timeStr,
                    trainType: service.trainType,
                    minutes: minutes,
                    isFirstTrain: entry.stationId == serviceOrigin
                )
            }
        }
        return best.merging(tomorrowFirst) { current, _ in current }
    }
}
