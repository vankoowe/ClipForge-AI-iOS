//
//  UploadViewModel.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Combine
import Foundation

@MainActor
final class UploadViewModel: ObservableObject {
    @Published var title = ""
    @Published private(set) var selectedFileURL: URL?
    @Published private(set) var isUploading = false
    @Published var errorMessage: String?

    var selectedFileName: String? {
        selectedFileURL?.lastPathComponent
    }

    var canUpload: Bool {
        selectedFileURL != nil && !isUploading
    }

    private let uploadService: any UploadServiceProtocol

    init(uploadService: any UploadServiceProtocol) {
        self.uploadService = uploadService
    }

    func selectFile(_ url: URL) {
        selectedFileURL = url

        if title.trimmed.isEmpty {
            title = url.deletingPathExtension().lastPathComponent
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
}
