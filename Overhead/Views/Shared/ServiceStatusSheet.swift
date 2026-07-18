import Combine
import SwiftUI
import WebKit
import Backbone

// MARK: - Service Status Sheet (運行情報)

/// Sheet content that peeks at the bottom of the line page and expands into a
/// web panel showing the operator's official status page or their X timeline.
struct ServiceStatusSheet: View {
    static let peekHeight: CGFloat = 72

    let lineId: String
    let delayInfo: DelayCheckInfo
    @ObservedObject var web: ServiceStatusWebController
    @State private var source: ServiceStatusSource = .official
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

            // Kept out of the peek state so the fold doesn't clip them.
            if !isPeeking {
                if web.xWebView != nil {
                    Picker("StationTimetable.ServiceStatus", selection: $source) {
                        Text("ServiceStatus.Tab.Official").tag(ServiceStatusSource.official)
                        Text(verbatim: "X").tag(ServiceStatusSource.x)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .transition(.blurReplace)
                }

                if let webView = web.webView(for: source) {
                    ServiceStatusWebView(webView: webView)
                        // Representables never swap their UIView; new identity per source.
                        .id(source)
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
        .interactiveDismissDisabled()
        // The sheet stays up while pushing between line pages; start each line at peek.
        .onChange(of: lineId) {
            detent = .height(Self.peekHeight)
            source = .official
        }
#if DEBUG
        .onAppear {
            if ScreenshotStaging.shared.expandServiceStatus {
                ScreenshotStaging.shared.expandServiceStatus = false
                detent = .large
            }
            if ScreenshotStaging.shared.serviceStatusShowsX {
                ScreenshotStaging.shared.serviceStatusShowsX = false
                source = .x
            }
        }
#endif
    }

    private func openInSafari() {
        if let url = web.webView(for: source)?.url ?? URL(string: delayInfo.localizedStatusPageURL) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Source

enum ServiceStatusSource {
    case official
    case x
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
    }

    @Published private(set) var context: Context?

    func activate(lineId: String, delayInfo: DelayCheckInfo?) {
        guard let delayInfo else {
            deactivate(lineId: lineId)
            return
        }
        guard context?.lineId != lineId else { return }
        context = Context(
            lineId: lineId,
            delayInfo: delayInfo,
            web: ServiceStatusWebController(delayInfo: delayInfo)
        )
    }

    /// A push fires the incoming page's onAppear before the outgoing page's
    /// onDisappear, so only the current owner may clear the sheet.
    func deactivate(lineId: String) {
        if context?.lineId == lineId {
            context = nil
        }
    }

    func dismiss() {
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

/// Preloads the status page (and X timeline) in cookie-less web views so the
/// sheet has content by the time it is dragged up. The non-persistent data
/// store keeps cookies in memory only; they vanish when the app exits.
@MainActor
final class ServiceStatusWebController: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()

    let officialWebView: WKWebView?
    let xWebView: WKWebView?

    private let officialDelegate: RestrictedWebDelegate?
    private let xDelegate: RestrictedWebDelegate?

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

        if let account = delayInfo?.xAccount,
           let xURL = URL(string: "https://x.com/\(account.hasPrefix("@") ? String(account.dropFirst()) : account)") {
            let delegate = RestrictedWebDelegate(allowedDomains: ["x.com", "twitter.com", "twimg.com"])
            self.xDelegate = delegate
            self.xWebView = Self.makeWebView(delegate: delegate, url: xURL)
        } else {
            self.xDelegate = nil
            self.xWebView = nil
        }
    }

    func webView(for source: ServiceStatusSource) -> WKWebView? {
        source == .x ? (xWebView ?? officialWebView) : officialWebView
    }

    private static func makeWebView(delegate: RestrictedWebDelegate, url: URL) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        // Safari-style UA: x.com sniffs in-app webviews and 302s them to its
        // Safari-only x-safari-https:// escape scheme, leaving a blank page.
        configuration.applicationNameForUserAgent = "Version/26.0 Mobile/15E148 Safari/604.1"
        // Non-zero frame so the page lays out at a phone viewport during preload.
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 700),
            configuration: configuration
        )
        webView.navigationDelegate = delegate
        webView.uiDelegate = delegate
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
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
        // Unwrap x.com's Safari-escape scheme back into a normal load.
        if scheme.hasPrefix("x-safari-"),
           var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            comps.scheme = String(scheme.dropFirst("x-safari-".count))
            if let unwrapped = comps.url, isAllowed(unwrapped) {
                webView.load(URLRequest(url: unwrapped))
            }
            decisionHandler(.cancel)
            return
        }
        // Only a tapped link may leave the app; scripted redirects (X's
        // app-open attempts fire on page load) are dropped silently.
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
