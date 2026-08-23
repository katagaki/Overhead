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

/// The network as artwork. Hand-picked so the plates read as a spread of
/// operators rather than a column of JR marks.
struct LineDataBadgeWall: View {
    var dimension: CGFloat = 34
    @ObservedObject private var installer = LineDataInstaller.shared
    @State private var revealed = false

    /// Station guide-sign yellow, the ground these plates hang on.
    private static let panelYellow = Color(hex: "#FFD400")

    private static let lineIds = [
        "Railway:JR-East.Yamanote", "Railway:TokyoMetro.Ginza", "Railway:Tokyu.Toyoko",
        "Railway:Toei.Oedo", "Railway:Keio.Keio", "Railway:MIR.TsukubaExpress",
        "Railway:JR-East.KeihinTohoku", "Railway:TokyoMetro.Marunouchi", "Railway:Odakyu.Odawara",
        "Railway:Seibu.Ikebukuro", "Railway:Yurikamome.Yurikamome", "Railway:Enoden.Enoshima",
        "Railway:JR-East.ChuoRapid", "Railway:TokyoMetro.Hanzomon", "Railway:Keikyu.Main",
        "Railway:Toei.Asakusa", "Railway:Tobu.Tojo", "Railway:TamaMonorail.TamaMonorail",
        "Railway:JR-East.ChuoSobuLocal", "Railway:TokyoMetro.Tozai", "Railway:Keisei.Main",
        "Railway:Tokyu.DenEnToshi", "Railway:YokohamaMunicipal.Blue", "Railway:TWR.Rinkai",
        "Railway:JR-East.JobanLocal", "Railway:TokyoMetro.Chiyoda", "Railway:Seibu.Shinjuku",
        "Railway:Keio.Inokashira", "Railway:Minatomirai.Minatomirai", "Railway:Toei.Shinjuku"
    ]

    private static let columns = 6
    private static let spacing: CGFloat = 10

    private var panelHeight: CGFloat {
        let rows = (Self.lineIds.count + Self.columns - 1) / Self.columns
        return CGFloat(rows) * dimension + CGFloat(rows - 1) * Self.spacing + 48
    }

    var body: some View {
        let styleCount = BadgeStyles.all.count
        let lines = styleCount == 0 ? [] : Self.lineIds.compactMap(Catalog.line(id:))
        ZStack {
            if lines.isEmpty {
                ProgressView()
                    .controlSize(.extraLarge)
                    .tint(.black.opacity(0.4))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Self.spacing),
                                         count: Self.columns),
                          spacing: Self.spacing) {
                    ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                        BadgeOutline(width: 1.5) {
                            LineSymbolBadge(symbol: line.symbol, color: Color(hex: line.colorHex),
                                            dimension: dimension, styleOverride: line.badgeStyle,
                                            lineId: line.id)
                        }
                        .opacity(revealed ? 1 : 0)
                        .offset(x: revealed ? 0 : 28)
                        .animation(.smooth(duration: 0.45).delay(Double(index) * 0.02),
                                   value: revealed)
                    }
                }
                .id(styleCount)
                .padding(.horizontal, 20)
                .onAppear { revealed = true }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: lines.isEmpty)
        .frame(maxWidth: .infinity)
        .frame(height: panelHeight)
        // The plates are drawn for signage: the panel behind them stays the
        // same yellow in either theme, and runs to both edges of the sheet.
        .background(Self.panelYellow)
        .accessibilityHidden(true)
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
