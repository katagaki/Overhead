import SwiftUI
import UniformTypeIdentifiers
import Backbone

// MARK: - Navigation route for the custom-line editor

enum CustomLineRoute: Hashable {
    case new
    case edit(String)   // line id
}

// MARK: - マイ路線 Section (home)

struct CustomLinesSection: View {
    @ObservedObject var viewModel: JourneyViewModel
    @ObservedObject private var store = CustomLineStore.shared
    @State private var showImporter = false
    @State private var importError: String?
    @State private var pendingImport: CustomLinePackage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "マイ路線")
                .font(.body.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(store.lines) { line in
                    NavigationLink(value: CustomLineRoute.edit(line.id)) {
                        row(for: line)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 60)
                }

                NavigationLink(value: CustomLineRoute.new) {
                    actionRow(title: "新しい路線を作成", systemImage: "plus")
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 60)

                Button {
                    showImporter = true
                } label: {
                    actionRow(title: ".ohlファイルを取り込む", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.plain)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.overheadLine, .json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .sheet(item: $pendingImport) { package in
            CustomLineImportView(package: package)
        }
        .alert(Text(verbatim: "取り込みに失敗しました"), isPresented: .constant(importError != nil)) {
            Button(role: .cancel) { importError = nil } label: { Text(verbatim: "OK") }
        } message: {
            Text(verbatim: importError ?? "")
        }
    }

    // MARK: Rows

    private func row(for line: CustomLine) -> some View {
        HStack(spacing: 12) {
            LineSymbolBadge(symbol: line.symbol.isEmpty ? "＋" : line.symbol, color: line.color,
                            dimension: 36, styleOverride: line.badgeStyle)

            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: line.localizedName.isEmpty ? "無名の路線" : line.localizedName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(verbatim: subtitle(for: line))
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                ride(line)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(line.stations.count >= 2 ? line.color : Color(.tertiaryLabel), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(line.stations.count < 2)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func actionRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.accentColor)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.14), in: Circle())
            Text(verbatim: title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentColor)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func subtitle(for line: CustomLine) -> String {
        var parts = ["\(line.stations.count)駅"]
        parts.append(line.hasSchedule ? "時刻表あり" : "時刻表なし")
        if line.hasAllCoordinates { parts.append("GPSあり") }
        return parts.joined(separator: " · ")
    }

    // MARK: Actions

    private func ride(_ line: CustomLine) {
        guard let first = line.stations.first, let last = line.stations.last,
              first.id != last.id else { return }
        viewModel.startCustomJourney(line: line, fromId: first.id, toId: last.id)
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsScope = url.startAccessingSecurityScopedResource()
            defer { if needsScope { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                pendingImport = try JSONDecoder().decode(CustomLinePackage.self, from: data)
            } catch {
                importError = error.localizedDescription
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}

extension CustomLinePackage: Identifiable {
    public var id: String { lines.map(\.id).joined(separator: "+") }
}
