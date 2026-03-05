import Foundation
import SwiftUI
import CoreModels

#if os(macOS)
import AppKit
#endif

public enum DayShareError: LocalizedError, Sendable {
    case notReady(DayShareEligibility)
    case renderFailed
    case writeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notReady(let eligibility):
            return eligibility.disabledReason ?? "This day is not ready to share yet."
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
    private let polaroidRenderer: PolaroidStackRenderer

    public init(
        fileManager: FileManager = .default,
        temporaryRootURL: URL? = nil,
        polaroidRenderer: PolaroidStackRenderer = PolaroidStackRenderer()
    ) {
        self.fileManager = fileManager
        self.temporaryRootURL = temporaryRootURL ?? fileManager.temporaryDirectory
            .appendingPathComponent("rosebudthorn-day-share", isDirectory: true)
        self.polaroidRenderer = polaroidRenderer
    }

    public func eligibility(for entry: EntryDay) -> DayShareEligibility {
        let hasText = EntryType.allCases.contains { !textPreview(for: entry.item(for: $0)).isEmpty }
        let hasMedia = EntryType.allCases.contains { entry.item(for: $0).hasMedia }
        if hasText || hasMedia {
            return .ready
        }
        return .emptyDay
    }

    public func makePayload(
        for entry: EntryDay,
        resolvePhotoURL: @Sendable (PhotoRef) -> URL
    ) async throws -> DayShareCardPayload {
        let eligibility = eligibility(for: entry)
        guard eligibility.isReady else {
            throw DayShareError.notReady(eligibility)
        }

        let rose = makeSelection(type: .rose, item: entry.roseItem, resolvePhotoURL: resolvePhotoURL)
        let bud = makeSelection(type: .bud, item: entry.budItem, resolvePhotoURL: resolvePhotoURL)
        let thorn = makeSelection(type: .thorn, item: entry.thornItem, resolvePhotoURL: resolvePhotoURL)

        let dayTitle = PresentationFormatting.localizedDayTitle(for: entry.dayKey)
        let messageBody = messageBody(dayTitle: dayTitle, selections: [rose, bud, thorn])

        let renderOutput = try await renderCardPNG(dayTitle: dayTitle, selections: [rose, bud, thorn])

        let outputURL = try makeTemporaryOutputURL(for: entry.dayKey)
        do {
            try renderOutput.pngData.write(to: outputURL, options: .atomic)
        } catch {
            throw DayShareError.writeFailed(error.localizedDescription)
        }

        return DayShareCardPayload(
            dayKey: entry.dayKey,
            dayTitle: dayTitle,
            rose: rose,
            bud: bud,
            thorn: thorn,
            outputURL: outputURL,
            messageBody: messageBody,
            renderMetadata: renderOutput.metadata
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
        selections: [DayShareCardSelection]
    ) async throws -> PolaroidStackRenderOutput {
        do {
            return try await polaroidRenderer.render(
                dayTitle: dayTitle,
                selections: selections
            )
        } catch {
            throw DayShareError.renderFailed
        }
    }

    private func makeSelection(
        type: EntryType,
        item: EntryItem,
        resolvePhotoURL: @Sendable (PhotoRef) -> URL
    ) -> DayShareCardSelection {
        let photoRef = latestPhoto(for: item)
        let sourceURL: URL?
        if let photoRef {
            let resolved = resolvePhotoURL(photoRef)
            sourceURL = fileManager.fileExists(atPath: resolved.path) ? resolved : nil
        } else {
            sourceURL = nil
        }

        return DayShareCardSelection(
            type: type,
            textPreview: textPreview(for: item),
            ref: photoRef,
            sourceURL: sourceURL
        )
    }

    private func messageBody(dayTitle: String, selections: [DayShareCardSelection]) -> String {
        let lines = selections.compactMap { selection -> String? in
            let trimmed = selection.textPreview.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return "\(selection.type.title): \(trimmed)"
        }

        guard !lines.isEmpty else {
            return "My Rose, Bud, Thorn for \(dayTitle)."
        }

        return """
        My Rose, Bud, Thorn for \(dayTitle).

        \(lines.joined(separator: "\n"))
        """
    }

    private func textPreview(for item: EntryItem) -> String {
        let short = item.shortText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !short.isEmpty {
            return String(short.prefix(120))
        }

        let journal = item.journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        if !journal.isEmpty {
            return String(journal.prefix(120))
        }

        return ""
    }
}
