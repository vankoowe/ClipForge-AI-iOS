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
    @State private var navigationPath: [DashboardRoute] = []
    @State private var presentedSheet: DashboardSheet?
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
        NavigationStack(path: $navigationPath) {
            content
                .navigationTitle("Videos")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            presentedSheet = .profile
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                        .accessibilityLabel("Profile")
                    }
                }
                .navigationDestination(for: DashboardRoute.self) { route in
                    switch route {
                    case .clips(let videoID, let jobID):
                        ClipsView(videoID: videoID, jobID: jobID, clipService: clipService)
                    case .job(let jobID):
                        JobStatusView(jobID: jobID, jobService: jobService, clipService: clipService)
                    }
                }
                .sheet(item: $presentedSheet) { sheet in
                    switch sheet {
                    case .upload:
                        UploadView(uploadService: uploadService) { video in
                            viewModel.upsert(video)
                        }
                    case .profile:
                        ProfileView(
                            user: currentUser,
                            isRefreshing: isRefreshingUser,
                            refreshAction: refreshUser,
                            logoutAction: {
                                authViewModel.logout()
                            }
                        )
                    }
                }
                .task {
                    await viewModel.loadVideosIfNeeded()
                }
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                DashboardHeader(
                    user: currentUser,
                    totalCount: viewModel.videos.count,
                    activeCount: viewModel.videos.filter(\.status.isActive).count,
                    readyCount: viewModel.videos.filter(\.status.isReady).count,
                    isUploadDisabled: isEmailUnverified,
                    uploadAction: {
                        presentedSheet = .upload
                    }
                )

                verificationNotice

                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                        .padding(.horizontal, 2)
                }

                LibrarySectionHeader(count: viewModel.videos.count)

                if viewModel.isLoading && viewModel.videos.isEmpty {
                    LoadingVideoCard()
                } else if viewModel.videos.isEmpty {
                    EmptyVideoLibraryCard(isEmailUnverified: isEmailUnverified)
                } else {
                    ForEach(viewModel.videos) { video in
                        VideoCard(
                            video: video,
                            primaryAction: {
                                navigationPath.append(primaryRoute(for: video))
                            },
                            jobAction: video.latestJobID.map { jobID in
                                {
                                    navigationPath.append(.job(jobID: jobID))
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .refreshable {
            await viewModel.loadVideos()
            await authViewModel.refreshCurrentUser()
        }
    }

    private func primaryRoute(for video: Video) -> DashboardRoute {
        if let latestJobID = video.latestJobID {
            return .job(jobID: latestJobID)
        }

        return .clips(videoID: video.id, jobID: video.latestJobID)
    }

    private var currentUser: User? {
        authViewModel.authState.user
    }

    private var isEmailUnverified: Bool {
        currentUser?.isEmailVerified == false
    }

    private func refreshUser() {
        Task {
            isRefreshingUser = true
            await authViewModel.refreshCurrentUser()
            isRefreshingUser = false
        }
    }

    @ViewBuilder
    private var verificationNotice: some View {
        if isEmailUnverified {
            EmailVerificationNotice(
                email: currentUser?.email,
                isRefreshing: isRefreshingUser,
                refreshAction: refreshUser
            )
        }
    }
}

private enum DashboardRoute: Hashable {
    case clips(videoID: String, jobID: String?)
    case job(jobID: String)
}

private enum DashboardSheet: Identifiable {
    case upload
    case profile

    var id: String {
        switch self {
        case .upload:
            return "upload"
        case .profile:
            return "profile"
        }
    }
}

private struct DashboardHeader: View {
    let user: User?
    let totalCount: Int
    let activeCount: Int
    let readyCount: Int
    let isUploadDisabled: Bool
    let uploadAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ClipForge AI")
                        .font(.title2.weight(.bold))

                    Text(user?.email ?? "Video processing workspace")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                VerificationBadge(isVerified: user?.isEmailVerified)
            }

            HStack(spacing: 10) {
                DashboardMetric(title: "Total", value: "\(totalCount)", systemImage: "rectangle.stack")
                DashboardMetric(title: "Active", value: "\(activeCount)", systemImage: "clock.arrow.circlepath")
                DashboardMetric(title: "Ready", value: "\(readyCount)", systemImage: "checkmark.seal")
            }

            Button(action: uploadAction) {
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.18), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upload video")
                            .font(.headline.weight(.bold))

                        Text(isUploadDisabled ? "Verify email to unlock uploads" : "Photos or Files")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(14)
                .background(Color(red: 0.06, green: 0.45, blue: 0.47), in: RoundedRectangle(cornerRadius: 8))
            }
            .disabled(isUploadDisabled)
            .opacity(isUploadDisabled ? 0.6 : 1)
            .accessibilityLabel("Upload video")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
    }
}

private struct DashboardMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))

            Text(value)
                .font(.title3.weight(.bold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct LibrarySectionHeader: View {
    let count: Int

    var body: some View {
        HStack {
            Text("Library")
                .font(.headline.weight(.bold))

            Spacer()

            Text("\(count) videos")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
}

private struct EmailVerificationNotice: View {
    let email: String?
    let isRefreshing: Bool
    let refreshAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Verify your email to upload", systemImage: "envelope.badge.shield.half.filled")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: refreshAction) {
                Label(isRefreshing ? "Refreshing" : "Refresh status", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(isRefreshing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
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

private struct VideoCard: View {
    let video: Video
    let primaryAction: () -> Void
    let jobAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: primaryAction) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VideoThumbnailPlaceholder(status: video.status)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(video.title)
                                    .font(.headline.weight(.semibold))
                                    .lineLimit(2)

                                Spacer(minLength: 8)

                                StatusBadge(title: video.status.displayName, status: video.status)
                            }

                            if let fileName = video.fileName {
                                Label(fileName, systemImage: "doc")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }

                    HStack(spacing: 14) {
                        if let durationSeconds = video.durationSeconds {
                            VideoMetadataItem(systemImage: "timer", value: durationSeconds.durationDisplay)
                        }

                        if let createdAt = video.createdAt {
                            VideoMetadataItem(systemImage: "calendar", value: createdAt.shortDisplay)
                        }

                        Spacer()

                        Label(video.latestJobID == nil ? "Open clips" : "Open job", systemImage: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))
                    }
                }
            }
            .buttonStyle(.plain)

            if let jobAction {
                Divider()

                Button(action: jobAction) {
                    Label("View processing job", systemImage: "clock.arrow.circlepath")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

private struct VideoThumbnailPlaceholder: View {
    let status: VideoStatus

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(status.tint.opacity(0.14))

            Image(systemName: "play.rectangle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(status.tint)
        }
        .frame(width: 58, height: 58)
    }
}

private struct VideoMetadataItem: View {
    let systemImage: String
    let value: String

    var body: some View {
        Label(value, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

private struct LoadingVideoCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()

            Text("Loading videos")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyVideoLibraryCard: View {
    let isEmailUnverified: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))

            Text("No videos yet")
                .font(.headline.weight(.bold))

            Text(isEmailUnverified ? "Verify your email before uploading source videos." : "Upload a source video to start processing clips.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct VerificationBadge: View {
    let isVerified: Bool?

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var title: String {
        switch isVerified {
        case true:
            return "Verified"
        case false:
            return "Unverified"
        case nil:
            return "Account"
        }
    }

    private var systemImage: String {
        isVerified == false ? "exclamationmark.triangle.fill" : "checkmark.seal.fill"
    }

    private var color: Color {
        isVerified == false ? .orange : Color(red: 0.06, green: 0.45, blue: 0.47)
    }
}

private extension VideoStatus {
    var isActive: Bool {
        switch self {
        case .uploading, .uploaded, .queued, .processing:
            return true
        case .processed, .completed, .ready, .failed, .unknown:
            return false
        }
    }

    var isReady: Bool {
        switch self {
        case .processed, .completed, .ready:
            return true
        case .uploading, .uploaded, .queued, .processing, .failed, .unknown:
            return false
        }
    }

    var tint: Color {
        switch self {
        case .ready, .processed, .completed:
            return .green
        case .failed:
            return .red
        case .processing, .uploading:
            return .blue
        case .queued, .uploaded:
            return .orange
        case .unknown:
            return .secondary
        }
    }
}

private extension Double {
    var durationDisplay: String {
        let totalSeconds = max(Int(self.rounded()), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }

        return "\(seconds)s"
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
