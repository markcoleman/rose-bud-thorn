import Foundation

public enum OnboardingTickOutcome: Equatable, Sendable {
    case none
    case autoAdvanced
    case autoCompleted
}

public struct OnboardingFlowController: Equatable, Sendable {
    public static let defaultCountdownSeconds = 10

    public private(set) var selectedIndex: Int
    public private(set) var countdown: Int
    public let slideCount: Int
    public let countdownDuration: Int

    public init(
        slideCount: Int,
        countdownDuration: Int = OnboardingFlowController.defaultCountdownSeconds,
        selectedIndex: Int = 0
    ) {
        self.slideCount = max(slideCount, 0)
        self.countdownDuration = max(countdownDuration, 1)
        self.selectedIndex = 0
        self.countdown = max(countdownDuration, 1)
        selectSlide(at: selectedIndex)
    }

    public var isOnLastSlide: Bool {
        guard slideCount > 0 else { return true }
        return selectedIndex >= (slideCount - 1)
    }

    public mutating func selectSlide(at index: Int) {
        guard slideCount > 0 else {
            selectedIndex = 0
            countdown = countdownDuration
            return
        }
        selectedIndex = min(max(index, 0), slideCount - 1)
        resetCountdown()
    }

    public mutating func advanceToNextSlide() -> Bool {
        guard !isOnLastSlide else { return false }
        selectSlide(at: selectedIndex + 1)
        return true
    }

    public mutating func registerInteraction() {
        resetCountdown()
    }

    public mutating func resetCountdown() {
        countdown = countdownDuration
    }

    public mutating func tick() -> OnboardingTickOutcome {
        guard slideCount > 0 else { return .autoCompleted }

        countdown -= 1
        guard countdown <= 0 else { return .none }

        return isOnLastSlide ? .autoCompleted : .autoAdvanced
    }
}
