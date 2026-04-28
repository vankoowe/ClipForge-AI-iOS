//
//  ClipsView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct ClipsView: View {
    @StateObject private var viewModel: ClipsViewModel

    init(videoID: String, clipService: any ClipServiceProtocol) {
        _viewModel = StateObject(wrappedValue: ClipsViewModel(videoID: videoID, clipService: clipService))
    }

    var body: some View {
        content
            .navigationTitle("Clips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.generateClips()
                        }
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    .disabled(viewModel.isGenerating)
                    .accessibilityLabel("Generate clips")
                }
            }
            .task {
                await viewModel.loadClips()
            }
            .refreshable {
                await viewModel.loadClips()
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.clips.isEmpty {
            LoadingStateView(message: "Loading clips")
        } else if viewModel.clips.isEmpty {
            EmptyStateView(
                title: "No clips",
                message: "Generate clips for this video when processing is complete.",
                systemImage: "scissors"
            )
            .overlay(alignment: .bottom) {
                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                        .padding()
                }
            }
        } else {
            List {
                if let generatedJob = viewModel.generatedJob {
                    Section("Generation Job") {
                        LabeledContent("Status", value: generatedJob.status.displayName)
                        LabeledContent("Progress", value: "\(generatedJob.progressPercentage)%")
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }

                ForEach(viewModel.clips) { clip in
                    ClipRow(clip: clip)
                }
            }
        }
    }
}

private struct ClipRow: View {
    let clip: Clip

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(clip.title)
                .font(.headline)

            Text("\(clip.startTime.formatted())s - \(clip.endTime.formatted())s")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let downloadURL = clip.downloadURL {
                Link("Download", destination: downloadURL)
                    .font(.footnote)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let container = AppContainer()

    NavigationStack {
        ClipsView(videoID: "video_123", clipService: container.clipService)
    }
}
