import SwiftUI

// MARK: - Section Header

/// Title, optional collapse chevron, and a trailing `SectionAction` or
/// `SectionStatus`. Fixed height so headers align whatever the slot holds.
struct SectionHeader<Trailing: View>: View {
    let title: Title
    var collapsed: Bool?
    var onTitleTap: (() -> Void)?
    @ViewBuilder var trailing: Trailing

    /// Grows with the subheadline the header is set in, so tall text isn't clipped.
    @ScaledMetric(relativeTo: .subheadline) private var height: CGFloat = 22

    /// Operator names arrive already localized, so they bypass the key lookup.
    enum Title {
        case key(LocalizedStringKey)
        case verbatim(String)
    }

    var body: some View {
        let row = HStack(spacing: 8) {
            titleView
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 4)
        .frame(height: height)
        // The whole row toggles; a trailing button still wins the tap.
        if let onTitleTap {
            row
                .contentShape(Rectangle())
                .onTapGesture(perform: onTitleTap)
        } else {
            row
        }
    }

    @ViewBuilder
    private var titleView: some View {
        let label = HStack(spacing: 4) {
            Group {
                switch title {
                case .key(let key): Text(key)
                case .verbatim(let string): Text(string)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.secondary)
            if let collapsed {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(collapsed ? -90 : 0))
            }
        }
        if let onTitleTap {
            Button(action: onTitleTap) {
                label.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            label
        }
    }
}

extension SectionHeader {
    init(
        title: LocalizedStringKey,
        collapsed: Bool? = nil,
        onTitleTap: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title: .key(title), collapsed: collapsed, onTitleTap: onTitleTap, trailing: trailing)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(
        title: LocalizedStringKey,
        collapsed: Bool? = nil,
        onTitleTap: (() -> Void)? = nil
    ) {
        self.init(title: .key(title), collapsed: collapsed, onTitleTap: onTitleTap) { EmptyView() }
    }

    init(
        verbatim title: String,
        collapsed: Bool? = nil,
        onTitleTap: (() -> Void)? = nil
    ) {
        self.init(title: .verbatim(title), collapsed: collapsed, onTitleTap: onTitleTap) { EmptyView() }
    }
}

// MARK: - Trailing Slot

/// Tinted and tappable.
struct SectionAction: View {
    let icon: String
    let label: LocalizedStringKey
    var enabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(enabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// State a section reports but can't act on: never tinted, never tappable.
struct SectionStatus: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}
