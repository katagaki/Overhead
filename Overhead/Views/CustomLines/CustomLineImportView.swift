import SwiftUI
import Backbone

// MARK: - Import Preview

struct CustomLineImportView: View {
    let package: CustomLinePackage
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CustomLineStore.shared

    private var conflicts: [String] {
        let existing = Set(store.lines.map(\.id))
        return package.lines.filter { existing.contains($0.id) }.map { $0.localizedName }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(package.lines) { line in
                        HStack(spacing: 12) {
                            LineSymbolBadge(symbol: line.symbol.isEmpty ? "＋" : line.symbol,
                                            color: line.color, dimension: 36,
                                            styleOverride: line.badgeStyle)
                            VStack(alignment: .leading, spacing: 1) {
                                (line.localizedName.isEmpty ? Text("CustomLine.Unnamed") : Text(verbatim: line.localizedName))
                                    .font(.system(size: 16, weight: .medium))
                                Text(verbatim: contentSummary(line))
                                    .font(.system(size: 12.5))
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                } header: {
                    Text("CustomLine.Import.Contents")
                } footer: {
                    if let author = package.author, !author.isEmpty {
                        Text("CustomLine.Import.Author \(author)")
                    }
                }

                if !conflicts.isEmpty {
                    Section {
                        Label {
                            if conflicts.count == 1 {
                                Text("CustomLine.Import.ConflictOne \(conflicts[0])")
                            } else {
                                Text("CustomLine.Import.ConflictMany \(conflicts.count)")
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        .font(.system(size: 13))
                    }
                }
            }
            .navigationTitle(Text("CustomLine.Import.Title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Text("Button.Cancel") }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    store.importLines(package.lines)
                    dismiss()
                } label: {
                    (package.lines.count == 1
                     ? Text("CustomLine.Import.AddOne")
                     : Text("CustomLine.Import.AddMany \(package.lines.count)"))
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .disabled(package.lines.isEmpty)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func contentSummary(_ line: CustomLine) -> String {
        var parts = [String(localized: "CustomLine.StationCount \(line.stations.count)")]
        if line.hasSchedule { parts.append(String(localized: "CustomLine.Timetable")) }
        if line.hasAllCoordinates { parts.append("GPS") }
        return parts.joined(separator: " · ")
    }
}
