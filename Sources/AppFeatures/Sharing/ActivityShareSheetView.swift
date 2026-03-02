#if os(iOS)
import SwiftUI
import UIKit

public struct ActivityShareSheetView: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public let completion: @MainActor @Sendable (Bool) -> Void

    public init(
        activityItems: [Any],
        completion: @escaping @MainActor @Sendable (Bool) -> Void = { _ in }
    ) {
        self.activityItems = activityItems
        self.completion = completion
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            Task { @MainActor in
                completion(completed)
            }
        }
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
