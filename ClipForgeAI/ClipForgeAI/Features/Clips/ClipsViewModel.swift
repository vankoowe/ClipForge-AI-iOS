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
    private var jobID: String?
    private let clipService: any ClipServiceProtocol

    init(
        videoID: String,
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
            guard let jobID else {
                if clips.isEmpty {
                    clips = []
                }
                return
            }

            let fetchedClips = try await clipService.fetchClips(jobID: jobID)

            if !fetchedClips.isEmpty || clips.isEmpty {
                clips = fetchedClips
            }
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
            jobID = generatedJob?.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
