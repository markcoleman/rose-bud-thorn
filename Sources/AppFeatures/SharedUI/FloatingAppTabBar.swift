import SwiftUI

public struct FloatingAppTabBar: View {
    @Binding private var selection: AppSection

    public init(selection: Binding<AppSection>) {
        _selection = selection
    }

    public var body: some View {
        HStack(spacing: 10) {
            tabButton(.journal)
            tabButton(.insights)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(DesignTokens.surfaceElevated.opacity(0.96))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(DesignTokens.dividerSubtle, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityIdentifier("floating-tab-bar")
    }

    private func tabButton(_ section: AppSection) -> some View {
        Button {
            withAnimation(MotionTokens.tabSwitch) {
                selection = section
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section.systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(section.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(selection == section ? Color.white : DesignTokens.textPrimaryOnSurface)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(selection == section ? DesignTokens.accent : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .touchTargetMinSize(ControlTokens.minTouchTarget)
        .accessibilityIdentifier("floating-tab-\(section.rawValue)")
        .accessibilityLabel(section.title)
    }
}
