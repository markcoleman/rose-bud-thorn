import Foundation
import SwiftUI
import CoreModels

#if os(macOS)
import AppKit
#endif

public enum DayShareError: LocalizedError, Sendable {
    case notReady(DayShareEligibility)
    case missingPhotoFile(type: EntryType)
    case renderFailed
    case writeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notReady(let eligibility):
            return eligibility.disabledReason ?? "This day is not ready to share yet."
        case .missingPhotoFile(let type):
            return "Could not find the selected \(type.title) photo to share."
        case .renderFailed:
            return "Unable to generate the share card right now."
        case .writeFailed(let description):
            return "Unable to prepare the share card file: \(description)"
        }
    }
}

public actor DayShareService {
    private let fileManager: FileManager
    private let temporaryRootURL: URL

    public init(
        fileManager: FileManager = .default,
        temporaryRootURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.temporaryRootURL = temporaryRootURL ?? fileManager.temporaryDirectory
            .appendingPathComponent("rosebudthorn-day-share", isDirectory: true)
    }

    public func eligibility(for entry: EntryDay) -> DayShareEligibility {
        var missing: [EntryType] = []

        for type in EntryType.allCases {
            if entry.item(for: type).photos.isEmpty {
                missing.append(type)
            }
        }

        if missing.isEmpty {
            return .ready
        }

        return .missingPhotos(types: missing)
    }

    public func makePayload(
        for entry: EntryDay,
        resolvePhotoURL: @Sendable (PhotoRef) -> URL
    ) async throws -> DayShareCardPayload {
        let eligibility = eligibility(for: entry)
        guard eligibility.isReady else {
            throw DayShareError.notReady(eligibility)
        }

        guard let roseRef = latestPhoto(for: entry.roseItem) else {
            throw DayShareError.notReady(.missingPhotos(types: [.rose]))
        }
        guard let budRef = latestPhoto(for: entry.budItem) else {
            throw DayShareError.notReady(.missingPhotos(types: [.bud]))
        }
        guard let thornRef = latestPhoto(for: entry.thornItem) else {
            throw DayShareError.notReady(.missingPhotos(types: [.thorn]))
        }

        let roseURL = resolvePhotoURL(roseRef)
        let budURL = resolvePhotoURL(budRef)
        let thornURL = resolvePhotoURL(thornRef)

        guard fileManager.fileExists(atPath: roseURL.path) else {
            throw DayShareError.missingPhotoFile(type: .rose)
        }
        guard fileManager.fileExists(atPath: budURL.path) else {
            throw DayShareError.missingPhotoFile(type: .bud)
        }
        guard fileManager.fileExists(atPath: thornURL.path) else {
            throw DayShareError.missingPhotoFile(type: .thorn)
        }

        let dayTitle = PresentationFormatting.localizedDayTitle(for: entry.dayKey)
        let messageBody = "My Rose, Bud, Thorn for \(dayTitle)."

        let pngData = try await renderCardPNG(
            dayTitle: dayTitle,
            roseURL: roseURL,
            budURL: budURL,
            thornURL: thornURL
        )

        let outputURL = try makeTemporaryOutputURL(for: entry.dayKey)
        do {
            try pngData.write(to: outputURL, options: .atomic)
        } catch {
            throw DayShareError.writeFailed(error.localizedDescription)
        }

        return DayShareCardPayload(
            dayKey: entry.dayKey,
            dayTitle: dayTitle,
            rose: DayShareCardSelection(type: .rose, ref: roseRef, sourceURL: roseURL),
            bud: DayShareCardSelection(type: .bud, ref: budRef, sourceURL: budURL),
            thorn: DayShareCardSelection(type: .thorn, ref: thornRef, sourceURL: thornURL),
            outputURL: outputURL,
            messageBody: messageBody
        )
    }

    public func removeTemporaryFile(at url: URL) {
        guard url.path.hasPrefix(temporaryRootURL.path) else { return }
        try? fileManager.removeItem(at: url)
    }

    private func latestPhoto(for item: EntryItem) -> PhotoRef? {
        item.photos.max { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    private func makeTemporaryOutputURL(for dayKey: LocalDayKey) throws -> URL {
        let token = DayShareNudgeStore.dayToken(for: dayKey)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let directory = temporaryRootURL.appendingPathComponent(dayKey.isoDate, isDirectory: true)

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw DayShareError.writeFailed(error.localizedDescription)
        }

        return directory
            .appendingPathComponent("\(token)-\(UUID().uuidString)")
            .appendingPathExtension("png")
    }

    private func renderCardPNG(
        dayTitle: String,
        roseURL: URL,
        budURL: URL,
        thornURL: URL
    ) async throws -> Data {
        let size = CGSize(width: 1200, height: 900)
        guard let pngData: Data = await MainActor.run(body: { () -> Data? in
            let cardView = DayShareCardView(
                dayTitle: dayTitle,
                roseURL: roseURL,
                budURL: budURL,
                thornURL: thornURL
            )
            .frame(width: size.width, height: size.height)

            let renderer = ImageRenderer(content: cardView)
            renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
            #if os(iOS)
            return renderer.uiImage?.pngData()
            #elseif os(macOS)
            guard let image = renderer.nsImage,
                  let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData) else {
                return nil
            }
            return bitmap.representation(using: .png, properties: [:])
            #else
            return nil
            #endif
        }) else {
            throw DayShareError.renderFailed
        }

        return pngData
    }
}
