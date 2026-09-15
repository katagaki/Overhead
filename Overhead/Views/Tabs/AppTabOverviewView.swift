import SwiftUI
import Backbone

struct AppTabOverviewView: View {
    @ObservedObject var store: AppTabStore
    @ObservedObject var viewModel: JourneyViewModel
    let hidesSelectedCard: Bool
    let dismiss: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 14),
            count: horizontalSizeClass == .regular ? 3 : 2
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(store.tabs) { tab in
                        card(tab)
                            .draggable(tab.id.uuidString)
                            .dropDestination(for: String.self) { items, _ in
                                guard let raw = items.first,
                                      let source = UUID(uuidString: raw) else { return false }
                                withAnimation(.smooth) { store.move(source, before: tab.id) }
                                return true
                            }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        _ = store.add()
                        dismiss()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New tab")
                }

                ToolbarSpacer(.flexible, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Button("Done", action: dismiss)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func card(_ tab: AppTab) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon(for: tab))
                    .foregroundStyle(accent(for: tab))
                Text(title(for: tab))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Button {
                    withAnimation(.smooth) { store.close(tab.id) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .frame(width: 26, height: 26)
                        .background(.quaternary, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close \(title(for: tab))")
            }
            .padding(.horizontal, 10)
            .frame(height: 42)

            preview(for: tab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
        // Keep the card close to the device viewport's aspect ratio so the
        // live workspace can be uniformly scaled into it without relayout.
        .aspectRatio(0.46, contentMode: .fit)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    tab.id == store.selectedTabID ? Color.accentColor : Color(.separator).opacity(0.4),
                    lineWidth: tab.id == store.selectedTabID ? 3 : 1
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        .opacity(hidesSelectedCard && tab.id == store.selectedTabID ? 0 : 1)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: TabCardFramePreferenceKey.self,
                    value: [
                        tab.id: proxy.frame(in: .named(TabCardFramePreferenceKey.coordinateSpace))
                    ]
                )
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            store.select(tab.id)
            dismiss()
        }
        .contextMenu {
            Button("Duplicate", systemImage: "plus.square.on.square") {
                store.duplicate(tab.id)
            }
            Button("Close", systemImage: "xmark", role: .destructive) {
                store.close(tab.id)
            }
        }
    }

    @ViewBuilder
    private func preview(for tab: AppTab) -> some View {
        switch tab.page {
        case .home:
            VStack(alignment: .leading, spacing: 12) {
                previewHeader(LocalizedStringKey("App.Name"), icon: "tram.fill")
                roundedLine(width: 0.72)
                roundedLine(width: 0.9)
                HStack(spacing: 8) {
                    previewTile(.indigo)
                    previewTile(.orange)
                }
                Spacer()
            }
            .padding(16)
        case .search:
            VStack(alignment: .leading, spacing: 12) {
                previewHeader(LocalizedStringKey("Search.Title"), icon: "magnifyingglass")
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text(tab.searchText.isEmpty ? String(localized: "Search.Prompt") : tab.searchText)
                        .lineLimit(1)
                }
                .font(.caption)
                .padding(9)
                .background(.quaternary, in: Capsule())
                ForEach(0..<4, id: \.self) { index in
                    HStack {
                        Circle().fill(index.isMultiple(of: 2) ? .orange : .blue)
                            .frame(width: 18, height: 18)
                        roundedLine(width: index.isMultiple(of: 2) ? 0.68 : 0.82)
                    }
                }
                Spacer()
            }
            .padding(16)
        case .destination(let destination):
            VStack(alignment: .leading, spacing: 12) {
                previewHeaderText(title(for: destination), icon: icon(for: destination))
                roundedLine(width: 0.85)
                roundedLine(width: 0.58)
                Divider()
                ForEach(0..<4, id: \.self) { _ in roundedLine(width: 0.9) }
                Spacer()
            }
            .padding(16)
        }
    }

    private func previewHeader(_ title: LocalizedStringKey, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title).font(.caption.bold()).lineLimit(1)
            Spacer()
        }
    }

    private func previewHeaderText(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title).font(.caption.bold()).lineLimit(1)
            Spacer()
        }
    }

    private func roundedLine(width: CGFloat) -> some View {
        GeometryReader { proxy in
            Capsule().fill(.quaternary).frame(width: proxy.size.width * width, height: 9)
        }
        .frame(height: 9)
    }

    private func previewTile(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.2)).frame(height: 76)
    }

    private func title(for tab: AppTab) -> String {
        switch tab.page {
        case .home:
            String(localized: "App.Name")
        case .search:
            tab.searchText.isEmpty ? String(localized: "Search.Title") : tab.searchText
        case .destination(let destination):
            title(for: destination)
        }
    }

    private func title(for destination: SearchDestination) -> String {
        switch destination {
        case .operatorLines(let operatorId):
            OperatorSections.title(for: operatorId)
        case .line(let lineId):
            viewModel.availableLines.first(where: { $0.id == lineId })?.localizedName
                ?? String(localized: "Search.Section.Lines")
        case .station(let lineId, let stationId):
            viewModel.availableLines.first(where: { $0.id == lineId })?
                .stations.first(where: { $0.id == stationId })?.localizedName
                ?? String(localized: "Search.Section.Stations")
        }
    }

    private func icon(for tab: AppTab) -> String {
        switch tab.page {
        case .home: "house"
        case .search: "magnifyingglass"
        case .destination(let destination): icon(for: destination)
        }
    }

    private func icon(for destination: SearchDestination) -> String {
        switch destination {
        case .operatorLines: "building.2"
        case .line: "tram.fill"
        case .station: "clock"
        }
    }

    private func accent(for tab: AppTab) -> Color {
        guard case .destination(.line(let lineID)) = tab.page else { return .accentColor }
        return viewModel.availableLines.first(where: { $0.id == lineID })?.color ?? .accentColor
    }
}

struct TabCardFramePreferenceKey: PreferenceKey {
    static let coordinateSpace = "AppTabShell"
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
