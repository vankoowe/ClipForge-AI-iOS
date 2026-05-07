//
//  JobStatusViewModel.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Combine
import Foundation

@MainActor
final class JobStatusViewModel: ObservableObject {
    @Published private(set) var job: Job?
    @Published private(set) var isPolling = false
    @Published var errorMessage: String?

    private let jobID: String
    private let jobService: any JobServiceProtocol
    private var pollingTask: Task<Void, Never>?

    init(jobID: String, jobService: any JobServiceProtocol) {
        self.jobID = jobID
        self.jobService = jobService
    }

    deinit {
        pollingTask?.cancel()
    }

    func startPolling() {
        guard pollingTask == nil else {
            return
        }

        isPolling = true
        errorMessage = nil

        pollingTask = Task { [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                do {
                    let job = try await jobService.fetchJob(id: jobID)
                    self.job = job

                    if job.shouldStopPolling {
                        self.isPolling = false
                        self.pollingTask = nil
                        return
                    }

                    try await Task.sleep(nanoseconds: 3_000_000_000)
                } catch is CancellationError {
                    return
                } catch {
                    self.errorMessage = error.localizedDescription
                    self.isPolling = false
                    self.pollingTask = nil
                    return
                }
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPolling = false
    }
}
