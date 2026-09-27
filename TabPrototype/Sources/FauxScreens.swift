import SwiftUI

struct FauxPlannerView: View {
    @ObservedObject var store: PrototypeTabStore
    private let stations = ["Nearest station", "Asakusa", "Ginza", "Kichijoji", "Shibuya", "Shinjuku", "Tokyo", "Yokohama"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Where are you going?").font(.largeTitle.bold())
                    Text("Each tab keeps its own route and results.").foregroundStyle(.secondary)
                }

                VStack(spacing: 0) {
                    stationPicker("From", selection: originBinding, color: .indigo)
                    Divider().padding(.leading, 52)
                    stationPicker("To", selection: destinationBinding, color: .pink)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                HStack(spacing: 10) {
                    Menu {
                        Picker("Departure", selection: departureBinding) {
                            Text("Leave now").tag(0)
                            Text("In 15 minutes").tag(15)
                            Text("In 30 minutes").tag(30)
                        }
                    } label: {
                        Label(departureLabel, systemImage: "clock")
                    }
                    .buttonStyle(.glass)

                    Toggle(isOn: firstTrainBinding) {
                        Label("First train", systemImage: "arrow.backward.to.line")
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.glass)
                }

                Button {
                    withAnimation(.smooth) { store.updateSelected { $0.planner.hasSearched = true } }
                } label: {
                    Label("Search journeys", systemImage: "magnifyingglass")
                        .fontWeight(.bold).frame(maxWidth: .infinity).padding(.vertical, 7)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)

                if store.selectedTab.planner.hasSearched {
                    results
                        .transition(.blurReplace.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(16)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Journey Planner")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggested journeys").font(.headline)
            routeOption(line: "Chuo · Tokaido", symbol: "JC", color: .orange, minutes: 49, transfers: 1)
            routeOption(line: "Inokashira · Toyoko", symbol: "IN", color: .purple, minutes: 54, transfers: 1)
        }
    }

    private func routeOption(line: String, symbol: String, color: Color, minutes: Int, transfers: Int) -> some View {
        Button {
            let draft = store.selectedTab.planner
            let journey = FauxJourney(
                lineName: line,
                lineSymbol: symbol,
                colorHex: color == .orange ? "F15A22" : "8F76D6",
                origin: draft.origin,
                destination: draft.destination,
                stops: [draft.origin, "Shinjuku", "Tokyo", "Shinagawa", draft.destination],
                startedAt: Date(),
                durationMinutes: minutes
            )
            store.updateSelected { $0.page = .journey(journey) }
            store.setActiveJourney(journey)
        } label: {
            HStack(spacing: 12) {
                Text(symbol)
                    .font(.caption.bold()).foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(color, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(line).font(.subheadline.bold())
                    Text("\(transfers) transfer · every 10 minutes")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(minutes) min").font(.headline)
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func stationPicker(_ label: String, selection: Binding<String>, color: Color) -> some View {
        Menu {
            Picker(label, selection: selection) {
                ForEach(stations, id: \.self) { Text($0).tag($0) }
            }
        } label: {
            HStack(spacing: 12) {
                Circle().fill(color).frame(width: 12, height: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption).foregroundStyle(.secondary)
                    Text(selection.wrappedValue).font(.title3.bold())
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .tint(.primary)
    }

    private var originBinding: Binding<String> {
        Binding(get: { store.selectedTab.planner.origin }, set: { value in
            store.updateSelected { $0.planner.origin = value; $0.planner.hasSearched = false }
        })
    }

    private var destinationBinding: Binding<String> {
        Binding(get: { store.selectedTab.planner.destination }, set: { value in
            store.updateSelected { $0.planner.destination = value; $0.planner.hasSearched = false }
        })
    }

    private var departureBinding: Binding<Int> {
        Binding(get: { store.selectedTab.planner.departureOffset }, set: { value in
            store.updateSelected { $0.planner.departureOffset = value }
        })
    }

    private var firstTrainBinding: Binding<Bool> {
        Binding(get: { store.selectedTab.planner.prefersFirstTrain }, set: { value in
            store.updateSelected { $0.planner.prefersFirstTrain = value }
        })
    }

    private var departureLabel: String {
        let offset = store.selectedTab.planner.departureOffset
        return offset == 0 ? "Leave now" : "In \(offset) min"
    }
}

struct FauxSearchView: View {
    @ObservedObject var store: PrototypeTabStore
    @State private var presentedDetail: FauxSearchDetail?

    private var results: [FauxSearchResult] {
        let query = store.selectedTab.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return FauxSearchResult.samples }
        return FauxSearchResult.samples.filter {
            $0.station.localizedCaseInsensitiveContains(query)
                || $0.line.localizedCaseInsensitiveContains(query)
                || $0.operatorName.localizedCaseInsensitiveContains(query)
                || $0.symbol.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section(results.isEmpty ? "No results" : "Stations, lines, and operators") {
                ForEach(results) { result in
                    Menu {
                        Button {
                            searchRoute(to: result)
                        } label: {
                            Label("Route here from nearest station", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        }
                        Button {
                            presentedDetail = .init(kind: .timetable, result: result)
                        } label: {
                            Label("Open station timetable", systemImage: "clock")
                        }
                        Divider()
                        Button {
                            presentedDetail = .init(kind: .line, result: result)
                        } label: {
                            Label("Open \(result.line)", systemImage: "tram.fill")
                        }
                        Button {
                            presentedDetail = .init(kind: .operatorInfo, result: result)
                        } label: {
                            Label("Open \(result.operatorName)", systemImage: "building.2")
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(result.symbol)
                                .font(.caption.bold()).foregroundStyle(.white)
                                .frame(width: 34, height: 34).background(result.color, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.station).font(.body.bold())
                                Text("\(result.line) · \(result.operatorName)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "ellipsis.circle").foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentedDetail) { detail in
            FauxSearchDetailSheet(detail: detail)
        }
    }

    private func searchRoute(to result: FauxSearchResult) {
        store.updateSelected {
            $0.page = .planner
            $0.planner.origin = "Nearest station"
            $0.planner.destination = result.station
            $0.planner.hasSearched = true
        }
    }

}

private struct FauxSearchDetail: Identifiable {
    enum Kind: Equatable {
        case timetable
        case line
        case operatorInfo
    }

    let id = UUID()
    let kind: Kind
    let result: FauxSearchResult
}

private struct FauxSearchDetailSheet: View {
    let detail: FauxSearchDetail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Text(detail.result.symbol)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(detail.result.color, in: Circle())
                        VStack(alignment: .leading) {
                            Text(title).font(.headline)
                            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if detail.kind == .timetable {
                    Section("Next departures") {
                        departure("Local", "2 min")
                        departure("Rapid", "7 min")
                        departure("Local", "12 min")
                    }
                } else {
                    Section("Information") {
                        Label("Service running normally", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Label("Stations and service pattern", systemImage: "map")
                        Label("Official service information", systemImage: "safari")
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var title: String {
        switch detail.kind {
        case .timetable: "\(detail.result.station) timetable"
        case .line: detail.result.line
        case .operatorInfo: detail.result.operatorName
        }
    }

    private var subtitle: String {
        switch detail.kind {
        case .timetable: detail.result.line
        case .line: detail.result.operatorName
        case .operatorInfo: "Railway operator"
        }
    }

    private func departure(_ service: String, _ time: String) -> some View {
        HStack {
            Text(service)
            Spacer()
            Text(time).foregroundStyle(.secondary)
        }
    }
}

struct FauxJourneyView: View {
    let journey: FauxJourney

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let index = journey.currentStopIndex(at: context.date)
            ScrollView {
                VStack(spacing: 18) {
                    lcdCard(at: context.date)
                    VStack(spacing: 0) {
                        ForEach(Array(journey.stops.enumerated()), id: \.offset) { stopIndex, stop in
                            stopRow(stop, index: stopIndex, currentIndex: index)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(journey.lineName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func lcdCard(at date: Date) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text(journey.lineSymbol)
                    .font(.title2.bold()).foregroundStyle(.white)
                    .frame(width: 48, height: 48).background(journey.color, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("FOR").font(.caption2.bold()).foregroundStyle(.secondary)
                    Text(journey.destination).font(.title.bold()).lineLimit(1)
                }
                Spacer()
            }
            ProgressView(value: journey.progress(at: date))
                .tint(journey.color).scaleEffect(y: 1.8)
            HStack {
                Label("Next: \(journey.nextStop(at: date))", systemImage: "tram.fill")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(max(0, journey.durationMinutes - Int(date.timeIntervalSince(journey.startedAt) / 60))) min")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func stopRow(_ stop: String, index: Int, currentIndex: Int) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Rectangle().fill(index == 0 ? .clear : journey.color.opacity(0.45)).frame(width: 4, height: 24)
                Circle()
                    .fill(index <= currentIndex ? journey.color : Color(.systemBackground))
                    .stroke(journey.color, lineWidth: 3)
                    .frame(width: index == currentIndex ? 22 : 16, height: index == currentIndex ? 22 : 16)
                Rectangle().fill(index == journey.stops.count - 1 ? .clear : journey.color.opacity(0.45))
                    .frame(width: 4, height: 24)
            }
            .frame(width: 28)
            Text(stop)
                .font(index == currentIndex ? .title3.bold() : .body)
                .foregroundStyle(index < currentIndex ? .secondary : .primary)
            Spacer()
            if index == currentIndex {
                Text("NOW").font(.caption2.bold()).foregroundStyle(journey.color)
            }
        }
        .frame(minHeight: 64)
    }
}
