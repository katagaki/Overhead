import SwiftUI
import Backbone

// MARK: - Operator Lines

/// Every line one operator runs, in the same 2-up grid the home catalog used.
struct OperatorLinesView: View {
    let operatorId: String
    @ObservedObject var viewModel: JourneyViewModel

    @State private var selectedLine: TrainLine?

    private var groups: [(id: String, title: String?, lines: [TrainLine])] {
        OperatorSections.groups(forOperator: operatorId, lines: viewModel.availableLines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(groups, id: \.id) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        if let title = group.title {
                            Text(title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                        }
                        LineGrid(lines: group.lines) { line in
                            selectedLine = line
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(OperatorSections.title(for: operatorId))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedLine) { line in
            StationPickerView(line: line, viewModel: viewModel)
        }
    }
}
