import Foundation
import Observation
import CoreModels

@MainActor
@Observable
public final class SearchViewModel {
    public enum PhotoFilter: String, CaseIterable, Identifiable {
        case any
        case hasPhoto
        case noPhoto

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .any: return "Any"
            case .hasPhoto: return "Has Media"
            case .noPhoto: return "No Media"
            }
        }
    }

    public var queryText = ""
    public var includeRose = true
    public var includeBud = true
    public var includeThorn = true
    public var photoFilter: PhotoFilter = .any
    public var results: [LocalDayKey] = []
    public var isSearching = false
    public var errorMessage: String?

    public let environment: AppEnvironment

    public init(environment: AppEnvironment) {
        self.environment = environment
    }

    public func runSearch() async {
        isSearching = true
        defer { isSearching = false }

        let categories = selectedCategories
        let query = EntrySearchQuery(
            text: queryText,
            categories: categories,
            hasPhoto: hasPhotoFilter,
            dateRange: nil
        )

        do {
            results = try await environment.entryStore.search(query)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public var selectedCategories: Set<EntryType> {
        var set: Set<EntryType> = []
        if includeRose { set.insert(.rose) }
        if includeBud { set.insert(.bud) }
        if includeThorn { set.insert(.thorn) }
        if set.isEmpty { return Set(EntryType.allCases) }
        return set
    }

    public var hasPhotoFilter: Bool? {
        switch photoFilter {
        case .any: return nil
        case .hasPhoto: return true
        case .noPhoto: return false
        }
    }
}
