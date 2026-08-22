import SwiftUI
import Combine
import FaviconFinder
import Backbone

// MARK: - Operator favicon cache

/// Fetches each operator's favicon from its website (`website` in the
/// catalog's operator data) and keeps it on disk, so the operator rows can
/// show the company mark instead of a bare colour circle.
@MainActor
final class OperatorFavicons: ObservableObject {
    static let shared = OperatorFavicons()

    /// A mark plus how to frame it: full-bleed artwork fills its chip and
    /// takes the rounded corners; artwork with its own margins sits padded
    /// on a white plate.
    struct Icon {
        let image: UIImage
        let fillsEdges: Bool
    }

    @Published private(set) var icons: [String: Icon] = [:]
    private var inFlight: Set<String> = []
    private var missed: Set<String> = []

    /// A site that had no usable icon is retried, but not on every launch.
    private static let missRetryInterval: TimeInterval = 7 * 24 * 3600
    /// Stored icons are capped; list rows never need more.
    private static let maxPixelSize: CGFloat = 256

    private static var cacheDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        return base.appendingPathComponent("OperatorIcons", isDirectory: true)
    }

    private static func iconURL(for operatorId: String) -> URL {
        cacheDirectory.appendingPathComponent(
            operatorId.replacingOccurrences(of: ":", with: "_") + ".png")
    }

    private static func missURL(for operatorId: String) -> URL {
        cacheDirectory.appendingPathComponent(
            operatorId.replacingOccurrences(of: ":", with: "_") + ".miss")
    }

    /// The cached icon, kicking off a load the first time an id is seen.
    func icon(for operatorId: String) -> Icon? {
        if let icon = icons[operatorId] { return icon }
        if !missed.contains(operatorId) { load(operatorId) }
        return nil
    }

    private func load(_ operatorId: String) {
        guard !inFlight.contains(operatorId) else { return }
        inFlight.insert(operatorId)

        let iconURL = Self.iconURL(for: operatorId)
        let missURL = Self.missURL(for: operatorId)
        let website = Catalog.operatorInfo(id: operatorId)?.website

        Task {
            defer { inFlight.remove(operatorId) }

            // Curated marks (rasterised from Wikimedia Commons, shipped in the
            // seed) cover the companies whose sites have no usable favicon,
            // and beat a scraped one when both exist.
            if let bundled = Self.bundledIcon(for: operatorId) {
                icons[operatorId] = Self.classified(bundled)
                return
            }
            if let data = try? Data(contentsOf: iconURL), let image = UIImage(data: data) {
                icons[operatorId] = Self.classified(image)
                return
            }
            if let attributes = try? FileManager.default.attributesOfItem(atPath: missURL.path),
               let stamp = attributes[.modificationDate] as? Date,
               Date().timeIntervalSince(stamp) < Self.missRetryInterval {
                missed.insert(operatorId)
                return
            }
            guard let website, let url = URL(string: website) else {
                missed.insert(operatorId)
                return
            }

            let fetched = await Self.fetch(url)
            try? FileManager.default.createDirectory(at: Self.cacheDirectory,
                                                     withIntermediateDirectories: true)
            guard let fetched else {
                missed.insert(operatorId)
                try? Data().write(to: missURL)
                return
            }
            icons[operatorId] = Self.classified(fetched)
            if let data = fetched.pngData() {
                try? data.write(to: iconURL, options: .atomic)
            }
        }
    }

    /// Samples the border of the artwork (after shaving any transparent
    /// margin): solid and rounded-square plates (メトロ, 埼玉高速, モノレール
    /// 各社…) are full-bleed and should fill their chip rather than float
    /// inside it. Half coverage is enough — a rounded square only misses its
    /// corners — while circles and free-standing glyphs stay well below it.
    private nonisolated static func classified(_ image: UIImage) -> Icon {
        let trimmed = trimmedToOpaqueBounds(image)
        let outer = edgeCoverage(trimmed, inset: 0)
        // A coloured border that only misses its rounded corners is a
        // designed plate (メトロ, 埼玉高速…) and fills the chip.
        if outer.colored >= 0.5 {
            return Icon(image: trimmed, fillsEdges: true)
        }
        // A white-bordered tile (東武) fills too — but only when its artwork
        // keeps its own margin. シーサイドライン's mascot runs to the edges,
        // and filling that reads as cramped, so it gets the padded plate.
        let inner = edgeCoverage(trimmed, inset: 3)
        return Icon(image: trimmed,
                    fillsEdges: outer.opaque >= 0.9 && inner.colored <= 0.2)
    }

    private nonisolated static func rgbaPixels(_ image: UIImage,
                                               side: Int) -> [UInt8]? {
        guard let cg = image.cgImage,
              let context = CGContext(
                  data: nil, width: side, height: side, bitsPerComponent: 8,
                  bytesPerRow: side * 4,
                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.clear(CGRect(x: 0, y: 0, width: side, height: side))
        context.interpolationQuality = .none
        context.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let buffer = context.data else { return nil }
        return Array(UnsafeBufferPointer(
            start: buffer.bindMemory(to: UInt8.self, capacity: side * side * 4),
            count: side * side * 4))
    }

    /// Favicons cropped out of larger artwork often carry a few transparent
    /// pixels of margin, which would read as "does not reach the edges".
    private nonisolated static func trimmedToOpaqueBounds(_ image: UIImage) -> UIImage {
        let side = 64
        guard let cg = image.cgImage, let pixels = rgbaPixels(image, side: side)
        else { return image }
        var minX = side, minY = side, maxX = -1, maxY = -1
        for y in 0..<side {
            for x in 0..<side where pixels[(y * side + x) * 4 + 3] >= 16 {
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            }
        }
        guard maxX >= 0,
              minX > 0 || minY > 0 || maxX < side - 1 || maxY < side - 1
        else { return image }
        let scaleX = CGFloat(cg.width) / CGFloat(side)
        let scaleY = CGFloat(cg.height) / CGFloat(side)
        let rect = CGRect(x: CGFloat(minX) * scaleX, y: CGFloat(minY) * scaleY,
                          width: CGFloat(maxX - minX + 1) * scaleX,
                          height: CGFloat(maxY - minY + 1) * scaleY)
        guard rect.width > 4, rect.height > 4, let cropped = cg.cropping(to: rect)
        else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
    }

    /// Coverage along the square ring `inset` pixels in from the border of a
    /// 24px downsample.
    private nonisolated static func edgeCoverage(
        _ image: UIImage, inset: Int
    ) -> (opaque: Double, colored: Double) {
        let side = 24
        let lo = inset, hi = side - 1 - inset
        guard lo < hi, let pixels = rgbaPixels(image, side: side) else { return (0, 0) }
        var opaque = 0, colored = 0, total = 0
        for y in lo...hi {
            for x in lo...hi where x == lo || y == lo || x == hi || y == hi {
                let p = (y * side + x) * 4
                let r = pixels[p], g = pixels[p + 1], b = pixels[p + 2], a = pixels[p + 3]
                total += 1
                guard a >= 230 else { continue }
                opaque += 1
                if !(r >= 240 && g >= 240 && b >= 240) { colored += 1 }
            }
        }
        guard total > 0 else { return (0, 0) }
        return (Double(opaque) / Double(total), Double(colored) / Double(total))
    }

    private nonisolated static func bundledIcon(for operatorId: String) -> UIImage? {
        guard let url = LineDataStore.operatorIconURL(operatorId: operatorId),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }

    /// Some sites 403 non-browser agents, so every request wears Safari's.
    private static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) "
        + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    private nonisolated static func fetch(_ url: URL) async -> UIImage? {
        if let image = await fetchViaFinder(url) { return image }
        // Sites that name no icon in their HTML often still serve one at the
        // well-known paths (and some serve PNG bytes as favicon.ico).
        if let image = await fetchWellKnown(url) { return image }
        // Last resort for markup FaviconFinder's parser rejects, like
        // りんかい線's uppercase rel="SHORTCUT ICON".
        return await fetchFromHTML(url)
    }

    private nonisolated static func fetchViaFinder(_ url: URL) async -> UIImage? {
        let configuration = FaviconFinder.Configuration(
            checkForMetaRefreshRedirect: true,
            httpHeaders: ["User-Agent": userAgent])
        guard let favicons = try? await FaviconFinder(url: url, configuration: configuration)
            .fetchFaviconURLs()
            .download()
        else { return nil }
        // `largest()` throws on any nil image, so take the max by hand.
        let best = favicons.compactMap(\.image?.image)
            .max { $0.size.width * $0.scale < $1.size.width * $1.scale }
        return usable(best)
    }

    private nonisolated static func fetchWellKnown(_ url: URL) async -> UIImage? {
        guard var root = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        root.path = ""
        root.query = nil
        guard let base = root.url else { return nil }

        var best: UIImage?
        for path in ["apple-touch-icon.png", "apple-touch-icon-precomposed.png",
                     "favicon.png", "favicon.ico"] {
            guard let image = await downloadImage(base.appendingPathComponent(path)) else { continue }
            if (best?.size.width ?? 0) * (best?.scale ?? 1) < image.size.width * image.scale {
                best = image
            }
        }
        return usable(best)
    }

    /// Fetches the homepage and scans the markup for icon links itself, with
    /// a case-insensitive rel match.
    private nonisolated static func fetchFromHTML(_ url: URL) async -> UIImage? {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let html = String(data: data, encoding: .utf8)
                  ?? String(data: data, encoding: .shiftJIS)
        else { return nil }

        let pattern = #"<link[^>]*rel\s*=\s*["']?[^"'>]*icon[^"'>]*["']?[^>]*>"#
        guard let tagRegex = try? NSRegularExpression(pattern: pattern,
                                                      options: .caseInsensitive),
              let hrefRegex = try? NSRegularExpression(pattern: #"href\s*=\s*["']?([^"'>\s]+)"#,
                                                       options: .caseInsensitive)
        else { return nil }

        let range = NSRange(html.startIndex..., in: html)
        var best: UIImage?
        for match in tagRegex.matches(in: html, range: range).prefix(6) {
            guard let tagRange = Range(match.range, in: html) else { continue }
            let tag = String(html[tagRange])
            let tagNSRange = NSRange(tag.startIndex..., in: tag)
            guard let href = hrefRegex.firstMatch(in: tag, range: tagNSRange),
                  let hrefRange = Range(href.range(at: 1), in: tag),
                  let iconURL = URL(string: String(tag[hrefRange]),
                                    relativeTo: response.url ?? url)
            else { continue }
            guard let image = await downloadImage(iconURL.absoluteURL) else { continue }
            if (best?.size.width ?? 0) * (best?.scale ?? 1) < image.size.width * image.scale {
                best = image
            }
        }
        return usable(best)
    }

    private nonisolated static func downloadImage(_ url: URL) async -> UIImage? {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200
        else { return nil }
        // A redirect into wp-includes lands on WordPress's own logo, which is
        // worse than no icon at all.
        if http.url?.path.contains("wp-includes") == true { return nil }
        return UIImage(data: data)
    }

    private nonisolated static func usable(_ image: UIImage?) -> UIImage? {
        // A 1px tracking-pixel-grade icon is worse than the colour circle.
        guard let image, image.size.width * image.scale >= 16 else { return nil }
        return downscaled(image)
    }

    private nonisolated static func downscaled(_ image: UIImage) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longest = max(pixelWidth, pixelHeight)
        guard longest > maxPixelSize else { return image }
        let scale = maxPixelSize / longest
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

// MARK: - Operator icon view

/// The operator's favicon on a white plate; the brand-colour circle until
/// one is available (or when the site has none).
struct OperatorIcon: View {
    let operatorId: String
    var fallbackColor: Color = .secondary
    var size: CGFloat = 30

    @ObservedObject private var store = OperatorFavicons.shared

    var body: some View {
        if let icon = store.icon(for: operatorId) {
            OperatorIconPlate(icon: icon, size: size)
        } else {
            Circle()
                .fill(fallbackColor)
                .frame(width: size * 0.6, height: size * 0.6)
                .frame(width: size, height: size)
        }
    }
}

/// The shared chip: full-bleed artwork fills it edge to edge, everything
/// else sits slightly padded on a white plate.
struct OperatorIconPlate: View {
    let icon: OperatorFavicons.Icon
    let size: CGFloat

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
    }

    var body: some View {
        Group {
            if icon.fillsEdges {
                Image(uiImage: icon.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    // Plates with baked-in rounded corners get their corners
                    // re-cut by the chip; white fills whatever peeks through.
                    .background(Color.white)
            } else {
                // Free-standing glyphs are content-trimmed, so they need a
                // real margin to sit like Settings glyphs rather than crowd
                // the plate.
                Image(uiImage: icon.image)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.18)
                    .frame(width: size, height: size)
                    .background(Color.white)
            }
        }
        .clipShape(shape)
        .overlay {
            // The barely-there keyline Settings draws around its glyph icons.
            shape.strokeBorder(Color.primary.opacity(0.18), lineWidth: 0.5)
        }
    }
}
