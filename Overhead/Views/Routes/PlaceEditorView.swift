import SwiftUI
import Backbone

// MARK: - Place Editor View

struct PlaceEditorView: View {
    let existingPlace: SavedPlace?
    let availableLines: [TrainLine]
    let onSave: (SavedPlace) -> Void

    @State private var kind: SavedPlace.Kind = .home
    @State private var customName: String = ""
    @State private var fromSelection: StationSearchHit?
    @State private var viaSelections: [StationSearchHit] = []
    @State private var toSelection: StationSearchHit?
    @State private var walkingSpeedRaw = WalkingSpeed.normal.rawValue
    @State private var avoidedLineIds: Set<String> = []
    @State private var ignoreTimetable = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                kindCard

                RouteSetupCard(
                    lines: availableLines,
                    fromSelection: $fromSelection,
                    viaSelections: $viaSelections,
                    toSelection: $toSelection,
                    walkingSpeedRaw: $walkingSpeedRaw,
                    avoidedLineIds: $avoidedLineIds,
                    ignoreTimetable: $ignoreTimetable
                )

                if fromSelection != nil, toSelection != nil, !routeAvailable {
                    noRouteNotice
                }

                saveButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(existingPlace == nil ? "Place.NewTitle" : "Place.EditTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if #available(iOS 26.0, *) {
                    Button(role: .close) {
                        dismiss()
                    }
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.secondary)
                    .accessibilityLabel("Button.Close")
                }
            }
        }
        .onAppear(perform: restore)
    }

    // MARK: - Cards

    private var kindCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Place.Kind")
                Spacer()
                Picker("Place.Kind", selection: $kind) {
                    ForEach(SavedPlace.Kind.allCases, id: \.self) { kind in
                        Label(
                            LocalizedStringKey(kind.localizationKey),
                            systemImage: kind.iconName
                        ).tag(kind)
                    }
                }
                .pickerStyle(.menu)
                // Keep the menu's symbols monochrome instead of line-color tinted
                .tint(.primary)
                .labelsHidden()
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 6)

            Divider()
                .padding(.leading, 16)

            TextField("Place.NamePlaceholder", text: $customName)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var noRouteNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
            Text("Setup.NoRoute")
            Spacer(minLength: 0)
        }
        .font(.system(size: 14))
        .foregroundColor(.secondary)
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var saveButton: some View {
        let label = Text("Button.SavePlace")
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

        if #available(iOS 26.0, *) {
            Button {
                save()
            } label: {
                label
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .disabled(!canSave)
        } else {
            Button {
                save()
            } label: {
                label
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(!canSave)
        }
    }

    // MARK: - Validation

    private var waypointNames: [String]? {
        guard let from = fromSelection, let to = toSelection else { return nil }
        return [from.station.name] + viaSelections.map(\.station.name) + [to.station.name]
    }

    /// True when every hop is rideable: one train, 直通, or via transfers.
    private var routeAvailable: Bool {
        guard let names = waypointNames else { return false }
        return zip(names, names.dropFirst()).allSatisfy { from, to in
            from != to
                && (!StaticTrainData.directRoutes(fromStationName: from, toStationName: to,
                                                  avoidingLineIds: avoidedLineIds).isEmpty
                    || StaticTrainData.planTransferRoute(fromStationName: from, toStationName: to,
                                                         avoidingLineIds: avoidedLineIds) != nil)
        }
    }

    private var canSave: Bool {
        if kind == .custom && customName.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        return routeAvailable
    }

    // MARK: - State

    private func restore() {
        guard fromSelection == nil, let existing = existingPlace else { return }
        kind = existing.kind
        customName = existing.customName
        walkingSpeedRaw = existing.walkingSpeedRaw
        avoidedLineIds = Set(existing.avoidedLineIds)
        ignoreTimetable = existing.ignoreTimetable

        let savedLine = availableLines.first(where: { $0.id == existing.lineId })
        if let savedLine,
           let from = savedLine.stations.first(where: { $0.id == existing.fromStationId }) {
            fromSelection = StationSearchHit(line: savedLine, station: from)
        }
        viaSelections = existing.viaStationIds.compactMap(hit(forStationId:))
        toSelection = hit(forStationId: existing.toStationId)
            ?? throughHit(forStationId: existing.toStationId, line: savedLine)
    }

    private func hit(forStationId id: String) -> StationSearchHit? {
        for line in availableLines {
            if let station = line.stations.first(where: { $0.id == id }) {
                return StationSearchHit(line: line, station: station)
            }
        }
        return nil
    }

    /// 直通 destinations aren't on any listed line; borrow the boarding line.
    private func throughHit(forStationId id: String, line: TrainLine?) -> StationSearchHit? {
        guard let line else { return nil }
        for group in StaticTrainData.throughDestinations(
            fromLineId: line.id,
            boardingStationId: fromSelection?.station.id
        ) {
            if let station = group.stations.first(where: { $0.id == id }) {
                return StationSearchHit(line: line, station: station)
            }
        }
        return nil
    }

    private func save() {
        guard let from = fromSelection, let to = toSelection else { return }
        let place = SavedPlace(
            id: existingPlace?.id ?? UUID(),
            kind: kind,
            customName: customName.trimmingCharacters(in: .whitespaces),
            lineId: from.line.id,
            fromStationId: from.station.id,
            toStationId: to.station.id,
            viaStationIds: viaSelections.map(\.station.id),
            walkingSpeedRaw: walkingSpeedRaw,
            avoidedLineIds: avoidedLineIds.sorted(),
            ignoreTimetable: ignoreTimetable
        )
        onSave(place)
        dismiss()
    }
}
