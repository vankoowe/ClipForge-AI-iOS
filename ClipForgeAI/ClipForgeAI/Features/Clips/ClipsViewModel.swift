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
            let fetchedClips: [Clip]

            if let resolvedJobID = jobID?.nilIfEmpty {
                fetchedClips = try await clipService.fetchClips(jobID: resolvedJobID)
            } else if let videoID = videoID?.nilIfEmpty {
                fetchedClips = try await clipService.fetchClips(videoID: videoID)
            } else {
                clips = []
                errorMessage = "This clips screen needs a video or processing job to load results."
                return
            }

            if !fetchedClips.isEmpty || clips.isEmpty {
                clips = fetchedClips
            }
        } catch {
            errorMessage = error.localizedDescription
        }
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
