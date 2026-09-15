import UIKit

@MainActor
enum AppTabSnapshotter {
    private static let targetWidth: CGFloat = 200

    static func captureVisiblePage() -> UIImage? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first,
              window.bounds.width > 0 else { return nil }

        let insets = window.safeAreaInsets
        let scale = targetWidth / window.bounds.width
        let height = window.bounds.height - insets.top - insets.bottom
        guard height > 0 else { return nil }

        let size = CGSize(width: targetWidth, height: height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = window.traitCollection.displayScale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            window.drawHierarchy(
                in: CGRect(
                    x: 0,
                    y: -insets.top * scale,
                    width: targetWidth,
                    height: window.bounds.height * scale
                ),
                afterScreenUpdates: false
            )
        }
    }
}
