import SwiftUI

enum AppTabZoom {
    static let coordinateSpace = "AppTabShell"
}

@MainActor
enum AppTabDeviceMetrics {
    static var safeAreaInsets: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.safeAreaInsets }
            .first ?? .zero
    }

}

/// Crops the scaled page to the preview without changing its layout.
struct AppTabPageClipShape: Shape {
    private static let tuckingStart: CGFloat = 0.85

    var progress: CGFloat
    let expanded: CGRect
    let collapsed: CGRect
    let expandedRadius: CGFloat
    let collapsedRadius: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in bounds: CGRect) -> Path {
        let zoom = min(max(progress, 0), 1)
        let width = interpolate(expanded.width, collapsed.width, zoom)
        let rect = CGRect(
            x: interpolate(expanded.minX, collapsed.minX, zoom),
            y: interpolate(expanded.minY, collapsed.minY, zoom),
            width: width,
            height: height(atWidth: width, zoom: zoom)
        )
        return Path(
            roundedRect: rect,
            cornerRadius: interpolate(expandedRadius, collapsedRadius, zoom),
            style: .continuous
        )
    }

    private func height(atWidth width: CGFloat, zoom: CGFloat) -> CGFloat {
        guard expanded.width > 0, collapsed.width > 0 else { return expanded.height }
        let start = Self.tuckingStart
        let tucking = min(max((zoom - start) / (1 - start), 0), 1)
        return interpolate(
            expanded.height * width / expanded.width,
            collapsed.height * width / collapsed.width,
            tucking * tucking * (3 - 2 * tucking)
        )
    }

    private func interpolate(_ start: CGFloat, _ end: CGFloat, _ amount: CGFloat) -> CGFloat {
        start + (end - start) * amount
    }
}
