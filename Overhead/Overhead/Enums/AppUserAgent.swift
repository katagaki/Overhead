import Foundation

// MARK: - App User Agent

/// The user agent used for all network requests in the app.
enum AppUserAgent {

    /// Safari on iOS 18.6
    static let safariIOS18_6 =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) " +
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1"

    /// Returns the configuration with the app-wide User-Agent header applied.
    /// Every URLSession in the app must be created through this.
    static func applying(to config: URLSessionConfiguration) -> URLSessionConfiguration {
        var headers = config.httpAdditionalHeaders ?? [:]
        headers["User-Agent"] = safariIOS18_6
        config.httpAdditionalHeaders = headers
        return config
    }
}
