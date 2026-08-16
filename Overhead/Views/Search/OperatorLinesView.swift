import SwiftUI
import Backbone

// MARK: - Operator Lines

/// Every line one operator runs, in the same 2-up grid the home catalog used.
struct OperatorLinesView: View {
    let operatorId: String
    @ObservedObject var viewModel: JourneyViewModel

    @State private var selectedLine: TrainLine?

    private var lines: [TrainLine] {
        OperatorSections.sections(for: viewModel.availableLines)
            .first { $0.operatorId == operatorId }?
            .lines ?? []
    }

    var body: some View {
        ScrollView {
            LineGrid(lines: lines) { line in
                selectedLine = line
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
