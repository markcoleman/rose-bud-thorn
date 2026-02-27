import SwiftUI

public struct BrandMarkView: View {
    public var body: some View {
        HStack(spacing: 10) {
            Image("RoseBudLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rose, Bud, Thorn")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Reflect daily in moments that matter")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rose, Bud, Thorn. Reflect daily in moments that matter.")
    }

    public init() {}
}
