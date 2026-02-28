import Foundation
import CoreModels
import ImageIO
import AVFoundation

public actor AttachmentRepositoryImpl: AttachmentRepository {
    private let fileManager: FileManager
    private let layout: FileLayout
    private let writer: AtomicFileWriter

    public init(
        configuration: DocumentStoreConfiguration,
        fileManager: FileManager = .default,
        writer: AtomicFileWriter = AtomicFileWriter()
    ) throws {
        self.fileManager = fileManager
        self.layout = FileLayout(rootURL: configuration.rootURL)
        self.writer = writer

        try layout.ensureBaseDirectories(using: fileManager)
    }

    public func importImage(from sourceURL: URL, day: LocalDayKey, type: EntryType) async throws -> PhotoRef {
        let attachmentDirectory = layout.attachmentDirectory(for: day, type: type)
        try fileManager.createDirectory(at: attachmentDirectory, withIntermediateDirectories: true)

        let fileExtension = normalizedExtension(for: sourceURL.pathExtension)
        let id = UUID()
        let fileName = "\(id.uuidString).\(fileExtension)"
        let destination = attachmentDirectory.appendingPathComponent(fileName)

        do {
            if sourceURL.path == destination.path {
                let data = try Data(contentsOf: sourceURL)
                try writer.write(data: data, to: destination, fileManager: fileManager)
            } else {
                let data = try Data(contentsOf: sourceURL)
                try writer.write(data: data, to: destination, fileManager: fileManager)
            }
        } catch {
            throw DomainError.storageFailure("Failed to import image: \(error.localizedDescription)")
        }

        let dimensions = imageDimensions(at: destination)

        let relativePath = destination.path.replacingOccurrences(of: layout.dayDirectory(for: day).path + "/", with: "")
        return PhotoRef(
            id: id,
            relativePath: relativePath,
            createdAt: .now,
            pixelWidth: dimensions?.0,
            pixelHeight: dimensions?.1
        )
    }

    public func importVideo(from sourceURL: URL, day: LocalDayKey, type: EntryType) async throws -> VideoRef {
        let attachmentDirectory = layout.attachmentDirectory(for: day, type: type)
        try fileManager.createDirectory(at: attachmentDirectory, withIntermediateDirectories: true)

        let fileExtension = normalizedVideoExtension(for: sourceURL.pathExtension)
        let id = UUID()
        let fileName = "\(id.uuidString).\(fileExtension)"
        let destination = attachmentDirectory.appendingPathComponent(fileName)

        do {
            let data = try Data(contentsOf: sourceURL)
            try writer.write(data: data, to: destination, fileManager: fileManager)
        } catch {
            throw DomainError.storageFailure("Failed to import video: \(error.localizedDescription)")
        }

        let metadata = videoMetadata(at: destination)
        let relativePath = destination.path.replacingOccurrences(of: layout.dayDirectory(for: day).path + "/", with: "")

        return VideoRef(
            id: id,
            relativePath: relativePath,
            createdAt: .now,
            durationSeconds: metadata.durationSeconds,
            pixelWidth: metadata.dimensions?.0,
            pixelHeight: metadata.dimensions?.1,
            hasAudio: metadata.hasAudio
        )
    }

    public func remove(_ ref: PhotoRef, day: LocalDayKey) async throws {
        try removeAttachment(relativePath: ref.relativePath, day: day)
    }

    public func removeVideo(_ ref: VideoRef, day: LocalDayKey) async throws {
        try removeAttachment(relativePath: ref.relativePath, day: day)
    }

    public func resolvePhotoURL(_ ref: PhotoRef, day: LocalDayKey) -> URL {
        layout.dayDirectory(for: day).appendingPathComponent(ref.relativePath)
    }

    private func normalizedExtension(for raw: String) -> String {
        let lower = raw.lowercased()
        if lower.isEmpty { return "jpg" }
        switch lower {
        case "jpeg", "jpg", "heic", "png", "gif", "tiff":
            return lower
        default:
            return "jpg"
        }
    }

    private func normalizedVideoExtension(for raw: String) -> String {
        let lower = raw.lowercased()
        if lower.isEmpty { return "mov" }
        switch lower {
        case "mov", "mp4", "m4v", "avi", "hevc":
            return lower
        default:
            return "mov"
        }
    }

    private func imageDimensions(at url: URL) -> (Int, Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            return nil
        }
        return (width, height)
    }

    private func videoMetadata(at url: URL) -> (durationSeconds: Double, dimensions: (Int, Int)?, hasAudio: Bool) {
        let asset = AVURLAsset(url: url)
        let duration = max(CMTimeGetSeconds(asset.duration), 0)
        let videoTrack = asset.tracks(withMediaType: .video).first

        let dimensions: (Int, Int)?
        if let videoTrack {
            let transformed = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
            dimensions = (Int(abs(transformed.width).rounded()), Int(abs(transformed.height).rounded()))
        } else {
            dimensions = nil
        }

        let hasAudio = !asset.tracks(withMediaType: .audio).isEmpty
        return (duration, dimensions, hasAudio)
    }

    private func removeAttachment(relativePath: String, day: LocalDayKey) throws {
        let dayDirectory = layout.dayDirectory(for: day)
        let fullPath = dayDirectory.appendingPathComponent(relativePath)

        guard fileManager.fileExists(atPath: fullPath.path) else {
            throw DomainError.missingAttachment(relativePath)
        }

        do {
            try fileManager.removeItem(at: fullPath)
        } catch {
            throw DomainError.storageFailure("Failed to remove attachment: \(error.localizedDescription)")
        }
    }
}
