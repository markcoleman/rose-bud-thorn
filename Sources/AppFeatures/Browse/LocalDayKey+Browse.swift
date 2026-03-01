import Foundation
import CoreModels

extension LocalDayKey {
    var monthKey: String {
        "\(year)-\(month)"
    }

    var dayInt: Int {
        Int(day) ?? 0
    }
}
