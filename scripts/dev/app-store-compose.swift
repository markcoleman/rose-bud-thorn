#!/usr/bin/env swift

import AppKit
import Foundation

enum ComposeError: Error, CustomStringConvertible {
    case missingArgument(String)
    case invalidDevice(String)
    case invalidDimension(String)
    case missingScene(String)
    case imageLoadFailed(String)
    case contextCreationFailed
    case pngEncodingFailed(String)

    var description: String {
        switch self {
        case .missingArgument(let flag):
            return "Missing required argument: \(flag)"
        case .invalidDevice(let value):
            return "Unsupported --device value '\(value)'. Use 'iphone' or 'ipad'."
        case .invalidDimension(let message):
            return "Invalid custom dimensions: \(message)"
        case .missingScene(let scene):
            return "No source screenshot found for scene '\(scene)'."
        case .imageLoadFailed(let path):
            return "Unable to load image at path: \(path)"
        case .contextCreationFailed:
            return "Unable to create bitmap graphics context."
        case .pngEncodingFailed(let path):
            return "Unable to write PNG output to path: \(path)"
        }
    }
}

struct Palette {
    let start: NSColor
    let end: NSColor
    let orbA: NSColor
    let orbB: NSColor
}

struct SceneStyle {
    let sourceKey: String
    let outputName: String
    let title: String
    let subtitle: String
    let chipTitles: [String]
    let palette: Palette
}

struct AttachmentManifestGroup: Decodable {
    let attachments: [AttachmentManifestItem]
}

struct AttachmentManifestItem: Decodable {
    let exportedFileName: String
    let suggestedHumanReadableName: String?
}

enum DeviceKind: String {
    case iphone
    case ipad

    var outputSize: CGSize {
        switch self {
        case .iphone:
            return CGSize(width: 1320, height: 2868)
        case .ipad:
            return CGSize(width: 2064, height: 2752)
        }
    }

    var frameSizeRatio: CGSize {
        switch self {
        case .iphone:
            return CGSize(width: 0.7, height: 0.74)
        case .ipad:
            return CGSize(width: 0.78, height: 0.76)
        }
    }

    var frameCornerRadius: CGFloat {
        switch self {
        case .iphone:
            return 92
        case .ipad:
            return 62
        }
    }

    var screenInsets: NSEdgeInsets {
        switch self {
        case .iphone:
            return NSEdgeInsets(top: 86, left: 26, bottom: 28, right: 26)
        case .ipad:
            return NSEdgeInsets(top: 34, left: 34, bottom: 34, right: 34)
        }
    }
}

func argumentValue(_ name: String, in arguments: [String]) -> String? {
    guard let index = arguments.firstIndex(of: name) else { return nil }
    let valueIndex = arguments.index(after: index)
    guard valueIndex < arguments.count else { return nil }
    return arguments[valueIndex]
}

func parsePositiveInt(_ value: String, argumentName: String) throws -> Int {
    guard let parsed = Int(value), parsed > 0 else {
        throw ComposeError.invalidDimension("\(argumentName) must be a positive integer.")
    }
    return parsed
}

func hex(_ value: Int, alpha: CGFloat = 1) -> NSColor {
    let red = CGFloat((value >> 16) & 0xFF) / 255
    let green = CGFloat((value >> 8) & 0xFF) / 255
    let blue = CGFloat(value & 0xFF) / 255
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func scenes(for device: DeviceKind) -> [SceneStyle] {
    switch device {
    case .iphone:
        return [
            SceneStyle(
                sourceKey: "01-onboarding-hero",
                outputName: "01-reflect-better",
                title: "Reflect Better Every Day",
                subtitle: "A calm, focused Rose Bud Thorn ritual in minutes.",
                chipTitles: ["Guided Onboarding", "Mood-Aware Prompts"],
                palette: Palette(
                    start: hex(0x10355E),
                    end: hex(0x4C9FBE),
                    orbA: hex(0xF7B267, alpha: 0.34),
                    orbB: hex(0xB9FBC0, alpha: 0.28)
                )
            ),
            SceneStyle(
                sourceKey: "02-today-capture",
                outputName: "02-capture-today-fast",
                title: "Capture Today Fast",
                subtitle: "Rose, Bud, and Thorn entries stay lightweight and intentional.",
                chipTitles: ["One-Tap Flow", "Progress Tracking"],
                palette: Palette(
                    start: hex(0x2D1B4E),
                    end: hex(0xB34F8B),
                    orbA: hex(0xFDE68A, alpha: 0.32),
                    orbB: hex(0x93C5FD, alpha: 0.26)
                )
            ),
            SceneStyle(
                sourceKey: "03-journal-timeline",
                outputName: "03-scroll-your-story",
                title: "Scroll Your Story",
                subtitle: "Your reflection timeline keeps momentum visible day after day.",
                chipTitles: ["Daily Timeline", "Memory Cards"],
                palette: Palette(
                    start: hex(0x1F513A),
                    end: hex(0x59A96A),
                    orbA: hex(0xFFE082, alpha: 0.28),
                    orbB: hex(0xA5B4FC, alpha: 0.24)
                )
            ),
            SceneStyle(
                sourceKey: "04-day-detail",
                outputName: "04-relive-each-day",
                title: "Relive Each Day Beautifully",
                subtitle: "Flip through focused day detail cards for Rose, Bud, and Thorn.",
                chipTitles: ["Polaroid View", "Fast Edit + Share"],
                palette: Palette(
                    start: hex(0x5A2A18),
                    end: hex(0xE07A5F),
                    orbA: hex(0xFEC5BB, alpha: 0.34),
                    orbB: hex(0xBDE0FE, alpha: 0.22)
                )
            ),
            SceneStyle(
                sourceKey: "05-insights",
                outputName: "05-grow-with-insights",
                title: "Grow With Insights",
                subtitle: "Actionable patterns help you build a stronger reflection habit.",
                chipTitles: ["Insight Cards", "Streak Motivation"],
                palette: Palette(
                    start: hex(0x19273C),
                    end: hex(0x2A6F97),
                    orbA: hex(0xFFD166, alpha: 0.30),
                    orbB: hex(0xCDB4DB, alpha: 0.24)
                )
            ),
        ]
    case .ipad:
        return [
            SceneStyle(
                sourceKey: "01-onboarding-hero",
                outputName: "01-reflect-better",
                title: "Reflect Better Every Day",
                subtitle: "A spacious guided experience crafted for iPad.",
                chipTitles: ["Immersive Onboarding", "Focus-First Design"],
                palette: Palette(
                    start: hex(0x0F395D),
                    end: hex(0x398AB9),
                    orbA: hex(0xFFD6A5, alpha: 0.3),
                    orbB: hex(0xCAFFBF, alpha: 0.24)
                )
            ),
            SceneStyle(
                sourceKey: "02-today-capture",
                outputName: "02-capture-today-fast",
                title: "Capture Today Fast",
                subtitle: "Complete your Rose Bud Thorn reflection in one clean workspace.",
                chipTitles: ["Tablet-Optimized Layout", "Daily Momentum"],
                palette: Palette(
                    start: hex(0x2B2D66),
                    end: hex(0x7B4EA3),
                    orbA: hex(0xFFE29A, alpha: 0.32),
                    orbB: hex(0xA0C4FF, alpha: 0.24)
                )
            ),
            SceneStyle(
                sourceKey: "03-journal-timeline",
                outputName: "03-scroll-your-story",
                title: "Scroll Your Story",
                subtitle: "A rich timeline makes patterns and memories instantly legible.",
                chipTitles: ["Memory Timeline", "Past Day Highlights"],
                palette: Palette(
                    start: hex(0x1E5A4A),
                    end: hex(0x3FAF82),
                    orbA: hex(0xFFE5A5, alpha: 0.28),
                    orbB: hex(0xBDB2FF, alpha: 0.24)
                )
            ),
            SceneStyle(
                sourceKey: "04-day-detail",
                outputName: "04-relive-each-day",
                title: "Relive Each Day Beautifully",
                subtitle: "Large-format day detail cards keep every reflection meaningful.",
                chipTitles: ["Polaroid Stack", "Gesture-Friendly"],
                palette: Palette(
                    start: hex(0x663D1E),
                    end: hex(0xCC7F54),
                    orbA: hex(0xFFD6A5, alpha: 0.3),
                    orbB: hex(0xD6EFFF, alpha: 0.22)
                )
            ),
            SceneStyle(
                sourceKey: "05-insights",
                outputName: "05-grow-with-insights",
                title: "Grow With Insights",
                subtitle: "Habit and reflection insights keep your streak moving forward.",
                chipTitles: ["Progress Intelligence", "Reflection Trends"],
                palette: Palette(
                    start: hex(0x1B2E47),
                    end: hex(0x2B7A9F),
                    orbA: hex(0xFFE08A, alpha: 0.28),
                    orbB: hex(0xE0BBE4, alpha: 0.22)
                )
            ),
        ]
    }
}

func discoverImagePath(inputDirectory: URL, key: String) -> URL? {
    let manifestURL = inputDirectory.appendingPathComponent("manifest.json")
    if let data = try? Data(contentsOf: manifestURL),
       let groups = try? JSONDecoder().decode([AttachmentManifestGroup].self, from: data) {
        for group in groups {
            for item in group.attachments {
                guard let suggestedName = item.suggestedHumanReadableName?.lowercased() else { continue }
                if suggestedName.contains(key.lowercased()) {
                    return inputDirectory.appendingPathComponent(item.exportedFileName)
                }
            }
        }
    }

    guard let enumerator = FileManager.default.enumerator(
        at: inputDirectory,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    ) else {
        return nil
    }

    for case let fileURL as URL in enumerator {
        let lower = fileURL.lastPathComponent.lowercased()
        guard lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") else { continue }
        if lower.contains(key.lowercased()) {
            return fileURL
        }
    }
    return nil
}

func createCanvas(size: CGSize) -> NSBitmapImageRep? {
    NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    )
}

func drawBackground(in rect: CGRect, palette: Palette) {
    let gradient = NSGradient(starting: palette.start, ending: palette.end)
    gradient?.draw(in: rect, angle: -38)

    let orbA = NSBezierPath(ovalIn: CGRect(
        x: rect.width * 0.04,
        y: rect.height * 0.68,
        width: rect.width * 0.62,
        height: rect.width * 0.62
    ))
    palette.orbA.setFill()
    orbA.fill()

    let orbB = NSBezierPath(ovalIn: CGRect(
        x: rect.width * 0.46,
        y: rect.height * 0.1,
        width: rect.width * 0.7,
        height: rect.width * 0.7
    ))
    palette.orbB.setFill()
    orbB.fill()

    let glaze = NSBezierPath(rect: rect)
    NSColor(calibratedWhite: 1, alpha: 0.07).setFill()
    glaze.fill()
}

func drawHeadline(style: SceneStyle, canvas: CGSize, device: DeviceKind) {
    let titleFontSize: CGFloat = device == .iphone ? 90 : 96
    let subtitleFontSize: CGFloat = device == .iphone ? 44 : 46
    let topPadding: CGFloat = device == .iphone ? 170 : 185

    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: "AvenirNextCondensed-Bold", size: titleFontSize)
            ?? NSFont.boldSystemFont(ofSize: titleFontSize),
        .foregroundColor: NSColor.white,
        .kern: -0.7,
    ]

    let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: "AvenirNext-Medium", size: subtitleFontSize)
            ?? NSFont.systemFont(ofSize: subtitleFontSize, weight: .medium),
        .foregroundColor: NSColor(calibratedWhite: 1, alpha: 0.9),
    ]

    let title = NSAttributedString(string: style.title, attributes: titleAttributes)
    let subtitle = NSAttributedString(string: style.subtitle, attributes: subtitleAttributes)

    let titleRect = CGRect(x: 110, y: canvas.height - topPadding - 120, width: canvas.width - 220, height: 140)
    let subtitleRect = CGRect(x: 110, y: titleRect.minY - 118, width: canvas.width - 220, height: 110)

    title.draw(with: titleRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
    subtitle.draw(with: subtitleRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
}

func drawChipRow(style: SceneStyle, canvas: CGSize, device: DeviceKind) {
    let chipFontSize: CGFloat = device == .iphone ? 34 : 36
    let paddingX: CGFloat = device == .iphone ? 24 : 28
    let paddingY: CGFloat = device == .iphone ? 14 : 16
    let startY: CGFloat = device == .iphone ? 198 : 205
    var currentX: CGFloat = 110

    for title in style.chipTitles {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "AvenirNext-DemiBold", size: chipFontSize)
                ?? NSFont.systemFont(ofSize: chipFontSize, weight: .semibold),
            .foregroundColor: NSColor.white,
        ]
        let text = NSAttributedString(string: title, attributes: attributes)
        let textSize = text.size()
        let chipRect = CGRect(
            x: currentX,
            y: startY,
            width: textSize.width + (paddingX * 2),
            height: textSize.height + (paddingY * 2)
        )

        let chipPath = NSBezierPath(roundedRect: chipRect, xRadius: chipRect.height / 2, yRadius: chipRect.height / 2)
        NSColor(calibratedWhite: 0.1, alpha: 0.24).setFill()
        chipPath.fill()
        NSColor(calibratedWhite: 1, alpha: 0.44).setStroke()
        chipPath.lineWidth = 2
        chipPath.stroke()

        let textRect = CGRect(
            x: chipRect.minX + paddingX,
            y: chipRect.minY + paddingY - 1,
            width: textSize.width,
            height: textSize.height + 6
        )
        text.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        currentX = chipRect.maxX + 18
    }
}

func drawDeviceFrame(
    screenshot: NSImage,
    in canvas: CGSize,
    device: DeviceKind
) {
    let frameSize = CGSize(
        width: canvas.width * device.frameSizeRatio.width,
        height: canvas.height * device.frameSizeRatio.height
    )
    let frameRect = CGRect(
        x: (canvas.width - frameSize.width) / 2,
        y: canvas.height * 0.1,
        width: frameSize.width,
        height: frameSize.height
    )

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowOffset = CGSize(width: 0, height: -26)
    shadow.shadowBlurRadius = 42
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.35)
    shadow.set()

    let bodyPath = NSBezierPath(
        roundedRect: frameRect,
        xRadius: device.frameCornerRadius,
        yRadius: device.frameCornerRadius
    )
    NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
    bodyPath.fill()
    NSGraphicsContext.restoreGraphicsState()

    let bezelPath = NSBezierPath(
        roundedRect: frameRect.insetBy(dx: 4, dy: 4),
        xRadius: max(device.frameCornerRadius - 4, 8),
        yRadius: max(device.frameCornerRadius - 4, 8)
    )
    NSColor(calibratedWhite: 0.2, alpha: 1).setStroke()
    bezelPath.lineWidth = 2
    bezelPath.stroke()

    let insets = device.screenInsets
    let screenRect = CGRect(
        x: frameRect.minX + insets.left,
        y: frameRect.minY + insets.bottom,
        width: frameRect.width - insets.left - insets.right,
        height: frameRect.height - insets.top - insets.bottom
    )

    let screenPath = NSBezierPath(
        roundedRect: screenRect,
        xRadius: device == .iphone ? 42 : 34,
        yRadius: device == .iphone ? 42 : 34
    )
    NSGraphicsContext.saveGraphicsState()
    screenPath.addClip()
    screenshot.draw(in: screenRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: false, hints: nil)
    NSGraphicsContext.restoreGraphicsState()

    if device == .iphone {
        let islandRect = CGRect(
            x: frameRect.midX - 112,
            y: frameRect.maxY - 76,
            width: 224,
            height: 34
        )
        let island = NSBezierPath(roundedRect: islandRect, xRadius: 17, yRadius: 17)
        NSColor.black.setFill()
        island.fill()
    } else {
        let cameraRect = CGRect(
            x: frameRect.midX - 10,
            y: frameRect.maxY - 20,
            width: 20,
            height: 20
        )
        let camera = NSBezierPath(ovalIn: cameraRect)
        NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
        camera.fill()
        NSColor(calibratedWhite: 0.22, alpha: 1).setStroke()
        camera.lineWidth = 2
        camera.stroke()
    }
}

func renderScene(
    scene: SceneStyle,
    sourcePath: URL,
    outputPath: URL,
    device: DeviceKind,
    outputSize: CGSize
) throws {
    guard let screenshot = NSImage(contentsOf: sourcePath) else {
        throw ComposeError.imageLoadFailed(sourcePath.path)
    }

    let canvasSize = outputSize
    guard let bitmap = createCanvas(size: canvasSize) else {
        throw ComposeError.contextCreationFailed
    }

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw ComposeError.contextCreationFailed
    }
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    context.shouldAntialias = true

    drawBackground(in: CGRect(origin: .zero, size: canvasSize), palette: scene.palette)
    drawHeadline(style: scene, canvas: canvasSize, device: device)
    drawDeviceFrame(screenshot: screenshot, in: canvasSize, device: device)
    drawChipRow(style: scene, canvas: canvasSize, device: device)

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw ComposeError.pngEncodingFailed(outputPath.path)
    }
    try pngData.write(to: outputPath, options: .atomic)
}

func run() throws {
    let arguments = CommandLine.arguments
    guard let inputDir = argumentValue("--input-dir", in: arguments) else {
        throw ComposeError.missingArgument("--input-dir")
    }
    guard let outputDir = argumentValue("--output-dir", in: arguments) else {
        throw ComposeError.missingArgument("--output-dir")
    }
    guard let deviceRaw = argumentValue("--device", in: arguments) else {
        throw ComposeError.missingArgument("--device")
    }
    guard let device = DeviceKind(rawValue: deviceRaw.lowercased()) else {
        throw ComposeError.invalidDevice(deviceRaw)
    }

    let widthRaw = argumentValue("--width", in: arguments)
    let heightRaw = argumentValue("--height", in: arguments)
    let outputSize: CGSize
    switch (widthRaw, heightRaw) {
    case (nil, nil):
        outputSize = device.outputSize
    case let (w?, h?):
        let width = try parsePositiveInt(w, argumentName: "--width")
        let height = try parsePositiveInt(h, argumentName: "--height")
        outputSize = CGSize(width: width, height: height)
    default:
        throw ComposeError.invalidDimension("Provide both --width and --height together.")
    }

    let inputDirectory = URL(fileURLWithPath: inputDir, isDirectory: true)
    let outputDirectory = URL(fileURLWithPath: outputDir, isDirectory: true)
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    for scene in scenes(for: device) {
        guard let sourceImagePath = discoverImagePath(inputDirectory: inputDirectory, key: scene.sourceKey) else {
            throw ComposeError.missingScene(scene.sourceKey)
        }
        let outputPath = outputDirectory.appendingPathComponent("\(scene.outputName).png")
        try renderScene(
            scene: scene,
            sourcePath: sourceImagePath,
            outputPath: outputPath,
            device: device,
            outputSize: outputSize
        )
        print("Generated: \(outputPath.path)")
    }
}

do {
    try run()
} catch {
    fputs("error: \(error)\n", stderr)
    exit(1)
}
