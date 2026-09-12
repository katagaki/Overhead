import SwiftUI
import Backbone

// MARK: - Search Section (home)

/// The home entry point to the catalog: one search field, three ways in.
/// The sheet closes before the selection is pushed, so the destination lands
/// on the root stack rather than inside the sheet.
struct SearchSection: View {
    @ObservedObject var viewModel: JourneyViewModel
    let onSelect: (SearchDestination) -> Void

    @State private var searchScope: SearchScope?
    @State private var pendingDestination: SearchDestination?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Search.Title")

            searchField

            HStack(spacing: 10) {
                chip(.operators)
                chip(.lines)
                chip(.stations)
            }
        }
        .sheet(item: $searchScope, onDismiss: pushPendingDestination) { scope in
            SearchSheet(lines: viewModel.availableLines, initialScope: scope) { destination in
                pendingDestination = destination
            }
        }
        .task {
            await viewModel.loadLines()
        }
    }

    private func pushPendingDestination() {
        guard let destination = pendingDestination else { return }
        pendingDestination = nil
        onSelect(destination)
    }

    /// Presented by scope rather than a flag: the sheet body is built from the
    /// item, so the chip's scope always reaches it and each scope gets its own
    /// view identity.
    private func open(_ scope: SearchScope) {
        searchScope = scope
    }

    // MARK: - Field

    private var searchField: some View {
        Button {
            open(.all)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("Search.Prompt")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chips

    private func chip(_ scope: SearchScope) -> some View {
        Button {
            open(scope)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: scope.icon)
                    .font(.system(size: 15, weight: .semibold))
                Text(scope.title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
