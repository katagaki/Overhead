import SwiftUI
import Backbone

/// The whole app on one scrolling surface: planner, favorites, and lines to browse.
struct RootView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @ObservedObject private var customStore = CustomLineStore.shared

    @AppStorage(JourneyMode.storageKey) private var journeyMode = JourneyMode.hybrid
    @AppStorage("hasDismissedStartupNotice") private var hasDismissedStartupNotice = false
    @AppStorage(JourneyNotificationManager.enabledKey) private var notificationsEnabled = true
    @AppStorage(JourneyNotificationManager.leadMinutesKey)
    private var notificationLeadMinutes = JourneyNotificationManager.defaultLeadMinutes
    @State private var showJourneySheet = false
    @State private var showTimetableModeNotice = false
    @State private var showStartupNotice = false
    @State private var navigationPath = NavigationPath()
    @StateObject private var serviceStatusPresenter = ServiceStatusPresenter()
#if DEBUG
    // Screenshot harness (overtrain:// deep links, see ScreenshotHarness.swift).
    @State private var debugTimetableTarget: ScreenshotTimetableTarget?
#endif
    @Namespace private var journeyZoom

    private static let journeyTransitionID = "activeJourney"
    private static let feedbackURL = URL(string: "https://forms.gle/U91cFDFTufF12PeF7")!

    // Pushed screens reachable from the root.
    private enum Destination: Hashable {
        case attributions
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 24) {
                        JourneyPlannerSection(viewModel: viewModel)
                        FavoritesSection(viewModel: viewModel)
                        LinesSection(viewModel: viewModel)
                            .id("lines")
                        CustomLinesSection(viewModel: viewModel)
                            .id("custom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
#if DEBUG
                .onReceive(ScreenshotStaging.shared.$homeScrollTarget) { target in
                    guard let target else { return }
                    ScreenshotStaging.shared.homeScrollTarget = nil
                    scrollProxy.scrollTo(target, anchor: .top)
                }
#endif
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("App.Name"))
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    moreMenu
                }
            }
            // Safe-area inset, not .bottomBar: late-inserted bottom-bar items don't show with a navigationDestination on the stack (iOS 26).
            .safeAreaInset(edge: .bottom) {
                if viewModel.activeJourney != nil {
                    JourneyToolbarAccessory(viewModel: viewModel) {
                        showJourneySheet = true
                    }
                    .padding(.vertical, 12)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    .matchedTransitionSource(id: Self.journeyTransitionID, in: journeyZoom)
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .attributions:
                    MoreAttributionsView()
                }
            }
            .navigationDestination(for: CustomLineRoute.self) { route in
                CustomLineEditorView(route: route)
            }
#if DEBUG
            .navigationDestination(for: ScreenshotLineTarget.self) { target in
                if let line = viewModel.availableLines.first(where: { $0.id == target.lineId }) {
                    StationPickerView(line: line, viewModel: viewModel)
                }
            }
#endif
            .task {
                await viewModel.loadLines()
#if DEBUG
                // Headless capture passes overtrain:// URLs as launch arguments,
                // since simctl openurl trips the system open-app confirmation.
                for argument in ProcessInfo.processInfo.arguments.dropFirst()
                where argument.hasPrefix("overtrain://") {
                    if let url = URL(string: argument) {
                        await handleScreenshotURL(url)
                    }
                }
                // TEMP notification verification
                if ProcessInfo.processInfo.arguments.contains("-notifTest") {
                    let names = ["東京", "自由が丘"]
                    let found = viewModel.searchTrainCandidates(stationNames: names, departure: Date())
                    print("[NOTIF] candidates=\(found.count)")
                    if let pick = found.first(where: { $0.transferCount > 0 }) ?? found.first {
                        print("[NOTIF] legs=\(pick.legs.map { "\($0.line.name):\($0.fromStation.name)→\($0.toStation.name) \($0.departureTime)-\($0.arrivalTime)" })")
                        viewModel.startJourney(candidate: pick)
                    }
                }
#endif
            }
        }
        .serviceStatusHost(serviceStatusPresenter)
        .sheet(isPresented: $showJourneySheet) {
            JourneySheetView(viewModel: viewModel)
                .navigationTransition(.zoom(sourceID: Self.journeyTransitionID, in: journeyZoom))
        }
        .sheet(item: $customStore.incomingPackage) { package in
            CustomLineImportView(package: package)
        }
#if DEBUG
        .onOpenURL { url in
            Task { await handleScreenshotURL(url) }
        }
        .sheet(item: $debugTimetableTarget) { target in
            if let line = viewModel.availableLines.first(where: { $0.id == target.lineId }),
               let station = line.stations.first(where: { $0.id == target.stationId }) {
                NavigationStack {
                    StationTimetableView(station: station, line: line, viewModel: viewModel)
                }
            }
        }
#endif
        // Keeps the PiP sample-buffer layer in the hierarchy while the
        // journey sheet is closed; the sheet's LCD hosts it otherwise so the
        // PiP restore animation lands on the LCD.
        .background {
            if !showJourneySheet {
                LCDPiPLayerHost()
                    .frame(width: 1, height: 1)
            }
        }
        .onChange(of: viewModel.activeJourney != nil) { _, hasJourney in
            guard hasJourney else {
                showJourneySheet = false
                LCDPiPManager.shared.teardown()
                return
            }
            LCDPiPManager.shared.prepare { [weak viewModel] in
                viewModel?.renderLCDImage(scale: 2, padded: false)
            }
            DispatchQueue.main.async { showJourneySheet = true }
        }
        .onChange(of: viewModel.positionState?.status) { _, status in
            LCDPiPManager.shared.setAutoStartAllowed(status != .arrived)
        }
        // Overwriting keeps activeJourney non-nil, so onChange won't fire — open here.
        .alert(
            "Journey.Overwrite.ConfirmTitle",
            isPresented: $viewModel.showOverwriteConfirmation
        ) {
            Button("Button.Overwrite", role: .destructive) {
                viewModel.confirmOverwrite()
                showJourneySheet = true
            }
            Button("Button.Cancel", role: .cancel) {
                viewModel.cancelOverwrite()
            }
        } message: {
            Text("Journey.Overwrite.ConfirmMessage")
        }
        .onChange(of: notificationsEnabled) { _, _ in
            viewModel.rescheduleNotifications()
        }
        .onChange(of: notificationLeadMinutes) { _, _ in
            viewModel.rescheduleNotifications()
        }
        // Timetable mode keeps a low-power location session so the app isn't suspended.
        .onChange(of: journeyMode) { _, newMode in
            if newMode == .timetable { showTimetableModeNotice = true }
        }
        .alert(
            "JourneyMode.TimetableNotice.Title",
            isPresented: $showTimetableModeNotice
        ) {} message: {
            Text("JourneyMode.TimetableNotice.Message")
        }
        // Solo-developer disclaimer, shown until the user opts out.
        .alert(
            "StartupNotice.Title",
            isPresented: $showStartupNotice
        ) {
            Button("Button.OK", role: .cancel) {}
            Button("Button.DontShowAgain") {
                hasDismissedStartupNotice = true
            }
        } message: {
            Text("StartupNotice.Message")
        }
        .onAppear {
            if !hasDismissedStartupNotice {
                showStartupNotice = true
            }
        }
    }

    // MARK: - More Menu

    private var moreMenu: some View {
        Menu {
            Section("Settings.Section.JourneyMode") {
                Picker("Settings.Section.JourneyMode", selection: $journeyMode) {
                    ForEach(JourneyMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            }
            .labelsVisibility(.visible)

            Section("Settings.Section.Notifications") {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Settings.Notifications.Enabled", systemImage: "bell.badge")
                }
                Picker("Settings.Notifications.LeadTime", selection: $notificationLeadMinutes) {
                    ForEach(JourneyNotificationManager.leadMinuteOptions, id: \.self) { minutes in
                        Text("Settings.Notifications.LeadTime \(minutes)").tag(minutes)
                    }
                }
                .disabled(!notificationsEnabled)
            }

            if viewModel.activeJourney != nil {
                Section("Settings.Section.CurrentJourney") {
                    Button(role: .destructive) {
                        viewModel.stopJourney()
                    } label: {
                        Label("Button.EndJourney", systemImage: "stop.circle.fill")
                    }
                }
            }

            Section {
                Link(destination: Self.feedbackURL) {
                    Label("More.SendFeedback", systemImage: "exclamationmark.bubble")
                }
                Link(destination: URL(string: "https://github.com/katagaki/Overhead")!) {
                    Label("More.GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Button("More.Attributions") {
                    navigationPath.append(Destination.attributions)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel("ViewTitle.More")
    }

#if DEBUG
    // MARK: - Screenshot Harness (overtrain://)

    private func handleScreenshotURL(_ url: URL) async {
        guard let command = ScreenshotCommand(url: url) else { return }
        await viewModel.loadLines()
        switch command {
        case .seedFavorites:
            ScreenshotSeeder.seedFavorites()
        case .seedCustomLine:
            ScreenshotSeeder.seedCustomLine()
        case .lcdStyle(let style):
            UserDefaults.standard.set(style, forKey: TrainLCDStyle.storageKey)
        case .journey(let lineId, let fromId, let toId, let minutesAgo):
            await viewModel.debugStartJourney(
                lineId: lineId, fromId: fromId, toId: toId, minutesAgo: minutesAgo
            )
        case .plannerSearch:
            ScreenshotStaging.shared.plannerCommand = .search
        case .plannerAvoid:
            ScreenshotStaging.shared.plannerCommand = .avoid
        case .plannerDeparture:
            ScreenshotStaging.shared.plannerCommand = .departure
        case .timetable(let target, let hidePast):
            ScreenshotStaging.shared.hidePastDepartures = hidePast
            viewModel.loadStationTimetable(stationId: target.stationId)
            try? await Task.sleep(for: .seconds(1))
            debugTimetableTarget = target
        case .linePage(let target):
            ScreenshotStaging.shared.expandServiceStatus = target.expandStatus
            ScreenshotStaging.shared.serviceStatusShowsX = target.showX
            navigationPath.append(target)
        case .customLineEditor:
            ScreenshotSeeder.seedCustomLine()
            try? await Task.sleep(for: .seconds(0.5))
            navigationPath.append(CustomLineRoute.edit(ScreenshotSeeder.customLineId))
        case .homeScroll(let anchor):
            try? await Task.sleep(for: .seconds(1))
            ScreenshotStaging.shared.homeScrollTarget = anchor
        case .placeEditor(let editFirst):
            try? await Task.sleep(for: .seconds(0.5))
            ScreenshotStaging.shared.placeEditorCommand = editFirst ? .editFirst : .new
        case .reset:
            viewModel.stopJourney()
            debugTimetableTarget = nil
            navigationPath = NavigationPath()
            UserDefaults.standard.removeObject(forKey: "journey.setup.stations")
            UserDefaults.standard.removeObject(forKey: "journey.avoidedLines")
        }
    }
#endif
}
