import SwiftUI
import CoreModels

public struct TimelineBrowseView: View {
    public let days: [LocalDayKey]
    @Binding public var selectedDayKey: LocalDayKey?

    public init(days: [LocalDayKey], selectedDayKey: Binding<LocalDayKey?>) {
        self.days = days
        self._selectedDayKey = selectedDayKey
    }

    public var body: some View {
        List(days, id: \.self, selection: $selectedDayKey) { day in
            Button {
                selectedDayKey = day
            } label: {
                HStack {
                    Text(day.isoDate)
                        .font(.body)
                    Spacer()
                    Text(day.timeZoneID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
