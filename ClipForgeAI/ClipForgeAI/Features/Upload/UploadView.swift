//
//  UploadView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: UploadViewModel
    @State private var isFileImporterPresented = false

    private let onUploadCompleted: (Video) -> Void

    init(
        uploadService: any UploadServiceProtocol,
        onUploadCompleted: @escaping (Video) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: UploadViewModel(uploadService: uploadService))
        self.onUploadCompleted = onUploadCompleted
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Video") {
                    TextField("Title", text: $viewModel.title)

                    Button {
                        isFileImporterPresented = true
                    } label: {
                        Label(viewModel.selectedFileName ?? "Choose video file", systemImage: "video.badge.plus")
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

                if viewModel.isUploading {
                    LoadingStateView(message: "Uploading video")
                }
            }
            .navigationTitle("Upload")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Upload") {
                        Task {
                            if let video = await viewModel.upload() {
                                onUploadCompleted(video)
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canUpload)
                }
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.movie, .video, .mpeg4Movie]
            ) { result in
                switch result {
                case .success(let url):
                    viewModel.selectFile(url)
                case .failure(let error):
                    viewModel.setError(error)
                }
            }
        }
    }
}

#Preview {
    let container = AppContainer()

    UploadView(uploadService: container.uploadService) { _ in }
}
