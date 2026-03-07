import Foundation
import CoreModels
import CoreDate
import DocumentStore

enum SharedPhotoImportError: LocalizedError {
    case unsupportedItem
    case singlePhotoRequired
    case missingCaptureTimestamp
    case nonTodayPhoto(expected: String, actual: String)

    var errorDescription: String? {
        switch self {
        case .unsupportedItem:
            return "Only image shares are supported."
        case .singlePhotoRequired:
            return "Share exactly one photo at a time."
        case .missingCaptureTimestamp:
            return "This photo is missing a capture timestamp, so it can't be attached to today."
        case .nonTodayPhoto(let expected, let actual):
            return "Only photos captured on \(expected) are allowed. This photo appears from \(actual)."
        }
    }
}

struct SharedPhotoImportService {
    private let dayCalculator: DayKeyCalculator
    private let entryRepository: EntryRepositoryImpl
    private let attachmentRepository: AttachmentRepositoryImpl

    init(
        appGroupID: String = AppGroupConstants.appGroupIdentifier,
        dayCalculator: DayKeyCalculator = DayKeyCalculator()
    ) throws {
        self.dayCalculator = dayCalculator
        let configuration = try DocumentStoreConfiguration.appGroup(appGroupID: appGroupID)
        let entryRepository = try EntryRepositoryImpl(configuration: configuration)
        let attachmentRepository = try AttachmentRepositoryImpl(configuration: configuration)

        self.entryRepository = entryRepository
        self.attachmentRepository = attachmentRepository
    }

    @discardableResult
    func importPhoto(from sourceURL: URL, type: EntryType, now: Date = .now, timeZone: TimeZone = .current) async throws -> LocalDayKey {
        let dayKey = dayCalculator.dayKey(for: now, timeZone: timeZone)

        switch ImageCaptureDateValidator.validateImage(at: sourceURL, matches: dayKey, dayCalculator: dayCalculator) {
        case .matches:
            break
        case .missingTimestamp:
            throw SharedPhotoImportError.missingCaptureTimestamp
        case .mismatched(let actual):
            throw SharedPhotoImportError.nonTodayPhoto(expected: dayKey.isoDate, actual: actual.isoDate)
        }

        var entry = try await entryRepository.load(day: dayKey) ?? EntryDay.empty(dayKey: dayKey, now: now)
        let photoRef = try await attachmentRepository.importImage(from: sourceURL, day: dayKey, type: type)

        var item = entry.item(for: type)
        item.photos.append(photoRef)
        item.updatedAt = .now
        entry.setItem(item, for: type)
        entry.updatedAt = .now

        try await entryRepository.save(entry)
        return dayKey
    }
}
