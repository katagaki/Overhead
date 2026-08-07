import Combine
import SwiftUI
import WebKit
import Backbone

// MARK: - Service Status Sheet (運行情報)

/// Sheet content that peeks at the bottom of the line page and expands into a
/// web panel showing the operator's official status page.
struct ServiceStatusSheet: View {
    static let peekHeight: CGFloat = 72

    let lineId: String
    let delayInfo: DelayCheckInfo
    /// True when opened directly (e.g. from a context menu) rather than as a
    /// line page's accessory; standalone sheets start expanded and can be
    /// swiped away since no page's onDisappear will ever clear them.
    var standalone = false
    @ObservedObject var web: ServiceStatusWebController
    @State private var detent: PresentationDetent = .height(ServiceStatusSheet.peekHeight)

    private var isPeeking: Bool {
        detent == .height(Self.peekHeight)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("StationTimetable.ServiceStatus")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                if !isPeeking {
                    if let xURL = web.xURL {
                        Button {
                            UIApplication.shared.open(xURL)
                        } label: {
                            // Optically smaller than an SF Symbol at the same size.
                            Text(verbatim: "𝕏")
                                .font(.system(size: 27, weight: .medium))
                                .foregroundStyle(Color.primary)
                                .frame(width: 44, height: 44)
                                .contentShape(Circle())
                        }
                        .glassEffect(.regular.interactive(), in: Circle())
                        .accessibilityLabel("ServiceStatus.OpenInX")
                        .transition(.blurReplace)
                    }

                    Button {
                        openInSafari()
                    } label: {
                        Image(systemName: "safari")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .glassEffect(.regular.interactive(), in: Circle())
                    .accessibilityLabel("ServiceStatus.OpenInSafari")
                    .transition(.blurReplace)
                }

                Button {
                    detent = isPeeking ? .medium : .height(Self.peekHeight)
                } label: {
                    Image(systemName: isPeeking ? "chevron.up" : "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel("StationTimetable.ServiceStatus")
            }
            .padding(.leading, 20)
            .padding(.trailing, 8)
            .padding(.top, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                detent = isPeeking ? .medium : .height(Self.peekHeight)
            }

            // Kept out of the peek state so the fold doesn't clip it.
            if !isPeeking {
                if let webView = web.officialWebView {
                    ServiceStatusWebView(webView: webView)
                        .ignoresSafeArea(edges: .bottom)
                        .transition(.opacity)
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .animation(.smooth(duration: 0.3), value: isPeeking)
        .presentationDetents([.height(Self.peekHeight), .medium, .large], selection: $detent)
        .presentationBackgroundInteraction(.enabled)
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(!standalone)
        .onAppear {
            if standalone {
                detent = .medium
            }
        }
        // The sheet stays up while pushing between line pages; start each line at peek.
        .onChange(of: lineId) {
            detent = .height(Self.peekHeight)
        }
#if DEBUG
        .onAppear {
            if ScreenshotStaging.shared.expandServiceStatus {
                ScreenshotStaging.shared.expandServiceStatus = false
                detent = .large
            }
        }
#endif
    }

    private func openInSafari() {
        if let url = web.officialWebView?.url ?? URL(string: delayInfo.localizedStatusPageURL) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Presenter

/// Single owner of the 運行情報 sheet across line pages. Pushing from one line
/// to another swaps the sheet's content in place instead of racing the old
/// page's dismissal against the new page's presentation.
@MainActor
final class ServiceStatusPresenter: ObservableObject {
    struct Context {
        let lineId: String
        let delayInfo: DelayCheckInfo
        let web: ServiceStatusWebController
        let standalone: Bool
    }

    @Published private(set) var context: Context?
    /// Identifies the page currently holding the sheet up. Keyed per page
    /// instance rather than per line, so pushing a station timetable on top of
    /// its own line page hands the sheet over instead of dropping it.
    private var owner: UUID?

    func activate(owner: UUID, lineId: String, delayInfo: DelayCheckInfo?, standalone: Bool = false) {
        guard let delayInfo else {
            deactivate(owner: owner)
            return
        }
        self.owner = owner
        guard context?.lineId != lineId else { return }
        context = Context(
            lineId: lineId,
            delayInfo: delayInfo,
            web: ServiceStatusWebController(delayInfo: delayInfo),
            standalone: standalone
        )
    }

    /// A push fires the incoming page's onAppear before the outgoing page's
    /// onDisappear, so only the current owner may clear the sheet.
    func deactivate(owner: UUID) {
        if self.owner == owner {
            self.owner = nil
            context = nil
        }
    }

    func dismiss() {
        owner = nil
        context = nil
    }
}

private struct ServiceStatusPresenterKey: EnvironmentKey {
    static let defaultValue: ServiceStatusPresenter? = nil
}

extension EnvironmentValues {
    var serviceStatusPresenter: ServiceStatusPresenter? {
        get { self[ServiceStatusPresenterKey.self] }
        set { self[ServiceStatusPresenterKey.self] = newValue }
    }
}

// MARK: - Host

private struct ServiceStatusHost: ViewModifier {
    @ObservedObject var presenter: ServiceStatusPresenter

    func body(content: Content) -> some View {
        content
            .environment(\.serviceStatusPresenter, presenter)
            .sheet(isPresented: Binding(
                get: { presenter.context != nil },
                set: { if !$0 { presenter.dismiss() } }
            )) {
                if let context = presenter.context {
                    ServiceStatusSheet(
                        lineId: context.lineId,
                        delayInfo: context.delayInfo,
                        standalone: context.standalone,
                        web: context.web
                    )
                }
            }
    }
}

extension View {
    /// Hosts the 運行情報 sheet for any line page pushed inside this hierarchy.
    func serviceStatusHost(_ presenter: ServiceStatusPresenter) -> some View {
        modifier(ServiceStatusHost(presenter: presenter))
    }
}

// MARK: - Web Controller

/// Preloads the status page in a cookie-less web view so the sheet has content
/// by the time it is dragged up. Cookies are blocked outright by a content rule
/// list, and the non-persistent store keeps anything WebKit still writes in
/// memory only. Every surveyed operator page renders fine without them.
@MainActor
final class ServiceStatusWebController: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()

    let officialWebView: WKWebView?
    /// The operator's X timeline, opened externally rather than embedded.
    let xURL: URL?

    private let officialDelegate: RestrictedWebDelegate?

    init(delayInfo: DelayCheckInfo?) {
        if let delayInfo, let statusURL = URL(string: delayInfo.localizedStatusPageURL) {
            let delegate = RestrictedWebDelegate(
                allowedDomains: Self.registrableDomain(of: statusURL).map { [$0] } ?? []
            )
            self.officialDelegate = delegate
            self.officialWebView = Self.makeWebView(delegate: delegate, url: statusURL)
        } else {
            self.officialDelegate = nil
            self.officialWebView = nil
        }

        if let account = delayInfo?.xAccount {
            self.xURL = URL(string: "https://x.com/\(account.hasPrefix("@") ? String(account.dropFirst()) : account)")
        } else {
            self.xURL = nil
        }
    }

    private static func makeWebView(delegate: RestrictedWebDelegate, url: URL) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.applicationNameForUserAgent = "Version/26.0 Mobile/15E148 Safari/604.1"
        configuration.userContentController.addUserScript(CookieBanners.sealScript)
        configuration.userContentController.addUserScript(CookieBanners.sweepScript)
        // Non-zero frame so the page lays out at a phone viewport during preload.
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 700),
            configuration: configuration
        )
        webView.navigationDelegate = delegate
        webView.uiDelegate = delegate
        webView.allowsBackForwardNavigationGestures = true
        // Held until the rule list is attached so the first load is cookie-less too.
        Task {
            if let rules = await CookieBanners.ruleList() {
                webView.configuration.userContentController.add(rules)
            }
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    /// "traininfo.jreast.co.jp" -> "jreast.co.jp"
    static func registrableDomain(of url: URL) -> String? {
        guard let host = url.host()?.lowercased() else { return nil }
        let labels = host.split(separator: ".").map(String.init)
        guard labels.count > 2 else { return host }
        let secondLevel: Set<String> = ["co", "or", "ne", "ac", "go", "lg", "ed", "gr"]
        let keep = labels[labels.count - 1] == "jp"
            && secondLevel.contains(labels[labels.count - 2]) ? 3 : 2
        return labels.suffix(keep).joined(separator: ".")
    }
}

// MARK: - Cookies & Banners

/// Blocks cookies and hides consent banners. Five of the operator status pages
/// ship one: 北総 (#cookie-agree), 京成 (#cookiePolicy), 東京メトロ (Cookiebot),
/// 京王 (OneTrust, injected seconds after load) and JR東日本's *English* pages
/// (#gdprWrapper — the Japanese ones have none). The fuzzy sweep behind them
/// catches sites that add one later.
@MainActor
enum CookieBanners {
    /// Hidden outright: each is the consent widget's own root.
    static let knownSelectors = """
        #cookie-agree, #cookiePolicy, #CybotCookiebotDialog, #CybotCookiebotDialogBodyUnderlay, \
        #gdprWrapper, #onetrust-consent-sdk
        """

    /// Hidden only when they float over the page, so ordinary page furniture
    /// that merely mentions cookies (京成's footer link) survives.
    private static let fuzzySelectors = """
        [id*="ookie"], [class*="ookie"], [id*="onsent"], [class*="onsent"], \
        [id*="gdpr"], [class*="gdpr"], [id*="onetrust"], [class*="onetrust"]
        """

    /// `block-cookies` only strips the HTTP Cookie/Set-Cookie headers; page JS
    /// can still write `document.cookie`. Neutering it too gets the count to a
    /// measured zero, and all 35 status pages render byte-identically without it.
    static let sealScript = WKUserScript(
        source: """
        (() => {
          try {
            Object.defineProperty(document, 'cookie', {
              get() { return ''; }, set(_value) { return ''; }, configurable: true
            });
          } catch (error) {}
        })();
        """,
        injectionTime: .atDocumentStart,
        forMainFrameOnly: false
    )

    static let sweepScript = WKUserScript(
        source: """
        (() => {
          const sweep = () => {
            document.querySelectorAll('\(knownSelectors)').forEach((element) => {
              element.style.setProperty('display', 'none', 'important');
            });
            document.querySelectorAll('\(fuzzySelectors)').forEach((element) => {
              const position = getComputedStyle(element).position;
              if (position === 'fixed' || position === 'sticky') {
                element.style.setProperty('display', 'none', 'important');
              }
            });
          };
          sweep();
          new MutationObserver(sweep).observe(document.documentElement, { childList: true, subtree: true });
        })();
        """,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true
    )

    private static var compiled: WKContentRuleList?
    private static var compilation: Task<WKContentRuleList?, Never>?

    static func ruleList() async -> WKContentRuleList? {
        if let compiled { return compiled }
        if let compilation { return await compilation.value }
        let task = Task<WKContentRuleList?, Never> {
            let rules = """
            [
              { "trigger": { "url-filter": ".*" }, "action": { "type": "block-cookies" } },
              { "trigger": { "url-filter": ".*" },
                "action": { "type": "css-display-none", "selector": "\(knownSelectors)" } }
            ]
            """
            return try? await WKContentRuleListStore.default()?.compileContentRuleList(
                forIdentifier: "ServiceStatusCookieBlock",
                encodedContentRuleList: rules
            )
        }
        compilation = task
        compiled = await task.value
        return compiled
    }
}

// MARK: - Navigation Policy

/// Keeps top-level navigation within the operator's own domain; anything else
/// (news links from X posts, banners, mailto:) flips out to Safari.
private final class RestrictedWebDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let allowedDomains: Set<String>

    init(allowedDomains: some Sequence<String>) {
        self.allowedDomains = Set(allowedDomains)
    }

    private func isAllowed(_ url: URL) -> Bool {
        guard let domain = ServiceStatusWebController.registrableDomain(of: url) else { return false }
        return allowedDomains.contains(domain)
    }

    private func openExternally(_ url: URL) {
        Task { @MainActor in
            UIApplication.shared.open(url)
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        // Embedded frames may pull from anywhere; only gate top-level navigation.
        guard navigationAction.targetFrame?.isMainFrame != false else {
            decisionHandler(.allow)
            return
        }
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == "about" || ((scheme == "http" || scheme == "https") && isAllowed(url)) {
            decisionHandler(.allow)
            return
        }
        // Only a tapped link may leave the app; scripted redirects are dropped
        // silently rather than yanking the user out to Safari.
        if isUserInitiated(navigationAction) {
            openExternally(url)
        }
        decisionHandler(.cancel)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            if isAllowed(url) {
                webView.load(navigationAction.request)
            } else if isUserInitiated(navigationAction) {
                openExternally(url)
            }
        }
        return nil
    }

    private func isUserInitiated(_ navigationAction: WKNavigationAction) -> Bool {
        navigationAction.navigationType == .linkActivated
            || navigationAction.navigationType == .formSubmitted
    }

#if DEBUG
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        NSLog("[ServiceStatusWeb] didFailProvisional %@", (error as NSError).description)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        NSLog("[ServiceStatusWeb] content process terminated %@", webView.url?.absoluteString ?? "-")
    }
#endif
}

// MARK: - Web View Wrapper

private struct ServiceStatusWebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
