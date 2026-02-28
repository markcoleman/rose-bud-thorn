import SwiftUI
import WidgetKit

private enum CaptureAction: String, CaseIterable, Identifiable {
    case rose
    case bud
    case thorn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rose:
            return "Rose"
        case .bud:
            return "Bud"
        case .thorn:
            return "Thorn"
        }
    }

    var subtitle: String {
        switch self {
        case .rose:
            return "What went well"
        case .bud:
            return "What might bloom"
        case .thorn:
            return "What felt hard"
        }
    }

    var symbolName: String {
        switch self {
        case .rose:
            return "sun.max.fill"
        case .bud:
            return "leaf.fill"
        case .thorn:
            return "bolt.fill"
        }
    }

    var tint: Color {
        switch self {
        case .rose:
            return Color(red: 0.86, green: 0.33, blue: 0.43)
        case .bud:
            return Color(red: 0.33, green: 0.64, blue: 0.42)
        case .thorn:
            return Color(red: 0.49, green: 0.36, blue: 0.33)
        }
    }

    var deepLink: URL {
        URL(string: "rosebudthorn://capture?source=widget&type=\(rawValue)")!
    }
}

private struct CaptureMomentEntry: TimelineEntry {
    let date: Date
    let actions: [CaptureAction]
}

private struct CaptureMomentProvider: TimelineProvider {
    func placeholder(in context: Context) -> CaptureMomentEntry {
        CaptureMomentEntry(date: .now, actions: CaptureAction.allCases)
    }

    func getSnapshot(in context: Context, completion: @escaping (CaptureMomentEntry) -> Void) {
        completion(CaptureMomentEntry(date: .now, actions: CaptureAction.allCases))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CaptureMomentEntry>) -> Void) {
        let entry = CaptureMomentEntry(date: .now, actions: CaptureAction.allCases)
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

private struct CaptureMomentWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: CaptureMomentEntry

    var body: some View {
        ZStack {
            background

            switch family {
            case .systemSmall:
                smallBody
            case .systemMedium:
                mediumBody
            default:
                largeBody
            }
        }
        .containerBackground(for: .widget) {
            background
        }
        .widgetURL(URL(string: "rosebudthorn://capture?source=widget")!)
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(backgroundOrbColor.opacity(colorScheme == .dark ? 0.16 : 0.32))
                .frame(width: 120, height: 120)
                .offset(x: 55, y: -50)

            Circle()
                .fill(backgroundOrbColor.opacity(colorScheme == .dark ? 0.12 : 0.24))
                .frame(width: 90, height: 90)
                .offset(x: -70, y: 65)
        }
    }

    private var smallBody: some View {
        Link(destination: CaptureAction.rose.deepLink) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Capture", systemImage: "bolt.badge.clock")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Log this moment before it slips away.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    quickPill(for: .rose)
                    quickPill(for: .bud)
                    quickPill(for: .thorn)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(10)
    }

    private var mediumBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Capture Moment", systemImage: "sparkles")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Open directly into your reflection flow.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(entry.actions) { action in
                    Link(destination: action.deepLink) {
                        actionCard(for: action)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
    }

    private var largeBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Capture Moment")
                .font(.title3.weight(.bold))

            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(entry.actions) { action in
                Link(destination: action.deepLink) {
                    HStack(spacing: 12) {
                        Image(systemName: action.symbolName)
                            .font(.headline)
                            .foregroundStyle(action.tint)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(action.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func quickPill(for action: CaptureAction) -> some View {
        HStack(spacing: 4) {
            Image(systemName: action.symbolName)
            Text(action.title)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(action.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            (colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.6)),
            in: Capsule()
        )
    }

    private func actionCard(for action: CaptureAction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: action.symbolName)
                .font(.headline)
                .foregroundStyle(action.tint)

            Text(action.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(action.subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.09, green: 0.12, blue: 0.18),
                Color(red: 0.10, green: 0.16, blue: 0.15)
            ]
        }

        return [
            Color(red: 0.96, green: 0.92, blue: 0.88),
            Color(red: 0.89, green: 0.94, blue: 0.90)
        ]
    }

    private var backgroundOrbColor: Color {
        colorScheme == .dark ? .cyan : .white
    }
}

struct CaptureMomentWidget: Widget {
    let kind: String = "CaptureMomentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaptureMomentProvider()) { entry in
            CaptureMomentWidgetView(entry: entry)
        }
        .configurationDisplayName("Capture Moment")
        .description("Quickly log a Rose, Bud, or Thorn from the Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct RoseBudThornWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CaptureMomentWidget()
    }
}
