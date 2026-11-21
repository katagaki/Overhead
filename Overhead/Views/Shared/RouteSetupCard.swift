import SwiftUI
import UserNotifications
import Backbone

// MARK: - Route Setup Card

/// 出発/経由/到着 rows, swap/add-via controls and the customization row,
/// shared by the journey planner and the favorite editor.
struct RouteSetupCard: View {
    let lines: [TrainLine]
    @Binding var fromSelection: RouteEndpoint?
    @Binding var viaSelections: [StationSearchHit]
    @Binding var toSelection: RouteEndpoint?
    @Binding var walkingSpeedRaw: String
    @Binding var routePriorityRaw: String
    /// 始発優先 — float trains that start at the boarding station to the top.
    @Binding var preferOriginating: Bool
    @Binding var avoidedLineIds: Set<String>
    /// Runs after any station row changes (the planner persists + invalidates).
    var onStationsChanged: () -> Void = {}
    /// 出発/到着 can be 現在地 or a landmark, not just a station.
    var allowsPlaces = false
    /// Extra leading customization items (the planner's departure time).
    var leadingItems: AnyView?

    // Global preferences — the same settings the tracker reads live.
    @AppStorage(JourneyMode.storageKey) private var journeyMode = JourneyMode.hybrid
    @AppStorage(JourneyNotificationManager.enabledKey) private var notificationsEnabled = true
    @AppStorage(JourneyNotificationManager.leadMinutesKey)
    private var notificationLeadMinutes = JourneyNotificationManager.defaultLeadMinutes
    @AppStorage(NotificationSound.storageKey) private var notificationSound = NotificationSound.system
    @State private var pickerTarget: PickerTarget?
    @ScaledMetric(relativeTo: .caption2) private var tagWidth: CGFloat = 44
    @ScaledMetric(relativeTo: .caption2) private var tagHeight: CGFloat = 22
    @ScaledMetric(relativeTo: .subheadline) private var roundButtonSize: CGFloat = 36
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var notificationsDenied = false
    @Environment(\.scenePhase) private var scenePhase
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

        func searchTitle(allowsPlaces: Bool) -> LocalizedStringKey {
            switch self {
            case .from: return allowsPlaces ? "StationSearch.Title.From.Place" : "StationSearch.Title.From"
            case .to: return allowsPlaces ? "StationSearch.Title.To.Place" : "StationSearch.Title.To"
            case .via, .addVia: return "StationSearch.Title.Via"
            }
        }
    }

    private var walkingSpeed: WalkingSpeed {
        WalkingSpeed(rawValue: walkingSpeedRaw) ?? .normal
    }

    private var routePriority: RoutePriority {
        RoutePriority(rawValue: routePriorityRaw) ?? .balanced
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
                    title: target.searchTitle(allowsPlaces: allowsPlaces),
                    showsCloseButton: true,
                    mergesStations: true,
                    onSelectPlace: placeHandler(for: target)
                ) { hit in
                    switch target {
                    case .from:
                        fromSelection = .station(hit)
                    case .to:
                        toSelection = .station(hit)
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

    private func placeHandler(for target: PickerTarget) -> ((RouteEndpoint) -> Void)? {
        guard allowsPlaces else { return nil }
        switch target {
        case .from:
            return { fromSelection = $0; onStationsChanged() }
        case .to:
            return { toSelection = $0; onStationsChanged() }
        case .via, .addVia:
            return nil
        }
    }

    @ViewBuilder
    private var stationRows: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .trailing, spacing: 10) {
                stationFields
                HStack(spacing: 10) {
                    swapButton
                    addViaButton
                }
            }
            .padding(14)
        } else {
            HStack(spacing: 12) {
                stationFields
                VStack(spacing: 10) {
                    swapButton
                    addViaButton
                }
            }
            .padding(14)
        }
    }

    private var stationFields: some View {
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
    }

    private var swapButton: some View {
        Button {
            let from = fromSelection
            fromSelection = toSelection
            toSelection = from
            viaSelections.reverse()
            onStationsChanged()
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .scaledFont(size: 15, weight: .semibold)
                .foregroundColor(fromSelection != nil || toSelection != nil ? .accentColor : .secondary)
                .frame(width: roundButtonSize, height: roundButtonSize)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())
        }
        .accessibilityLabel("Setup.Swap")
        .disabled(fromSelection == nil && toSelection == nil)
    }

    private var addViaButton: some View {
        Button {
            pickerTarget = .addVia
        } label: {
            Image(systemName: "plus")
                .scaledFont(size: 15, weight: .semibold)
                .foregroundColor(viaSelections.count < Self.maxViaCount ? .accentColor : .secondary)
                .frame(width: roundButtonSize, height: roundButtonSize)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())
        }
        .accessibilityLabel("Setup.AddVia")
        .disabled(viaSelections.count >= Self.maxViaCount)
    }

    @ViewBuilder
    private func viaField(index: Int, selection: StationSearchHit) -> some View {
        HStack(spacing: 10) {
            Button {
                pickerTarget = .via(index)
            } label: {
                fieldRow(label: "Setup.Via") {
                    Text(selection.station.localizedName)
                        .scaledFont(size: 17, weight: .semibold)
                        .foregroundColor(.primary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
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
                    .scaledFont(size: 18)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Setup.RemoveVia")
        }
    }

    @ViewBuilder
    private func stationField(
        label: LocalizedStringKey,
        selection: RouteEndpoint?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            fieldRow(label: label) {
                if let selection {
                    endpointLabel(selection)
                        .scaledFont(size: 17, weight: .semibold)
                        .foregroundColor(.primary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        .id(selection.id)
                        .transition(.scale(0.9, anchor: .leading).combined(with: .blurReplace))
                } else {
                    Text("Setup.SelectStation")
                        .scaledFont(size: 16)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Label chip beside the value; above it at accessibility sizes so the value keeps the full row.
    @ViewBuilder
    private func fieldRow(label: LocalizedStringKey, @ViewBuilder value: () -> some View) -> some View {
        let chip = Text(label)
            .scaledFont(size: 11, weight: .medium)
            .foregroundColor(.secondary)
            .frame(width: tagWidth, height: tagHeight)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                chip
                value()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 10) {
                chip
                value()
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func endpointLabel(_ endpoint: RouteEndpoint) -> some View {
        switch endpoint {
        case .station(let hit):
            Text(hit.station.localizedName)
        case .currentLocation:
            Label("StationSearch.CurrentLocation", systemImage: "location.fill")
                .labelStyle(EndpointLabelStyle())
        case .place(let place):
            Label(place.name, systemImage: "mappin")
                .labelStyle(EndpointLabelStyle())
        }
    }

    @ViewBuilder
    private var fieldDivider: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Divider()
                .padding(.vertical, 4)
        } else {
            dottedDivider
        }
    }

    private var dottedDivider: some View {
        HStack(spacing: 10) {
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 2.5, height: 2.5)
                }
            }
            .frame(width: tagWidth)

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
                routePriorityItem
                walkingSpeedItem
                preferOriginatingItem
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

    private var routePriorityItem: some View {
        Menu {
            Picker("Setup.RoutePriority", selection: Binding(
                get: { routePriority },
                set: { routePriorityRaw = $0.rawValue }
            )) {
                ForEach(RoutePriority.allCases) { priority in
                    Label {
                        Text(priority.label)
                        Text(priority.detail)
                    } icon: {
                        Image(systemName: priority.iconName)
                    }
                    .tag(priority)
                }
            }
        } label: {
            CustomizationItem(
                icon: routePriority.iconName,
                label: "Setup.RoutePriority",
                active: routePriority != .balanced
            )
        }
        .buttonStyle(.plain)
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

    private var preferOriginatingItem: some View {
        Menu {
            Picker("Setup.PreferOriginating", selection: $preferOriginating) {
                Text("Setup.PreferOriginating.Off").tag(false)
                Text("Setup.PreferOriginating.On").tag(true)
            }
        } label: {
            CustomizationItem(
                icon: "carseat.left.fill",
                label: "Setup.PreferOriginating",
                active: preferOriginating
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

    /// Previews on selection. Set through a binding rather than `.onChange` so it
    /// only fires on a deliberate pick, not on any write to the preference.
    private var notificationSoundBinding: Binding<NotificationSound> {
        Binding(
            get: { notificationSound },
            set: { sound in
                notificationSound = sound
                NotificationSoundPreview.shared.play(sound)
            }
        )
    }

    /// Nested menu so the sound sits under the lead time without crowding the
    /// customization row with a second item.
    private var notificationSoundMenu: some View {
        Menu {
            // Two pickers sharing one binding, rather than one picker with
            // Sections: a menu flattens Sections inside a Picker and draws no
            // rule, but it does honour a Divider between sibling elements.
            // Making no sound is a different kind of choice from picking which
            // sound, and the rule is what says so.
            Picker("Settings.Notifications.Sound", selection: notificationSoundBinding) {
                Text("Settings.Notifications.Sound.Silent")
                    .tag(NotificationSound.silent)
            }
            .pickerStyle(.inline)

            Divider()

            Picker("Settings.Notifications.Sound", selection: notificationSoundBinding) {
                Text("Settings.Notifications.Sound.System")
                    .tag(NotificationSound.system)
                ForEach([NotificationSound.Category.melody, .arrangement, .chime]) { category in
                    Section(category.label) {
                        ForEach(NotificationSound.cases(in: category)) { sound in
                            Text(verbatim: sound.title).tag(sound)
                        }
                    }
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label("Settings.Notifications.Sound", systemImage: "speaker.wave.2")
        }
        // Nothing to choose while alerts are off.
        .disabled(!notificationsEnabled)
    }

    private var notificationsItem: some View {
        Menu {
            if notificationsDenied {
                Section("Settings.Notifications.Denied") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        Link(destination: url) {
                            Label("Button.OpenSettings", systemImage: "gear")
                        }
                    }
                }
            }
            Picker("Settings.Section.Notifications", selection: notificationLeadBinding) {
                Text("Settings.Notifications.Off").tag(0)
                ForEach(JourneyNotificationManager.leadMinuteOptions, id: \.self) { minutes in
                    Text("Settings.Notifications.LeadTime \(minutes)").tag(minutes)
                }
            }
            notificationSoundMenu
        } label: {
            CustomizationItem(
                icon: notificationsEnabled && !notificationsDenied ? "bell.badge" : "bell.slash",
                label: "Settings.Section.Notifications",
                active: notificationsEnabled && !notificationsDenied
            )
        }
        .buttonStyle(.plain)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            notificationsDenied = status == .denied
        }
    }
}

// MARK: - Endpoint Label Style

/// A small tinted glyph marks an endpoint that isn't a station.
private struct EndpointLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon
                .scaledFont(size: 13, weight: .semibold)
                .foregroundColor(.accentColor)
            configuration.title
        }
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
    private static let circleSize: CGFloat = 56

    @ScaledMetric(relativeTo: .title3) private var circleSize: CGFloat = Self.circleSize
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Capped at accessibility sizes, like the label, so the row stays a row.
    private var shownCircleSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? min(circleSize, Self.circleSize * 1.7) : circleSize
    }

    enum IconSource {
        case system
        case asset
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            // One unbroken line per label; the row scrolls, so the item widens instead.
            content(labelLines: 1)
                .fixedSize()
                .frame(minWidth: shownCircleSize)
                .padding(.horizontal, 6)
                .contentShape(Rectangle())
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        } else {
            content(labelLines: 2)
                // Sized so a 5th item peeks in when the row overflows; grows with the text.
                .containerRelativeFrame(.horizontal) { length, _ in
                    let growth = circleSize / Self.circleSize
                    let usable = length - Self.rowInset - Self.spacing * 4
                    return min(Self.maxWidth * growth, max(Self.minWidth * growth, usable / 4.5))
                }
                .contentShape(Rectangle())
        }
    }

    private func content(labelLines: Int) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(active ? Color.accentColor : Color(.tertiarySystemFill))
                switch iconSource {
                case .system:
                    Image(systemName: icon)
                        .scaledFont(size: 20, weight: .semibold)
                case .asset:
                    Image(icon)
                        .scaledFont(size: 20, weight: .semibold)
                }
            }
            .foregroundColor(active ? .white : .primary)
            .frame(width: shownCircleSize, height: shownCircleSize)

            Text(label)
                .scaledFont(size: 11, weight: .medium)
                .foregroundColor(.secondary)
                .lineLimit(labelLines)
                .multilineTextAlignment(.center)
        }
    }
}
