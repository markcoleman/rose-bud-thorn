import SwiftUI
import CoreModels

public struct MemoryDayCardView: View {
    public let snapshot: BrowseDaySnapshot
    public let isSelected: Bool
    public let onSelect: () -> Void

    public init(snapshot: BrowseDaySnapshot, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.snapshot = snapshot
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                header
                emotionalStrip
                previewRows
                metadataRow
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DesignTokens.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? DesignTokens.accent : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.4 : 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.12 : 0.06), radius: isSelected ? 14 : 8, x: 0, y: 6)
        }
        .buttonStyle(MemoryCardPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(Self.dayTitle(for: snapshot.dayKey))
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            if snapshot.favorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)

            Text("\(snapshot.completionCount)/3")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DesignTokens.surface)
                )
        }
    }

    private var emotionalStrip: some View {
        HStack(spacing: 6) {
            stripBlock(color: DesignTokens.rose, isActive: snapshot.hasRoseContent)
            stripBlock(color: DesignTokens.bud, isActive: snapshot.hasBudContent)
            stripBlock(color: DesignTokens.thorn, isActive: snapshot.hasThornContent)
        }
    }

    private func stripBlock(color: Color, isActive: Bool) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(color.opacity(isActive ? 0.95 : 0.2))
            .frame(height: 8)
            .accessibilityHidden(true)
    }

    private var previewRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            previewRow(symbol: "r.circle.fill", text: snapshot.rosePreview, color: DesignTokens.rose)
            previewRow(symbol: "b.circle.fill", text: snapshot.budPreview, color: DesignTokens.bud)
            previewRow(symbol: "t.circle.fill", text: snapshot.thornPreview, color: DesignTokens.thorn)
        }
    }

    @ViewBuilder
    private func previewRow(symbol: String, text: String, color: Color) -> some View {
        if !text.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: symbol)
                    .font(.caption)
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 10) {
            if let mood = snapshot.mood {
                Label("\(mood)/5", systemImage: "face.smiling")
                    .labelStyle(.titleAndIcon)
            }

            if snapshot.hasMedia {
                Label("\(snapshot.mediaCount)", systemImage: "photo.on.rectangle.angled")
                    .labelStyle(.titleAndIcon)
            }

            if !snapshot.tags.isEmpty {
                Text(snapshot.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                    .lineLimit(1)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var accessibilitySummary: String {
        let moodText = snapshot.mood.map { "Mood \($0) out of 5." } ?? ""
        let favoriteText = snapshot.favorite ? "Favorite day." : ""
        let mediaText = snapshot.hasMedia ? "\(snapshot.mediaCount) media items." : "No media."
        return "\(Self.dayTitle(for: snapshot.dayKey)). \(snapshot.completionCount) of 3 reflections completed. \(moodText) \(favoriteText) \(mediaText)"
    }

    private static func dayTitle(for dayKey: LocalDayKey) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateStyle = .full

        let parts = dayKey.isoDate.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return dayKey.isoDate
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))
        if let date {
            return formatter.string(from: date)
        }

        return dayKey.isoDate
    }
}

private struct MemoryCardPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(reduceMotion ? nil : MotionTokens.quick, value: configuration.isPressed)
    }
}
