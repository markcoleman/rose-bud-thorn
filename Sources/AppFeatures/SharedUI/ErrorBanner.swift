import SwiftUI

public struct ErrorBanner: View {
    public let message: String
    public let dismiss: () -> Void

    public init(message: String, dismiss: @escaping () -> Void) {
        self.message = message
        self.dismiss = dismiss
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: AppIcon.alert.systemName)
                .foregroundStyle(.yellow)
            Text(message)
                .font(.footnote)
                .lineLimit(3)
                .foregroundStyle(DesignTokens.textPrimaryOnSurface)
            Spacer()
            Button("Dismiss", action: dismiss)
                .font(.footnote.weight(.semibold))
                .touchTargetMinSize(ControlTokens.minCompactTouchTarget)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.warning.opacity(0.16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignTokens.focusStroke.opacity(0.28), lineWidth: 1)
        )
    }
}
