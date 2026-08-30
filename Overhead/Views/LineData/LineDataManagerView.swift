import SwiftUI
import Backbone

// MARK: - Line Data Manager

/// Reads like Software Update: what the update is, how big it is, what it
/// touches, and one row that starts it.
struct LineDataManagerView: View {
    @StateObject private var model = LineDataModel()
    @ObservedObject private var installer = LineDataInstaller.shared
    @AppStorage("lineData.onboarded") private var onboarded = false
    @AppStorage(LineDataAutoUpdater.enabledKey) private var autoUpdate = false
    @AppStorage(LineDataAutoUpdater.notifyKey) private var notifyOnUpdate = false
    @State private var isConfirmingDelete = false
    /// How many plates the summary row fits at the current width.
    @State private var rowCapacity = 0

    private static let plateDimension: CGFloat = 26
    private static let plateSpacing: CGFloat = 6

    var body: some View {
        List {
            autoUpdateSection

            if installer.needsAppUpdate {
                Section {
                    Label("LineData.AppTooOld", systemImage: "exclamationmark.triangle")
                } footer: {
                    Text("LineData.AppTooOld.Footer")
                }
            }

            if installer.isDownloading || installer.hasPendingWork {
                Section {
                    updateSummary
                    actionRow
                }
            } else if Catalog.current.lines.isEmpty {
                // A wipe that could not reach the catalog afterwards leaves
                // nothing to describe and nothing pending, so this screen is
                // the only way back.
                Section {
                    Button("LineData.DownloadNow") {
                        Task { await model.upgrade() }
                    }
                    .disabled(installer.isBusy)
                }
            }

            Section {
                LabeledContent("LineData.Version") {
                    Text(installer.installedVersion)
                }
                LabeledContent("LineData.Section.Included") {
                    Text("LineData.LineCount \(Catalog.current.lines.count)")
                }
            }

            Section {
                Button("LineData.Redownload", role: .destructive) {
                    isConfirmingDelete = true
                }
                .disabled(installer.isBusy)
            } footer: {
                Text("LineData.Redownload.Footer")
            }
        }
        .navigationTitle("LineData.Title")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await model.checkForUpdates() }
        .task { await installer.recomputePending() }
        .alert("LineData.Redownload.Confirm", isPresented: $isConfirmingDelete) {
            Button("LineData.Redownload.Action", role: .destructive) {
                // The first-run sheet is the only download screen that starts
                // from nothing, so the root brings it back — right away, with
                // the wipe running behind it.
                onboarded = false
                model.deleteAllData()
            }
            Button("Button.Cancel", role: .cancel) { }
        } message: {
            Text("LineData.Redownload.Confirm.Message")
        }
        .alert("LineData.Error", isPresented: .constant(model.error != nil)) {
            Button("Shared.OK") { model.error = nil }
        } message: {
            Text(model.error ?? "")
        }
    }

    // MARK: Automatic updates

    /// Two switches rather than one: updating on its own and being told about
    /// it are separate wishes, and neither is on until the user says so.
    private var autoUpdateSection: some View {
        Section {
            Toggle("LineData.AutoUpdate", isOn: $autoUpdate)
                .onChange(of: autoUpdate) { _, _ in
                    LineDataAutoUpdater.shared.settingsChanged()
                }
            Toggle("LineData.AutoUpdate.Notify", isOn: $notifyOnUpdate)
                .disabled(!autoUpdate)
                .onChange(of: notifyOnUpdate) { _, isOn in
                    guard isOn else { return }
                    Task {
                        // Denied permission would leave a switch on that can
                        // never fire anything.
                        notifyOnUpdate = await LineDataAutoUpdater.shared
                            .requestNotificationAuthorization()
                    }
                }
        } footer: {
            Text("LineData.AutoUpdate.Footer")
        }
    }

    // MARK: Update summary

    private var updateSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(installer.isFirstDownload ? "LineData.Update.First" : "LineData.Update.Title")
                .font(.title3.weight(.semibold))
            Text("LineData.Update.Meta \(installer.pending.count) \(LineDataModel.formatted(bytes: installer.pendingBytes))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            affectedLines
                .padding(.top, 6)
        }
        .padding(.vertical, 6)
    }

    /// Which lines the update touches, the way Software Update names what it
    /// contains. Lines already on the device are named by their plate; ones
    /// the device has never held, and ones whose plate carries no lettering,
    /// have nothing the user would recognise, so they are counted instead.
    /// One row only: a wall of plates stops being a summary. A first download
    /// is all of them, and says nothing.
    @ViewBuilder
    private var affectedLines: some View {
        if !installer.isFirstDownload {
            let held = installer.pending.map(\.line)
                .filter { LineDataStore.isDownloaded(folder: $0.folder) && !$0.symbol.isEmpty }
            let shown = held.prefix(rowCapacity)
            let others = installer.pending.count - shown.count
            HStack(spacing: Self.plateSpacing) {
                ForEach(shown) { line in
                    LineSymbolBadge(symbol: line.symbol, color: Color(hex: line.colorHex),
                                    dimension: Self.plateDimension, styleOverride: line.badgeStyle,
                                    lineId: line.id)
                }
                Spacer(minLength: 0)
            }
            .frame(height: Self.plateDimension)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.size.width, initial: true) { _, width in
                            rowCapacity = max(Int((width + Self.plateSpacing)
                                                  / (Self.plateDimension + Self.plateSpacing)), 0)
                        }
                }
            }
            if others > 0 {
                Text("LineData.Update.OtherLines \(others)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, shown.isEmpty ? 0 : 4)
            }
        }
    }

    // MARK: Action

    @ViewBuilder
    private var actionRow: some View {
        if let progress = installer.progress {
            LineDataProgressBlock(progress: progress)
                .padding(.vertical, 6)
        } else {
            Button("LineData.DownloadNow") {
                Task { await model.download() }
            }
            .disabled(installer.isChecking)
        }
    }
}
