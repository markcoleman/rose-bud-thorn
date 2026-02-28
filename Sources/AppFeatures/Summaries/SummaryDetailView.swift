import SwiftUI
import CoreModels

public struct SummaryDetailView: View {
    public let artifact: SummaryArtifact
    public let markdownURL: URL
    public let regenerate: () -> Void

    public init(
        artifact: SummaryArtifact,
        markdownURL: URL,
        regenerate: @escaping () -> Void
    ) {
        self.artifact = artifact
        self.markdownURL = markdownURL
        self.regenerate = regenerate
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(artifact.key)
                    .font(.title2.weight(.semibold))

                if let attributed = try? AttributedString(markdown: artifact.contentMarkdown) {
                    Text(attributed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(artifact.contentMarkdown)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ShareLink(item: markdownURL) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                Button("Regenerate", action: regenerate)
            }
        }
    }
}
