//
//  ClipsView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct ClipsView: View {
    @StateObject private var viewModel: ClipsViewModel

    init(
        videoID: String?,
        jobID: String?,
        clipService: any ClipServiceProtocol,
        initialClips: [Clip] = []
    ) {
        _viewModel = StateObject(
            wrappedValue: ClipsViewModel(
                videoID: videoID,
                jobID: jobID,
                clipService: clipService,
                initialClips: initialClips
            )
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ClipsHeader(
                    count: viewModel.clips.count,
                    isGenerating: viewModel.isGenerating,
                    canGenerate: viewModel.canGenerateClips,
                    generateAction: {
                        Task {
                            await viewModel.generateClips()
                        }
                    }
                )

                if let generatedJob = viewModel.generatedJob {
                    GenerationJobCard(job: generatedJob)
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                        .padding(.horizontal, 2)
                }

                if viewModel.isLoading && viewModel.clips.isEmpty {
                    LoadingClipCard()
                } else if viewModel.clips.isEmpty {
                    EmptyClipsCard()
                } else {
                    ForEach(viewModel.clips) { clip in
                        ClipCard(clip: clip)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Clips")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadClips()
        }
        .refreshable {
            await viewModel.loadClips()
        }
    }
}

private struct ClipsHeader: View {
    let count: Int
    let isGenerating: Bool
    let canGenerate: Bool
    let generateAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Generated clips")
                        .font(.title3.weight(.bold))

                    Text("\(count) clips ready")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "scissors")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))
                    .frame(width: 42, height: 42)
                    .background(Color(red: 0.06, green: 0.45, blue: 0.47).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }

            if canGenerate {
                Button(action: generateAction) {
                    Label(isGenerating ? "Generating" : "Generate clips", systemImage: "sparkles")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(red: 0.06, green: 0.45, blue: 0.47), in: RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isGenerating)
                .opacity(isGenerating ? 0.65 : 1)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct GenerationJobCard: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Generation job")
                    .font(.headline.weight(.bold))

                Spacer()

                StatusBadge(title: job.displayStatus.displayName, status: job.displayStatus)
            }

            ProgressView(value: job.normalizedProgress)

            Text("\(job.progressPercentage)% complete")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ClipCard: View {
    let clip: Clip

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.06, green: 0.45, blue: 0.47).opacity(0.12))

                    Image(systemName: "play.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 6) {
                    Text(clip.title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(2)

                    Text(timeRange)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Label(duration, systemImage: "timer")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                if let downloadURL = clip.downloadURL {
                    Link(destination: downloadURL) {
                        Label("Open", systemImage: "arrow.up.right")
                            .font(.footnote.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.06, green: 0.45, blue: 0.47).opacity(0.12), in: Capsule())
                    }
                } else {
                    Text("Render pending")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }

    private var timeRange: String {
        "\(clip.startTime.clipTimeDisplay) - \(clip.endTime.clipTimeDisplay)"
    }

    private var duration: String {
        max(clip.endTime - clip.startTime, 0).clipTimeDisplay
    }
}

private struct LoadingClipCard: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()

            Text("Loading clips")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyClipsCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "scissors")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color(red: 0.06, green: 0.45, blue: 0.47))

            Text("No clips yet")
                .font(.headline.weight(.bold))

            Text("When processing completes, generated clips will appear here.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private extension Double {
    var clipTimeDisplay: String {
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

    NavigationStack {
        ClipsView(videoID: "video_123", jobID: "job_123", clipService: container.clipService)
    }
}
