import SwiftUI
import WidgetKit
import CoreModels
#if canImport(UIKit)
import UIKit
#endif

private struct TodayReflectionEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetTodaySnapshot?
    let isPrivacyLockEnabled: Bool
    let currentPhotoIndex: Int
}

private struct TodayReflectionProvider: TimelineProvider {
    private let photoRotationMinutes = 2

    func placeholder(in context: Context) -> TodayReflectionEntry {
        TodayReflectionEntry(
            date: .now,
            snapshot: WidgetTodaySnapshot(
                dayKeyISODate: "2026-03-19",
                roseExcerpt: "Coffee with a friend",
                budExcerpt: "Pitching the prototype",
                thornExcerpt: "Tight deadline",
                photos: [
                    WidgetTodaySnapshotPhoto(
                        id: UUID().uuidString,
                        type: .rose,
                        relativePath: "rose/attachments/sample.jpg",
                        createdAt: .now
                    )
                ],
                completionCount: 3,
                updatedAt: .now
            ),
            isPrivacyLockEnabled: false,
            currentPhotoIndex: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayReflectionEntry) -> Void) {
        completion(loadCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayReflectionEntry>) -> Void) {
        let baseEntry = loadCurrentEntry()
        guard let snapshot = baseEntry.snapshot,
              !baseEntry.isPrivacyLockEnabled,
              !snapshot.photos.isEmpty else {
            let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
            completion(Timeline(entries: [baseEntry], policy: .after(refresh)))
            return
        }

        let now = Date()
        let entries = snapshot.photos.enumerated().map { index, _ in
            let date = Calendar.current.date(byAdding: .minute, value: index * photoRotationMinutes, to: now) ?? now
            return TodayReflectionEntry(
                date: date,
                snapshot: snapshot,
                isPrivacyLockEnabled: false,
                currentPhotoIndex: index
            )
        }
        let refresh = Calendar.current.date(byAdding: .minute, value: entries.count * photoRotationMinutes, to: now) ?? .now
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private func loadCurrentEntry() -> TodayReflectionEntry {
        let defaults = UserDefaults(suiteName: WidgetSharedDefaults.appGroupIdentifier) ?? .standard
        let snapshot: WidgetTodaySnapshot?
        if let data = defaults.data(forKey: WidgetSharedDefaults.todaySnapshotKey),
           let decoded = try? JSONDecoder().decode(WidgetTodaySnapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = nil
        }

        let isPrivacyLockEnabled = defaults.bool(forKey: WidgetSharedDefaults.privacyLockEnabledKey)
        return TodayReflectionEntry(
            date: .now,
            snapshot: snapshot,
            isPrivacyLockEnabled: isPrivacyLockEnabled,
            currentPhotoIndex: 0
        )
    }
}

private struct TodayReflectionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayReflectionEntry

    private var todayURL: URL {
        if let focusType = widgetTapFocusType {
            return focusURL(focusType)
        }
        return URL(string: "rosebudthorn://today?source=widget")!
    }

    private func focusURL(_ type: EntryType) -> URL {
        URL(string: "rosebudthorn://today?source=widget&focus=\(type.rawValue)")!
    }

    private var displayContent: WidgetTodayDisplayContent {
        WidgetTodayDisplayContent(snapshot: entry.snapshot, isPrivacyLockEnabled: entry.isPrivacyLockEnabled)
    }

    private var snapshot: WidgetTodaySnapshot? {
        entry.snapshot
    }

    private var dayDirectoryURL: URL? {
        guard let snapshot else { return nil }
        let components = snapshot.dayKeyISODate.split(separator: "-")
        guard components.count == 3,
              let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetSharedDefaults.appGroupIdentifier) else {
            return nil
        }

        return containerURL
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("Entries", isDirectory: true)
            .appendingPathComponent(String(components[0]), isDirectory: true)
            .appendingPathComponent(String(components[1]), isDirectory: true)
            .appendingPathComponent(String(components[2]), isDirectory: true)
    }

    private var currentPhoto: WidgetTodaySnapshotPhoto? {
        guard let snapshot,
              !snapshot.photos.isEmpty else { return nil }
        let index = entry.currentPhotoIndex % snapshot.photos.count
        return snapshot.photo(at: index)
    }

    private var widgetTapFocusType: EntryType? {
        guard displayContent.state != .privacyLocked,
              displayContent.state != .notStarted else {
            return nil
        }

        if let currentPhoto {
            return currentPhoto.type
        }

        return EntryType.allCases.first { type in
            !displayContent.excerpt(for: type).isEmpty
        }
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallBody
            case .systemMedium:
                mediumBody
            case .systemLarge:
                largeBody
            case .systemExtraLarge:
                extraLargeBody
            default:
                largeBody
            }
        }
        .widgetURL(todayURL)
        .containerBackground(for: .widget) {
            ZStack {
                Color(.systemBackground)
                LinearGradient(
                    colors: [
                        EntryType.rose.widgetTint.opacity(0.10),
                        EntryType.bud.widgetTint.opacity(0.08),
                        EntryType.thorn.widgetTint.opacity(0.08),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var smallBody: some View {
        ZStack(alignment: .topLeading) {
            switch displayContent.state {
            case .privacyLocked:
                lockedCard
            case .notStarted:
                notStartedCard
            case .inProgress, .complete:
                if let currentPhoto {
                    photoCard(photo: currentPhoto, cornerRadius: 14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(alignment: .topLeading) {
                            progressBadge
                                .padding(8)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            pageBadge
                                .padding(8)
                        }
                        .overlay(alignment: .bottomLeading) {
                            autoCycleBadge
                                .padding(8)
                        }
                } else {
                    fallbackProgressCard
                }
            }
        }
    }

    private var mediumBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if displayContent.state == .privacyLocked {
                lockedInline
            } else if displayContent.state == .notStarted {
                notStartedInline
            } else {
                sectionPhotoStrip(tileHeight: 44, labelFont: .caption2, cornerRadius: 14)
            }
        }
        .padding(12)
    }

    private var largeBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if displayContent.state == .privacyLocked {
                lockedInline
            } else if displayContent.state == .notStarted {
                notStartedInline
            } else {
                sectionPhotoStrip(tileHeight: 56, labelFont: .caption, cornerRadius: 15)
                VStack(spacing: 8) {
                    ForEach(EntryType.allCases, id: \.self) { type in
                        Link(destination: focusURL(type)) {
                            textRow(type: type, excerpt: displayContent.excerpt(for: type))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
    }

    private var extraLargeBody: some View {
        HStack(spacing: 14) {
            if displayContent.state == .privacyLocked {
                lockedCard
            } else if let currentPhoto {
                photoCard(photo: currentPhoto, cornerRadius: 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                notStartedCard
            }

            VStack(alignment: .leading, spacing: 10) {
                header

                ForEach(EntryType.allCases, id: \.self) { type in
                    Link(destination: focusURL(type)) {
                        textRow(type: type, excerpt: displayContent.excerpt(for: type))
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(16)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Today's Reflection")
                .font(.headline.weight(.semibold))

            Spacer(minLength: 0)

            switch displayContent.state {
            case .privacyLocked:
                Label("Locked", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            case .notStarted:
                Text("Begin")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            case .inProgress, .complete:
                Text("\(displayContent.completionCount)/3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var autoCycleBadge: some View {
        Text("Auto")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var progressBadge: some View {
        Text("\(displayContent.completionCount)/3")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var pageBadge: some View {
        let count = snapshot?.photos.count ?? 0
        let index = count > 0 ? (entry.currentPhotoIndex % count) + 1 : 1
        return Text("\(index)/\(max(count, 1))")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var lockedCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Privacy Lock Enabled", systemImage: "lock.fill")
                .font(.caption.weight(.semibold))
            Text("Unlock in app to view photos and text.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.thinMaterial))
    }

    private var notStartedCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Start your Rose, Bud, Thorn")
                .font(.caption.weight(.semibold))
            Text("Add a photo or thought to begin.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.thinMaterial))
    }

    private var fallbackProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(displayContent.completionCount)/3 complete")
                .font(.headline)
            Text("Add a photo to enrich today's reflection.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var lockedInline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Privacy Lock is on", systemImage: "lock.fill")
                .font(.caption.weight(.semibold))
            Text("Open the app to view photos and reflections.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.thinMaterial))
    }

    private var notStartedInline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Start your Rose, Bud, Thorn")
                .font(.caption.weight(.semibold))
            Text("Add a photo or reflection to fill this widget.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.thinMaterial))
    }

    private func textRow(type: EntryType, excerpt: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: type.widgetSymbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(type.widgetTint)

            VStack(alignment: .leading, spacing: 1) {
                Text(type.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(excerpt.isEmpty ? type.widgetPlaceholder : excerpt)
                    .font(.caption2)
                    .foregroundStyle(excerpt.isEmpty ? .tertiary : .secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: excerpt.isEmpty ? "plus.circle" : "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(excerpt.isEmpty ? .secondary : type.widgetTint)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(type.widgetTint.opacity(0.18), lineWidth: 0.8)
                )
        )
    }

    private func sectionPhotoStrip(
        tileHeight: CGFloat,
        labelFont: Font,
        cornerRadius: CGFloat
    ) -> some View {
        HStack(spacing: 8) {
            ForEach(EntryType.allCases, id: \.self) { type in
                Link(destination: focusURL(type)) {
                    sectionPhotoTile(
                        type: type,
                        tileHeight: tileHeight,
                        labelFont: labelFont
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func sectionPhotoTile(type: EntryType, tileHeight: CGFloat, labelFont: Font) -> some View {
        let hasContent = !displayContent.excerpt(for: type).isEmpty
        return VStack(alignment: .center, spacing: 5) {
            ZStack(alignment: .topTrailing) {
                photoCard(photo: latestPhoto(for: type), cornerRadius: 10)
                Image(systemName: hasContent ? "checkmark.circle.fill" : "circle")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(hasContent ? type.widgetTint : .secondary)
                    .padding(4)
            }
            .frame(height: tileHeight)
            .clipped()

            Text(type.title)
                .font(labelFont.weight(.semibold))
                .foregroundStyle(type.widgetTint)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    private func latestPhoto(for type: EntryType) -> WidgetTodaySnapshotPhoto? {
        snapshot?.photos.first(where: { $0.type == type })
    }

    private func photoCard(photo: WidgetTodaySnapshotPhoto?, cornerRadius: CGFloat) -> some View {
        Group {
            if let image = loadedImage(for: photo) {
                image
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipped()
    }

    private func resolvedPhotoURL(for photo: WidgetTodaySnapshotPhoto) -> URL? {
        dayDirectoryURL?.appendingPathComponent(photo.relativePath)
    }

    private func loadedImage(for photo: WidgetTodaySnapshotPhoto?) -> Image? {
        guard let photo else { return nil }
        #if canImport(UIKit)
        if let jpegData = photo.thumbnailJPEGData,
           let image = UIImage(data: jpegData) {
            return Image(uiImage: image)
        }

        guard let url = resolvedPhotoURL(for: photo) else {
            return nil
        }
        guard let uiImage = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return Image(uiImage: uiImage)
        #else
        return nil
        #endif
    }
}

private extension EntryType {
    var widgetSymbol: String {
        switch self {
        case .rose:
            return "sun.max.fill"
        case .bud:
            return "leaf.fill"
        case .thorn:
            return "bolt.fill"
        }
    }

    var widgetTint: Color {
        switch self {
        case .rose:
            return Color(red: 0.95, green: 0.30, blue: 0.72)
        case .bud:
            return Color(red: 0.24, green: 0.80, blue: 0.49)
        case .thorn:
            return Color(red: 0.40, green: 0.34, blue: 0.86)
        }
    }

    var widgetPlaceholder: String {
        switch self {
        case .rose:
            return "Add Rose..."
        case .bud:
            return "Add Bud..."
        case .thorn:
            return "Add Thorn..."
        }
    }
}

struct CaptureMomentWidget: Widget {
    let kind: String = "CaptureMomentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayReflectionProvider()) { entry in
            TodayReflectionWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Rose, Bud, Thorn")
        .description("Photos and progress for today's reflection with fast resume links.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

@main
struct RoseBudThornWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CaptureMomentWidget()
    }
}
