//
//  VideosViewModel.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Combine
import Foundation

@MainActor
final class VideosViewModel: ObservableObject {
    @Published private(set) var videos: [Video] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let videoService: any VideoServiceProtocol

    init(videoService: any VideoServiceProtocol) {
        self.videoService = videoService
    }

    func loadVideosIfNeeded() async {
        guard videos.isEmpty else {
            return
        }

        await loadVideos()
    }

    func loadVideos() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            videos = try await videoService.fetchVideos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func upsert(_ video: Video) {
        if let index = videos.firstIndex(where: { $0.id == video.id }) {
            videos[index] = video
        } else {
            videos.insert(video, at: 0)
        }
    }
}
