import SwiftUI
import Backbone

// MARK: - Line Data Manager

struct LineDataManagerView: View {
    @StateObject private var model = LineDataModel()
    @ObservedObject private var installer = LineDataInstaller.shared
    @State private var expanded: Set<String> = []

    var body: some View {
        List {
            if !installer.staleLineIds.isEmpty {
                Section {
                    Button {
                        Task { try? await installer.updateStale() }
                    } label: {
                        LabeledContent {
                            Text("\(installer.staleLineIds.count)")
                        } label: {
                            Label("LineData.UpdatesAvailable", systemImage: "arrow.down.circle")
                        }
                    }
                }
            }

            ForEach(model.orderedOperators, id: \.self) { operatorId in
                operatorSection(operatorId)
            }

            Section {
                Button {
                    Task { await model.checkForUpdates() }
                } label: {
                    Label("LineData.CheckNow", systemImage: "arrow.clockwise")
                }
                if let checked = installer.lastChecked {
                    LabeledContent("LineData.LastChecked") {
                        Text(checked, style: .relative)
                    }
                }
                LabeledContent("LineData.Version") {
                    Text(Catalog.current.version).monospaced()
                }
            }
        }
        .navigationTitle("LineData.Title")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { installBar }
        .alert("LineData.Error", isPresented: .constant(model.error != nil)) {
            Button("Shared.OK") { model.error = nil }
        } message: {
            Text(model.error ?? "")
        }
    }

    @ViewBuilder
    private func operatorSection(_ operatorId: String) -> some View {
        let lines = model.lines(for: operatorId)
        let installed = lines.filter(model.isInstalled).count

        Section {
            if expanded.contains(operatorId) {
                ForEach(lines) { line in
                    lineRow(line)
                }
            }
        } header: {
            Button {
                if expanded.contains(operatorId) { expanded.remove(operatorId) }
                else { expanded.insert(operatorId) }
            } label: {
                HStack {
                    Image(systemName: expanded.contains(operatorId) ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Text(OperatorSections.title(for: operatorId))
                    Spacer()
                    Text("\(installed)/\(lines.count)")
                        .monospacedDigit()
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func lineRow(_ line: CatalogLine) -> some View {
        let installed = model.isInstalled(line)
        let downloading = installer.inFlight.contains(line.id)

        HStack(spacing: 10) {
            LineSymbolBadge(symbol: line.symbol, color: Color(hex: line.colorHex),
                            dimension: 26, styleOverride: line.badgeStyle)
            VStack(alignment: .leading, spacing: 1) {
                Text(line.localizedName)
                Text(LineDataModel.formatted(bytes: line.bytes))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()

            if downloading {
                DownloadDonut(progress: installer.progress[line.id] ?? 0)
            } else if installed {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("LineData.Installed")
            } else {
                Button {
                    model.toggle(line)
                } label: {
                    Image(systemName: model.selection.contains(line.id)
                          ? "icloud.and.arrow.down.fill" : "icloud.and.arrow.down")
                        .font(.system(size: 17))
                        .foregroundStyle(model.selection.contains(line.id)
                                         ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("LineData.Download")
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            if installed {
                Button(role: .destructive) {
                    model.remove(line)
                } label: {
                    Label("LineData.Remove", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private var installBar: some View {
        if !model.selection.isEmpty {
            VStack(spacing: 8) {
                Button {
                    Task { await model.install() }
                } label: {
                    HStack {
                        if model.isWorking { ProgressView().tint(.white) }
                        Text("LineData.Install \(model.selection.count)")
                        Text(LineDataModel.formatted(bytes: model.selectedBytes))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isWorking)
            }
            .padding()
            .background(.regularMaterial)
        }
    }
}

// MARK: - Progress Donut

/// Determinate ring with a stop square, the shape iOS uses for downloads.
struct DownloadDonut: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 2)
            Circle()
                .trim(from: 0, to: max(0.02, min(1, progress)))
                .stroke(Color.accentColor,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
        }
        .frame(width: 20, height: 20)
        .accessibilityLabel("LineData.Downloading")
    }
}
