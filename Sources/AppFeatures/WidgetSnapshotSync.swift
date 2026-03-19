import Foundation
import CoreModels
#if canImport(ImageIO)
import ImageIO
import UniformTypeIdentifiers
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetSnapshotSync {
    static func syncTodayEntry(
        _ entry: EntryDay,
        dayDirectoryURL: URL,
        widgetsEnabled: Bool,
        now: Date = .now
    ) {
        let defaults = sharedDefaults()
        let snapshot = enrichedSnapshot(
            entry.widgetTodaySnapshot(now: now),
            dayDirectoryURL: dayDirectoryURL
        )

        if let encoded = try? JSONEncoder().encode(snapshot) {
            defaults.set(encoded, forKey: WidgetSharedDefaults.todaySnapshotKey)
        } else {
            defaults.removeObject(forKey: WidgetSharedDefaults.todaySnapshotKey)
        }

        reloadTimelinesIfNeeded(widgetsEnabled: widgetsEnabled)
    }

    static func mirrorPrivacyLockEnabled(_ isEnabled: Bool, widgetsEnabled: Bool) {
        let defaults = sharedDefaults()
        defaults.set(isEnabled, forKey: WidgetSharedDefaults.privacyLockEnabledKey)
        reloadTimelinesIfNeeded(widgetsEnabled: widgetsEnabled)
    }

    private static func reloadTimelinesIfNeeded(widgetsEnabled: Bool) {
        guard widgetsEnabled else { return }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private static func sharedDefaults() -> UserDefaults {
        if let testDefaults = isolatedTestDefaults {
            return testDefaults
        }

        return UserDefaults(suiteName: WidgetSharedDefaults.appGroupIdentifier) ?? .standard
    }

    private static let isolatedTestDefaults: UserDefaults? = {
        guard isTestProcess else { return nil }
        return UserDefaults(suiteName: "WidgetSnapshotSync.Tests.\(UUID().uuidString)")
    }()

    private static var isTestProcess: Bool {
        let environment = ProcessInfo.processInfo.environment
        let processName = ProcessInfo.processInfo.processName.lowercased()
        return environment["XCTestConfigurationFilePath"] != nil ||
            processName.contains("xctest") ||
            processName.contains("swift-test") ||
            NSClassFromString("XCTestCase") != nil
    }

    private static func enrichedSnapshot(
        _ snapshot: WidgetTodaySnapshot,
        dayDirectoryURL: URL
    ) -> WidgetTodaySnapshot {
        let enrichedPhotos = snapshot.photos.prefix(maxPhotosInSnapshot).map { photo in
            let fullPath = dayDirectoryURL.appendingPathComponent(photo.relativePath)
            let thumbnailData = makeThumbnailJPEGData(at: fullPath)
            return WidgetTodaySnapshotPhoto(
                id: photo.id,
                type: photo.type,
                relativePath: photo.relativePath,
                createdAt: photo.createdAt,
                thumbnailJPEGData: thumbnailData
            )
        }

        return WidgetTodaySnapshot(
            dayKeyISODate: snapshot.dayKeyISODate,
            roseExcerpt: snapshot.roseExcerpt,
            budExcerpt: snapshot.budExcerpt,
            thornExcerpt: snapshot.thornExcerpt,
            photos: Array(enrichedPhotos),
            completionCount: snapshot.completionCount,
            updatedAt: snapshot.updatedAt
        )
    }

    private static let maxPhotosInSnapshot = 8
    private static let maxRawFallbackBytes = 1_500_000

    private static func makeThumbnailJPEGData(at url: URL) -> Data? {
        #if canImport(ImageIO)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return makeFallbackJPEGData(at: url)
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 560
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return makeFallbackJPEGData(at: url)
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return makeFallbackJPEGData(at: url)
        }

        let destinationOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.78
        ]
        CGImageDestinationAddImage(destination, thumbnail, destinationOptions as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return makeFallbackJPEGData(at: url)
        }

        return output as Data
        #else
        return makeFallbackJPEGData(at: url)
        #endif
    }

    private static func makeFallbackJPEGData(at url: URL) -> Data? {
        #if canImport(UIKit)
        if let image = UIImage(contentsOfFile: url.path) {
            let scaled = scaledImage(image, maxDimension: 560)
            if let jpegData = scaled.jpegData(compressionQuality: 0.78) {
                return jpegData
            }
        }
        #endif

        guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]),
              data.count <= maxRawFallbackBytes else {
            return nil
        }
        return data
    }

    #if canImport(UIKit)
    private static func scaledImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestEdge = max(size.width, size.height)
        guard longestEdge > maxDimension, longestEdge > 0 else {
            return image
        }

        let scale = maxDimension / longestEdge
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    #endif
}
