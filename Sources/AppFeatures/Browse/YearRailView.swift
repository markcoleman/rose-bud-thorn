import SwiftUI

#if os(iOS)
import UIKit
#endif

public struct YearRailView: View {
    public let years: [String]
    @Binding public var selectedYear: String?

    public init(years: [String], selectedYear: Binding<String?>) {
        self.years = years
        self._selectedYear = selectedYear
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                yearButton(title: "All", year: nil)
                ForEach(years, id: \.self) { year in
                    yearButton(title: year, year: year)
                }
            }
            .padding(.horizontal, 2)
        }
        .accessibilityLabel("Year selector")
    }

    private func yearButton(title: String, year: String?) -> some View {
        let isActive = selectedYear == year
        return Button {
            selectedYear = year
            #if os(iOS)
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
            #endif
        } label: {
            Text(title)
                .font(.subheadline.weight(isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? Color.white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isActive ? DesignTokens.accent : DesignTokens.surface)
                )
        }
        .buttonStyle(.plain)
    }
}
