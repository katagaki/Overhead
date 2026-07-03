import Foundation

// MARK: - App User Agent

enum AppUserAgent {

    // Safari on iOS 18.6
    static let safariIOS186 =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) " +
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1"

    static func applying(to config: URLSessionConfiguration) -> URLSessionConfiguration {
        var headers = config.httpAdditionalHeaders ?? [:]
        headers["User-Agent"] = safariIOS186
        config.httpAdditionalHeaders = headers
        return config
    }
}
