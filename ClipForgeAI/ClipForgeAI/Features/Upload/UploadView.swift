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

                    ProcessingLanguageCard(
                        selectedLanguageHint: $viewModel.selectedLanguageHint,
                        isDisabled: viewModel.isUploading || viewModel.isImportingPhoto
                    )

                    ProcessingFeaturesCard(
                        selectedFeatures: viewModel.selectedFeatures,
                        isDisabled: viewModel.isUploading || viewModel.isImportingPhoto,
                        featureBinding: featureBinding
                    )

                    if viewModel.isClipsEnabled {
                        ClipSettingsCard(
                            selectedPreset: Binding(
                                get: { viewModel.selectedClipPreset },
                                set: { viewModel.applyClipPreset($0) }
                            ),
                            targetClipCount: $viewModel.targetClipCount,
                            minDurationSeconds: $viewModel.minDurationSeconds,
                            maxDurationSeconds: $viewModel.maxDurationSeconds,
                            preferredDurationSeconds: $viewModel.preferredDurationSeconds,
                            captionsEnabled: $viewModel.captionsEnabled,
                            selectedAspectRatio: $viewModel.selectedAspectRatio,
                            validationMessage: viewModel.clipSettingsValidationMessage,
                            isDisabled: viewModel.isUploading || viewModel.isImportingPhoto
                        )
                    }

                    if let processingValidationMessage = viewModel.processingValidationMessage {
                        ErrorMessageView(message: processingValidationMessage)
                    }

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

    private func featureBinding(for feature: ProcessingFeature) -> Binding<Bool> {
        Binding(
            get: {
                viewModel.isFeatureEnabled(feature)
            },
            set: { isEnabled in
                viewModel.setFeature(feature, isEnabled: isEnabled)
            }
        )
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

private struct ProcessingLanguageCard: View {
    @Binding var selectedLanguageHint: ProcessingLanguageHint
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Language",
                subtitle: selectedLanguageHint.rawValue
            )

            Picker("Language", selection: $selectedLanguageHint) {
                ForEach(ProcessingLanguageHint.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.65 : 1)
    }
}

private struct ProcessingFeaturesCard: View {
    let selectedFeatures: Set<ProcessingFeature>
    let isDisabled: Bool
    let featureBinding: (ProcessingFeature) -> Binding<Bool>

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Processing",
                subtitle: "\(selectedFeatures.count) selected"
            )

            VStack(spacing: 10) {
                ForEach(ProcessingFeature.allCases, id: \.self) { feature in
                    ProcessingFeatureToggle(
                        feature: feature,
                        isOn: featureBinding(feature)
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.65 : 1)
    }
}

private struct ProcessingFeatureToggle: View {
    let feature: ProcessingFeature
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: feature.systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))
                    .frame(width: 34, height: 34)
                    .background(Color(red: 0.06, green: 0.45, blue: 0.47).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.displayName)
                        .font(.subheadline.weight(.semibold))

                    Text(feature.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
    }
}

private struct ClipSettingsCard: View {
    @Binding var selectedPreset: ClipLengthPreset
    @Binding var targetClipCount: Int
    @Binding var minDurationSeconds: Int
    @Binding var maxDurationSeconds: Int
    @Binding var preferredDurationSeconds: Int
    @Binding var captionsEnabled: Bool
    @Binding var selectedAspectRatio: ClipAspectRatio

    let validationMessage: String?
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Clip settings", subtitle: "\(targetClipCount) clips")

            Picker("Clip length", selection: $selectedPreset) {
                ForEach(ClipLengthPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            Picker("Aspect ratio", selection: $selectedAspectRatio) {
                ForEach(ClipAspectRatio.allCases) { aspectRatio in
                    Text(aspectRatio.displayName).tag(aspectRatio)
                }
            }
            .pickerStyle(.segmented)

            Toggle(isOn: $captionsEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "captions.bubble")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))
                        .frame(width: 34, height: 34)
                        .background(Color(red: 0.06, green: 0.45, blue: 0.47).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clip captions")
                            .font(.subheadline.weight(.semibold))

                        Text("Burn captions into generated clips.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toggleStyle(.switch)

            VStack(spacing: 12) {
                SettingsStepper(
                    title: "Target clips",
                    value: $targetClipCount,
                    range: 1...20,
                    suffix: "clips"
                )

                SettingsStepper(
                    title: "Minimum duration",
                    value: $minDurationSeconds,
                    range: 5...120,
                    suffix: "sec"
                )

                SettingsStepper(
                    title: "Maximum duration",
                    value: $maxDurationSeconds,
                    range: 5...120,
                    suffix: "sec"
                )

                SettingsStepper(
                    title: "Preferred duration",
                    value: $preferredDurationSeconds,
                    range: 5...120,
                    suffix: "sec"
                )
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.65 : 1)
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline.weight(.bold))

            Spacer()

            Text(subtitle)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct SettingsStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String

    var body: some View {
        Stepper(value: $value, in: range) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(value) \(suffix)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))
            }
        }
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
