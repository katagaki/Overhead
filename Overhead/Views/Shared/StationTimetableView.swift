import SwiftUI
import Backbone

// MARK: - Station Timetable View

struct StationTimetableView: View {
    let station: Station
    let line: TrainLine
    var preferredDirectionId: String? = nil
    @ObservedObject var viewModel: JourneyViewModel

    @State private var selectedDirection: String?
    @State private var detailDeparture: StationDeparture?
    @State private var statusTarget: ServiceStatusTarget?

    var body: some View {
        Group {
            if viewModel.isLoadingTimetable {
                ProgressView("StationTimetable.Loading")
            } else if viewModel.stationTimetable.isEmpty {
                noDataView
            } else {
                timetableContent
            }
        }
        .navigationTitle(station.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .serviceStatusToolbar(
            target: $statusTarget,
            lineId: line.id,
            delayInfo: viewModel.delayCheckInfo(for: line.id)
        )
        .onAppear {
            viewModel.loadStationTimetable(stationId: station.id)
        }
    }

    // MARK: - Content

    private var currentTimetable: StationTimetableData? {
        let timetables = viewModel.stationTimetable
        if let selectedDirection,
           let match = timetables.first(where: { $0.railDirection == selectedDirection }) {
            return match
        }
        if let preferredDirectionId,
           let match = timetables.first(where: {
               matchesPreferredDirection($0, preferredDirectionId: preferredDirectionId)
           }) {
            return match
        }
        return timetables.first
    }

    private var timetableContent: some View {
        TimelineView(.everyMinute) { context in
            let nowMinutes = railNowMinutes(at: context.date)
            Group {
                if let timetable = currentTimetable {
                    let visible = visibleDepartures(timetable)
                    if visible.isEmpty {
                        VStack {
                            Spacer()
                            Text("StationTimetable.NoMoreTrains")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            Spacer()
                        }
                    } else {
                        minuteGrid(visible, nowMinutes: nowMinutes, timetable: timetable)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                header(nowMinutes: nowMinutes)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    private func header(nowMinutes: Int) -> some View {
        VStack(spacing: 10) {
            if viewModel.stationTimetable.count > 1 {
                directionPicker
                    .glassEffect(.regular, in: .capsule)
            }
            if let timetable = currentTimetable {
                DepartureBoardView(
                    departures: upcomingDepartures(in: visibleDepartures(timetable), nowMinutes: nowMinutes),
                    nowMinutes: nowMinutes,
                    typeColor: boardTypeColor,
                    noticeText: boardNotice(for: timetable)
                )
                // The LED panel is always dark regardless of system appearance.
                .environment(\.colorScheme, .dark)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var directionPicker: some View {
        Picker("StationTimetable.Direction", selection: directionBinding) {
            ForEach(viewModel.stationTimetable, id: \.railDirection) { timetable in
                Text(timetable.localizedDirectionName)
                    .tag(timetable.railDirection)
            }
        }
        .pickerStyle(.segmented)
    }

    private var directionBinding: Binding<String> {
        Binding(
            get: { currentTimetable?.railDirection ?? "" },
            set: { selectedDirection = $0 }
        )
    }

    private func visibleDepartures(_ timetable: StationTimetableData) -> [StationDeparture] {
#if DEBUG
        // Screenshot harness: staged shots hide departed trains.
        return ScreenshotStaging.shared.hidePastDepartures
            ? timetable.departures.filter { !isPast($0, nowMinutes: railNowMinutes(at: Date())) }
            : timetable.departures
#else
        return timetable.departures
#endif
    }

    private func upcomingDepartures(in departures: [StationDeparture], nowMinutes: Int) -> [StationDeparture] {
        Array(departures.filter { !isPast($0, nowMinutes: nowMinutes) }.prefix(2))
    }

    // MARK: - Minute Grid

    private struct HourRow: Identifiable {
        let hour: Int
        let departures: [StationDeparture]
        var id: Int { hour }
    }

    private func hourRows(_ departures: [StationDeparture]) -> [HourRow] {
        var byHour: [Int: [StationDeparture]] = [:]
        for departure in departures {
            guard let minutes = TimetableEntry.railMinutes(departure.departureTime) else { continue }
            byHour[minutes / 60, default: []].append(departure)
        }
        return byHour.keys.sorted().map { HourRow(hour: $0, departures: byHour[$0]!) }
    }

    /// Most frequent destination goes unannotated; others get a superscript initial.
    private func primaryDestination(_ departures: [StationDeparture]) -> String {
        var counts: [String: Int] = [:]
        for departure in departures {
            counts[departure.localizedDestination, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? ""
    }

    /// The line's base service type stays unmarked; only exceptions get color.
    private func primaryType(_ departures: [StationDeparture]) -> TrainService.TrainType {
        var counts: [TrainService.TrainType: Int] = [:]
        for departure in departures {
            counts[departure.trainType, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? .local
    }

    private func minuteGrid(
        _ departures: [StationDeparture],
        nowMinutes: Int,
        timetable: StationTimetableData
    ) -> some View {
        let rows = hourRows(departures)
        let primaryDest = primaryDestination(departures)
        let baseType = primaryType(departures)
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            gridRow(
                                row,
                                nowHour: nowMinutes / 60,
                                nowMinutes: nowMinutes,
                                primaryDest: primaryDest,
                                baseType: baseType
                            )
                            .id(row.hour)
                            if row.hour != rows.last?.hour {
                                Divider().padding(.leading, 40)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    throughServiceLinks(for: timetable)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .onAppear {
                scrollToCurrentHour(proxy: proxy, rows: rows, nowMinutes: nowMinutes)
            }
            // The grid first renders stale data on push, so rescroll on change.
            .onChange(of: "\(timetable.stationId)|\(timetable.railDirection)") {
                scrollToCurrentHour(proxy: proxy, rows: rows, nowMinutes: nowMinutes)
            }
        }
    }

    private func scrollToCurrentHour(proxy: ScrollViewProxy, rows: [HourRow], nowMinutes: Int) {
        guard let target = rows.first(where: { $0.hour >= nowMinutes / 60 })?.hour else { return }
        // Async so layout exists; slightly below the top so the previous hour peeks through.
        DispatchQueue.main.async {
            proxy.scrollTo(target, anchor: UnitPoint(x: 0, y: 0.055))
        }
    }

    private func gridRow(
        _ row: HourRow,
        nowHour: Int,
        nowMinutes: Int,
        primaryDest: String,
        baseType: TrainService.TrainType
    ) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text("\(row.hour % 24)")
                .font(.system(size: 17, weight: .bold))
                .monospacedDigit()
                .foregroundColor(.white)
                .padding(.top, 8)
                .frame(width: 38)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(row.hour == nowHour ? line.color.mix(with: .black, by: 0.25) : line.color)
            let rowHasAnnotations = row.departures.contains {
                $0.isFirst || $0.localizedDestination != primaryDest
            }
            FlowLayout(spacing: 2, lineSpacing: 8) {
                ForEach(row.departures) { departure in
                    minuteCell(
                        departure,
                        isPast: isPast(departure, nowMinutes: nowMinutes),
                        primaryDest: primaryDest,
                        baseType: baseType,
                        showAnnotationLine: rowHasAnnotations
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(row.hour == nowHour ? line.color.opacity(0.08) : .clear)
    }

    private func minuteCell(
        _ departure: StationDeparture,
        isPast: Bool,
        primaryDest: String,
        baseType: TrainService.TrainType,
        showAnnotationLine: Bool
    ) -> some View {
        let minute = departure.departureTime.components(separatedBy: ":").last ?? ""
        let annotation = departure.localizedDestination != primaryDest
            // Latin names need two letters to read; a single CJK glyph is enough.
            ? String(departure.localizedDestination.prefix(
                departure.localizedDestination.first?.isASCII == true ? 2 : 1)) : ""
        return Button {
            detailDeparture = departure
        } label: {
            VStack(spacing: 0) {
                Text(minute)
                    .font(.system(size: 17, weight: minuteWeight(departure, baseType: baseType)))
                    .monospacedDigit()
                    .foregroundColor(minuteColor(departure, isPast: isPast, baseType: baseType))
                // Unmarked rows skip the annotation line to stay symmetric.
                if showAnnotationLine {
                    (Text(departure.isFirst ? "StationTimetable.FirstMark" : "").foregroundColor(.green)
                        + Text(annotation.isEmpty && !departure.isFirst ? " " : annotation).foregroundColor(.gray))
                        .font(.system(size: 9, weight: .bold))
                        .opacity(isPast ? 0.4 : 1)
                }
            }
            .frame(minWidth: 30)
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: Binding(
                get: { detailDeparture?.id == departure.id },
                set: { if !$0 { detailDeparture = nil } }
            )
        ) {
            departureDetail(departure)
        }
    }

    private func minuteWeight(_ departure: StationDeparture, baseType: TrainService.TrainType) -> Font.Weight {
        departure.trainType != baseType ? .heavy : .semibold
    }

    private func minuteColor(
        _ departure: StationDeparture,
        isPast: Bool,
        baseType: TrainService.TrainType
    ) -> Color {
        let base: Color = departure.trainType != baseType ? gridTypeColor(departure.trainType) : .primary
        return isPast ? base.opacity(0.35) : base
    }

    /// Skip-stop tiers: rapid family red, express family orange, liner/limited purple.
    private func gridTypeColor(_ type: TrainService.TrainType) -> Color {
        switch type {
        case .local:
            return .blue
        case .rapid, .sectionRapid, .commuterRapid, .specialRapid:
            return .red
        case .semiExpress, .sectionSemiExpress, .commuterSemiExpress,
             .express, .sectionExpress, .rapidExpress, .commuterExpress:
            return .orange
        case .liner, .rapidLimitedExpress, .limitedExpress, .commuterLimitedExpress:
            return .purple
        @unknown default:
            return .primary
        }
    }

    private func boardTypeColor(_ type: TrainService.TrainType) -> Color {
        type.skipsStations ? gridTypeColor(type) : .green
    }


    // MARK: - Departure Detail

    private func departureDetail(_ departure: StationDeparture) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(departure.departureTime)
                    .font(.system(size: 32, weight: .bold))
                    .monospacedDigit()
                Text("StationTimetable.DepartureSuffix")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 8) {
                Text(departure.trainType.localizedDisplayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(departure.trainType.skipsStations ? gridTypeColor(departure.trainType) : line.color)
                    .clipShape(Capsule())
                if !departure.localizedDestination.isEmpty {
                    Text("\(departure.localizedDestination) 行")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                departureStatusLabel(departure)
                if departure.isFirst {
                    Label("StationTimetable.StartsHere",
                          systemImage: "arrow.up.forward.circle.fill")
                        .foregroundStyle(.green)
                }
                if departure.isLast {
                    Label("StationTimetable.LastTrain",
                          systemImage: "moon.circle.fill")
                        .foregroundStyle(.red)
                }
                if !departure.trainNumber.isEmpty {
                    Label(departure.trainNumber, systemImage: "number.circle")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 13, weight: .medium))
        }
        .padding(16)
        .presentationCompactAdaptation(.popover)
    }

    @ViewBuilder
    private func departureStatusLabel(_ departure: StationDeparture) -> some View {
        if let secs = TimetableEntry.parseRailTime(departure.departureTime) {
            let remaining = TimetableEntry.railMinutes(fromMinutes: secs / 60) - railNowMinutes(at: Date())
            if remaining <= 0 {
                Label("StationTimetable.Departed", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            } else if remaining == 1 {
                Label("StationTimetable.DepartingSoon", systemImage: "clock.fill")
                    .foregroundStyle(.orange)
            } else if remaining < 120 {
                Label("StationTimetable.DepartsIn \(remaining)",
                      systemImage: "clock.fill")
                    .foregroundStyle(.green)
            } else {
                Label("StationTimetable.DepartsInHours \(remaining / 60) \(remaining % 60)",
                      systemImage: "clock")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func detailTag(_ key: LocalizedStringKey, color: Color) -> some View {
        Text(key)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }

    // MARK: - Through Services

    private func boardNotice(for timetable: StationTimetableData) -> String? {
        let throughs = throughServices(for: timetable)
        guard !throughs.isEmpty else { return nil }
        return throughs.map {
            String(localized: "Board.ThroughNotice \(junctionName(for: $0)) \($0.localizedLineName) \($0.localizedToward)")
        }.joined(separator: "  ")
    }

    @ViewBuilder
    private func throughServiceLinks(for timetable: StationTimetableData) -> some View {
        let throughs = throughServices(for: timetable)
        if !throughs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(throughs, id: \.self) { through in
                    if let connecting = connectingLine(for: through) {
                        NavigationLink {
                            StationPickerView(line: connecting, viewModel: viewModel)
                        } label: {
                            throughServiceLabel(through, color: connecting.color)
                        }
                    } else {
                        throughServiceLabel(through, color: .secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func throughServiceLabel(_ through: ThroughService, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 12))
                .foregroundColor(color)
            Text("StationTimetable.ThroughService \(junctionName(for: through)) \(through.localizedLineName) \(through.localizedToward)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
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
        let nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        return TimetableEntry.railMinutes(fromMinutes: nowMinutes)
    }

    private func isPast(_ departure: StationDeparture, nowMinutes: Int) -> Bool {
        guard let minutes = TimetableEntry.railMinutes(departure.departureTime) else { return false }
        // On the departure minute the train has already left.
        return minutes <= nowMinutes
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

// MARK: - Departure Board

private struct DepartureBoardView: View {
    let departures: [StationDeparture]
    let nowMinutes: Int
    let typeColor: (TrainService.TrainType) -> Color
    let noticeText: String?

    private let boardBackground = Color(red: 0.024, green: 0.031, blue: 0.039)
    private let amber = Color(red: 1.0, green: 0.71, blue: 0.16)
    private let ledGreen = Color(red: 0.22, green: 0.88, blue: 0.43)

    var body: some View {
        VStack(spacing: 0) {
            // Rows keep the panel inset; the marquee below runs edge to edge.
            VStack(spacing: 0) {
                header
                if departures.isEmpty {
                    Text("Board.NoDepartures")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ledGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                } else {
                    ForEach(Array(departures.enumerated()), id: \.element.id) { index, departure in
                        boardRow(departure, ordinal: ordinalName(index))
                        if index == 0 && departures.count > 1 {
                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            if let noticeText {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                BoardMarquee(text: noticeText, color: amber)
                    .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 6)
        .background(boardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(6)
        .glassEffect(
            .regular.tint(Color(red: 0.2, green: 0.26, blue: 0.33).opacity(0.4)),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private func ordinalName(_ index: Int) -> String {
        String(localized: index == 0 ? "Board.Ordinal.First" : "Board.Ordinal.Second")
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("").frame(width: 36)
            Text("Board.Header.Type").frame(width: 78, alignment: .leading)
            Text("Board.Header.Time").frame(width: 56, alignment: .leading)
            Text("Board.Header.Destination").frame(maxWidth: .infinity, alignment: .leading)
            Text("Board.Header.Countdown").frame(width: 56, alignment: .trailing)
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(Color(white: 0.55))
        .padding(.vertical, 3)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
        }
    }

    private func boardRow(_ departure: StationDeparture, ordinal: String) -> some View {
        HStack(spacing: 6) {
            Text(ordinal)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36)
            typeLabel(departure.trainType)
                .frame(width: 78)
            Text(departure.departureTime)
                .font(.system(size: 17, weight: .bold))
                .monospacedDigit()
                .foregroundColor(amber)
                .frame(width: 56)
            Text(departure.localizedDestination)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(countdownText(departure))
                .font(.system(size: 17, weight: .bold))
                .monospacedDigit()
                .foregroundColor(ledGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.vertical, 7)
    }

    @ViewBuilder
    private func typeLabel(_ type: TrainService.TrainType) -> some View {
        let color = typeColor(type)
        if type.skipsStations {
            Text(spacedTypeName(type))
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(boardBackground)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.vertical, 2)
                .frame(width: 78)
                .background(color, in: RoundedRectangle(cornerRadius: 2))
        } else {
            Text(type.localizedDisplayName)
                .font(.system(size: 17, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(color)
        }
    }

    /// Japanese two-character types get the traditional full-width spacing (快　速).
    private func spacedTypeName(_ type: TrainService.TrainType) -> String {
        let name = type.localizedDisplayName
        let isCJK = !name.contains { $0.isASCII }
        return name.count == 2 && isCJK ? name.map(String.init).joined(separator: "　") : name
    }

    private func countdownText(_ departure: StationDeparture) -> String {
        guard let minutes = TimetableEntry.railMinutes(departure.departureTime) else { return "" }
        let remaining = minutes - nowMinutes
        return remaining <= 1
            ? String(localized: "Board.Countdown.Soon")
            : String(localized: "Board.Countdown.Minutes \(remaining)")
    }
}

// MARK: - Board Marquee

private struct BoardMarquee: View {
    let text: String
    let color: Color

    @State private var textWidth: CGFloat = 0
    @State private var startDate: Date?

    private let speed: CGFloat = 60

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                marqueeText
                    .offset(x: offsetX(at: context.date, containerWidth: geo.size.width))
                    .opacity(textWidth > 0 ? 1 : 0)
            }
        }
        .frame(height: 18)
        .clipped()
    }

    private var marqueeText: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(color)
            .lineLimit(1)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                guard width > 0, width != textWidth else { return }
                textWidth = width
                startDate = Date()
            }
    }

    /// Clock-driven; a state animation can coalesce and start mid-panel.
    private func offsetX(at date: Date, containerWidth: CGFloat) -> CGFloat {
        guard textWidth > 0, let startDate else { return containerWidth }
        let distance = containerWidth + textWidth
        let period = Double(distance / speed)
        let phase = date.timeIntervalSince(startDate).truncatingRemainder(dividingBy: period)
        return containerWidth - CGFloat(phase) * speed
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 2
    var lineSpacing: CGFloat = 2

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
