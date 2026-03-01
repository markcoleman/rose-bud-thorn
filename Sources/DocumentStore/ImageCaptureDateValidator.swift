import Foundation
import ImageIO
import CoreModels
import CoreDate

public enum ImageCaptureDayValidationResult: Equatable, Sendable {
    case matches
    case mismatched(actual: LocalDayKey)
    case missingTimestamp
}

public enum ImageCaptureDateValidator {
    public static func validateImage(
        at imageURL: URL,
        matches expectedDayKey: LocalDayKey,
        dayCalculator: DayKeyCalculator = DayKeyCalculator()
    ) -> ImageCaptureDayValidationResult {
        guard let captureDate = captureDate(from: imageURL, fallbackTimeZoneID: expectedDayKey.timeZoneID) else {
            return .missingTimestamp
        }

        let timeZone = TimeZone(identifier: expectedDayKey.timeZoneID) ?? .current
        let actualDayKey = dayCalculator.dayKey(for: captureDate, timeZone: timeZone)
        if actualDayKey.isoDate == expectedDayKey.isoDate {
            return .matches
        }
        return .mismatched(actual: actualDayKey)
    }

    private static func captureDate(from imageURL: URL, fallbackTimeZoneID: String) -> Date? {
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return nil
        }

        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let date = exifCaptureDate(from: exif, fallbackTimeZoneID: fallbackTimeZoneID) {
            return date
        }

        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let dateString = tiff[kCGImagePropertyTIFFDateTime] as? String {
            return parse(dateString: dateString, offsetString: nil, fallbackTimeZoneID: fallbackTimeZoneID)
        }

        return nil
    }

    private static func exifCaptureDate(from exif: [CFString: Any], fallbackTimeZoneID: String) -> Date? {
        let dateString = (exif[kCGImagePropertyExifDateTimeOriginal] as? String) ??
            (exif[kCGImagePropertyExifDateTimeDigitized] as? String)

        guard let dateString else {
            return nil
        }

        let offsetString = (exif[kCGImagePropertyExifOffsetTimeOriginal] as? String) ??
            (exif[kCGImagePropertyExifOffsetTimeDigitized] as? String)

        return parse(
            dateString: dateString,
            offsetString: offsetString,
            fallbackTimeZoneID: fallbackTimeZoneID
        )
    }

    private static func parse(
        dateString: String,
        offsetString: String?,
        fallbackTimeZoneID: String
    ) -> Date? {
        if let offset = normalizedOffset(offsetString),
           let date = parseWithOffset(dateString: dateString, offset: offset) {
            return date
        }

        return parseWithoutOffset(dateString: dateString, fallbackTimeZoneID: fallbackTimeZoneID)
    }

    private static func parseWithOffset(dateString: String, offset: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ssXXXXX"
        return formatter.date(from: "\(dateString)\(offset)")
    }

    private static func parseWithoutOffset(dateString: String, fallbackTimeZoneID: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: fallbackTimeZoneID) ?? .current
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateString)
    }

    private static func normalizedOffset(_ value: String?) -> String? {
        guard var value, !value.isEmpty else {
            return nil
        }

        if value == "Z" {
            return "Z"
        }

        if value.count == 5, let first = value.first, (first == "+" || first == "-") {
            let body = value.dropFirst()
            if body.allSatisfy(\.isNumber) {
                let hours = body.prefix(2)
                let minutes = body.suffix(2)
                value = "\(first)\(hours):\(minutes)"
            }
        }

        return value
    }
}
