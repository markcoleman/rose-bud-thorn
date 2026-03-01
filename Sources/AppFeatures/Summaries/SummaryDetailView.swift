import SwiftUI
import CoreModels

public struct SummaryDetailView: View {
    public let artifact: SummaryArtifact
    public let markdownURL: URL
    public let regenerate: () -> Void
    public let onPreviewShare: () -> Void
    public let onConfirmShare: () -> Void

    @State private var isSharePreviewPresented = false
    @State private var shareDraftText = ""
    @State private var shareConfirmed = false

    public init(
        artifact: SummaryArtifact,
        markdownURL: URL,
        regenerate: @escaping () -> Void,
        onPreviewShare: @escaping () -> Void = {},
        onConfirmShare: @escaping () -> Void = {}
    ) {
        self.artifact = artifact
        self.markdownURL = markdownURL
        self.regenerate = regenerate
        self.onPreviewShare = onPreviewShare
        self.onConfirmShare = onConfirmShare
    }

    public var body: some View {
        let title = PresentationFormatting.summaryTitle(for: artifact)
        let range = PresentationFormatting.summaryRangeText(for: artifact, timeZone: .current)
        let metadata = PresentationFormatting.summaryMetadataText(for: artifact)

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))

                    Text(range)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(metadata)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(title). \(range). \(metadata).")
                .accessibilityHint("Summary period details.")

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
                Button {
                    shareDraftText = artifact.contentMarkdown
                    shareConfirmed = false
                    isSharePreviewPresented = true
                    onPreviewShare()
                } label: {
                    Label("Share Snippet", systemImage: "square.and.arrow.up")
                }

                ShareLink(item: markdownURL) {
                    Label("Export File", systemImage: "doc.richtext")
                }

                Button("Regenerate", action: regenerate)
            }
        }
        .sheet(isPresented: $isSharePreviewPresented) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review and redact before sharing.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $shareDraftText)
                        .frame(minHeight: 220)
                        .padding(8)
                        .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Toggle("I confirm this snippet is ready to share", isOn: $shareConfirmed)
                        .font(.footnote)

                    if shareConfirmed {
                        ShareLink(item: shareDraftText) {
                            Label("Share Snippet", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                onConfirmShare()
                            }
                        )
                    } else {
                        Text("Enable confirmation to share.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding()
                .navigationTitle("Share Preview")
                #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            isSharePreviewPresented = false
                        }
                    }
                }
            }
        }
    }
}
