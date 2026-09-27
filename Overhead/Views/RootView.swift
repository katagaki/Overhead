import SwiftUI
import Backbone
import EnhancedNavigation

/// The app shell for persistent tabs, journey planning, and the catalog.
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
    @State private var tabStore = AppTabSessionMigration.makeStore()
    @State private var searchStates = AppTabSearchStateStorage.load()
    @State private var showsBrowserSearchOverlay = false
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
        TabZoomContainer(store: tabStore, cardCornerRadius: TabSwitcherCardMetrics.cornerRadius) {
            TabSwitcher(
                store: tabStore,
                strings: TabSwitcherStrings(title: { $0 == 1 ? "1 Tab" : "\($0) Tabs" }),
                placeholderIcon: .systemImage("tram.fill"),
                rebuildingPath: rebuildPath
            ) { tab in
                let identity = tab.pageIdentity ?? identity(for: tab.root, tabID: tab.id)
                Label(identity.title, systemImage: identity.symbolName)
                    .lineLimit(1)
            }
        } page: { width in
            LiveTabStack(store: tabStore) { tab in
                workspace(for: tab)
                    .frame(width: width)
                    .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
            .ignoresSafeArea(.container)
        }
        .ignoresSafeArea(.container)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .overlay {
            if showsBrowserSearchOverlay, !tabStore.isShowingTabSwitcher {
                CatalogSearchView(
                    lines: viewModel.availableLines,
                    searchText: selectedSearchText,
                    scope: searchScope(for: tabStore.selectedTabID),
                    dismiss: dismissSearchOverlay,
                    onOpen: openInSelectedTab,
                    onRoute: routeFromNearest
                )
                .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.2), value: showsBrowserSearchOverlay)
        .serviceStatusHost(serviceStatusPresenter)
        .onChange(of: tabStore.tabs.map(\.id)) { _, tabIDs in
            let liveIDs = Set(tabIDs)
            searchStates = searchStates.filter { liveIDs.contains($0.key) }
            AppTabSearchStateStorage.save(searchStates)
        }
        .task {
            tabStore.loadPersistedSnapshots()
            await viewModel.loadLines()
#if DEBUG
            // Launch arguments let the screenshot harness open deep links directly.
            for argument in ProcessInfo.processInfo.arguments.dropFirst()
            where argument.hasPrefix("overtrain://") {
                if let url = URL(string: argument) {
                    await handleScreenshotURL(url)
                }
            }
#endif
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
            tabStore.updateSelectedTab { $0.path = NavigationPath() }
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

    private func workspace(for tab: AppNavigationStore.Tab) -> some View {
        NavigationStack(path: tabStore.pathBinding(for: tab.id)) {
            Group {
                switch tab.root {
                case .home:
                    homeContent
                case .search:
                    homeContent // A saved search tab is normalized to Home on launch.
                case .destination(let destination):
                    searchDestinationView(destination)
                }
            }
            .background(Color(.systemGroupedBackground))
            .tabPage(pathToken: Optional<AppPathToken>.none)
            .toolbar {
                if tab.root != .home && tab.root != .search {
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
            }
            .navigationDestination(for: AppMenuDestination.self) { destination in
                Group {
                    switch destination {
                    case .attributions:
                        MoreAttributionsView()
                    case .lineData:
                        LineDataManagerView()
                    }
                }
                .tabPage(pathToken: AppPathToken.menu(destination))
                .onAppear {
                    tabStore.setPageIdentity(
                        AppTabIdentity(
                            title: destination == .attributions
                                ? String(localized: "More.Attributions") : String(localized: "LineData.Title"),
                            symbolName: destination == .attributions ? "info.circle" : "cylinder.split.1x2",
                            pathToken: .menu(destination)
                        ),
                        for: tab.id
                    )
                }
            }
            .navigationDestination(for: SearchDestination.self) { destination in
                searchDestinationView(destination)
                    .tabPage(pathToken: AppPathToken.search(destination))
                    .onAppear {
                        tabStore.setPageIdentity(
                            AppTabIdentity(title: title(for: destination), symbolName: icon(for: .destination(destination)), pathToken: .search(destination)),
                            for: tab.id
                        )
                    }
            }
            .navigationDestination(for: CustomLineRoute.self) { route in
                CustomLineEditorView(route: route)
                    .tabPage(pathToken: AppPathToken.customLine(route))
                    .onAppear {
                        tabStore.setPageIdentity(
                            AppTabIdentity(
                                title: String(localized: "CustomLine.Section"),
                                symbolName: "tram.fill",
                                pathToken: .customLine(route)
                            ),
                            for: tab.id
                        )
                    }
            }
#if DEBUG
            .navigationDestination(for: ScreenshotLineTarget.self) { target in
                if let line = viewModel.availableLines.first(where: { $0.id == target.lineId }) {
                    StationPickerView(line: line, viewModel: viewModel)
                }
            }
#endif
        }
        .environment(\.appTabOpenDestination, { tabStore.push($0) })
        .tabBottomBar {
            browserBottomBar(for: tab)
        }
        .onAppear { tabStore.setPageIdentity(identity(for: tab.root, tabID: tab.id), for: tab.id) }
        .onChange(of: tab.root) { _, root in
            tabStore.setPageIdentity(identity(for: root, tabID: tab.id), for: tab.id)
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

    private var selectedSearchText: Binding<String> { searchText(for: tabStore.selectedTabID) }

    private func searchText(for tabID: UUID) -> Binding<String> {
        Binding(
            get: { searchStates[tabID]?.text ?? "" },
            set: { value in
                searchStates[tabID, default: AppTabSearchState()].text = value
                AppTabSearchStateStorage.save(searchStates)
            }
        )
    }

    private func searchScope(for tabID: UUID) -> Binding<SearchScope> {
        Binding(
            get: { searchStates[tabID]?.scope ?? .all },
            set: { value in
                searchStates[tabID, default: AppTabSearchState()].scope = value
                AppTabSearchStateStorage.save(searchStates)
            }
        )
    }

    private func browserBottomBar(for tab: AppNavigationStore.Tab) -> some View {
        GlassEffectContainer(spacing: TabBottomBarMetrics.itemSpacing) {
            HStack(spacing: TabBottomBarMetrics.itemSpacing) {
                JourneyStationToolbarButton(viewModel: viewModel) {
                    showJourneySheet = true
                }
                .matchedTransitionSource(id: Self.journeyTransitionID, in: journeyZoom)

                BrowserAddressToolbarItem(
                    viewModel: viewModel,
                    searchText: searchText(for: tab.id),
                    onOpenSearch: openSearch,
                    onSwipe: switchTab
                )
                .frame(maxWidth: .infinity, minHeight: TabBottomBarMetrics.itemHeight)
                .glassEffect(.regular.interactive(), in: .capsule)

                Button {
                    tabStore.showTabSwitcher()
                } label: {
                    Image(systemName: "square.on.square")
                        .frame(width: TabBottomBarMetrics.itemHeight, height: TabBottomBarMetrics.itemHeight)
                        .contentShape(Circle())
                }
                .accessibilityLabel("Show tabs")
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
        }
        .opacity(showsBrowserSearchOverlay ? 0 : 1)
        .allowsHitTesting(!showsBrowserSearchOverlay)
        .accessibilityHidden(showsBrowserSearchOverlay)
    }

    private func openSearch() {
        withAnimation(.smooth(duration: 0.2)) { showsBrowserSearchOverlay = true }
    }

    private func dismissSearchOverlay() {
        withAnimation(.smooth(duration: 0.2)) { showsBrowserSearchOverlay = false }
    }

    private func openHome() {
        dismissSearchOverlay()
        tabStore.updateSelectedTab { tab in
            tab.path = NavigationPath()
            tab.root = .home
        }
        tabStore.setPageIdentity(identity(for: .home, tabID: tabStore.selectedTabID), for: tabStore.selectedTabID)
        tabStore.persistTabs()
    }

    private func openInSelectedTab(_ destination: SearchDestination) {
        dismissSearchOverlay()
        tabStore.push(destination)
    }

    private func routeFromNearest(_ origin: StationSearchHit, _ destination: StationSearchHit) {
        viewModel.plannerFromRequest = origin
        viewModel.plannerToRequest = destination
        openHome()
    }

    private func switchTab(_ delta: Int) {
        let index = tabStore.tabs.firstIndex { $0.id == tabStore.selectedTabID } ?? 0
        let target = index + delta
        guard tabStore.tabs.indices.contains(target) else { return }
        dismissSearchOverlay()
        withAnimation(.smooth(duration: 0.3)) { tabStore.select(tabStore.tabs[target].id) }
    }

    private func rebuildPath(_ token: AppPathToken, _ path: inout NavigationPath) -> Bool {
        switch token {
        case .search(let destination): path.append(destination)
        case .menu(let destination): path.append(destination)
        case .customLine(let route): path.append(route)
        }
        return true
    }

    private func identity(for page: AppTabPage, tabID: UUID) -> AppTabIdentity {
        AppTabIdentity(title: title(for: page, searchText: searchStates[tabID]?.text),
                       symbolName: icon(for: page), pathToken: nil)
    }

    private func title(for page: AppTabPage, searchText: String?) -> String {
        switch page {
        case .home: String(localized: "App.Name")
        case .search: searchText.flatMap { $0.isEmpty ? nil : $0 } ?? String(localized: "Search.Title")
        case .destination(let destination): title(for: destination)
        }
    }

    private func title(for destination: SearchDestination) -> String {
        switch destination {
        case .operatorLines(let id): OperatorSections.title(for: id)
        case .line(let id): viewModel.availableLines.first { $0.id == id }?.localizedName ?? String(localized: "Search.Section.Lines")
        case .station(let lineID, let stationID),
             .stationWithDirection(let lineID, let stationID, _):
            viewModel.availableLines.first { $0.id == lineID }?.stations.first { $0.id == stationID }?.localizedName
                ?? String(localized: "Search.Section.Stations")
        }
    }

    private func icon(for page: AppTabPage) -> String {
        switch page {
        case .home: "house"
        case .search: "magnifyingglass"
        case .destination(let destination):
            switch destination {
            case .operatorLines: "building.2"
            case .line: "tram.fill"
            case .station, .stationWithDirection: "clock"
            }
        }
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
            OperatorLinesView(operatorId: operatorId, viewModel: viewModel) { lineID in
                tabStore.push(SearchDestination.line(lineID))
            }
        case .line(let lineId):
            if let line = viewModel.availableLines.first(where: { $0.id == lineId }) {
                StationPickerView(line: line, viewModel: viewModel)
            }
        case .station(let lineId, let stationId):
            if let line = viewModel.availableLines.first(where: { $0.id == lineId }),
               let station = line.stations.first(where: { $0.id == stationId }) {
                StationTimetableView(station: station, line: line, viewModel: viewModel)
            }
        case .stationWithDirection(let lineId, let stationId, let directionId):
            if let line = viewModel.availableLines.first(where: { $0.id == lineId }),
               let station = line.stations.first(where: { $0.id == stationId }) {
                StationTimetableView(
                    station: station,
                    line: line,
                    preferredDirectionId: directionId,
                    viewModel: viewModel
                )
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
                    tabStore.push(AppMenuDestination.lineData)
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
                    tabStore.push(AppMenuDestination.attributions)
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
            tabStore.push(target)
        case .customLineEditor:
            ScreenshotSeeder.seedCustomLine()
            try? await Task.sleep(for: .seconds(0.5))
            tabStore.push(CustomLineRoute.edit(ScreenshotSeeder.customLineId))
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
