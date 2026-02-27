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
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.footnote)
                .lineLimit(3)
            Spacer()
            Button("Dismiss", action: dismiss)
                .font(.footnote.weight(.semibold))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.15)))
    }
}
