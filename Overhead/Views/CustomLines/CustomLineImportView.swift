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
                                Text(verbatim: line.localizedName.isEmpty ? "無名の路線" : line.localizedName)
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
                    Text(verbatim: "取り込む内容")
                } footer: {
                    if let author = package.author, !author.isEmpty {
                        Text(verbatim: "作者：\(author)")
                    }
                }

                if !conflicts.isEmpty {
                    Section {
                        Label {
                            Text(verbatim: conflicts.count == 1
                                 ? "「\(conflicts[0])」は既にあります。取り込むと置き換えられます。"
                                 : "\(conflicts.count)件の路線が既にあり、置き換えられます。")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        .font(.system(size: 13))
                    }
                }
            }
            .navigationTitle(Text(verbatim: "路線を取り込む"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Text(verbatim: "キャンセル") }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    store.importLines(package.lines)
                    dismiss()
                } label: {
                    Text(verbatim: package.lines.count == 1 ? "1路線を追加" : "\(package.lines.count)路線を追加")
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
        var parts = ["\(line.stations.count)駅"]
        if line.hasSchedule { parts.append("時刻表") }
        if line.hasAllCoordinates { parts.append("GPS") }
        return parts.joined(separator: " · ")
    }
}
