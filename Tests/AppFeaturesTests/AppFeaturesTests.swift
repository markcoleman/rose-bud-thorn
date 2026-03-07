import XCTest
@testable import AppFeatures
@testable import DocumentStore
@testable import CoreModels
@testable import CoreDate

@MainActor
final class AppFeaturesTests: XCTestCase {
    private func makeEnvironment() throws -> AppEnvironment {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return try AppEnvironment(configuration: DocumentStoreConfiguration(rootURL: root))
    }

    private func makeInMemoryEntryStore() -> EntryStore {
        EntryStore(
            entries: InMemoryEntryRepository(),
            attachments: NoopAttachmentRepository()
        )
    }

    private func writeAttachmentFile(
        in environment: AppEnvironment,
        dayKey: LocalDayKey,
        ref: PhotoRef
    ) throws {
        let dayDirectory = FileLayout(rootURL: environment.configuration.rootURL).dayDirectory(for: dayKey)
        let outputURL = dayDirectory.appendingPathComponent(ref.relativePath)
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("image-bytes".utf8).write(to: outputURL)
    }

    func testTodayCaptureFlowPersistsEntry() async throws {
        let environment = try makeEnvironment()
        let fixedDate = Date(timeIntervalSince1970: 1_772_201_600) // 2026-03-05
        let viewModel = TodayViewModel(environment: environment, now: fixedDate)

        await viewModel.load()
        viewModel.updateShortText("Great coffee", for: .rose)
        viewModel.updateShortText("New project kickoff", for: .bud)
        viewModel.updateJournalText("Commute was rough.", for: .thorn)
        try await viewModel.saveNow()

        let dayKey = viewModel.dayKey
        let persisted = try await environment.entryStore.load(day: dayKey)

        XCTAssertEqual(persisted.roseItem.shortText, "Great coffee")
        XCTAssertEqual(persisted.budItem.shortText, "New project kickoff")
        XCTAssertEqual(persisted.thornItem.journalTextMarkdown, "Commute was rough.")
    }

    func testTodayViewModelImportVideoPersistsEntry() async throws {
        let environment = try makeEnvironment()
        let viewModel = TodayViewModel(environment: environment, now: Date(timeIntervalSince1970: 1_772_201_600))
        await viewModel.load()

        let source = environment.configuration.rootURL.appendingPathComponent("captured.mov")
        try Data("video-bytes".utf8).write(to: source)

        try await viewModel.importVideoNow(from: source, for: .bud, targetDay: viewModel.dayKey)
        let persisted = try await environment.entryStore.load(day: viewModel.dayKey)

        XCTAssertEqual(persisted.budItem.videos.count, 1)
        XCTAssertTrue(persisted.budItem.videos[0].relativePath.contains("bud/attachments"))
    }

    func testCaptureLaunchRequestParserParsesTypedDeepLink() {
        let url = URL(string: "rosebudthorn://capture?source=widget&type=bud")!
        let request = RootAppView.captureLaunchRequest(from: url)

        XCTAssertEqual(request?.type, .bud)
        XCTAssertEqual(request?.source, "widget")
    }

    func testSummaryLaunchRequestParserParsesWeeklySummaryDeepLink() {
        let url = URL(string: "rosebudthorn://summary?period=week&action=open-current&source=intent")!
        let request = RootAppView.summaryLaunchRequest(from: url)

        XCTAssertEqual(request?.action, .openCurrentWeeklySummary)
        XCTAssertEqual(request?.source, "intent")
    }

    func testSummaryLaunchRequestParserParsesWeeklyReviewDeepLink() {
        let url = URL(string: "rosebudthorn://summary?action=start-weekly-review&source=intent")!
        let request = RootAppView.summaryLaunchRequest(from: url)

        XCTAssertEqual(request?.action, .startWeeklyReview)
        XCTAssertEqual(request?.source, "intent")
    }

    func testReminderPreferencesPersistAcrossStoreReload() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = ReminderPreferencesStore(defaults: defaults)
        let prefs = ReminderPreferences(
            isEnabled: true,
            startHour: 9,
            endHour: 21,
            includeWeekends: false,
            allowsEndOfDayFallback: true
        )

        store.save(prefs)
        XCTAssertEqual(store.load(), prefs)
    }

    func testPromptSelectorAvoidsConsecutiveDuplicatesInDeterministicMode() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let preferencesStore = PromptPreferencesStore(defaults: defaults)
        let cacheStore = PromptRotationCacheStore(defaults: defaults)
        let selector = PromptSelector(preferencesStore: preferencesStore, cacheStore: cacheStore)
        let preferences = PromptPreferences(
            isEnabled: true,
            themePreference: .gratitude,
            selectionMode: .deterministic,
            hiddenTypes: []
        )

        let firstDay = LocalDayKey(isoDate: "2026-03-01", timeZoneID: "America/Los_Angeles")
        let secondDay = LocalDayKey(isoDate: "2026-03-02", timeZoneID: "America/Los_Angeles")

        let firstPrompt = selector.prompt(for: .rose, dayKey: firstDay, preferences: preferences)
        let secondPrompt = selector.prompt(for: .rose, dayKey: secondDay, preferences: preferences)

        XCTAssertNotNil(firstPrompt)
        XCTAssertNotNil(secondPrompt)
        XCTAssertNotEqual(firstPrompt?.text, secondPrompt?.text)
    }

    func testPromptSelectorSkipsHiddenPromptTypes() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let selector = PromptSelector(
            preferencesStore: PromptPreferencesStore(defaults: defaults),
            cacheStore: PromptRotationCacheStore(defaults: defaults)
        )

        let preferences = PromptPreferences(
            isEnabled: true,
            themePreference: .gratitude,
            selectionMode: .deterministic,
            hiddenTypes: [.thorn]
        )
        let dayKey = LocalDayKey(isoDate: "2026-03-02", timeZoneID: "America/Los_Angeles")

        XCTAssertNil(selector.prompt(for: .thorn, dayKey: dayKey, preferences: preferences))
        XCTAssertNotNil(selector.prompt(for: .rose, dayKey: dayKey, preferences: preferences))
    }

    func testIntentLaunchStoreQueuesAndConsumesDeepLink() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let url = URL(string: "rosebudthorn://weekly-review?source=test")!

        IntentLaunchStore.queueDeepLink(url, defaults: defaults)
        XCTAssertEqual(IntentLaunchStore.consumePendingURL(defaults: defaults), url)
        XCTAssertNil(IntentLaunchStore.consumePendingURL(defaults: defaults))
    }

    func testEnvironmentDisablesReminderSchedulingInTests() throws {
        let environment = try makeEnvironment()
        XCTAssertFalse(environment.featureFlags.remindersEnabled)
    }

    func testWeeklyIntentionStorePersistsAdjacentToSummaryArtifacts() async throws {
        let environment = try makeEnvironment()
        let weekKey = "2026-W10"

        try await environment.weeklyIntentionStore.save(text: "Pause before reacting.", for: weekKey)
        let loaded = try await environment.weeklyIntentionStore.load(for: weekKey)

        XCTAssertEqual(loaded?.text, "Pause before reacting.")

        let layout = FileLayout(rootURL: environment.configuration.rootURL)
        let intentionURL = layout.summaryDirectory(for: .week).appendingPathComponent("\(weekKey).intention.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: intentionURL.path))
    }

    func testWeeklyReviewViewModelLoadsPreviousWeekIntention() async throws {
        let environment = try makeEnvironment()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 12))!
        let periodCalculator = PeriodKeyCalculator()
        let previousDate = calendar.date(byAdding: .day, value: -7, to: referenceDate)!
        let previousWeekKey = periodCalculator.key(for: previousDate, period: .week, timeZone: .current)

        try await environment.weeklyIntentionStore.save(text: "Stay consistent.", for: previousWeekKey)

        let viewModel = WeeklyReviewViewModel(environment: environment, referenceDate: referenceDate)
        await viewModel.load()

        XCTAssertEqual(viewModel.previousWeekIntention?.text, "Stay consistent.")
    }

    func testCompletionTrackerUpdatesWhenTodayEntrySaved() async throws {
        let dayCalculator = DayKeyCalculator()
        let entryStore = makeInMemoryEntryStore()
        let tracker = EntryCompletionTracker(entryStore: entryStore, dayCalculator: dayCalculator)

        var entry = EntryDay.empty(dayKey: dayCalculator.dayKey(for: .now))
        entry.roseItem.shortText = "Done"
        try await entryStore.save(entry)

        let partialSummary = try await tracker.summary(for: .now, timeZone: .current)
        XCTAssertFalse(partialSummary.isTodayComplete)
        XCTAssertEqual(partialSummary.streakCount, 0)
        XCTAssertEqual(partialSummary.last7DaysCompleted.filter(\.self).count, 0)

        entry.budItem.shortText = "Done"
        entry.thornItem.shortText = "Done"
        try await entryStore.save(entry)

        let summary = try await tracker.summary(for: .now, timeZone: .current)
        XCTAssertTrue(summary.isTodayComplete)
        XCTAssertEqual(summary.streakCount, 1)
        XCTAssertEqual(summary.last7DaysCompleted.filter(\.self).count, 1)
    }

    func testCompletionTrackerReturnsEmptySummaryWithoutEntries() async throws {
        let tracker = EntryCompletionTracker(entryStore: makeInMemoryEntryStore(), dayCalculator: DayKeyCalculator())

        let summary = try await tracker.summary(for: Date(timeIntervalSince1970: 1_772_201_600), timeZone: .current)

        XCTAssertFalse(summary.isTodayComplete)
        XCTAssertEqual(summary.streakCount, 0)
        XCTAssertEqual(summary.previousStreakCount, 0)
        XCTAssertEqual(summary.last7DaysCompleted, Array(repeating: false, count: 7))
    }

    func testCompletionTrackerUsesProvidedTimezoneForConsecutiveDays() async throws {
        let dayCalculator = DayKeyCalculator()
        let entryStore = makeInMemoryEntryStore()
        let tracker = EntryCompletionTracker(entryStore: entryStore, dayCalculator: dayCalculator)
        let tz = TimeZone(identifier: "America/Los_Angeles")!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12))!

        for offset in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -offset, to: now)!
            let dayKey = dayCalculator.dayKey(for: date, timeZone: tz)
            var entry = EntryDay.empty(dayKey: dayKey)
            entry.roseItem.shortText = "Rose \(offset)"
            entry.budItem.shortText = "Bud \(offset)"
            entry.thornItem.shortText = "Thorn \(offset)"
            try await entryStore.save(entry)
        }

        let summary = try await tracker.summary(for: now, timeZone: tz)
        XCTAssertTrue(summary.isTodayComplete)
        XCTAssertEqual(summary.streakCount, 3)
        XCTAssertEqual(summary.last7DaysCompleted.filter(\.self).count, 3)
    }

    func testLocalAnalyticsStorePersistsCountsAcrossReload() async {
        let suite = "LocalAnalyticsStoreTests.\(UUID().uuidString)"
        let dayCalculator = DayKeyCalculator()
        let store = LocalAnalyticsStore(
            defaults: UserDefaults(suiteName: suite)!,
            dayCalculator: dayCalculator
        )
        let tz = TimeZone(identifier: "America/Los_Angeles")!
        let date = Date(timeIntervalSince1970: 1_772_201_600)
        let dayKey = dayCalculator.dayKey(for: date, timeZone: tz)

        await store.record(.todayScreenOpened, at: date, timeZone: tz)
        await store.record(.todayScreenOpened, count: 2, at: date, timeZone: tz)

        let total = await store.totalCount(for: .todayScreenOpened)
        let daily = await store.dayCount(for: .todayScreenOpened, dayKey: dayKey)
        XCTAssertEqual(total, 3)
        XCTAssertEqual(daily, 3)

        let reloaded = LocalAnalyticsStore(
            defaults: UserDefaults(suiteName: suite)!,
            dayCalculator: dayCalculator
        )
        let reloadedTotal = await reloaded.totalCount(for: .todayScreenOpened)
        let reloadedDaily = await reloaded.dayCount(for: .todayScreenOpened, dayKey: dayKey)
        XCTAssertEqual(reloadedTotal, 3)
        XCTAssertEqual(reloadedDaily, 3)
    }

    func testLocalAnalyticsStoreRecordOncePerDayIsDeduplicated() async {
        let defaults = UserDefaults(suiteName: "LocalAnalyticsStoreTests.\(UUID().uuidString)")!
        let store = LocalAnalyticsStore(defaults: defaults, dayCalculator: DayKeyCalculator())
        let dayKey = LocalDayKey(isoDate: "2026-03-10", timeZoneID: "America/Los_Angeles")

        let first = await store.recordOncePerDay(.completionRingViewed, dayKey: dayKey)
        let second = await store.recordOncePerDay(.completionRingViewed, dayKey: dayKey)

        XCTAssertTrue(first)
        XCTAssertFalse(second)
        let total = await store.totalCount(for: .completionRingViewed)
        let daily = await store.dayCount(for: .completionRingViewed, dayKey: dayKey)
        XCTAssertEqual(total, 1)
        XCTAssertEqual(daily, 1)
    }

    func testTodayViewModelRecordsDailyCompletionOncePerDay() async throws {
        let environment = try makeEnvironment()
        let viewModel = TodayViewModel(environment: environment)

        await viewModel.load()
        let today = viewModel.dayKey

        let openCount = await environment.analyticsStore.dayCount(for: .todayScreenOpened, dayKey: today)
        let initialCompletionCount = await environment.analyticsStore.dayCount(for: .dailyEntryCompleted, dayKey: today)
        XCTAssertEqual(openCount, 1)
        XCTAssertEqual(initialCompletionCount, 0)

        viewModel.updateShortText("Rose done", for: .rose)
        try await viewModel.saveNow()
        let firstCompletionCount = await environment.analyticsStore.dayCount(for: .dailyEntryCompleted, dayKey: today)
        XCTAssertEqual(firstCompletionCount, 0)

        viewModel.updateShortText("Bud done", for: .bud)
        try await viewModel.saveNow()
        let secondCompletionCount = await environment.analyticsStore.dayCount(for: .dailyEntryCompleted, dayKey: today)
        XCTAssertEqual(secondCompletionCount, 0)

        viewModel.updateShortText("Thorn done", for: .thorn)
        try await viewModel.saveNow()
        let thirdCompletionCount = await environment.analyticsStore.dayCount(for: .dailyEntryCompleted, dayKey: today)
        XCTAssertEqual(thirdCompletionCount, 1)

        viewModel.updateShortText("Updated text only", for: .rose)
        try await viewModel.saveNow()
        let fourthCompletionCount = await environment.analyticsStore.dayCount(for: .dailyEntryCompleted, dayKey: today)
        XCTAssertEqual(fourthCompletionCount, 1)
    }

    func testTodayViewModelExposesThreeOfThreeCompletionState() async throws {
        let environment = try makeEnvironment()
        let model = TodayViewModel(environment: environment)
        await model.load()
        let today = model.dayKey

        XCTAssertFalse(model.isThreeOfThreeComplete)
        XCTAssertEqual(model.todayCompletionCount, 0)

        model.updateShortText("Rose", for: .rose)
        model.updateShortText("Bud", for: .bud)
        model.updateShortText("Thorn", for: .thorn)
        try await model.saveNow()

        XCTAssertTrue(model.isThreeOfThreeComplete)
        XCTAssertEqual(model.todayCompletionCount, 3)
        XCTAssertEqual(model.typeCompletionStates[.rose], true)
        XCTAssertEqual(model.typeCompletionStates[.bud], true)
        XCTAssertEqual(model.typeCompletionStates[.thorn], true)

        let firstCompletionCount = await environment.analyticsStore.dayCount(for: .dailyEntryCompleted, dayKey: today)
        XCTAssertEqual(firstCompletionCount, 1)
    }

    func testInsightEngineProducesDeterministicCards() async throws {
        let environment = try makeEnvironment()
        let tz = TimeZone(identifier: "America/Los_Angeles")!
        let dayCalculator = DayKeyCalculator()

        let day1 = dayCalculator.dayKey(for: Date(timeIntervalSince1970: 1_772_201_600), timeZone: tz) // 2026-03-05
        let day2 = dayCalculator.dayKey(for: Date(timeIntervalSince1970: 1_772_288_000), timeZone: tz) // 2026-03-06

        var first = EntryDay.empty(dayKey: day1)
        first.roseItem.shortText = "Sunny walk"
        first.tags = ["health", "family"]
        first.mood = 4
        try await environment.entryStore.save(first)

        var second = EntryDay.empty(dayKey: day2)
        second.budItem.shortText = "Project momentum"
        second.tags = ["work", "health"]
        second.mood = 5
        try await environment.entryStore.save(second)

        let cardsA = try await environment.insightEngine.cards(for: Date(timeIntervalSince1970: 1_772_288_000), timeZone: tz)
        let cardsB = try await environment.insightEngine.cards(for: Date(timeIntervalSince1970: 1_772_288_000), timeZone: tz)

        XCTAssertEqual(cardsA.map(\.id), cardsB.map(\.id))
        XCTAssertEqual(cardsA.map(\.body), cardsB.map(\.body))
        XCTAssertTrue(cardsA.contains { $0.type == .consistency })
    }

    func testMemoryResurfacingAppliesCooldownAfterSnooze() async throws {
        let environment = try makeEnvironment()
        let tz = TimeZone(identifier: "America/Los_Angeles")!
        let dayCalculator = DayKeyCalculator()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        let reference = calendar.date(from: DateComponents(year: 2026, month: 3, day: 22, hour: 12))!
        let historical = calendar.date(from: DateComponents(year: 2025, month: 3, day: 22, hour: 12))!

        let historicalKey = dayCalculator.dayKey(for: historical, timeZone: tz)
        var historicalEntry = EntryDay.empty(dayKey: historicalKey)
        historicalEntry.roseItem.shortText = "Old reflection"
        try await environment.entryStore.save(historicalEntry)

        let initial = try await environment.memoryResurfacingService.memories(for: reference, timeZone: tz)
        XCTAssertEqual(initial.count, 1)

        if let memory = initial.first {
            _ = try await environment.memoryResurfacingService.record(
                decisionAction: .snooze,
                for: memory,
                referenceDate: reference,
                timeZone: tz
            )
        }

        let afterSnooze = try await environment.memoryResurfacingService.memories(for: reference, timeZone: tz)
        XCTAssertTrue(afterSnooze.isEmpty)
    }

    func testCommitmentServiceLifecycle() async throws {
        let environment = try makeEnvironment()
        let weekKey = "2026-W12"

        let saved = try await environment.commitmentService.save(text: "Walk every morning", for: weekKey)
        XCTAssertEqual(saved?.status, .planned)

        let loaded = try await environment.commitmentService.load(for: weekKey)
        XCTAssertEqual(loaded?.text, "Walk every morning")

        let completed = try await environment.commitmentService.markCompleted(for: weekKey)
        XCTAssertEqual(completed?.status, .completed)
        XCTAssertNotNil(completed?.completedAt)
    }

    func testPresentationFormattingSummaryRangeUsesReadableRangeForValidKey() {
        let artifact = SummaryArtifact(
            period: .week,
            key: "2026-W09",
            generatedAt: Date(timeIntervalSince1970: 1_772_201_600),
            contentMarkdown: "",
            highlights: [],
            photoRefs: []
        )

        let text = PresentationFormatting.summaryRangeText(
            for: artifact,
            timeZone: TimeZone(identifier: "America/Los_Angeles")!,
            locale: Locale(identifier: "en_US_POSIX")
        )

        XCTAssertNotEqual(text, artifact.key)
        XCTAssertTrue(text.contains("2026"))
    }

    func testPresentationFormattingSummaryRangeFallsBackToKeyWhenInvalid() {
        let artifact = SummaryArtifact(
            period: .week,
            key: "bad-key",
            generatedAt: .now,
            contentMarkdown: "",
            highlights: [],
            photoRefs: []
        )

        let text = PresentationFormatting.summaryRangeText(for: artifact)
        XCTAssertEqual(text, artifact.key)
    }

    func testLocalAnalyticsStoreTracksDayDetailsOpenEvents() async {
        let defaults = UserDefaults(suiteName: "LocalAnalyticsStoreTests.\(UUID().uuidString)")!
        let dayCalculator = DayKeyCalculator()
        let store = LocalAnalyticsStore(defaults: defaults, dayCalculator: dayCalculator)
        let tz = TimeZone(identifier: "America/Los_Angeles")!
        let date = Date(timeIntervalSince1970: 1_772_201_600)
        let dayKey = dayCalculator.dayKey(for: date, timeZone: tz)

        await store.record(.summaryDayDetailsOpened, count: 2, at: date, timeZone: tz)

        let summaryTotal = await store.totalCount(for: .summaryDayDetailsOpened)
        let summaryDay = await store.dayCount(for: .summaryDayDetailsOpened, dayKey: dayKey)

        XCTAssertEqual(summaryTotal, 2)
        XCTAssertEqual(summaryDay, 2)
    }

    func testTodayViewModelThenVsNowPromptPreservesExistingJournalText() async throws {
        let environment = try makeEnvironment()
        let now = Date(timeIntervalSince1970: 1_772_201_600)
        let model = TodayViewModel(environment: environment, now: now)
        await model.load()

        model.updateJournalText("Existing journal text.", for: .rose)
        let memory = ResurfacedMemory(
            id: "memory-1",
            sourceDayKey: LocalDayKey(isoDate: "2025-03-05", timeZoneID: "America/Los_Angeles"),
            type: .rose,
            excerpt: "Old thought",
            thenVsNowPrompt: "Then vs now: What's different?"
        )

        model.applyThenVsNowPrompt(for: memory)

        let journal = model.bindingJournal(for: .rose)
        XCTAssertTrue(journal.contains("Existing journal text."))
        XCTAssertTrue(journal.contains(memory.thenVsNowPrompt))
    }

    func testDayShareEligibilityRequiresAnyTextOrMedia() async throws {
        let environment = try makeEnvironment()
        let dayKey = LocalDayKey(isoDate: "2026-03-12", timeZoneID: "America/Los_Angeles")
        var entry = EntryDay.empty(dayKey: dayKey)

        let empty = await environment.dayShareService.eligibility(for: entry)
        XCTAssertEqual(empty, .emptyDay)

        entry.roseItem.shortText = "A reflected moment"
        let readyFromText = await environment.dayShareService.eligibility(for: entry)
        XCTAssertEqual(readyFromText, .ready)

        entry.roseItem.shortText = ""
        entry.budItem.photos = [PhotoRef(id: UUID(), relativePath: "bud/attachments/b.jpg", createdAt: .now)]
        let readyFromMedia = await environment.dayShareService.eligibility(for: entry)
        XCTAssertEqual(readyFromMedia, .ready)
    }

    func testDayShareServiceSelectsMostRecentPhotosAndIncludesEntryTextInPayload() async throws {
        let environment = try makeEnvironment()
        let dayKey = LocalDayKey(isoDate: "2026-03-12", timeZoneID: "America/Los_Angeles")
        let old = Date(timeIntervalSince1970: 100)
        let newer = Date(timeIntervalSince1970: 200)
        let newest = Date(timeIntervalSince1970: 300)

        let roseOld = PhotoRef(id: UUID(), relativePath: "rose/attachments/old.jpg", createdAt: old)
        let roseNew = PhotoRef(id: UUID(), relativePath: "rose/attachments/new.jpg", createdAt: newest)
        let budOld = PhotoRef(id: UUID(), relativePath: "bud/attachments/old.jpg", createdAt: old)
        let budNew = PhotoRef(id: UUID(), relativePath: "bud/attachments/new.jpg", createdAt: newer)
        let thornOnly = PhotoRef(id: UUID(), relativePath: "thorn/attachments/new.jpg", createdAt: newer)

        var entry = EntryDay.empty(dayKey: dayKey)
        entry.roseItem.shortText = "rose private text"
        entry.budItem.shortText = "bud private text"
        entry.thornItem.shortText = "thorn private text"
        entry.roseItem.photos = [roseOld, roseNew]
        entry.budItem.photos = [budOld, budNew]
        entry.thornItem.photos = [thornOnly]

        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: roseOld)
        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: roseNew)
        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: budOld)
        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: budNew)
        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: thornOnly)

        let payload = try await environment.dayShareService.makePayload(
            for: entry,
            resolvePhotoURL: { ref in
                environment.photoURL(for: ref, day: dayKey)
            }
        )

        XCTAssertEqual(payload.rose.ref?.id, roseNew.id)
        XCTAssertEqual(payload.bud.ref?.id, budNew.id)
        XCTAssertEqual(payload.thorn.ref?.id, thornOnly.id)
        XCTAssertEqual(payload.rose.textPreview, "rose private text")
        XCTAssertEqual(payload.bud.textPreview, "bud private text")
        XCTAssertEqual(payload.thorn.textPreview, "thorn private text")
        XCTAssertTrue(payload.messageBody.contains("Rose: rose private text"))
        XCTAssertTrue(payload.messageBody.contains("Bud: bud private text"))
        XCTAssertTrue(payload.messageBody.contains("Thorn: thorn private text"))
    }

    func testDayShareServiceProducesPayloadForTextOnlyDay() async throws {
        let environment = try makeEnvironment()
        let dayKey = LocalDayKey(isoDate: "2026-03-12", timeZoneID: "America/Los_Angeles")
        var entry = EntryDay.empty(dayKey: dayKey)
        entry.roseItem.shortText = "A text-only rose"
        entry.budItem.journalTextMarkdown = "A text-only bud"

        let payload = try await environment.dayShareService.makePayload(
            for: entry,
            resolvePhotoURL: { ref in
                environment.photoURL(for: ref, day: dayKey)
            }
        )

        XCTAssertNil(payload.rose.sourceURL)
        XCTAssertNil(payload.bud.sourceURL)
        XCTAssertNil(payload.thorn.sourceURL)
        XCTAssertTrue(payload.messageBody.contains("Rose: A text-only rose"))
        XCTAssertTrue(payload.messageBody.contains("Bud: A text-only bud"))
    }

    func testDayShareNudgeStoreSuppressesRepeatedPromptPerDay() {
        let defaults = UserDefaults(suiteName: "DayShareNudgeStoreTests.\(UUID().uuidString)")!
        let store = DayShareNudgeStore(defaults: defaults, key: "DayShareNudgeStoreTests.key")
        let dayKey = LocalDayKey(isoDate: "2026-03-12", timeZoneID: "America/Los_Angeles")

        XCTAssertTrue(store.shouldPresentPrompt(for: dayKey))
        store.markHandled(for: dayKey)
        XCTAssertFalse(store.shouldPresentPrompt(for: dayKey))
    }

    func testTodayViewModelTriggersDaySharePromptOnReadyTransitionOncePerDay() async throws {
        let environment = try makeEnvironment()
        let model = TodayViewModel(environment: environment)
        await model.load()

        let dayKey = model.dayKey
        let roseRef = PhotoRef(id: UUID(), relativePath: "rose/attachments/ready.jpg", createdAt: .now)
        let budRef = PhotoRef(id: UUID(), relativePath: "bud/attachments/ready.jpg", createdAt: .now)
        let thornRef = PhotoRef(id: UUID(), relativePath: "thorn/attachments/ready.jpg", createdAt: .now)

        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: roseRef)
        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: budRef)
        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: thornRef)

        model.entry.roseItem.photos = [roseRef]
        model.entry.budItem.photos = [budRef]
        model.entry.thornItem.photos = [thornRef]
        try await model.saveNow()

        XCTAssertTrue(model.isDayShareReady)
        XCTAssertTrue(model.shouldPresentShareNudge)

        model.dismissShareNudge()
        model.entry.roseItem.photos = []
        model.entry.budItem.photos = []
        model.entry.thornItem.photos = []
        try await model.saveNow()
        XCTAssertFalse(model.isDayShareReady)

        model.entry.roseItem.photos = [roseRef]
        model.entry.thornItem.photos = [thornRef]
        try await model.saveNow()
        XCTAssertTrue(model.isDayShareReady)
        XCTAssertFalse(model.shouldPresentShareNudge)
    }

    func testDayDetailViewModelPrepareShareSavePersistsLatestEntry() async throws {
        let environment = try makeEnvironment()
        let dayKey = LocalDayKey(isoDate: "2026-03-12", timeZoneID: "America/Los_Angeles")
        let model = DayDetailViewModel(environment: environment, dayKey: dayKey)
        await model.load()

        model.updateShortText("Saved before share", for: .rose)
        await model.prepareShareSaveIfNeeded()

        let persisted = try await environment.entryStore.load(day: dayKey)
        XCTAssertEqual(persisted.roseItem.shortText, "Saved before share")
    }

    func testDayShareAnalyticsEventsAreTracked() async throws {
        let environment = try makeEnvironment()
        let model = TodayViewModel(environment: environment)
        await model.load()
        let dayKey = model.dayKey

        let roseRef = PhotoRef(id: UUID(), relativePath: "rose/attachments/ready.jpg", createdAt: .now)
        let budRef = PhotoRef(id: UUID(), relativePath: "bud/attachments/ready.jpg", createdAt: .now)
        let thornRef = PhotoRef(id: UUID(), relativePath: "thorn/attachments/ready.jpg", createdAt: .now)

        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: roseRef)
        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: budRef)
        try writeAttachmentFile(in: environment, dayKey: dayKey, ref: thornRef)

        model.entry.roseItem.photos = [roseRef]
        model.entry.budItem.photos = [budRef]
        model.entry.thornItem.photos = [thornRef]
        try await model.saveNow()

        let payload = try await model.makeDaySharePayload()
        await model.recordDayShareSent()
        await model.recordDayShareFailed()
        await model.disposeDaySharePayload(payload)

        let promptShownCount = await environment.analyticsStore.totalCount(for: .daySharePromptShown)
        let initiatedCount = await environment.analyticsStore.totalCount(for: .dayShareInitiated)
        let sentCount = await environment.analyticsStore.totalCount(for: .dayShareSent)
        let failedCount = await environment.analyticsStore.totalCount(for: .dayShareFailed)

        XCTAssertEqual(promptShownCount, 1)
        XCTAssertEqual(initiatedCount, 1)
        XCTAssertEqual(sentCount, 1)
        XCTAssertEqual(failedCount, 1)
    }

    func testOnboardingStateStoreDefaultsToUnseenAndPersistsCompletion() {
        let defaults = UserDefaults(suiteName: "OnboardingStateStoreTests.\(UUID().uuidString)")!
        let key = "OnboardingStateStoreTests.key"

        let store = OnboardingStateStore(defaults: defaults, key: key)
        XCTAssertFalse(store.hasCompletedFirstLaunchOnboarding)
        XCTAssertTrue(store.shouldPresentFirstLaunchOnboarding())

        store.markFirstLaunchOnboardingCompleted()
        XCTAssertTrue(store.hasCompletedFirstLaunchOnboarding)
        XCTAssertFalse(store.shouldPresentFirstLaunchOnboarding())

        let reloaded = OnboardingStateStore(defaults: defaults, key: key)
        XCTAssertTrue(reloaded.hasCompletedFirstLaunchOnboarding)
        XCTAssertFalse(reloaded.shouldPresentFirstLaunchOnboarding())
    }

    func testOnboardingFlowControllerAutoAdvancesAfterTenTicks() {
        var controller = OnboardingFlowController(slideCount: 3)

        for _ in 0..<9 {
            XCTAssertEqual(controller.tick(), .none)
        }

        XCTAssertEqual(controller.tick(), .autoAdvanced)
        XCTAssertTrue(controller.advanceToNextSlide())
        XCTAssertEqual(controller.selectedIndex, 1)
        XCTAssertEqual(controller.countdown, OnboardingFlowController.defaultCountdownSeconds)
    }

    func testOnboardingFlowControllerAutoCompletesOnLastSlide() {
        var controller = OnboardingFlowController(slideCount: 3)
        controller.selectSlide(at: 2)

        for _ in 0..<9 {
            XCTAssertEqual(controller.tick(), .none)
        }

        XCTAssertEqual(controller.tick(), .autoCompleted)
    }

    func testOnboardingFlowControllerResetsTimerOnInteraction() {
        var controller = OnboardingFlowController(slideCount: 3)

        _ = controller.tick()
        _ = controller.tick()
        XCTAssertEqual(controller.countdown, 8)

        controller.registerInteraction()
        XCTAssertEqual(controller.countdown, OnboardingFlowController.defaultCountdownSeconds)

        controller.selectSlide(at: 1)
        XCTAssertEqual(controller.selectedIndex, 1)
        XCTAssertEqual(controller.countdown, OnboardingFlowController.defaultCountdownSeconds)
    }

    func testOnboardingAnalyticsEventsTrackFunnelCounts() async {
        let defaults = UserDefaults(suiteName: "OnboardingAnalyticsTests.\(UUID().uuidString)")!
        let store = LocalAnalyticsStore(defaults: defaults, dayCalculator: DayKeyCalculator())

        await store.record(.onboardingStarted)
        await store.record(.onboardingRoseViewed)
        await store.record(.onboardingBudViewed)
        await store.record(.onboardingThornViewed)
        await store.record(.onboardingAutoAdvanced, count: 2)
        await store.record(.onboardingSkipped)
        await store.record(.onboardingCompleted)
        await store.record(.onboardingReplayOpened)

        let started = await store.totalCount(for: .onboardingStarted)
        let roseViewed = await store.totalCount(for: .onboardingRoseViewed)
        let budViewed = await store.totalCount(for: .onboardingBudViewed)
        let thornViewed = await store.totalCount(for: .onboardingThornViewed)
        let autoAdvanced = await store.totalCount(for: .onboardingAutoAdvanced)
        let skipped = await store.totalCount(for: .onboardingSkipped)
        let completed = await store.totalCount(for: .onboardingCompleted)
        let replayOpened = await store.totalCount(for: .onboardingReplayOpened)

        XCTAssertEqual(started, 1)
        XCTAssertEqual(roseViewed, 1)
        XCTAssertEqual(budViewed, 1)
        XCTAssertEqual(thornViewed, 1)
        XCTAssertEqual(autoAdvanced, 2)
        XCTAssertEqual(skipped, 1)
        XCTAssertEqual(completed, 1)
        XCTAssertEqual(replayOpened, 1)
    }

    func testFeatureFlagStoreRoundTripIncludesEngagementFlags() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = FeatureFlagStore(defaults: defaults, key: "flags.test")
        let flags = AppFeatureFlags(
            remindersEnabled: false,
            streaksEnabled: true,
            widgetsEnabled: false,
            insightsEnabled: false,
            resurfacingEnabled: true,
            commitmentsEnabled: false,
            dayShareEnabled: false,
            os26UIEnabled: true
        )

        store.save(flags)
        XCTAssertEqual(store.load(defaults: AppFeatureFlags()), flags)
    }

}

private actor InMemoryEntryRepository: EntryRepository {
    private var entries: [LocalDayKey: EntryDay] = [:]

    func load(day: LocalDayKey) async throws -> EntryDay? {
        entries[day]
    }

    func save(_ entry: EntryDay) async throws {
        entries[entry.dayKey] = entry
    }

    func delete(day: LocalDayKey) async throws {
        entries.removeValue(forKey: day)
    }

    func list(range: DateInterval?) async throws -> [LocalDayKey] {
        let dayCalculator = DayKeyCalculator()
        return entries.keys
            .filter { dayKey in
                guard let range else { return true }
                guard let date = dayCalculator.date(for: dayKey) else { return false }
                return range.contains(date)
            }
            .sorted(by: >)
    }
}

private actor NoopAttachmentRepository: AttachmentRepository {
    func importImage(from sourceURL: URL, day: LocalDayKey, type: EntryType) async throws -> PhotoRef {
        PhotoRef(id: UUID(), relativePath: sourceURL.path, createdAt: .now)
    }

    func importVideo(from sourceURL: URL, day: LocalDayKey, type: EntryType) async throws -> VideoRef {
        VideoRef(id: UUID(), relativePath: sourceURL.path, createdAt: .now, durationSeconds: 1, hasAudio: false)
    }

    func remove(_ ref: PhotoRef, day: LocalDayKey) async throws {}

    func removeVideo(_ ref: VideoRef, day: LocalDayKey) async throws {}
}
