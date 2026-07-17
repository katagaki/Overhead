import SwiftUI
import Backbone

// MARK: - Custom Line Editor

struct CustomLineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CustomLineStore.shared
    @AppStorage(TrainLCDStyle.storageKey) private var lcdStyleRaw = TrainLCDStyle.joban.rawValue
    @AppStorage(TrainLCDOrientation.storageKey) private var lcdOrientationRaw = TrainLCDOrientation.left.rawValue

    @State private var draft: CustomLine
    @State private var isNew: Bool
    @State private var showDeleteConfirm = false

    init(route: CustomLineRoute) {
        switch route {
        case .new:
            _draft = State(initialValue: .new())
            _isNew = State(initialValue: true)
        case .edit(let id):
            let existing = CustomLineStore.shared.line(withId: id) ?? .new()
            _draft = State(initialValue: existing)
            _isNew = State(initialValue: false)
        }
    }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    TextField("", text: $draft.name, prompt: Text(verbatim: "例：山彦電鉄本線"))
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text(verbatim: "路線名")
                }
                LabeledContent {
                    TextField("", text: $draft.symbol, prompt: Text(verbatim: "YH"))
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: draft.symbol) { _, value in
                            let cleaned = String(value.uppercased().prefix(2))
                            if cleaned != draft.symbol { draft.symbol = cleaned }
                        }
                } label: {
                    Text(verbatim: "路線記号")
                }
                Toggle(isOn: $draft.isLoop) {
                    Text(verbatim: "環状運転")
                }
            } header: {
                Text(verbatim: "基本情報")
            }

            Section {
                colorSwatches
            } header: {
                Text(verbatim: "ラインカラー")
            }

            Section {
                Picker(selection: $draft.badgeStyle) {
                    ForEach(BadgeStyle.allCases) { style in
                        Text(verbatim: style.labelJa).tag(style)
                    }
                } label: {
                    Text(verbatim: "スタイル")
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            } header: {
                Text(verbatim: "駅番号バッジ")
            }

            Section {
                NavigationLink {
                    CustomStationsEditorView(line: $draft)
                } label: {
                    LabeledContent {
                        Text(verbatim: "\(draft.stations.count)駅")
                    } label: {
                        Text(verbatim: "駅")
                    }
                }
                NavigationLink {
                    CustomTimetableEditorView(line: $draft)
                } label: {
                    LabeledContent {
                        Text(verbatim: draft.hasSchedule ? "あり" : "なし")
                    } label: {
                        Text(verbatim: "時刻表")
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Text(verbatim: "路線を削除")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle(Text(verbatim: isNew ? "新しい路線" : "路線を編集"))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            CustomLinePreview(
                line: draft,
                style: TrainLCDStyle(stored: lcdStyleRaw),
                orientation: TrainLCDOrientation(rawValue: lcdOrientationRaw) ?? .left
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .background(Color(.systemGroupedBackground))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: CustomLineDocument(
                        package: CustomLinePackage(lines: [normalizedDraft]),
                        suggestedName: draft.name.isEmpty ? "MyLine" : draft.name
                    ),
                    preview: SharePreview(draft.name.isEmpty ? "路線" : draft.name)
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(draft.stations.isEmpty)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(TrainLCDStyleCategory.allCases) { category in
                        Section(category.label) {
                            Picker("Button.LCDStyle", selection: $lcdStyleRaw) {
                                ForEach(category.styles) { style in
                                    Text(verbatim: style.label).tag(style.rawValue)
                                }
                            }
                            .pickerStyle(.inline)
                        }
                    }
                    Picker("Button.LCDOrientation", selection: $lcdOrientationRaw) {
                        ForEach(TrainLCDOrientation.allCases) { orientation in
                            Text(verbatim: orientation.label).tag(orientation.rawValue)
                        }
                    }
                } label: {
                    Label("Button.LCDStyle", systemImage: "widget.medium")
                }
            }
        }
        .onChange(of: draft) { _, newValue in
            // Skip a blank brand-new line so backing out leaves no junk behind.
            guard !(newValue.name.isEmpty && newValue.stations.isEmpty && newValue.symbol.isEmpty) else { return }
            store.upsert(newValue)
            isNew = false
        }
        .confirmationDialog(
            Text(verbatim: "この路線を削除しますか？"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                store.delete(id: draft.id)
                dismiss()
            } label: {
                Text(verbatim: "削除")
            }
            Button(role: .cancel) {} label: { Text(verbatim: "キャンセル") }
        }
    }

    private var normalizedDraft: CustomLine {
        var copy = draft
        copy.normalizeHopMinutes()
        return copy
    }

    // MARK: Color swatches

    private var colorSwatches: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(CustomLinePalette.colors, id: \.self) { hex in
                Button {
                    draft.colorHex = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(height: 30)
                        .overlay {
                            if draft.colorHex.caseInsensitiveCompare(hex) == .orderedSame {
                                Circle().strokeBorder(Color.primary, lineWidth: 2).padding(-3)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: hex))
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Live LCD preview

/// Preview of the draft line, reusing the real LCD views.
struct CustomLinePreview: View {
    let line: CustomLine
    var style: TrainLCDStyle = .joban
    var orientation: TrainLCDOrientation = .left

    var body: some View {
        if line.stations.count >= 2, let journey, let state {
            StyledTrainLCDView(style: style, journey: journey, state: state,
                               lineColor: line.color, orientation: orientation)
        } else {
            placeholder
        }
    }

    private var journey: Journey? {
        guard let first = line.stations.first, let last = line.stations.last,
              let service = CustomJourneyBuilder.untimedService(line: line, fromId: first.id, toId: last.id)
        else { return nil }
        return Journey(
            id: UUID(), service: service, line: line.trainLine,
            boardingStationId: first.id, alightingStationId: last.id,
            startedAt: Date(), hasSchedule: false
        )
    }

    private var state: TrainPositionState? {
        let names = line.stations
        guard names.count >= 2 else { return nil }
        return TrainPositionState(
            progress: 0.25, segmentFrom: 0, segmentTo: 1, segmentProgress: 0.5,
            currentStationIndex: nil,
            nextStationName: names[1].name, nextStationNameEn: names[1].nameEn,
            delayMinutes: 0, estimatedArrival: Date().addingTimeInterval(600),
            status: .onTime, trackingModeRaw: "GPS"
        )
    }

    private var placeholder: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: "tram.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.tertiary)
                Text(verbatim: "駅を2つ以上追加するとプレビューが表示されます")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.vertical, 24)
    }
}
