import SwiftUI
import Backbone

// MARK: - Lines Section (browse all lines)

/// Home-screen section listing every train line grouped by operator.
struct LinesSection: View {
    @ObservedObject var viewModel: JourneyViewModel
    @State private var expandedOperators: Set<String> = ["Operator:JR-East", "Operator:TokyoMetro"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tab.Lines")
                .font(.body.weight(.semibold))
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
                Image(systemName: "train.side.front.car")
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
        // Eager on purpose: lazy containers mis-estimate the collapsed
        // sections' heights and make the scroll offset jitter.
        VStack(alignment: .leading, spacing: 20) {
            ForEach(OperatorSections.sections(for: viewModel.availableLines), id: \.operatorId) { section in
                let isCollapsed = !expandedOperators.contains(section.operatorId)

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation(.smooth.speed(2.0)) {
                            if isCollapsed {
                                expandedOperators.insert(section.operatorId)
                            } else {
                                expandedOperators.remove(section.operatorId)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(section.title)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                            Spacer(minLength: 0)
                        }
                        .padding(.leading, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if !isCollapsed {
                        lineGrid(section.lines)
                            .transition(
                                .scale(0.96, anchor: .top)
                                    .combined(with: .opacity)
                                    .combined(with: .blurReplace)
                            )
                    }
                }
            }
        }
    }

    private func lineGrid(_ lines: [TrainLine]) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(stride(from: 0, to: lines.count, by: 2)), id: \.self) { start in
                HStack(alignment: .top, spacing: 10) {
                    lineCellLink(line: lines[start])
                    if start + 1 < lines.count {
                        lineCellLink(line: lines[start + 1])
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func lineCellLink(line: TrainLine) -> some View {
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
