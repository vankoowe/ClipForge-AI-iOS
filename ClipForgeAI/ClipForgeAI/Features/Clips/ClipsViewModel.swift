//
//  ClipsViewModel.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Combine
import Foundation

@MainActor
final class ClipsViewModel: ObservableObject {
    @Published private(set) var clips: [Clip] = []
    @Published private(set) var generatedJob: Job?
    @Published private(set) var isLoading = false
    @Published private(set) var isGenerating = false
    @Published var errorMessage: String?

    private let videoID: String
    private let clipService: any ClipServiceProtocol

    init(videoID: String, clipService: any ClipServiceProtocol) {
        self.videoID = videoID
        self.clipService = clipService
    }

    func loadClips() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            clips = try await clipService.fetchClips(videoID: videoID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generateClips() async {
        isGenerating = true
        errorMessage = nil

        defer {
            isGenerating = false
        }

        do {
            generatedJob = try await clipService.generateClips(videoID: videoID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
