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
    @State private var isRefreshingUser = false

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
                        .disabled(isEmailUnverified)
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
            VStack(spacing: 16) {
                verificationNotice

                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

                EmptyStateView(
                    title: "No videos",
                    message: isEmailUnverified ? "Verify your email before uploading source videos." : "Upload a source video to start processing clips.",
                    systemImage: "video"
                )
            }
            .padding()
        } else {
            List {
                verificationNotice

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

    private var currentUser: User? {
        authViewModel.authState.user
    }

    private var isEmailUnverified: Bool {
        currentUser?.isEmailVerified == false
    }

    @ViewBuilder
    private var verificationNotice: some View {
        if isEmailUnverified {
            EmailVerificationNotice(
                email: currentUser?.email,
                isRefreshing: isRefreshingUser
            ) {
                Task {
                    isRefreshingUser = true
                    await authViewModel.refreshCurrentUser()
                    isRefreshingUser = false
                }
            }
        }
    }
}

private struct EmailVerificationNotice: View {
    let email: String?
    let isRefreshing: Bool
    let refreshAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Verify your email to upload", systemImage: "envelope.badge.shield.half.filled")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: refreshAction) {
                if isRefreshing {
                    ProgressView()
                } else {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isRefreshing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }

    private var message: String {
        if let email {
            return "The backend requires \(email) to be verified before upload and processing are available."
        }

        return "The backend requires your email to be verified before upload and processing are available."
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
