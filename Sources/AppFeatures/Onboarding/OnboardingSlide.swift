import SwiftUI

public struct OnboardingSlide: Identifiable {
    public let id: String
    public let imageName: String
    public let headline: String
    public let body: String
    public let themeColor: Color

    public init(
        id: String,
        imageName: String,
        headline: String,
        body: String,
        themeColor: Color
    ) {
        self.id = id
        self.imageName = imageName
        self.headline = headline
        self.body = body
        self.themeColor = themeColor
    }

    public static let defaultSlides: [OnboardingSlide] = [
        OnboardingSlide(
            id: "rose",
            imageName: "OnboardRose",
            headline: "Rose: what went well today",
            body: "Capture one bright moment, big or small. A sentence is enough.",
            themeColor: DesignTokens.rose
        ),
        OnboardingSlide(
            id: "bud",
            imageName: "OnboardBud",
            headline: "Bud: what is growing",
            body: "Note something you're looking forward to, learning, or building.",
            themeColor: DesignTokens.bud
        ),
        OnboardingSlide(
            id: "thorn",
            imageName: "OnboardThorn",
            headline: "Thorn: what felt hard",
            body: "Record one challenge with honesty. Reflection helps you notice patterns and reset.",
            themeColor: DesignTokens.thorn
        ),
    ]
}

public enum OnboardingDismissReason: String, Sendable {
    case skipped
    case completed
    case closed
    case autoCompleted
}
