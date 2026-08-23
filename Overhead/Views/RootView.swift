import SwiftUI
import Backbone

/// The whole app on one scrolling surface: planner, favorites, and lines to browse.
struct RootView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @ObservedObject private var customStore = CustomLineStore.shared
    @ObservedObject private var lineDataInstaller = LineDataInstaller.shared

    @AppStorage(JourneyMode.storageKey) private var journeyMode = JourneyMode.hybrid
    @AppStorage("hasDismissedStartupNotice") private var hasDismissedStartupNotice = false
    @AppStorage(JourneyNotificationManager.enabledKey) private var notificationsEnabled = true
    @AppStorage(JourneyNotificationManager.leadMinutesKey)
    private var notificationLeadMinutes = JourneyNotificationManager.defaultLeadMinutes
    @State private var showJourneySheet = false
    @State private var showTimetableModeNotice = false
    @State private var showStartupNotice = false
    @State private var showDisclaimer = false
    @State private var navigationPath = NavigationPath()
    /// Measured width; toolbar items can't resolve `maxWidth: .infinity`.
    @State private var barWidth: CGFloat = 0
    /// Total inset either side, so the bar doesn't run to the screen edges.
    private static let journeyBarInset: CGFloat = 48
    @StateObject private var serviceStatusPresenter = ServiceStatusPresenter()
#if DEBUG
    // Screenshot harness (overtrain:// deep links, see ScreenshotHarness.swift).
    @State private var debugTimetableTarget: ScreenshotTimetableTarget?
#endif
    @Namespace private var journeyZoom
    @AppStorage("lineData.onboarded") private var lineDataOnboarded = false
    @State private var showLineDataOnboarding = false

    private static let journeyTransitionID = "activeJourney"
    private static let feedbackURL = URL(string: "https://forms.gle/U91cFDFTufF12PeF7")!

    // Pushed screens reachable from the root.
    private enum Destination: Hashable {
        case attributions
        case lineData
    }

    private var needsLineDataOnboarding: Bool {
        // An app update that moved the schema on leaves the installed copy
        // unreadable-in-spirit, so the sheet comes back as an update.
        if Catalog.needsSchemaUpgrade { return true }
        if Catalog.current.lines.isEmpty { return true }
        return !lineDataOnboarded
            && Catalog.current.lines.contains { !LineDataStore.isPresent(folder: $0.folder) }
    }

    /// A conditional GET is cheap, but not on every appearance.
    private static let updateCheckInterval: TimeInterval = 6 * 60 * 60

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 24) {
                        FavoritesSection(viewModel: viewModel)
                        JourneyPlannerSection(viewModel: viewModel)
                        NearbyStationsSection(viewModel: viewModel)
                            .id("nearby")
                        SearchSection(viewModel: viewModel) { destination in
                            navigationPath.append(destination)
                        }
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
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { barWidth = $0 }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("App.Name"))
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    moreMenu
                }
            }
            .toolbar {
                if viewModel.activeJourney != nil {
                    ToolbarItem(placement: .bottomBar) {
                        JourneyToolbarAccessory(
                            viewModel: viewModel,
                            availableWidth: max(barWidth - Self.journeyBarInset, 200)
                        ) {
                            showJourneySheet = true
                        }
                        .frame(width: max(barWidth - Self.journeyBarInset, 200))
                        .matchedTransitionSource(id: Self.journeyTransitionID, in: journeyZoom)
                    }
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .attributions:
                    MoreAttributionsView()
                case .lineData:
                    LineDataManagerView()
                }
            }
            .navigationDestination(for: SearchDestination.self) { destination in
                searchDestinationView(destination)
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
                // Launch arguments, since simctl openurl needs a confirmation.
                for argument in ProcessInfo.processInfo.arguments.dropFirst()
                where argument.hasPrefix("overtrain://") {
                    if let url = URL(string: argument) {
                        await handleScreenshotURL(url)
                    }
                }
#endif
            }
        }
        .serviceStatusHost(serviceStatusPresenter)
        .task {
            if needsLineDataOnboarding { showLineDataOnboarding = true }
            await checkForLineDataUpdates()
        }
        .onChange(of: lineDataOnboarded) { _, isOnboarded in
            // The manager screen clears the flag as it starts the wipe; the
            // first-run sheet is what downloads from nothing, so it comes
            // back, over the root rather than over the screen being left.
            guard !isOnboarded else { return }
            navigationPath = NavigationPath()
            showLineDataOnboarding = true
        }
        .sheet(isPresented: $showLineDataOnboarding) {
            // The disclaimer waits its turn: two modals on a first launch land
            // on top of each other.
            if !hasDismissedStartupNotice { showStartupNotice = true }
        } content: {
            LineDataOnboardingView()
        }
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
        // Keeps the PiP layer alive while the journey sheet is closed.
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
        // Same text, reachable from the menu after the startup alert is dismissed for good.
        .alert(
            "More.Disclaimer",
            isPresented: $showDisclaimer
        ) {
            Button("Button.OK", role: .cancel) {}
        } message: {
            Text("StartupNotice.Message")
        }
        .onAppear {
            if !hasDismissedStartupNotice, !needsLineDataOnboarding {
                showStartupNotice = true
            }
        }
    }

    // MARK: - Search Destinations

    @ViewBuilder
    private func searchDestinationView(_ destination: SearchDestination) -> some View {
        switch destination {
        case .operatorLines(let operatorId):
            OperatorLinesView(operatorId: operatorId, viewModel: viewModel)
        case .line(let lineId):
            if let line = viewModel.availableLines.first(where: { $0.id == lineId }) {
                StationPickerView(line: line, viewModel: viewModel)
            }
        case .station(let lineId, let stationId):
            if let line = viewModel.availableLines.first(where: { $0.id == lineId }),
               let station = line.stations.first(where: { $0.id == stationId }) {
                StationTimetableView(station: station, line: line, viewModel: viewModel)
            }
        }
    }

    // MARK: - More Menu

    private var moreMenu: some View {
        Menu {
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
                Button {
                    navigationPath.append(Destination.lineData)
                } label: {
                    Label {
                        Text("LineData.Title")
                        if lineDataInstaller.hasUpdate {
                            Text("LineData.UpdatesAvailable")
                        }
                    } icon: {
                        Image(systemName: "cylinder.split.1x2")
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
                Button("More.Disclaimer") {
                    showDisclaimer = true
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .overlay(alignment: .topTrailing) {
                    if lineDataInstaller.hasUpdate {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 6, y: -6)
                    }
                }
        }
        .accessibilityLabel(lineDataInstaller.hasUpdate
                            ? Text("ViewTitle.More.UpdateAvailable") : Text("ViewTitle.More"))
    }

    /// Keeps the menu badge honest without spending a request every launch.
    private func checkForLineDataUpdates() async {
        guard lineDataOnboarded, !lineDataInstaller.isBusy else { return }
        if let checked = lineDataInstaller.lastChecked,
           Date().timeIntervalSince(checked) < Self.updateCheckInterval {
            await lineDataInstaller.recomputePending()
            return
        }
        _ = try? await lineDataInstaller.refreshCatalog()
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
        case .plannerArrival:
            ScreenshotStaging.shared.plannerCommand = .arrival
        case .timetable(let target, let hidePast):
            ScreenshotStaging.shared.hidePastDepartures = hidePast
            viewModel.loadStationTimetable(stationId: target.stationId)
            try? await Task.sleep(for: .seconds(1))
            debugTimetableTarget = target
        case .linePage(let target):
            ScreenshotStaging.shared.expandServiceStatus = target.expandStatus
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
        case .dismissSheet:
            try? await Task.sleep(for: .seconds(1.5))
            showJourneySheet = false
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
