//
//  DashboardView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: VideosViewModel
    @State private var isShowingUpload = false

    private let uploadService: any UploadServiceProtocol
    private let jobService: any JobServiceProtocol
    private let clipService: any ClipServiceProtocol

    init(
        videoService: any VideoServiceProtocol,
        uploadService: any UploadServiceProtocol,
        jobService: any JobServiceProtocol,
        clipService: any ClipServiceProtocol
    ) {
        _viewModel = StateObject(wrappedValue: VideosViewModel(videoService: videoService))
        self.uploadService = uploadService
        self.jobService = jobService
        self.clipService = clipService
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Videos")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Log Out") {
                            authViewModel.logout()
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingUpload = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Upload video")
                    }
                }
                .sheet(isPresented: $isShowingUpload) {
                    UploadView(uploadService: uploadService) { video in
                        viewModel.upsert(video)
                    }
                }
                .task {
                    await viewModel.loadVideosIfNeeded()
                }
                .refreshable {
                    await viewModel.loadVideos()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.videos.isEmpty {
            LoadingStateView(message: "Loading videos")
        } else if viewModel.videos.isEmpty {
            EmptyStateView(
                title: "No videos",
                message: "Upload a source video to start processing clips.",
                systemImage: "video"
            )
        } else {
            List {
                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

                ForEach(viewModel.videos) { video in
                    VStack(alignment: .leading, spacing: 12) {
                        NavigationLink {
                            ClipsView(videoID: video.id, jobID: video.latestJobID, clipService: clipService)
                        } label: {
                            VideoRow(video: video)
                        }

                        if let latestJobID = video.latestJobID {
                            NavigationLink {
                                JobStatusView(jobID: latestJobID, jobService: jobService)
                            } label: {
                                Label("View processing job", systemImage: "clock.arrow.circlepath")
                                    .font(.footnote)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

private struct VideoRow: View {
    let video: Video

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(video.title)
                    .font(.headline)

                Spacer()

                StatusBadge(title: video.status.displayName, status: video.status)
            }

            if let fileName = video.fileName {
                Text(fileName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let createdAt = video.createdAt {
                Text(createdAt.shortDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let container = AppContainer()

    DashboardView(
        videoService: container.videoService,
        uploadService: container.uploadService,
        jobService: container.jobService,
        clipService: container.clipService
    )
    .environmentObject(container.authViewModel)
}
