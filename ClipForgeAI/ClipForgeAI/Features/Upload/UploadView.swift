//
//  UploadView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct UploadView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: UploadViewModel
    @State private var isFileImporterPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?

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
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    UploadHeader()

                    UploadTitleField(title: $viewModel.title)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Source")
                            .font(.headline.weight(.bold))

                        HStack(spacing: 12) {
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .videos,
                                photoLibrary: .shared()
                            ) {
                                UploadSourceButton(
                                    title: "Photos",
                                    subtitle: "Camera roll",
                                    systemImage: "photo.on.rectangle"
                                )
                            }
                            .disabled(viewModel.isUploading || viewModel.isImportingPhoto)

                            Button {
                                isFileImporterPresented = true
                            } label: {
                                UploadSourceButton(
                                    title: "Files",
                                    subtitle: "Local files",
                                    systemImage: "folder"
                                )
                            }
                            .disabled(viewModel.isUploading || viewModel.isImportingPhoto)
                        }
                    }

                    if let selectedFileName = viewModel.selectedFileName {
                        SelectedVideoCard(fileName: selectedFileName)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        ErrorMessageView(message: errorMessage)
                    }

                    if viewModel.isImportingPhoto {
                        UploadProgressCard(title: "Importing video", message: "Preparing the selected gallery item.")
                    }

                    if viewModel.isUploading {
                        UploadProgressCard(title: "Uploading video", message: "Creating the source file and processing job.")
                    }
                }
                .padding(16)
                .padding(.bottom, 92)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                UploadFooterButton(
                    isEnabled: viewModel.canUpload,
                    isLoading: viewModel.isUploading,
                    action: upload
                )
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
            .onChange(of: selectedPhotoItem) { _, item in
                Task {
                    await viewModel.importPhotoItem(item)
                    selectedPhotoItem = nil
                }
            }
        }
    }

    private func upload() {
        Task {
            if let video = await viewModel.upload() {
                onUploadCompleted(video)
                dismiss()
            }
        }
    }
}

private struct UploadHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "video.badge.plus")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))
                    .frame(width: 44, height: 44)
                    .background(Color(red: 0.06, green: 0.45, blue: 0.47).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Create a processing job")
                        .font(.title3.weight(.bold))

                    Text("Choose a video and ClipForge will upload, register, and process it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct UploadTitleField: View {
    @Binding var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.headline.weight(.bold))

            TextField("Optional video title", text: $title)
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                )
        }
    }
}

private struct UploadSourceButton: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
    }
}

private struct SelectedVideoCard: View {
    let fileName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 3) {
                Text("Selected video")
                    .font(.subheadline.weight(.semibold))

                Text(fileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.green.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct UploadProgressCard: View {
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct UploadFooterButton: View {
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                }

                Text(isLoading ? "Uploading" : "Start Upload")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(red: 0.06, green: 0.45, blue: 0.47), in: RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.48)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }
}

#Preview {
    let container = AppContainer()

    UploadView(uploadService: container.uploadService) { _ in }
}
