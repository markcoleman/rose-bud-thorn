import XCTest
@testable import AppFeatures
@testable import DocumentStore
@testable import CoreModels

@MainActor
final class DayDetailViewModelTests: XCTestCase {
    func testRemoveDayDeletesPersistedEntryFromStore() async throws {
        let environment = try makeEnvironment()
        let dayKey = LocalDayKey(isoDate: "2026-03-01", timeZoneID: "America/New_York")
        var entry = EntryDay.empty(dayKey: dayKey)
        entry.roseItem.shortText = "Will be removed"
        entry.roseItem.updatedAt = .now
        entry.updatedAt = .now
        try await environment.entryStore.save(entry)

        let model = DayDetailViewModel(environment: environment, dayKey: dayKey)
        await model.load()

        let removed = await model.removeDay()
        XCTAssertTrue(removed)

        let persisted = try await environment.entryRepository.load(day: dayKey)
        XCTAssertNil(persisted)
    }

    func testRemoveDayOnMissingEntryReturnsSuccessWithoutError() async throws {
        let environment = try makeEnvironment()
        let dayKey = LocalDayKey(isoDate: "2026-03-02", timeZoneID: "America/New_York")
        let model = DayDetailViewModel(environment: environment, dayKey: dayKey)

        let removed = await model.removeDay()
        XCTAssertTrue(removed)
        XCTAssertFalse(model.isRemoving)
        XCTAssertNil(model.errorMessage)
    }

    private func makeEnvironment() throws -> AppEnvironment {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return try AppEnvironment(configuration: DocumentStoreConfiguration(rootURL: root))
    }
}
