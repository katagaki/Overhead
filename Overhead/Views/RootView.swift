import SwiftUI
import Backbone

/// The whole app on one scrolling surface: planner, favorites, and lines to browse.
struct RootView: View {
    @ObservedObject var viewModel: JourneyViewModel
    @ObservedObject private var customStore = CustomLineStore.shared
    @ObservedObject private var lineDataInstaller = LineDataInstaller.shared

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
    @StateObject private var tabStore = AppTabStore()
    @State private var showsTabOverview = false
    @State private var workspaceIsCollapsed = false
    @State private var workspaceIsSwappedForSnapshot = false
    @State private var collapseTarget: CGRect?
    @State private var showsBrowserSearchOverlay = false
    @FocusState private var browserSearchFocused: Bool
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
        GeometryReader { rootProxy in
            ZStack {
                AppTabOverviewView(
                    store: tabStore,
                    viewModel: viewModel,
                    dismiss: { resetsNavigation in
                        dismissTabOverview(resetsNavigation: resetsNavigation)
                    }
                )
                .allowsHitTesting(showsTabOverview)
                .accessibilityHidden(!showsTabOverview)

                workspace(width: rootProxy.size.width)
                    .id(tabStore.selectedTabID)
                    // Edge to edge: inset, the page jumps as the transform starts.
                    .ignoresSafeArea(.container)
                    .frame(width: rootProxy.size.width, height: rootProxy.size.height)
                    .background(Color(.systemGroupedBackground).ignoresSafeArea())
                    .compositingGroup()
                    .scaleEffect(workspaceScale(in: rootProxy.size), anchor: .topLeading)
                    .offset(workspaceOffset(in: rootProxy.size))
                    .clipShape(
                        AppTabPageClipShape(
                            progress: workspaceIsCollapsed ? 1 : 0,
                            expanded: expandedWorkspaceRect(in: rootProxy.size),
                            collapsed: collapseTarget
                                ?? expandedWorkspaceRect(in: rootProxy.size),
                            expandedRadius: 0,
                            collapsedRadius: AppTabOverviewView.cardCornerRadius
                        )
                    )
                    .animation(
                        AppTabOverviewView.transitionAnimation,
                        value: workspaceIsCollapsed
                    )
                    .opacity(workspaceIsSwappedForSnapshot ? 0 : 1)
                    .allowsHitTesting(!showsTabOverview)
                    .accessibilityHidden(showsTabOverview)
            }
        }
        .coordinateSpace(name: AppTabZoom.coordinateSpace)
        .ignoresSafeArea(.container)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .overlay {
            if showsBrowserSearchOverlay, !showsTabOverview {
                BrowserSearchOverlay(
                    store: tabStore,
                    isFocused: $browserSearchFocused,
                    dismiss: dismissSearchOverlay
                )
                .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.2), value: showsBrowserSearchOverlay)
        .serviceStatusHost(serviceStatusPresenter)
        .task {
            if needsLineDataOnboarding { showLineDataOnboarding = true }
            await checkForLineDataUpdates()
        }
        .onChange(of: lineDataInstaller.wipeCount) { _, _ in
            // The manager screen clears the flag as it starts the wipe; the
            // first-run sheet is what downloads from nothing, so it comes
            // back, over the root rather than over the screen being left.
            // The wipe itself is the trigger: clearing a flag that is already
            // clear says nothing, and a second wipe has to bring the sheet
            // back too.
            navigationPath = NavigationPath()
            Task { @MainActor in
                // A sheet raised in the same turn as the pop is swallowed by
                // the transition, leaving the app on an empty catalog.
                try? await Task.sleep(for: .milliseconds(450))
                showLineDataOnboarding = true
            }
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

    private func workspace(width: CGFloat) -> some View {
        NavigationStack(path: $navigationPath) {
            Group {
                switch tabStore.selectedTab.page {
                case .home:
                    homeContent
                case .search:
                    CatalogTabSearchView(
                        lines: viewModel.availableLines,
                        searchText: selectedSearchText,
                        scope: selectedSearchScope,
                        onOpen: openInSelectedTab,
                        onRoute: routeFromNearest
                    )
                case .destination(let destination):
                    searchDestinationView(destination)
                }
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                if tabStore.selectedTab.page != .home {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            openHome()
                        } label: {
                            Image(systemName: "house")
                        }
                        .accessibilityLabel("App.Name")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    moreMenu
                }

                if !showsBrowserSearchOverlay {
                    if viewModel.activeJourney != nil {
                        ToolbarItem(placement: .bottomBar) {
                            JourneyStationToolbarButton(viewModel: viewModel) {
                                showJourneySheet = true
                            }
                            .matchedTransitionSource(id: Self.journeyTransitionID, in: journeyZoom)
                        }

                        ToolbarSpacer(.fixed, placement: .bottomBar)
                    }

                    ToolbarItem(placement: .bottomBar) {
                        BrowserAddressToolbarItem(
                            store: tabStore,
                            onOpenSearch: openSearch,
                            onSwipe: switchTab
                        )
                        .frame(width: browserAddressWidth(in: width))
                    }

                    ToolbarSpacer(.fixed, placement: .bottomBar)

                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            showTabOverview()
                        } label: {
                            Image(systemName: "square.on.square")
                        }
                        .accessibilityLabel("Show tabs")
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
    }

    private var homeContent: some View {
        ScrollViewReader { scrollProxy in
            Group {
                if horizontalSizeClass == .regular {
                    splitColumns
                } else {
                    ScrollView {
                        column {
                            plannerSections
                            catalogSections
                        }
                    }
                }
            }
#if DEBUG
            .onReceive(ScreenshotStaging.shared.$homeScrollTarget) { target in
                guard let target else { return }
                ScreenshotStaging.shared.homeScrollTarget = nil
                scrollProxy.scrollTo(target, anchor: .top)
            }
#endif
        }
        .navigationTitle(Text("App.Name"))
        .toolbarTitleDisplayMode(.inlineLarge)
    }

    private var selectedSearchText: Binding<String> {
        Binding(
            get: { tabStore.selectedTab.searchText },
            set: { value in tabStore.updateSelected { $0.searchText = value } }
        )
    }

    private func browserAddressWidth(in width: CGFloat) -> CGFloat {
        let surroundingControlsWidth: CGFloat = viewModel.activeJourney == nil ? 86 : 140
        return max(0, width - 32 - surroundingControlsWidth)
    }

    private var selectedSearchScope: Binding<SearchScope> {
        Binding(
            get: { tabStore.selectedTab.searchScope },
            set: { value in tabStore.updateSelected { $0.searchScope = value } }
        )
    }

    private func openSearch() {
        navigationPath = NavigationPath()
        tabStore.updateSelected { $0.page = .search }
        withAnimation(.smooth(duration: 0.2)) {
            showsBrowserSearchOverlay = true
        }
    }

    private func dismissSearchOverlay() {
        browserSearchFocused = false
        withAnimation(.smooth(duration: 0.2)) {
            showsBrowserSearchOverlay = false
        }
    }

    private func openHome() {
        dismissSearchOverlay()
        navigationPath = NavigationPath()
        tabStore.updateSelected { $0.page = .home }
    }

    private func openInSelectedTab(_ destination: SearchDestination) {
        dismissSearchOverlay()
        navigationPath = NavigationPath()
        tabStore.updateSelected { $0.page = .destination(destination) }
    }

    private func routeFromNearest(_ origin: StationSearchHit, _ destination: StationSearchHit) {
        viewModel.plannerFromRequest = origin
        viewModel.plannerToRequest = destination
        openHome()
    }

    private func switchTab(_ delta: Int) {
        tabStore.captureSelectedTabSnapshot()
        dismissSearchOverlay()
        navigationPath = NavigationPath()
        withAnimation(.smooth(duration: 0.3)) {
            _ = tabStore.selectAdjacent(delta)
        }
    }

    private func dismissTabOverview(resetsNavigation: Bool) {
        freezeCollapseTarget()
        if resetsNavigation {
            navigationPath = NavigationPath()
        }
        setShowsTabOverviewWithoutAnimation(false)
        Task { @MainActor in
            setWorkspaceSwappedWithoutAnimation(false)
            withAnimation(AppTabOverviewView.transitionAnimation) {
                workspaceIsCollapsed = false
            }
        }
    }

    private func showTabOverview() {
        tabStore.captureSelectedTabSnapshot()
        freezeCollapseTarget()
        setShowsTabOverviewWithoutAnimation(true)
        withAnimation(
            AppTabOverviewView.transitionAnimation,
            completionCriteria: .removed
        ) {
            workspaceIsCollapsed = true
        } completion: {
            guard workspaceIsCollapsed else { return }
            setWorkspaceSwappedWithoutAnimation(true)
        }
    }

    private func setWorkspaceSwappedWithoutAnimation(_ isSwapped: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            workspaceIsSwappedForSnapshot = isSwapped
        }
    }

    private func setShowsTabOverviewWithoutAnimation(_ isShowing: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            showsTabOverview = isShowing
        }
    }

    private func freezeCollapseTarget() {
        guard let card = tabStore.cardFrames[tabStore.selectedTabID] else {
            collapseTarget = nil
            return
        }
        let previewHeight = card.width / AppTabOverviewView.previewAspectRatio
        collapseTarget = CGRect(
            x: card.minX,
            y: card.maxY - previewHeight,
            width: card.width,
            height: previewHeight
        )
    }

    private var selectedTabPreviewFrame: CGRect? {
        workspaceIsCollapsed ? collapseTarget : nil
    }

    private func workspaceScale(in size: CGSize) -> CGFloat {
        guard let target = selectedTabPreviewFrame, size.width > 0 else { return 1 }
        return target.width / size.width
    }

    private func workspaceOffset(in size: CGSize) -> CGSize {
        guard let target = selectedTabPreviewFrame else { return .zero }
        return CGSize(
            width: target.minX,
            height: target.minY
        )
    }

    private func expandedWorkspaceRect(in size: CGSize) -> CGRect {
        CGRect(origin: .zero, size: size)
    }

    // MARK: - Layout

    /// Wide windows read as two halves: what you are riding on the left,
    /// what there is to browse on the right, each scrolling on its own.
    private var splitColumns: some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView {
                column { plannerSections }
            }
            .frame(maxWidth: .infinity)

            Divider()
                .ignoresSafeArea(edges: .bottom)

            ScrollView {
                column { catalogSections }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func column<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 24) {
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var plannerSections: some View {
        FavoritesSection(viewModel: viewModel)
        JourneyPlannerSection(viewModel: viewModel)
    }

    @ViewBuilder
    private var catalogSections: some View {
        NearbyStationsSection(viewModel: viewModel)
            .id("nearby")
        CustomLinesSection(viewModel: viewModel)
            .id("custom")
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
        case .timetable(let target, let hidePast, let popoverType):
            ScreenshotStaging.shared.hidePastDepartures = hidePast
            ScreenshotStaging.shared.timetablePopoverType = popoverType
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
            openHome()
            UserDefaults.standard.removeObject(forKey: "journey.setup.stations")
            UserDefaults.standard.removeObject(forKey: "journey.avoidedLines")
        }
    }
#endif
}
