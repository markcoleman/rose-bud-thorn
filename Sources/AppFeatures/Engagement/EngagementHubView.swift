import SwiftUI

public struct EngagementHubView: View {
    public let insightCards: [InsightCard]
    public let resurfacedMemories: [ResurfacedMemory]
    public let onTapInsightCard: (InsightCard) -> Void
    public let onOpenMemoryDay: (ResurfacedMemory) -> Void
    public let onSnoozeMemory: (ResurfacedMemory) -> Void
    public let onDismissMemory: (ResurfacedMemory) -> Void
    public let onThenVsNow: (ResurfacedMemory) -> Void

    public init(
        insightCards: [InsightCard],
        resurfacedMemories: [ResurfacedMemory],
        onTapInsightCard: @escaping (InsightCard) -> Void = { _ in },
        onOpenMemoryDay: @escaping (ResurfacedMemory) -> Void = { _ in },
        onSnoozeMemory: @escaping (ResurfacedMemory) -> Void,
        onDismissMemory: @escaping (ResurfacedMemory) -> Void,
        onThenVsNow: @escaping (ResurfacedMemory) -> Void
    ) {
        self.insightCards = insightCards
        self.resurfacedMemories = resurfacedMemories
        self.onTapInsightCard = onTapInsightCard
        self.onOpenMemoryDay = onOpenMemoryDay
        self.onSnoozeMemory = onSnoozeMemory
        self.onDismissMemory = onDismissMemory
        self.onThenVsNow = onThenVsNow
    }

    public var body: some View {
        if !insightCards.isEmpty || !resurfacedMemories.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Engagement Hub", systemImage: "bolt.heart")
                    .font(.headline.weight(.semibold))

                if !insightCards.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(insightCards) { card in
                                insightCardView(card)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }

                if !resurfacedMemories.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(resurfacedMemories) { memory in
                            resurfacedMemoryCard(memory)
                        }
                    }
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Engagement hub")
            .accessibilityHint("Insights and resurfaced memories to keep your reflection momentum.")
        }
    }

    private func insightCardView(_ card: InsightCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(card.body)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            Text(card.explainability)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
        }
        .frame(width: 220, alignment: .leading)
        .padding(12)
        .background(DesignTokens.surfaceElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            onTapInsightCard(card)
        }
        .accessibilityAddTraits(.isButton)
    }

    private func resurfacedMemoryCard(_ memory: ResurfacedMemory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label("On this day", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
                Text(memory.sourceDayKey.isoDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(memory.type.title): \(memory.excerpt)")
                .font(.footnote)
                .foregroundStyle(.primary)
                .lineLimit(3)

            Text(memory.thenVsNowPrompt)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button("View Day Details") {
                    onOpenMemoryDay(memory)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint("Opens the full day entry for \(PresentationFormatting.localizedDayTitle(for: memory.sourceDayKey)).")

                Button("Then vs Now") {
                    onThenVsNow(memory)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Snooze") {
                    onSnoozeMemory(memory)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Dismiss") {
                    onDismissMemory(memory)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(DesignTokens.surfaceElevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
