import Foundation
import Observation
import CoreModels

@MainActor
@Observable
public final class DayDetailViewModel {
    public let dayKey: LocalDayKey
    public var entry: EntryDay
    public var expandedTypes: Set<EntryType> = Set(EntryType.allCases)
    public var errorMessage: String?
    public var isSaving = false
    public var isDayShareFeatureEnabled = true
    public var isDayShareReady = false
    public var dayShareDisabledReason: String?

    private let environment: AppEnvironment

    public init(environment: AppEnvironment, dayKey: LocalDayKey) {
        self.environment = environment
        self.dayKey = dayKey
        self.entry = EntryDay.empty(dayKey: dayKey)
    }

    public func load() async {
        do {
            entry = try await environment.entryStore.load(day: dayKey)
            await refreshDayShareState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updateShortText(_ text: String, for type: EntryType) {
        var item = entry.item(for: type)
        item.shortText = text
        item.updatedAt = .now
        entry.setItem(item, for: type)
        entry.updatedAt = .now
    }

    public func updateJournal(_ text: String, for type: EntryType) {
        var item = entry.item(for: type)
        item.journalTextMarkdown = text
        item.updatedAt = .now
        entry.setItem(item, for: type)
        entry.updatedAt = .now
    }

    public func importPhoto(from sourceURL: URL, for type: EntryType) async {
        do {
            let ref = try await environment.entryStore.importPhoto(from: sourceURL, day: dayKey, type: type)
            var item = entry.item(for: type)
            item.photos.append(ref)
            item.updatedAt = .now
            entry.setItem(item, for: type)
            entry.updatedAt = .now
            await refreshDayShareState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func removePhoto(_ ref: PhotoRef, for type: EntryType) async {
        do {
            try await environment.entryStore.removePhoto(ref, day: dayKey)
            var item = entry.item(for: type)
            item.photos.removeAll { $0.id == ref.id }
            item.updatedAt = .now
            entry.setItem(item, for: type)
            entry.updatedAt = .now
            await refreshDayShareState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await environment.entryStore.save(entry)
            await refreshDayShareState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func prepareShareSaveIfNeeded() async {
        await save()
    }

    public func makeDaySharePayload() async throws -> DayShareCardPayload {
        await environment.analyticsStore.record(.dayShareInitiated)
        do {
            let payload = try await environment.dayShareService.makePayload(
                for: entry,
                resolvePhotoURL: { [environment, dayKey] ref in
                    environment.photoURL(for: ref, day: dayKey)
                }
            )
            return payload
        } catch {
            await environment.analyticsStore.record(.dayShareFailed)
            throw error
        }
    }

    public func recordDayShareSent() async {
        await environment.analyticsStore.record(.dayShareSent)
    }

    public func recordDayShareFailed() async {
        await environment.analyticsStore.record(.dayShareFailed)
    }

    public func disposeDaySharePayload(_ payload: DayShareCardPayload) async {
        await environment.dayShareService.removeTemporaryFile(at: payload.outputURL)
    }

    public func photoURL(for ref: PhotoRef) -> URL {
        environment.photoURL(for: ref, day: dayKey)
    }

    private func refreshDayShareState() async {
        let flags = environment.featureFlagStore.load(defaults: environment.featureFlags)
        isDayShareFeatureEnabled = flags.dayShareEnabled

        guard flags.dayShareEnabled else {
            isDayShareReady = false
            dayShareDisabledReason = nil
            return
        }

        let eligibility = await environment.dayShareService.eligibility(for: entry)
        isDayShareReady = eligibility.isReady
        dayShareDisabledReason = eligibility.disabledReason
    }
}
