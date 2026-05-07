//
//  ClipService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

protocol ClipServiceProtocol {
    func fetchClips(jobID: String) async throws -> [Clip]
    func fetchClips(videoID: String) async throws -> [Clip]
    func fetchLatestJobID(videoID: String) async throws -> String?
    func generateClips(videoID: String) async throws -> Job
}

final class ClipService: ClipServiceProtocol {
    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchClips(jobID: String) async throws -> [Clip] {
        let endpoint = APIEndpoint(path: "/jobs/\(jobID)/clips", method: .get)
        let response = try await apiClient.request(endpoint, as: APICollectionResponse<Clip>.self)
        return response.items
    }

    func fetchClips(videoID: String) async throws -> [Clip] {
        let lookup = try await fetchVideoClipLookup(videoID: videoID)

        if !lookup.clips.isEmpty {
            return lookup.clips
        }

        if let latestJobID = lookup.latestJobID {
            return try await fetchClips(jobID: latestJobID)
        }

        if let discoveredJobID = try await fetchDiscoveredJobID(videoID: videoID) {
            return try await fetchClips(jobID: discoveredJobID)
        }

        NetworkLogger.logClipLookup("video detail did not include a job id; trying video clip endpoints videoId=\"\(videoID)\"")
        return try await fetchVideoScopedClips(videoID: videoID)
    }

    func fetchLatestJobID(videoID: String) async throws -> String? {
        let endpoint = APIEndpoint(path: "/videos/\(videoID)", method: .get)
        let response = try await apiClient.request(endpoint, as: APIObjectResponse<VideoClipLookup>.self)
        return response.value.latestJobID
    }

    func generateClips(videoID: String) async throws -> Job {
        let body = ProcessVideoRequest(selectedFeatures: [.clips], clipSettings: .balanced)
        let endpoint = APIEndpoint(
            path: "/videos/\(videoID)/process",
            method: .post,
            body: try APIEndpoint.jsonBody(body)
        )
        let response = try await apiClient.request(endpoint, as: APIObjectResponse<ProcessVideoResponse>.self)
        let jobEndpoint = APIEndpoint(path: "/jobs/\(response.value.jobID)", method: .get)
        let jobResponse = try await apiClient.request(jobEndpoint, as: APIObjectResponse<Job>.self)
        return jobResponse.value
    }

    private func fetchVideoClipLookup(videoID: String) async throws -> VideoClipLookup {
        let endpoint = APIEndpoint(path: "/videos/\(videoID)", method: .get)
        let response = try await apiClient.request(endpoint, as: APIObjectResponse<VideoClipLookup>.self)
        return response.value
    }

    private func fetchDiscoveredJobID(videoID: String) async throws -> String? {
        for endpoint in jobDiscoveryEndpoints(videoID: videoID) {
            do {
                let response = try await apiClient.request(endpoint, as: APICollectionResponse<Job>.self)

                if let jobID = response.items.preferredClipJobID {
                    NetworkLogger.logClipLookup("resolved job from video job endpoint jobId=\"\(jobID)\" videoId=\"\(videoID)\"")
                    return jobID
                }
            } catch {
                guard shouldTryNextFallback(after: error) else {
                    throw error
                }
            }
        }

        return nil
    }

    private func fetchVideoScopedClips(videoID: String) async throws -> [Clip] {
        for endpoint in videoClipEndpoints(videoID: videoID) {
            do {
                let response = try await apiClient.request(endpoint, as: APICollectionResponse<Clip>.self)
                return response.items
            } catch {
                guard shouldTryNextFallback(after: error) else {
                    throw error
                }
            }
        }

        throw ClipLookupError.missingVideoClipLookup
    }

    private func jobDiscoveryEndpoints(videoID: String) -> [APIEndpoint] {
        [
            APIEndpoint(path: "/videos/\(videoID)/jobs", method: .get),
            APIEndpoint(
                path: "/jobs",
                method: .get,
                queryItems: [URLQueryItem(name: "videoId", value: videoID)]
            )
        ]
    }

    private func videoClipEndpoints(videoID: String) -> [APIEndpoint] {
        [
            APIEndpoint(path: "/videos/\(videoID)/clips", method: .get),
            APIEndpoint(
                path: "/clips",
                method: .get,
                queryItems: [URLQueryItem(name: "videoId", value: videoID)]
            )
        ]
    }

    private func shouldTryNextFallback(after error: Error) -> Bool {
        guard let appError = error as? AppError else {
            return false
        }

        switch appError {
        case .notFound:
            return true
        case .server(let statusCode, _):
            return [400, 405].contains(statusCode)
        default:
            return false
        }
    }
}

enum ClipLookupError: LocalizedError {
    case missingVideoClipLookup

    var errorDescription: String? {
        switch self {
        case .missingVideoClipLookup:
            return "No clip records were returned for this video yet. If processing is complete, the backend needs to return a latest job ID with the video."
        }
    }
}

private struct VideoClipLookup: Decodable {
    let latestJobID: String?
    let clips: [Clip]

    private enum CodingKeys: String, CodingKey {
        case latestJobID
        case latestJobId
        case jobID
        case jobId
        case processingJobID
        case processingJobId
        case latestJob
        case job
        case processingJob
        case jobs
        case processingJobs
        case clips
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedJobs = Self.decodeNestedJobs(from: container)
        let directClips = (try? container.decodeIfPresent([Clip].self, forKey: .clips)) ?? []

        self.clips = directClips.isEmpty ? nestedJobs.embeddedClips : directClips
        self.latestJobID = Self.decodeDirectJobID(from: container) ?? nestedJobs.preferredClipJobID
    }

    private static func decodeDirectJobID(from container: KeyedDecodingContainer<CodingKeys>) -> String? {
        [
            CodingKeys.latestJobID,
            .latestJobId,
            .jobID,
            .jobId,
            .processingJobID,
            .processingJobId,
            .latestJob,
            .job,
            .processingJob
        ].compactMap { key in
            if let id = try? container.decodeIfPresent(String.self, forKey: key)?.nilIfEmpty {
                return id
            }

            return try? container.decodeIfPresent(Job.self, forKey: key)?.id.nilIfEmpty
        }
        .first
    }

    private static func decodeNestedJobs(from container: KeyedDecodingContainer<CodingKeys>) -> [Job] {
        var jobs: [Job] = []

        for key in [CodingKeys.latestJob, .job, .processingJob] {
            if let job = try? container.decodeIfPresent(Job.self, forKey: key) {
                jobs.append(job)
            }
        }

        for key in [CodingKeys.jobs, .processingJobs] {
            if let nestedJobs = try? container.decodeIfPresent([Job].self, forKey: key) {
                jobs.append(contentsOf: nestedJobs)
            }
        }

        return jobs
    }
}

private extension Array where Element == Job {
    var preferredClipJobID: String? {
        first(where: { ($0.availableClipsCount ?? 0) > 0 })?.id
            ?? first(where: { $0.status == .completed })?.id
            ?? first?.id
    }

    var embeddedClips: [Clip] {
        first { job in
            guard let clips = job.clips else {
                return false
            }

            return !clips.isEmpty
        }?.clips ?? []
    }
}
