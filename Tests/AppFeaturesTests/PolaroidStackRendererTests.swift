import XCTest
@testable import AppFeatures
@testable import CoreModels

final class PolaroidStackRendererTests: XCTestCase {
    func testRenderProducesExpectedCanvasOrderingAndPNG() async throws {
        let renderer = PolaroidStackRenderer()
        let output = try await renderer.render(
            dayTitle: "Sunday, March 1, 2026",
            selections: [
                DayShareCardSelection(type: .thorn, textPreview: "Thorn text", ref: nil, sourceURL: nil),
                DayShareCardSelection(type: .rose, textPreview: "Rose text", ref: nil, sourceURL: nil),
                DayShareCardSelection(type: .bud, textPreview: "Bud text", ref: nil, sourceURL: nil)
            ],
            configuration: PolaroidStackRenderConfiguration(canvasWidth: 1024, maxCaptionLength: 120, includeWatermark: true)
        )

        XCTAssertEqual(output.metadata.canvasWidth, 1024)
        XCTAssertEqual(output.metadata.orderedTypes, EntryType.allCases)
        XCTAssertGreaterThan(output.metadata.canvasHeight, 1024)
        XCTAssertFalse(output.pngData.isEmpty)
        XCTAssertTrue(output.pngData.starts(with: [0x89, 0x50, 0x4E, 0x47]))
    }

    func testRenderTruncatesLongCaptionsToConfiguredLength() async throws {
        let renderer = PolaroidStackRenderer()
        let longText = String(repeating: "a", count: 300)
        let maxLength = 48

        let output = try await renderer.render(
            dayTitle: "Sunday, March 1, 2026",
            selections: [
                DayShareCardSelection(type: .rose, textPreview: longText, ref: nil, sourceURL: nil)
            ],
            configuration: PolaroidStackRenderConfiguration(canvasWidth: 1080, maxCaptionLength: maxLength, includeWatermark: true)
        )

        guard let roseCaption = output.metadata.truncatedCaptions[.rose] else {
            XCTFail("Expected truncated rose caption")
            return
        }

        XCTAssertTrue(roseCaption.hasSuffix("…"))
        XCTAssertLessThanOrEqual(roseCaption.count, maxLength + 1)
        XCTAssertEqual(output.metadata.maxCaptionLength, maxLength)
    }
}
