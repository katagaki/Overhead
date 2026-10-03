import Combine
import SwiftUI
import WebKit
import Backbone

// MARK: - Service Status (運行情報)

/// The operator's official status page, pushed onto the tab, with X / Safari escapes.
struct ServiceStatusView: View {
    let lineId: String
    let delayInfo: DelayCheckInfo
    @StateObject private var web: ServiceStatusWebController

    init(lineId: String, delayInfo: DelayCheckInfo) {
        self.lineId = lineId
        self.delayInfo = delayInfo
        _web = StateObject(wrappedValue: ServiceStatusWebController(delayInfo: delayInfo))
    }

    var body: some View {
        Group {
            if let webView = web.officialWebView {
                ServiceStatusWebView(webView: webView)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle("StationTimetable.ServiceStatus")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let xURL = web.xURL {
                    Button {
                        UIApplication.shared.open(xURL)
                    } label: {
                        Image("sns.twitter.x")
                            .resizable()
                            .scaleEffect(0.8)
                    }
                    .accessibilityLabel("ServiceStatus.OpenInX")
                }
                Button {
                    openInSafari()
                } label: {
                    Label("ServiceStatus.OpenInSafari", systemImage: "safari")
                }
            }
        }
    }

    private func openInSafari() {
        if let url = web.officialWebView?.url ?? URL(string: delayInfo.localizedStatusPageURL) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Toolbar Button

/// Centered 運行情報 bottom-bar button, shared by the line and timetable pages.
private struct ServiceStatusToolbar: ViewModifier {
    @Environment(\.appTabOpenDestination) private var openTabDestination
    let lineId: String
    let delayInfo: DelayCheckInfo?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarSpacer(.flexible, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        openTabDestination?(.serviceStatus(lineId: lineId))
                    } label: {
                        Text("StationTimetable.ServiceStatus")
                    }
                    .disabled(delayInfo == nil || openTabDestination == nil)
                }

                ToolbarSpacer(.flexible, placement: .bottomBar)
            }
#if DEBUG
            .onAppear {
                if ScreenshotStaging.shared.expandServiceStatus, delayInfo != nil {
                    ScreenshotStaging.shared.expandServiceStatus = false
                    openTabDestination?(.serviceStatus(lineId: lineId))
                }
            }
#endif
    }
}

extension View {
    func serviceStatusToolbar(lineId: String, delayInfo: DelayCheckInfo?) -> some View {
        modifier(ServiceStatusToolbar(lineId: lineId, delayInfo: delayInfo))
    }
}

// MARK: - Web Controller

/// Loads the status page in a cookie-less web view.
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

/// Known selectors for the operator pages that ship a consent banner, plus a
/// fuzzy sweep for any added later.
@MainActor
enum CookieBanners {
    /// Hidden outright: each is the consent widget's own root.
    static let knownSelectors = """
        #cookie-agree, #cookiePolicy, #CybotCookiebotDialog, #CybotCookiebotDialogBodyUnderlay, \
        #gdprWrapper, #onetrust-consent-sdk
        """

    /// Hidden only when floating, so footer links mentioning cookies survive.
    private static let fuzzySelectors = """
        [id*="ookie"], [class*="ookie"], [id*="onsent"], [class*="onsent"], \
        [id*="gdpr"], [class*="gdpr"], [id*="onetrust"], [class*="onetrust"]
        """

    /// `block-cookies` only strips headers; neuter `document.cookie` too.
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

/// Keeps top-level navigation on the operator's domain; anything else goes to Safari.
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
        // Only a tapped link may leave the app; scripted redirects are dropped.
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
