import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
final class PhotoShareViewController: UIViewController {
    private let model = PhotoShareComposerModel()
    private var hostingController: UIHostingController<PhotoShareComposerView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHostingController()
        Task {
            await loadSharedImage()
        }
    }

    private func configureHostingController() {
        let rootView = PhotoShareComposerView(
            model: model,
            onCancel: { [weak self] in
                self?.cancelShare()
            },
            onSend: { [weak self] in
                self?.sendSharedPhoto()
            },
            onDone: { [weak self] in
                self?.completeShare()
            },
            onOpenApp: { [weak self] in
                self?.openHostApp()
            }
        )

        let hostingController = UIHostingController(rootView: rootView)
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
    }

    private func loadSharedImage() async {
        do {
            let provider = try singleImageProvider()
            let imageURL = try await loadImageFileURL(from: provider)
            guard let preview = UIImage(contentsOfFile: imageURL.path) else {
                model.viewState = .failure("The selected photo couldn't be previewed.")
                return
            }

            model.sourceImageURL = imageURL
            model.previewImage = preview
            model.viewState = .ready
        } catch let shareError as SharedPhotoImportError {
            model.viewState = .failure(shareError.localizedDescription)
        } catch {
            model.viewState = .failure(error.localizedDescription)
        }
    }

    private func sendSharedPhoto() {
        guard let sourceImageURL = model.sourceImageURL else {
            model.viewState = .failure("No photo is available to share.")
            return
        }

        model.isSending = true
        Task {
            defer { model.isSending = false }
            do {
                let service = try SharedPhotoImportService()
                _ = try await service.importPhoto(from: sourceImageURL, type: model.selectedType)
                model.viewState = .success("Saved to today's \(model.selectedType.title).")
            } catch let shareError as SharedPhotoImportError {
                model.viewState = .failure(shareError.localizedDescription)
            } catch {
                model.viewState = .failure(error.localizedDescription)
            }
        }
    }

    private func singleImageProvider() throws -> NSItemProvider {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            throw SharedPhotoImportError.unsupportedItem
        }

        let providers = extensionItems
            .flatMap { $0.attachments ?? [] }
            .filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }

        guard !providers.isEmpty else {
            throw SharedPhotoImportError.unsupportedItem
        }

        guard providers.count == 1 else {
            throw SharedPhotoImportError.singlePhotoRequired
        }

        return providers[0]
    }

    private func loadImageFileURL(from provider: NSItemProvider) async throws -> URL {
        if let url = try? await loadFileRepresentationURL(from: provider) {
            return url
        }

        let data = try await loadDataRepresentation(from: provider)
        let fileExtension = Self.preferredFileExtension(for: provider)
        let destinationURL = Self.temporaryImageURL(fileExtension: fileExtension)
        try data.write(to: destinationURL, options: .atomic)
        return destinationURL
    }

    private func loadFileRepresentationURL(from provider: NSItemProvider) async throws -> URL {
        let fallbackExtension = Self.preferredFileExtension(for: provider)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let url else {
                    continuation.resume(throwing: SharedPhotoImportError.unsupportedItem)
                    return
                }

                do {
                    let ext = url.pathExtension.isEmpty ? fallbackExtension : url.pathExtension
                    let destinationURL = Self.temporaryImageURL(fileExtension: ext)
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    continuation.resume(returning: destinationURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func loadDataRepresentation(from provider: NSItemProvider) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data else {
                    continuation.resume(throwing: SharedPhotoImportError.unsupportedItem)
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }

    nonisolated private static func preferredFileExtension(for provider: NSItemProvider) -> String {
        for identifier in provider.registeredTypeIdentifiers {
            guard let type = UTType(identifier), type.conforms(to: .image) else {
                continue
            }

            if let fileExtension = type.preferredFilenameExtension {
                return fileExtension
            }
        }

        return "jpg"
    }

    nonisolated private static func temporaryImageURL(fileExtension: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)
    }

    private func openHostApp() {
        guard let url = URL(string: "rosebudthorn://today?source=share-extension") else {
            completeShare()
            return
        }

        extensionContext?.open(url, completionHandler: { [weak self] _ in
            Task { @MainActor in
                self?.completeShare()
            }
        })
    }

    private func completeShare() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func cancelShare() {
        let error = NSError(domain: "RoseBudThorn.Share", code: NSUserCancelledError)
        extensionContext?.cancelRequest(withError: error)
    }
}
