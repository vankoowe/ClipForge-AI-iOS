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
    @Published private(set) var selectedFileURL: URL?
    @Published private(set) var isUploading = false
    @Published private(set) var isImportingPhoto = false
    @Published var errorMessage: String?

    var selectedFileName: String? {
        selectedFileURL?.lastPathComponent
    }

    var canUpload: Bool {
        selectedFileURL != nil && !isUploading && !isImportingPhoto
    }

    private let uploadService: any UploadServiceProtocol
    private var temporaryImportedFileURL: URL?

    init(uploadService: any UploadServiceProtocol) {
        self.uploadService = uploadService
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
            return try await uploadService.uploadVideo(
                fileURL: selectedFileURL,
                title: title.trimmed.nilIfEmpty ?? selectedFileURL.deletingPathExtension().lastPathComponent
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func clearTemporaryImportedFile() {
        guard let temporaryImportedFileURL else {
            return
        }

        try? FileManager.default.removeItem(at: temporaryImportedFileURL)
        self.temporaryImportedFileURL = nil
    }
}
