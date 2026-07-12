import SwiftUI
import Backbone

// MARK: - Lines Section (browse all lines)

/// Home-screen section listing every train line grouped by operator, drawn as
/// a grid of tappable line badges. Tapping a line opens its station map.
struct LinesSection: View {
    @ObservedObject var viewModel: JourneyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tab.Lines")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            if viewModel.availableLines.isEmpty {
                emptyState
            } else {
                browseByLineGrid
            }
        }
        .task {
            await viewModel.loadLines()
        }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView()
                Text("Loading.Lines")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
            } else {
                Image(systemName: "tram")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                Text("Error.NoLinesAvailable")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
                Button("Button.Retry") {
                    Task { await viewModel.forceRefreshLines() }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var browseByLineGrid: some View {
        let grouped = Dictionary(grouping: viewModel.availableLines) { $0.operatorId }
        let knownOrder = [
            "Operator:JR-East",
            "Operator:TokyoMetro",
            "Operator:Toei",
            "Operator:Keisei",
            "Operator:Tobu",
            "Operator:Odakyu",
            "Operator:Tokyu",
            "Operator:Keikyu",
            "Operator:Keio",
            "Operator:Seibu",
            "Operator:Sotetsu",
            "Operator:Minatomirai",
            "Operator:SaitamaRailway",
            "Operator:TWR",
            "Operator:MIR",
            "Operator:TamaMonorail",
            "Operator:YokohamaMunicipal"
        ]
        // Operators missing from knownOrder still get a section at the end
        // instead of silently disappearing from the browser
        let sectionOrder = knownOrder.filter { grouped[$0] != nil }
            + grouped.keys.filter { !knownOrder.contains($0) }.sorted()
        let sectionTitles: [String: String] = [
            "Operator:JR-East": "JR",
            "Operator:TokyoMetro": "東京メトロ",
            "Operator:Toei": "都営",
            "Operator:Keisei": "京成",
            "Operator:Tobu": "東武",
            "Operator:Odakyu": "小田急",
            "Operator:Tokyu": "東急",
            "Operator:Keikyu": "京急",
            "Operator:Keio": "京王",
            "Operator:Seibu": "西武",
            "Operator:Sotetsu": "相鉄",
            "Operator:Minatomirai": "みなとみらい線",
            "Operator:SaitamaRailway": "埼玉高速鉄道",
            "Operator:TWR": "りんかい線",
            "Operator:MIR": "つくばエクスプレス",
            "Operator:TamaMonorail": "多摩都市モノレール",
            "Operator:YokohamaMunicipal": "横浜市営地下鉄"
        ]
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

        return LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(sectionOrder, id: \.self) { operatorId in
                if let lines = grouped[operatorId] {
                    // Symbol order (JA, JB, JC… / A, C, E…); symbol-less lines last
                    let sorted = lines.sorted {
                        switch ($0.lineSymbol.isEmpty, $1.lineSymbol.isEmpty) {
                        case (false, false):
                            return $0.lineSymbol == $1.lineSymbol
                                ? $0.localizedName < $1.localizedName
                                : $0.lineSymbol < $1.lineSymbol
                        case (false, true): return true
                        case (true, false): return false
                        case (true, true): return $0.localizedName < $1.localizedName
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(sectionTitles[operatorId] ?? operatorId)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(sorted) { line in
                                NavigationLink {
                                    StationPickerView(
                                        line: line,
                                        viewModel: viewModel
                                    )
                                } label: {
                                    lineCell(line: line)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func lineCell(line: TrainLine) -> some View {
        HStack(spacing: 10) {
            if !line.lineSymbol.isEmpty {
                LineSymbolBadge(
                    symbol: line.lineSymbol,
                    color: line.color,
                    dimension: 44
                )
            } else {
                RoundedRectangle(cornerRadius: 7)
                    .fill(line.color)
                    .frame(width: 44, height: 44)
            }

            HorizontallyFittedText(
                text: line.localizedName,
                font: .system(size: 12, weight: .semibold),
                alignment: .leading
            )
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .contentShape(Rectangle())
    }
}
