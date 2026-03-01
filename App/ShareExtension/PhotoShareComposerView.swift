import SwiftUI
import UIKit
import CoreModels

@MainActor
final class PhotoShareComposerModel: ObservableObject {
    enum ViewState: Equatable {
        case loading
        case ready
        case failure(String)
        case success(String)
    }

    @Published var previewImage: UIImage?
    @Published var selectedType: EntryType = .rose
    @Published var viewState: ViewState = .loading
    @Published var isSending = false

    var sourceImageURL: URL?

    var canSend: Bool {
        if isSending {
            return false
        }
        if case .ready = viewState {
            return sourceImageURL != nil
        }
        return false
    }
}

struct PhotoShareComposerView: View {
    @ObservedObject var model: PhotoShareComposerModel
    let onCancel: () -> Void
    let onSend: () -> Void
    let onDone: () -> Void
    let onOpenApp: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                switch model.viewState {
                case .loading:
                    ProgressView("Loading photo…")
                        .frame(maxHeight: .infinity)
                case .ready:
                    readyContent
                case .failure(let message):
                    stateMessage(
                        title: "Unable to Share",
                        message: message,
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .orange
                    )
                case .success(let message):
                    VStack(spacing: 14) {
                        stateMessage(
                            title: "Sent",
                            message: message,
                            systemImage: "checkmark.circle.fill",
                            tint: .green
                        )
                        Button("Open App", action: onOpenApp)
                            .buttonStyle(.borderedProminent)
                        Button("Done", action: onDone)
                            .buttonStyle(.bordered)
                    }
                }
            }
            .padding(16)
            .navigationTitle("Send to Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private var readyContent: some View {
        VStack(spacing: 14) {
            if let previewImage = model.previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Picker("Category", selection: $model.selectedType) {
                Text("Rose").tag(EntryType.rose)
                Text("Bud").tag(EntryType.bud)
                Text("Thorn").tag(EntryType.thorn)
            }
            .pickerStyle(.segmented)

            Button {
                onSend()
            } label: {
                if model.isSending {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Send to Today")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canSend)
        }
    }

    private func stateMessage(
        title: String,
        message: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(tint)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
