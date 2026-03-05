import SwiftUI
import CoreModels

public struct DayPolaroidStackView: View {
    public let entry: EntryDay
    public let selectedType: EntryType
    public let availableWidth: CGFloat
    public let viewportHeight: CGFloat
    public let photoURL: (PhotoRef) -> URL
    public let onSelectType: (EntryType) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var dragOffset: CGFloat = 0

    public init(
        entry: EntryDay,
        selectedType: EntryType,
        availableWidth: CGFloat,
        viewportHeight: CGFloat,
        photoURL: @escaping (PhotoRef) -> URL,
        onSelectType: @escaping (EntryType) -> Void
    ) {
        self.entry = entry
        self.selectedType = selectedType
        self.availableWidth = availableWidth
        self.viewportHeight = viewportHeight
        self.photoURL = photoURL
        self.onSelectType = onSelectType
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TabView(selection: selectionBinding) {
                ForEach(EntryType.allCases, id: \.self) { type in
                    GeometryReader { geometry in
                        let frame = geometry.frame(in: .global)
                        let width = max(geometry.size.width, 1)
                        let progress = max(-1, min(1, frame.minX / width))
                        let tilt = reduceMotion ? 0 : Double(progress * 3.5) + Double(dragOffset / 140)

                        PolaroidCard(
                            type: type,
                            caption: caption(for: type),
                            photoURL: latestPhotoURL(for: type),
                            tiltAngle: tilt,
                            reduceMotion: reduceMotion
                        )
                        .frame(width: cardWidth, alignment: .top)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .accessibilityIdentifier("day-polaroid-card-\(type.rawValue)")
                    }
                    .tag(type)
                }
            }
            .frame(height: pagerHeight)
            #if os(macOS)
            .tabViewStyle(.automatic)
            #else
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .accessibilityIdentifier("day-polaroid-pager")
            .simultaneousGesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        guard !reduceMotion else { return }
                        dragOffset = value.translation.width
                    }
                    .onEnded { _ in
                        withAnimation(MotionTokens.quick) {
                            dragOffset = 0
                        }
                    }
            )

            indicator
                .padding(.horizontal, 6)
        }
    }

    private var selectionBinding: Binding<EntryType> {
        Binding(
            get: { selectedType },
            set: { onSelectType($0) }
        )
    }

    private var indicator: some View {
        HStack(spacing: 8) {
            ForEach(EntryType.allCases, id: \.self) { type in
                Button {
                    withAnimation(MotionTokens.tabSwitch) {
                        onSelectType(type)
                    }
                } label: {
                    Text(type.title)
                }
                .buttonStyle(
                    PolaroidIndicatorChipStyle(
                        isSelected: selectedType == type,
                        tint: tint(for: type)
                    )
                )
                .accessibilityLabel("Show \(type.title)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rose Bud Thorn indicator")
        .accessibilityValue(selectedType.title)
        .accessibilityIdentifier("day-polaroid-indicator")
    }

    private func caption(for type: EntryType) -> String {
        let item = entry.item(for: type)
        let short = item.shortText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !short.isEmpty {
            return short
        }

        let journal = item.journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        if !journal.isEmpty {
            return journal
        }

        return ""
    }

    private func latestPhotoURL(for type: EntryType) -> URL? {
        let item = entry.item(for: type)
        guard let latest = item.photos.max(by: { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.createdAt < rhs.createdAt
        }) else {
            return nil
        }

        return photoURL(latest)
    }

    private func tint(for type: EntryType) -> Color {
        switch type {
        case .rose:
            return DesignTokens.rose
        case .bud:
            return DesignTokens.bud
        case .thorn:
            return DesignTokens.thorn
        }
    }

    private var pagerHeight: CGFloat {
        let base = cardWidth + (dynamicTypeSize >= .accessibility1 ? 320.0 : 240.0)
        let minimum: CGFloat = dynamicTypeSize >= .accessibility1 ? 640.0 : 560.0
        return max(minimum, base)
    }

    private var cardWidth: CGFloat {
        let widthCap = min(availableWidth - 12, 520)
        let heightLimitedWidth = max(240, viewportHeight - (dynamicTypeSize >= .accessibility1 ? 390 : 320))
        return max(240, min(widthCap, heightLimitedWidth))
    }
}

private struct PolaroidIndicatorChipStyle: ButtonStyle {
    let isSelected: Bool
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : DesignTokens.textPrimaryOnSurface)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? tint.opacity(0.90) : DesignTokens.surfaceElevated)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DesignTokens.dividerSubtle, lineWidth: isSelected ? 0 : 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(MotionTokens.subtle, value: configuration.isPressed)
    }
}
