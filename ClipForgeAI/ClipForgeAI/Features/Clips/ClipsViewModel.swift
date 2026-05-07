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

    private let videoID: String?
    private var jobID: String?
    private let clipService: any ClipServiceProtocol

    var canGenerateClips: Bool {
        videoID?.nilIfEmpty != nil
    }

    init(
        videoID: String?,
        jobID: String?,
        clipService: any ClipServiceProtocol,
        initialClips: [Clip] = []
    ) {
        self.videoID = videoID
        self.jobID = jobID
        self.clipService = clipService
        self.clips = initialClips
    }

    func loadClips() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            guard let resolvedJobID = try await resolvedJobID() else {
                clips = []
                errorMessage = "The video does not include a processing job yet."
                return
            }

            let fetchedClips = try await clipService.fetchClips(jobID: resolvedJobID)

            if !fetchedClips.isEmpty || clips.isEmpty {
                clips = fetchedClips
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolvedJobID() async throws -> String? {
        if let jobID = jobID?.nilIfEmpty {
            return jobID
        }

        guard let videoID = videoID?.nilIfEmpty else {
            return nil
        }

        let latestJobID = try await clipService.fetchLatestJobID(videoID: videoID)
        jobID = latestJobID
        return latestJobID
    }

    func generateClips() async {
        guard let videoID = videoID?.nilIfEmpty else {
            errorMessage = "This job can show generated clips, but it does not include a video ID for starting a new generation."
            return
        }

        isGenerating = true
        errorMessage = nil

        defer {
            isGenerating = false
        }

        do {
            generatedJob = try await clipService.generateClips(videoID: videoID)
            jobID = generatedJob?.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
