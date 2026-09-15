import SwiftUI
import Backbone

struct AppTabOverviewView: View {
    static let cardCornerRadius: CGFloat = 16

    @ObservedObject var store: AppTabStore
    @ObservedObject var viewModel: JourneyViewModel
    let hidesSelectedCard: Bool
    let dismiss: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(store.tabs) { tab in
                        AppTabOverviewCard(
                            title: title(for: tab),
                            icon: icon(for: tab),
                            accent: accent(for: tab),
                            isSelected: tab.id == store.selectedTabID,
                            canClose: store.canCloseTabs,
                            isHidden: hidesSelectedCard && tab.id == store.selectedTabID,
                            preview: preview(for: tab),
                            onSelect: {
                                store.select(tab.id)
                                dismiss()
                            },
                            onClose: {
                                withAnimation(.smooth.speed(1.5)) {
                                    store.close(tab.id)
                                }
                            }
                        )
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: TabCardFramePreferenceKey.self,
                                    value: [
                                        tab.id: proxy.frame(
                                            in: .named(TabCardFramePreferenceKey.coordinateSpace)
                                        )
                                    ]
                                )
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Close All Tabs", systemImage: "xmark.square.fill", role: .destructive) {
                            withAnimation(.smooth.speed(1.5)) {
                                store.closeAll()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
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

    @ViewBuilder
    private func preview(for tab: AppTab) -> some View {
        if let snapshot = store.snapshots[tab.id] {
            GeometryReader { proxy in
                Image(uiImage: snapshot)
                    .resizable()
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.width / snapshotAspectRatio(snapshot)
                    )
            }
        } else {
            standIn(for: tab)
                .padding(12)
        }
    }

    @ViewBuilder
    private func standIn(for tab: AppTab) -> some View {
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
        case .destination(let destination):
            VStack(alignment: .leading, spacing: 12) {
                previewHeaderText(title(for: destination), icon: icon(for: destination))
                roundedLine(width: 0.85)
                roundedLine(width: 0.58)
                Divider()
                ForEach(0..<4, id: \.self) { _ in roundedLine(width: 0.9) }
                Spacer()
            }
        }
    }

    private func snapshotAspectRatio(_ snapshot: UIImage) -> CGFloat {
        guard snapshot.size.height > 0 else { return 1 }
        return snapshot.size.width / snapshot.size.height
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
        case .operatorLines(let operatorID):
            OperatorSections.title(for: operatorID)
        case .line(let lineID):
            viewModel.availableLines.first(where: { $0.id == lineID })?.localizedName
                ?? String(localized: "Search.Section.Lines")
        case .station(let lineID, let stationID):
            viewModel.availableLines.first(where: { $0.id == lineID })?
                .stations.first(where: { $0.id == stationID })?.localizedName
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

private struct AppTabOverviewCard<Preview: View>: View {
    private static var closeDistance: CGFloat { 90 }

    let title: String
    let icon: String
    let accent: Color
    let isSelected: Bool
    let canClose: Bool
    let isHidden: Bool
    let preview: Preview
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                header
                Color.clear
                    .aspectRatio(0.75, contentMode: .fit)
                    .overlay(alignment: .top) { preview }
                    .clipped()
            }
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(
                    cornerRadius: AppTabOverviewView.cardCornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppTabOverviewView.cardCornerRadius,
                    style: .continuous
                )
                .strokeBorder(isSelected ? accent : .clear, lineWidth: 2.5)
            }
            .contentShape(
                RoundedRectangle(
                    cornerRadius: AppTabOverviewView.cardCornerRadius,
                    style: .continuous
                )
            )
        }
        .offset(x: dragOffset)
        .opacity(isHidden ? 0 : closeProgress)
        .highPriorityGesture(closeDragGesture)
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(accent)
            Text(title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
            Spacer(minLength: 0)
            if canClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close \(title)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var closeProgress: Double {
        1 - min(1, Double(-dragOffset / Self.closeDistance))
    }

    private var closeDragGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                dragOffset = min(0, value.translation.width)
            }
            .onEnded { value in
                if canClose, value.translation.width < -Self.closeDistance {
                    withAnimation(.smooth(duration: 0.2)) {
                        dragOffset = -Self.closeDistance * 2
                    }
                    onClose()
                } else {
                    withAnimation(.smooth(duration: 0.2)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

struct TabCardFramePreferenceKey: PreferenceKey {
    static let coordinateSpace = "AppTabShell"
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
