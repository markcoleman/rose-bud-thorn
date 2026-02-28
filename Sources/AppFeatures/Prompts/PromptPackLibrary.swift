import Foundation
import CoreModels

public enum PromptPackLibrary {
    public static let packs: [PromptPack] = [
        PromptPack(
            theme: .gratitude,
            rosePrompts: [
                "What felt unexpectedly generous today?",
                "Name one small detail you want to remember from this good moment.",
                "Who made your day easier and how?",
                "What ordinary thing felt special today?"
            ],
            budPrompts: [
                "What future moment are you quietly grateful is possible?",
                "Which opportunity today feels worth protecting?",
                "What is one seed you planted that could grow this week?",
                "What support would help this possibility bloom?"
            ],
            thornPrompts: [
                "What challenge still revealed something to appreciate?",
                "What helped you get through the hardest part of today?",
                "What did this setback teach you to value more?",
                "Who or what gave you steadiness when things felt heavy?"
            ]
        ),
        PromptPack(
            theme: .resilience,
            rosePrompts: [
                "Which strength did you rely on in this positive moment?",
                "What did you handle better than you would have last month?",
                "Where did you choose progress over perfection today?",
                "What win proves you can adapt under pressure?"
            ],
            budPrompts: [
                "What next step feels challenging but doable?",
                "Where can consistency beat intensity this week?",
                "What obstacle can you prepare for ahead of time?",
                "What is one boundary that would protect your momentum?"
            ],
            thornPrompts: [
                "What was hardest and how did you respond?",
                "What would a kinder interpretation of this setback be?",
                "What is one thing you can do differently next time?",
                "What support can you ask for before this repeats?"
            ]
        ),
        PromptPack(
            theme: .relationships,
            rosePrompts: [
                "What interaction made you feel seen today?",
                "Who did you connect with in a meaningful way?",
                "What conversation left you lighter?",
                "How did you show care or receive care today?"
            ],
            budPrompts: [
                "What relationship deserves intentional attention this week?",
                "Who would benefit from a quick check-in from you?",
                "What shared plan are you excited about?",
                "How can you make space for a better conversation soon?"
            ],
            thornPrompts: [
                "Where did tension show up and what was underneath it?",
                "What do you wish you had said more clearly?",
                "What repair step feels possible after this tough moment?",
                "Which assumption may have made this harder?"
            ]
        ),
        PromptPack(
            theme: .work,
            rosePrompts: [
                "What work moment felt energizing today?",
                "What output are you proud of from today?",
                "Which decision improved your day the most?",
                "What did you finish that created breathing room?"
            ],
            budPrompts: [
                "What project has the most meaningful upside right now?",
                "What is the clearest next action for your top priority?",
                "Where can you create leverage instead of more effort?",
                "What could make tomorrow's workday smoother?"
            ],
            thornPrompts: [
                "What work friction slowed you down most today?",
                "What was unclear, and how could you clarify it sooner?",
                "What task drained energy without much return?",
                "What would reduce this stress before it compounds?"
            ]
        )
    ]

    public static func prompts(for theme: PromptTheme, type: EntryType) -> [String] {
        pack(for: theme)?.prompts(for: type) ?? []
    }

    public static func pack(for theme: PromptTheme) -> PromptPack? {
        packs.first(where: { $0.theme == theme })
    }
}
