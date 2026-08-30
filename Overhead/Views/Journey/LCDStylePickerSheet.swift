import SwiftUI
import Backbone

// MARK: - Style Picker

/// Grid of LCD style previews, two columns, scrolling vertically.
/// Every cell shows the same fixed sample line so the previews stay cheap.
struct LCDStylePickerSheet: View {
    @Binding var styleRaw: String
    @AppStorage(TrainLCDOrientation.storageKey)
    private var orientationRaw = TrainLCDOrientation.left.rawValue
    @AppStorage(LCDLanguageRotation.storageKey)
    private var languagesRaw = LCDLanguageRotation.default.map(\.rawValue).joined(separator: ",")
    @Environment(\.dismiss) private var dismiss

    private var orientation: TrainLCDOrientation {
        TrainLCDOrientation(rawValue: orientationRaw) ?? .left
    }

    private var languages: [TrainLCDLanguage] {
        let picked = Set(languagesRaw.split(separator: ",").map(String.init))
        let selected = TrainLCDLanguage.allCases.filter { picked.contains($0.rawValue) }
        return selected.isEmpty ? LCDLanguageRotation.default : selected
    }

    /// Toggling off the last language would leave the LCDs with nothing to show.
    private func toggle(_ language: TrainLCDLanguage) {
        var next = languages
        if let index = next.firstIndex(of: language) {
            guard next.count > 1 else { return }
            next.remove(at: index)
        } else {
            next.append(language)
        }
        languagesRaw = TrainLCDLanguage.allCases
            .filter { next.contains($0) }
            .map(\.rawValue)
            .joined(separator: ",")
    }

    /// Card width as a share of the sheet, leaving the next card peeking out.
    private static let cellWidthFraction: CGFloat = 0.4
    private static let spacing: CGFloat = 12
    private static let horizontalPadding: CGFloat = 16
    private static let cellPadding: CGFloat = 12
    /// Breathing room either side of the title, inside the card's own padding.
    private static let titleInset: CGFloat = 4
    private static let cornerRadius: CGFloat = 24
    /// Room the title takes under the preview, spacing included.
    private static let titleAllowance: CGFloat = 46

    /// A 4:3 window, so styles of that shape use the full card width.
    private static func previewHeight(cellWidth: CGFloat) -> CGFloat {
        (cellWidth - Self.cellPadding * 2) * 3 / 4
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                // 40% of the sheet: the next card always peeks in from the
                // right edge, so the row reads as scrollable.
                let cellWidth = geo.size.width * Self.cellWidthFraction
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(TrainLCDStyleCategory.allCases) { category in
                            Section {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: Self.spacing) {
                                        ForEach(category.styles) { style in
                                            cell(style: style, width: cellWidth)
                                        }
                                    }
                                    .padding(.horizontal, Self.horizontalPadding)
                                }
                            } header: {
                                Text(verbatim: category.label)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, Self.horizontalPadding)
                                    .padding(.top, 14)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Button.LCDStyle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(TrainLCDLanguage.allCases) { language in
                            Button {
                                toggle(language)
                            } label: {
                                Label {
                                    Text(verbatim: language.label)
                                } icon: {
                                    if languages.contains(language) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Button.LCDLanguages", systemImage: "character.bubble")
                    }
                    .menuOrder(.fixed)
                    // Multi-select: the menu stays up while languages are ticked.
                    .menuActionDismissBehavior(.disabled)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        orientationRaw = (orientation == .left
                            ? TrainLCDOrientation.right
                            : TrainLCDOrientation.left).rawValue
                    } label: {
                        Label("Button.LCDOrientation", systemImage: "arrow.left.arrow.right")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        // Swiping the cards scrolls them; it does not grow the sheet.
        .presentationContentInteraction(.scrolls)
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    private func cell(style: TrainLCDStyle, width: CGFloat) -> some View {
        let isSelected = styleRaw == style.rawValue
        let previewHeight = Self.previewHeight(cellWidth: width)
        Button {
            styleRaw = style.rawValue
        } label: {
            VStack(spacing: 6) {
                LCDStylePreview(style: style,
                                orientation: orientation,
                                width: width - Self.cellPadding * 2,
                                height: previewHeight)
                    .frame(maxHeight: .infinity)
                    .allowsHitTesting(false)

                // Long names squash on one line rather than wrapping.
                HorizontallySquashed(
                    maxWidth: width - (Self.cellPadding + Self.titleInset) * 2
                ) {
                    Text(verbatim: style.label)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(Self.cellPadding)
            .frame(width: width,
                   height: previewHeight + Self.titleAllowance,
                   alignment: .bottom)
            .background {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(isSelected
                          ? AnyShapeStyle(Color.accentColor.opacity(0.28))
                          : AnyShapeStyle(Color(.secondarySystemBackground)))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: style.label))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Preview Cell

/// One style rendered at its 360pt design width, scaled down into a grid cell.
private struct LCDStylePreview: View {
    let style: TrainLCDStyle
    let orientation: TrainLCDOrientation
    let width: CGFloat
    let height: CGFloat

    /// Every LCD style lays itself out against this width.
    private static let designWidth: CGFloat = 360
    /// Upper bound on an LCD's height at the design width.
    private static let designMaxHeight: CGFloat = 400
    @State private var contentHeight: CGFloat = 0

    /// Fit the whole LCD inside the cell, wide or short.
    private var scale: CGFloat {
        guard contentHeight > 0 else { return width / Self.designWidth }
        return min(width / Self.designWidth,
                   height / min(contentHeight, Self.designMaxHeight))
    }

    var body: some View {
        Group {
            if let journey = LCDStyleSample.journey {
                StyledTrainLCDView(
                    style: style,
                    journey: journey,
                    state: LCDStyleSample.state,
                    lineColor: LCDStyleSample.lineColor,
                    orientation: orientation
                )
                // Aspect-fitting styles need a generous height offered to them,
                // the way the journey sheet's safe-area inset does; the measured
                // height is then what the fit scales down.
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
                .frame(width: Self.designWidth, height: Self.designMaxHeight, alignment: .top)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: Self.designWidth * scale,
                       height: min(contentHeight, Self.designMaxHeight) * scale,
                       alignment: .topLeading)
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Fixed Sample Line

/// A made-up line the previews ride, so no style has to touch the real journey.
enum LCDStyleSample {
    static let lineColor = Color(red: 0.0, green: 0.40, blue: 0.75)

    private static let line = CustomLine(
        id: "Custom:Line.LCDStyleSample",
        name: "ミレニアム線",
        nameEn: "Millennium Line",
        symbol: "M",
        colorHex: "#0067C0",
        badgeStyleId: "metro",
        isLoop: false,
        stations: [
            CustomStation(id: "Custom:Station.ML01", name: "ミレニアム中央", nameEn: "Millennium Central"),
            CustomStation(id: "Custom:Station.ML02", name: "ゲーム開発部", nameEn: "Game Dev Club"),
            CustomStation(id: "Custom:Station.ML03", name: "ヴェリタス", nameEn: "Veritas"),
            CustomStation(id: "Custom:Station.ML04", name: "ミレニアムポート", nameEn: "Millennium Port"),
        ],
        hopMinutes: [2, 3, 2]
    )

    static let journey: Journey? = {
        let stations = line.stations
        guard let service = CustomJourneyBuilder.untimedService(
            line: line, fromId: stations[0].id, toId: stations[3].id
        ) else { return nil }
        return Journey(
            id: UUID(), service: service, line: line.trainLine,
            boardingStationId: stations[0].id, alightingStationId: stations[3].id,
            startedAt: Date(), hasSchedule: false
        )
    }()

    static let state = TrainPositionState(
        progress: 0.25, segmentFrom: 0, segmentTo: 1, segmentProgress: 0.5,
        currentStationIndex: nil,
        nextStationName: line.stations[1].name, nextStationNameEn: line.stations[1].nameEn,
        delayMinutes: 0, estimatedArrival: Date().addingTimeInterval(600),
        status: .onTime, trackingModeRaw: "GPS"
    )
}
