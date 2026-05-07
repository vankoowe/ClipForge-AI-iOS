//
//  UploadViewModel.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Combine
import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class UploadViewModel: ObservableObject {
    @Published var title = ""
    @Published var selectedFeatures = Set(ProcessingFeature.allCases)
    @Published var selectedClipPreset: ClipLengthPreset = .balanced
    @Published var targetClipCount = ClipSettingsRequest.balanced.targetClipCount
    @Published var minDurationSeconds = ClipSettingsRequest.balanced.minDurationSeconds
    @Published var maxDurationSeconds = ClipSettingsRequest.balanced.maxDurationSeconds
    @Published var preferredDurationSeconds = ClipSettingsRequest.balanced.preferredDurationSeconds
    @Published private(set) var selectedFileURL: URL?
    @Published private(set) var isUploading = false
    @Published private(set) var isImportingPhoto = false
    @Published var errorMessage: String?

    var selectedFileName: String? {
        selectedFileURL?.lastPathComponent
    }

    var canUpload: Bool {
        selectedFileURL != nil
            && !selectedFeatures.isEmpty
            && clipSettingsValidationMessage == nil
            && !isUploading
            && !isImportingPhoto
    }

    var isClipsEnabled: Bool {
        selectedFeatures.contains(.clips)
    }

    var processingValidationMessage: String? {
        if selectedFeatures.isEmpty {
            return "Choose at least one processing feature."
        }

        return clipSettingsValidationMessage
    }

    var clipSettingsValidationMessage: String? {
        guard isClipsEnabled else {
            return nil
        }

        do {
            try clipSettingsRequest.validate()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private let uploadService: any UploadServiceProtocol
    private var temporaryImportedFileURL: URL?

    init(uploadService: any UploadServiceProtocol) {
        self.uploadService = uploadService
    }

    func setFeature(_ feature: ProcessingFeature, isEnabled: Bool) {
        if isEnabled {
            selectedFeatures.insert(feature)
        } else {
            selectedFeatures.remove(feature)
        }
    }

    func isFeatureEnabled(_ feature: ProcessingFeature) -> Bool {
        selectedFeatures.contains(feature)
    }

    func applyClipPreset(_ preset: ClipLengthPreset) {
        selectedClipPreset = preset
        minDurationSeconds = preset.settings.minDurationSeconds
        maxDurationSeconds = preset.settings.maxDurationSeconds
        preferredDurationSeconds = preset.settings.preferredDurationSeconds
    }

    func selectFile(_ url: URL) {
        clearTemporaryImportedFile()
        selectedFileURL = url

        if title.trimmed.isEmpty {
            title = url.deletingPathExtension().lastPathComponent
        }
    }

    func importPhotoItem(_ item: PhotosPickerItem?) async {
        guard let item else {
            return
        }

        isImportingPhoto = true
        errorMessage = nil

        defer {
            isImportingPhoto = false
        }

        do {
            guard let pickedVideo = try await item.loadTransferable(type: PickedVideo.self) else {
                throw AppError.missingFile
            }

            clearTemporaryImportedFile()
            temporaryImportedFileURL = pickedVideo.url
            selectedFileURL = pickedVideo.url

            if title.trimmed.isEmpty {
                title = pickedVideo.url.deletingPathExtension().lastPathComponent
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setError(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    func upload() async -> Video? {
        guard let selectedFileURL else {
            errorMessage = AppError.missingFile.localizedDescription
            return nil
        }

        isUploading = true
        errorMessage = nil

        defer {
            isUploading = false
        }

        do {
            let processRequest = try processVideoRequest()

            return try await uploadService.uploadVideo(
                fileURL: selectedFileURL,
                title: title.trimmed.nilIfEmpty ?? selectedFileURL.deletingPathExtension().lastPathComponent,
                processRequest: processRequest
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private var clipSettingsRequest: ClipSettingsRequest {
        ClipSettingsRequest(
            targetClipCount: targetClipCount,
            minDurationSeconds: minDurationSeconds,
            maxDurationSeconds: maxDurationSeconds,
            preferredDurationSeconds: preferredDurationSeconds
        )
    }

    private func processVideoRequest() throws -> ProcessVideoRequest {
        guard !selectedFeatures.isEmpty else {
            throw ClipSettingsValidationError("Choose at least one processing feature.")
        }

        let clipSettings: ClipSettingsRequest?

        if isClipsEnabled {
            let settings = clipSettingsRequest
            try settings.validate()
            clipSettings = settings
        } else {
            clipSettings = nil
        }

        return ProcessVideoRequest(
            selectedFeatures: ProcessingFeature.allCases.filter { selectedFeatures.contains($0) },
            clipSettings: clipSettings
        )
    }

    private func clearTemporaryImportedFile() {
        guard let temporaryImportedFileURL else {
            return
        }

        try? FileManager.default.removeItem(at: temporaryImportedFileURL)
        self.temporaryImportedFileURL = nil
    }
}

enum ClipLengthPreset: String, CaseIterable, Identifiable {
    case short
    case balanced
    case longer

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .short:
            return "Short"
        case .balanced:
            return "Balanced"
        case .longer:
            return "Longer"
        }
    }

    var settings: ClipSettingsRequest {
        switch self {
        case .short:
            return ClipSettingsRequest(
                targetClipCount: 3,
                minDurationSeconds: 15,
                maxDurationSeconds: 25,
                preferredDurationSeconds: 20
            )
        case .balanced:
            return .balanced
        case .longer:
            return ClipSettingsRequest(
                targetClipCount: 3,
                minDurationSeconds: 30,
                maxDurationSeconds: 60,
                preferredDurationSeconds: 45
            )
        }
    }
}
