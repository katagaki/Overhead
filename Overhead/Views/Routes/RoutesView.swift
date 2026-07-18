import SwiftUI
import Backbone

// MARK: - Favorites Section (旅程)

struct FavoritesSection: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var places: [SavedPlace] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Section.Favorites")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.secondary)

                Spacer()

                NavigationLink {
                    PlaceEditorView(
                        existingPlace: nil,
                        availableLines: viewModel.availableLines,
                        onSave: { upsert($0) }
                    )
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                }
                .accessibilityLabel("Button.AddPlace")
            }
            .padding(.leading, 4)
            .padding(.trailing, 4)

            if places.isEmpty {
                emptyState
            } else {
                placesList
            }
        }
        .task {
            await viewModel.loadLines()
        }
        .onAppear { places = SavedPlaceStore.load() }
    }

    // MARK: - List

    private var placesList: some View {
        VStack(spacing: 0) {
            ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                if let resolved = resolve(place) {
                    placeRow(place: place, resolved: resolved)
                } else {
                    brokenPlaceRow(place: place)
                }
                if index < places.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    @ViewBuilder
    private func placeRow(
        place: SavedPlace,
        resolved: (line: TrainLine, from: Station, to: Station, isThrough: Bool)
    ) -> some View {
        HStack(spacing: 12) {
            NavigationLink {
                PlaceEditorView(
                    existingPlace: place,
                    availableLines: viewModel.availableLines,
                    onSave: { upsert($0) }
                )
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: place.kind.iconName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(resolved.line.color)
                        .clipShape(RoundedRectangle(cornerRadius: 9))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(displayName(of: place))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: 5) {
                            Text(resolved.from.localizedName)
                            Image(systemName: resolved.isThrough ? "arrow.triangle.branch" : "arrow.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                            Text(resolved.to.localizedName)
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                        Text(resolved.line.localizedName)
                            .font(.system(size: 12))
                            .foregroundColor(resolved.line.color)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                Task {
                    await viewModel.startJourney(
                        line: resolved.line,
                        from: resolved.from,
                        to: resolved.to
                    )
                }
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(resolved.line.color)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Button.StartJourney")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contextMenu {
            deleteButton(for: place)
        }
    }

    @ViewBuilder
    private func brokenPlaceRow(place: SavedPlace) -> some View {
        HStack(spacing: 14) {
            Image(systemName: place.kind.iconName)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName(of: place))
                    .font(.system(size: 16, weight: .semibold))
                Text("Place.Unresolvable")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contextMenu {
            deleteButton(for: place)
        }
    }

    private func deleteButton(for place: SavedPlace) -> some View {
        Button(role: .destructive) {
            places.removeAll { $0.id == place.id }
            SavedPlaceStore.save(places)
        } label: {
            Label("Button.DeletePlace", systemImage: "trash")
        }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Place.EmptyTitle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                Text("Place.EmptyDescription")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // MARK: - Helpers

    private func displayName(of place: SavedPlace) -> String {
        if !place.customName.isEmpty {
            return place.customName
        }
        return String(localized: String.LocalizationValue(place.kind.localizationKey))
    }

    private func resolve(_ place: SavedPlace) -> (line: TrainLine, from: Station, to: Station, isThrough: Bool)? {
        guard let line = viewModel.availableLines.first(where: { $0.id == place.lineId }),
              let from = line.stations.first(where: { $0.id == place.fromStationId })
        else { return nil }

        if let to = line.stations.first(where: { $0.id == place.toStationId }) {
            return (line, from, to, false)
        }

        for group in StaticTrainData.throughDestinations(fromLineId: line.id, boardingStationId: from.id) {
            if let to = group.stations.first(where: { $0.id == place.toStationId }) {
                return (line, from, to, true)
            }
        }
        return nil
    }

    private func upsert(_ place: SavedPlace) {
        if let idx = places.firstIndex(where: { $0.id == place.id }) {
            places[idx] = place
        } else {
            places.append(place)
        }
        SavedPlaceStore.save(places)
    }
}
