#if os(iOS) && !targetEnvironment(macCatalyst)
import SwiftUI
import MessageUI

public enum MessageComposerResult: Sendable {
    case sent
    case cancelled
    case failed
}

public struct MessageComposerView: UIViewControllerRepresentable {
    public let bodyText: String
    public let attachmentURL: URL
    public let attachmentTypeIdentifier: String
    public let completion: @MainActor @Sendable (MessageComposerResult) -> Void

    public init(
        bodyText: String,
        attachmentURL: URL,
        attachmentTypeIdentifier: String,
        completion: @escaping @MainActor @Sendable (MessageComposerResult) -> Void
    ) {
        self.bodyText = bodyText
        self.attachmentURL = attachmentURL
        self.attachmentTypeIdentifier = attachmentTypeIdentifier
        self.completion = completion
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    public func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.body = bodyText

        if !controller.addAttachmentURL(attachmentURL, withAlternateFilename: attachmentURL.lastPathComponent),
           let data = try? Data(contentsOf: attachmentURL) {
            _ = controller.addAttachmentData(data, typeIdentifier: attachmentTypeIdentifier, filename: attachmentURL.lastPathComponent)
        }

        return controller
    }

    public func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    public final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        private let completion: @MainActor @Sendable (MessageComposerResult) -> Void

        init(completion: @escaping @MainActor @Sendable (MessageComposerResult) -> Void) {
            self.completion = completion
        }

        public func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            let mapped: MessageComposerResult
            switch result {
            case .sent:
                mapped = .sent
            case .cancelled:
                mapped = .cancelled
            case .failed:
                mapped = .failed
            @unknown default:
                mapped = .failed
            }

            Task { @MainActor in
                completion(mapped)
            }
        }
    }
}
#endif
