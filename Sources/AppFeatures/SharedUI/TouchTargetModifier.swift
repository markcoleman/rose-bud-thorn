import SwiftUI

private struct TouchTargetModifier: ViewModifier {
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(minWidth: size, minHeight: size, alignment: .center)
            .contentShape(Rectangle())
    }
}

public extension View {
    func touchTargetMinSize(_ size: CGFloat = ControlTokens.minTouchTarget) -> some View {
        modifier(TouchTargetModifier(size: size))
    }
}
