import SwiftUI
import UIKit
import CoreTransferable
import Backbone

// MARK: - .ohl export document

/// A `.ohl` payload for `ShareLink` — encodes a package to the custom-line
/// document type so AirDrop / Messages / Save-to-Files all work natively.
struct CustomLineDocument: Transferable {
    let package: CustomLinePackage
    let suggestedName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .overheadLine) { document in
            try JSONEncoder().encode(document.package)
        }
        .suggestedFileName { "\($0.suggestedName).ohl" }
    }
}

// MARK: - Share sheet wrapper (for a rendered image)

/// Identifiable box so a freshly rendered image can drive `.sheet(item:)`.
struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Presents the system share sheet for arbitrary items (used for the rendered
/// LCD image, whose "Save Image" covers saving to Photos without an extra
/// permission prompt).
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
