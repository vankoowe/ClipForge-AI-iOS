//
//  JobStatusView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct JobStatusView: View {
    @StateObject private var viewModel: JobStatusViewModel
    private let clipService: any ClipServiceProtocol

    init(jobID: String, jobService: any JobServiceProtocol, clipService: any ClipServiceProtocol) {
        _viewModel = StateObject(wrappedValue: JobStatusViewModel(jobID: jobID, jobService: jobService))
        self.clipService = clipService
    }

    var body: some View {
        content
            .navigationTitle("Job Status")
            .task {
                viewModel.startPolling()
            }
            .onDisappear {
                viewModel.stopPolling()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let job = viewModel.job {
            Form {
                Section("Progress") {
                    ProgressView(value: job.normalizedProgress) {
                        Text(job.displayStatus.displayName)
                    } currentValueLabel: {
                        Text("\(job.progressPercentage)%")
                    }

                    StatusBadge(title: job.displayStatus.displayName, status: job.displayStatus)

                    if let errorMessage = job.errorMessage {
                        ErrorMessageView(message: errorMessage)
                    } else if let message = job.displayMessage {
                        Text(message)
                            .foregroundStyle(.secondary)
                    }

                    if let clipsCount = job.clipsCount {
                        if clipsCount > 0, let videoID = job.videoID {
                            NavigationLink {
                                ClipsView(
                                    videoID: videoID,
                                    jobID: job.id,
                                    clipService: clipService,
                                    initialClips: job.clips ?? []
                                )
                            } label: {
                                LabeledContent("Clips", value: "\(clipsCount)")
                            }
                        } else {
                            LabeledContent("Clips", value: "\(clipsCount)")
                        }
                    }
                }

                Section("Details") {
                    LabeledContent("Job ID", value: job.id)

                    if let type = job.type {
                        LabeledContent("Type", value: type)
                    }

                    if let updatedAt = job.updatedAt {
                        LabeledContent("Updated", value: updatedAt.shortDisplay)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }
            }
        } else if let errorMessage = viewModel.errorMessage {
            ErrorMessageView(message: errorMessage)
                .padding()
        } else {
            LoadingStateView(message: "Checking job")
        }
    }
}

#Preview {
    let container = AppContainer()

    NavigationStack {
        JobStatusView(jobID: "job_123", jobService: container.jobService, clipService: container.clipService)
    }
}
