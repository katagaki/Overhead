import SwiftUI
import Backbone

// MARK: - Route Setup Card

/// Planner-style route card shared by the journey planner and the favorite
/// editor: 出発/経由/到着 rows, swap/add-via controls, and the customization
/// icon row (walking speed, avoided lines, journey mode).
struct RouteSetupCard: View {
    let lines: [TrainLine]
    @Binding var fromSelection: StationSearchHit?
    @Binding var viaSelections: [StationSearchHit]
    @Binding var toSelection: StationSearchHit?
    @Binding var walkingSpeedRaw: String
    @Binding var avoidedLineIds: Set<String>
    /// Runs after any station row changes (the planner persists + invalidates).
    var onStationsChanged: () -> Void = {}
    /// Extra leading customization items (the planner's departure time).
    var leadingItems: AnyView?

    // Global preferences — the same settings the tracker reads live.
    @AppStorage(JourneyMode.storageKey) private var journeyMode = JourneyMode.hybrid
    @AppStorage(JourneyNotificationManager.enabledKey) private var notificationsEnabled = true
    @AppStorage(JourneyNotificationManager.leadMinutesKey)
    private var notificationLeadMinutes = JourneyNotificationManager.defaultLeadMinutes
    @State private var pickerTarget: PickerTarget?
    @State private var showAvoidLinesSheet = false

    static let maxViaCount = 3

    private enum PickerTarget: Identifiable {
        case from
        case to
        case via(Int)
        case addVia

        var id: String {
            switch self {
            case .from: return "from"
            case .to: return "to"
            case .via(let index): return "via\(index)"
            case .addVia: return "addVia"
            }
        }
    }

    private var walkingSpeed: WalkingSpeed {
        WalkingSpeed(rawValue: walkingSpeedRaw) ?? .normal
    }

    var body: some View {
        VStack(spacing: 0) {
            stationRows

            Divider()

            customizationRow
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .sheet(item: $pickerTarget) { target in
            NavigationStack {
                StationSearchSelectionView(
                    lines: lines,
                    showsCloseButton: true,
                    mergesStations: true
                ) { hit in
                    switch target {
                    case .from:
                        fromSelection = hit
                    case .to:
                        toSelection = hit
                    case .via(let index):
                        if viaSelections.indices.contains(index) {
                            viaSelections[index] = hit
                        }
                    case .addVia:
                        viaSelections.append(hit)
                    }
                    onStationsChanged()
                }
            }
        }
        .sheet(isPresented: $showAvoidLinesSheet) {
            AvoidLinesSheet(
                lines: lines,
                avoidedLineIds: $avoidedLineIds
            )
        }
    }

    private var stationRows: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                stationField(label: "Setup.From", selection: fromSelection) {
                    pickerTarget = .from
                }

                ForEach(Array(viaSelections.enumerated()), id: \.offset) { index, via in
                    fieldDivider
                    viaField(index: index, selection: via)
                }

                fieldDivider

                stationField(label: "Setup.To", selection: toSelection) {
                    pickerTarget = .to
                }
            }

            VStack(spacing: 10) {
                Button {
                    let from = fromSelection
                    fromSelection = toSelection
                    toSelection = from
                    viaSelections.reverse()
                    onStationsChanged()
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(fromSelection != nil || toSelection != nil ? .accentColor : .secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Setup.Swap")
                .disabled(fromSelection == nil && toSelection == nil)

                Button {
                    pickerTarget = .addVia
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(viaSelections.count < Self.maxViaCount ? .accentColor : .secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Setup.AddVia")
                .disabled(viaSelections.count >= Self.maxViaCount)
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private func viaField(index: Int, selection: StationSearchHit) -> some View {
        HStack(spacing: 10) {
            Button {
                pickerTarget = .via(index)
            } label: {
                HStack(spacing: 10) {
                    Text("Setup.Via")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 22)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(selection.station.localizedName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                viaSelections.remove(at: index)
                onStationsChanged()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Setup.RemoveVia")
        }
    }

    @ViewBuilder
    private func stationField(
        label: LocalizedStringKey,
        selection: StationSearchHit?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 22)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                if let selection {
                    Text(selection.station.localizedName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                } else {
                    Text("Setup.SelectStation")
                        .font(.system(size: 16))
                        .foregroundColor(Color(.tertiaryLabel))
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var fieldDivider: some View {
        HStack(spacing: 10) {
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 2.5, height: 2.5)
                }
            }
            .frame(width: 44)

            VStack { Divider() }
        }
        .frame(height: 10)
    }

    // MARK: - Customization Row

    private var customizationRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: CustomizationItem.spacing) {
                if let leadingItems {
                    leadingItems
                }
                walkingSpeedItem
                avoidLinesItem
                journeyModeItem
                notificationsItem
            }
            .padding(.horizontal, CustomizationItem.rowInset / 2)
            .padding(.vertical, 14)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
    }

    private var walkingSpeedItem: some View {
        Menu {
            Picker("Setup.WalkingSpeed", selection: Binding(
                get: { walkingSpeed },
                set: { walkingSpeedRaw = $0.rawValue }
            )) {
                ForEach(WalkingSpeed.allCases) { speed in
                    Label(speed.label, systemImage: speed.iconName).tag(speed)
                }
            }
        } label: {
            CustomizationItem(
                icon: walkingSpeed.iconName,
                label: "Setup.WalkingSpeed",
                active: walkingSpeed != .none
            )
        }
        .buttonStyle(.plain)
    }

    private var avoidLinesItem: some View {
        Button {
            showAvoidLinesSheet = true
        } label: {
            CustomizationItem(
                icon: "train.slash",
                label: "Setup.AvoidLines",
                active: !avoidedLineIds.isEmpty,
                iconSource: .asset
            )
        }
        .buttonStyle(.plain)
    }

    private var journeyModeItem: some View {
        Menu {
            Picker("Settings.Section.JourneyMode", selection: $journeyMode) {
                ForEach(JourneyMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.iconName).tag(mode)
                }
            }
        } label: {
            CustomizationItem(
                icon: journeyMode.iconName,
                label: "Settings.Section.JourneyMode",
                active: journeyMode != .hybrid
            )
        }
        .buttonStyle(.plain)
    }

    /// 0 stands for オフ; anything else is the lead time in minutes.
    private var notificationLeadBinding: Binding<Int> {
        Binding(
            get: { notificationsEnabled ? notificationLeadMinutes : 0 },
            set: { minutes in
                notificationsEnabled = minutes != 0
                if minutes != 0 { notificationLeadMinutes = minutes }
            }
        )
    }

    private var notificationsItem: some View {
        Menu {
            Picker("Settings.Section.Notifications", selection: notificationLeadBinding) {
                Text("Settings.Notifications.Off").tag(0)
                ForEach(JourneyNotificationManager.leadMinuteOptions, id: \.self) { minutes in
                    Text("Settings.Notifications.LeadTime \(minutes)").tag(minutes)
                }
            }
        } label: {
            CustomizationItem(
                icon: notificationsEnabled ? "bell.badge" : "bell.slash",
                label: "Settings.Section.Notifications",
                active: notificationsEnabled
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Customization Item

struct CustomizationItem: View {
    let icon: String
    let label: LocalizedStringKey
    let active: Bool
    var iconSource: IconSource = .system

    static let spacing: CGFloat = 4
    static let rowInset: CGFloat = 20
    static let minWidth: CGFloat = 64
    static let maxWidth: CGFloat = 82

    enum IconSource {
        case system
        case asset
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(active ? Color.accentColor : Color(.tertiarySystemFill))
                switch iconSource {
                case .system:
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                case .asset:
                    Image(icon)
                        .font(.system(size: 20, weight: .semibold))
                }
            }
            .foregroundColor(active ? .white : .primary)
            .frame(width: 56, height: 56)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        // Sized so a 5th item peeks in at the trailing edge when the row
        // overflows; capped at 82 so wide layouts keep the normal size.
        .containerRelativeFrame(.horizontal) { length, _ in
            let usable = length - Self.rowInset - Self.spacing * 4
            return min(Self.maxWidth, max(Self.minWidth, usable / 4.5))
        }
        .contentShape(Rectangle())
    }
}
