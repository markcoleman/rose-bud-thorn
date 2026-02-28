import Foundation
import CoreModels

public enum PromptTheme: String, Codable, CaseIterable, Sendable {
    case gratitude
    case resilience
    case relationships
    case work

    public var title: String {
        switch self {
        case .gratitude: return "Gratitude"
        case .resilience: return "Resilience"
        case .relationships: return "Relationships"
        case .work: return "Work"
        }
    }
}

public enum PromptThemePreference: String, Codable, CaseIterable, Sendable {
    case rotate
    case gratitude
    case resilience
    case relationships
    case work

    public var title: String {
        switch self {
        case .rotate: return "Auto Rotate"
        case .gratitude: return PromptTheme.gratitude.title
        case .resilience: return PromptTheme.resilience.title
        case .relationships: return PromptTheme.relationships.title
        case .work: return PromptTheme.work.title
        }
    }

    public var resolvedTheme: PromptTheme? {
        switch self {
        case .rotate: return nil
        case .gratitude: return .gratitude
        case .resilience: return .resilience
        case .relationships: return .relationships
        case .work: return .work
        }
    }
}

public enum PromptSelectionMode: String, Codable, CaseIterable, Sendable {
    case deterministic
    case random

    public var title: String {
        switch self {
        case .deterministic: return "Daily Rotation"
        case .random: return "Random"
        }
    }
}

public struct PromptPreferences: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var themePreference: PromptThemePreference
    public var selectionMode: PromptSelectionMode
    public var hiddenTypes: Set<EntryType>

    public init(
        isEnabled: Bool = true,
        themePreference: PromptThemePreference = .rotate,
        selectionMode: PromptSelectionMode = .deterministic,
        hiddenTypes: Set<EntryType> = []
    ) {
        self.isEnabled = isEnabled
        self.themePreference = themePreference
        self.selectionMode = selectionMode
        self.hiddenTypes = hiddenTypes
    }

    public func isTypeEnabled(_ type: EntryType) -> Bool {
        !hiddenTypes.contains(type)
    }
}

public struct PromptPack: Hashable, Sendable {
    public let theme: PromptTheme
    public let rosePrompts: [String]
    public let budPrompts: [String]
    public let thornPrompts: [String]

    public init(
        theme: PromptTheme,
        rosePrompts: [String],
        budPrompts: [String],
        thornPrompts: [String]
    ) {
        self.theme = theme
        self.rosePrompts = rosePrompts
        self.budPrompts = budPrompts
        self.thornPrompts = thornPrompts
    }

    public func prompts(for type: EntryType) -> [String] {
        switch type {
        case .rose: return rosePrompts
        case .bud: return budPrompts
        case .thorn: return thornPrompts
        }
    }
}

public struct PromptSelection: Equatable, Sendable {
    public let type: EntryType
    public let theme: PromptTheme
    public let text: String

    public init(type: EntryType, theme: PromptTheme, text: String) {
        self.type = type
        self.theme = theme
        self.text = text
    }
}
