import SwiftUI
import Backbone

// MARK: - First-run line download

/// The app carries every line in the catalog, so the first run has one
/// decision: download now, or later.
struct LineDataOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = LineDataModel()
    @ObservedObject private var installer = LineDataInstaller.shared
    @AppStorage("lineData.onboarded") private var onboarded = false
    /// Held, not recomputed: the catalog stops being stale mid-download.
    @State private var isUpgrade = Catalog.needsSchemaUpgrade

    private var lineCount: Int { Catalog.current.lines.count }

    private var titleKey: LocalizedStringKey {
        isUpgrade ? "LineData.Onboarding.Update.Title" : "LineData.Onboarding.Title"
    }

    private var bodyKey: LocalizedStringKey {
        isUpgrade ? "LineData.Onboarding.Update.Body" : "LineData.Onboarding.Body"
    }

    private var actionKey: LocalizedStringKey {
        let size = LineDataModel.formatted(bytes: installer.catalogBytes)
        return isUpgrade
            ? "LineData.Onboarding.Update \(size)"
            : "LineData.Onboarding.Download \(size)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            LineDataBadgeWall()
            VStack(alignment: .leading, spacing: 8) {
                Text(titleKey)
                    .font(.largeTitle.bold())
                Text(bodyKey)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .safeAreaInset(edge: .bottom) { actions }
        .ignoresSafeArea(edges: .top)
        .interactiveDismissDisabled(true)
        .task { await model.prepare() }
        .onChange(of: installer.installedCount) { _, count in
            // However the download was started, finishing it ends the sheet.
            guard lineCount > 0, count == lineCount, !installer.isDownloading else { return }
            onboarded = true
            dismiss()
        }
        .alert("LineData.Error", isPresented: .constant(model.error != nil)) {
            Button("Shared.OK") { model.error = nil }
        } message: {
            Text(model.error ?? "")
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: 12) {
            if let progress = installer.progress {
                LineDataProgressCapsule(progress: progress)
            } else {
                // Holds the capsule's place, so the button never moves.
                Color.clear.frame(height: 44)
            }

            Button {
                Task {
                    if isUpgrade { await model.upgrade() } else { await model.download() }
                    if !installer.hasPendingWork {
                        onboarded = true
                        dismiss()
                    }
                }
            } label: {
                Text(actionKey)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(installer.isBusy)
        }
        .padding()
    }
}

// MARK: - Badge wall

/// The network as artwork. The plates are drawn at random from the whole
/// catalog and swapped out every few seconds, so the wall never reads as the
/// same fixed set twice.
struct LineDataBadgeWall: View {
    var dimension: CGFloat = 34
    @ObservedObject private var installer = LineDataInstaller.shared
    @State private var lines: [CatalogLine] = []
    @State private var revealed = false
    /// Where a hidden plate sits: left before it comes in, right after it
    /// leaves, so the wall reads as one pass across the panel.
    @State private var hiddenOffset: CGFloat = -travel

    /// Station guide-sign yellow, the ground these plates hang on.
    private static let panelYellow = Color(hex: "#FFD400")

    private static let columns = 6
    private static let rows = 5
    private static let slots = columns * rows
    private static let spacing: CGFloat = 10
    private static let outline: CGFloat = 1.5
    /// How long a set of plates stays up, apart from its own animations.
    private static let dwell: Duration = .seconds(4.5)
    /// The wall moves row by row, with a small lean across each row.
    private static let rowStagger = 0.12
    private static let columnStagger = 0.02
    private static let travel: CGFloat = 28
    private static let fadeIn = 0.55
    private static let fadeOut = 0.4
    /// A beat with the next set laid in but still hidden, so the plates are
    /// built and rasterized before anything has to move.
    private static let warmup: Duration = .milliseconds(180)

    /// When a plate at this slot starts moving.
    private static func delay(slot: Int) -> Double {
        Double(slot / columns) * rowStagger + Double(slot % columns) * columnStagger
    }

    /// The longest a sweep can take: the last plate's delay plus its own run.
    private static func sweep(_ duration: Double) -> Double {
        duration + delay(slot: max(slots - 1, 0))
    }

    /// The plate carries its own white edge, so a row is wider than the badge.
    private var plate: CGFloat { dimension + Self.outline * 2 }

    private var panelHeight: CGFloat {
        CGFloat(Self.rows) * plate + CGFloat(Self.rows - 1) * Self.spacing + 48
    }

    /// A fresh draw, capped per operator so a shuffle cannot hand back a wall
    /// of one company's marks.
    private static func sample() -> [CatalogLine] {
        // Lines with no symbol of their own would hang a blank plate.
        let all = Catalog.current.lines.filter { !$0.symbol.isEmpty }
        guard !all.isEmpty else { return [] }
        var perOperator: [String: Int] = [:]
        var picked: [CatalogLine] = []
        let shuffled = all.shuffled()
        for line in shuffled where picked.count < slots {
            let taken = perOperator[line.operatorId, default: 0]
            guard taken < 3 else { continue }
            perOperator[line.operatorId] = taken + 1
            picked.append(line)
        }
        // Too few operators to fill the wall under the cap: top it up anyway.
        if picked.count < slots {
            let chosen = Set(picked.map(\.id))
            for line in shuffled where !chosen.contains(line.id) && picked.count < slots {
                picked.append(line)
            }
        }
        return picked
    }

    var body: some View {
        let styleCount = BadgeStyles.all.count
        ZStack {
            if lines.isEmpty {
                ProgressView()
                    .controlSize(.extraLarge)
                    .tint(.black.opacity(0.4))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Self.spacing),
                                         count: Self.columns),
                          spacing: Self.spacing) {
                    // Keyed by slot, not by line: a plate swaps its contents in
                    // place rather than being torn out of the grid.
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        BadgeOutline(width: Self.outline) {
                            LineSymbolBadge(symbol: line.symbol, color: Color(hex: line.colorHex),
                                            dimension: dimension, styleOverride: line.badgeStyle,
                                            lineId: line.id)
                        }
                        // Not quite zero: a fully clear layer is skipped
                        // outright, and the work lands on the first frame in.
                        .opacity(revealed ? 1 : 0.01)
                        .offset(x: revealed ? 0 : hiddenOffset)
                        .animation(.easeOut(duration: revealed ? Self.fadeIn : Self.fadeOut)
                            .delay(Self.delay(slot: index)),
                                   value: revealed)
                    }
                }
                .id(styleCount)
                .padding(.horizontal, 20)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: lines.isEmpty)
        .frame(maxWidth: .infinity)
        .frame(height: panelHeight)
        // The plates are drawn for signage: the panel behind them stays the
        // same yellow in either theme, and runs to both edges of the sheet.
        .background(Self.panelYellow)
        .accessibilityHidden(true)
        .task(id: styleCount) { await rotate() }
    }

    /// Deal a wall, hold it, sweep it out, deal the next one. The deal always
    /// happens a beat before the reveal: building thirty plates on the frame
    /// the animation starts is what makes it stutter.
    private func rotate() async {
        let out = Self.sweep(Self.fadeOut)
        lines = Self.sample()
        hiddenOffset = -Self.travel
        try? await Task.sleep(for: Self.warmup)
        guard !Task.isCancelled else { return }
        revealed = true
        while !Task.isCancelled {
            try? await Task.sleep(for: Self.dwell)
            guard !Task.isCancelled else { return }
            hiddenOffset = Self.travel
            revealed = false
            try? await Task.sleep(for: .seconds(out))
            guard !Task.isCancelled else { return }
            lines = Self.sample()
            // Untweened, since nothing the animation watches changes: the
            // plates step back to the left edge while still invisible.
            hiddenOffset = -Self.travel
            try? await Task.sleep(for: Self.warmup)
            guard !Task.isCancelled else { return }
            revealed = true
        }
    }
}

/// A white edge around a plate, cut from the plate's own silhouette so a
/// circle, a hexagon and a blossom each keep their shape against the yellow.
private struct BadgeOutline<Content: View>: View {
    let width: CGFloat
    @ViewBuilder var content: Content

    private static var directions: [CGPoint] {
        [CGPoint(x: 1, y: 0), CGPoint(x: -1, y: 0), CGPoint(x: 0, y: 1), CGPoint(x: 0, y: -1),
         CGPoint(x: 0.7, y: 0.7), CGPoint(x: -0.7, y: 0.7),
         CGPoint(x: 0.7, y: -0.7), CGPoint(x: -0.7, y: -0.7)]
    }

    var body: some View {
        content
            .background {
                ZStack {
                    ForEach(Array(Self.directions.enumerated()), id: \.offset) { _, direction in
                        Color.white
                            .mask { content }
                            .offset(x: direction.x * width, y: direction.y * width)
                    }
                }
            }
            // Nine layers per plate is too much to keep live while thirty of
            // them animate: rasterize once, then move the flattened texture.
            .padding(width)
            .drawingGroup()
    }
}

// MARK: - Progress

/// A glass capsule that fills as the download runs, so the button below never
/// has to change size or place.
struct LineDataProgressCapsule: View {
    let progress: LineDataProgress

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                // Square right edge, so a short fill reads as a bar and not a pill.
                Rectangle()
                    .fill(Color.accentColor.opacity(0.35))
                    .frame(width: proxy.size.width * progress.fraction)
                    .animation(.linear(duration: 0.2), value: progress.fraction)
                HStack(spacing: 8) {
                    Text(progress.currentLine ?? String(localized: "LineData.Downloading"))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(verbatim: "\(progress.completedLines) / \(progress.totalLines)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 18)
            }
            .clipShape(.capsule)
        }
        .frame(height: 44)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Progress row

/// The same progress, shaped for a list row.
struct LineDataProgressBlock: View {
    let progress: LineDataProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: progress.fraction)
                .animation(.linear(duration: 0.2), value: progress.fraction)
            HStack {
                Text(progress.currentLine ?? String(localized: "LineData.Downloading"))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(verbatim: "\(progress.completedLines) / \(progress.totalLines)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
