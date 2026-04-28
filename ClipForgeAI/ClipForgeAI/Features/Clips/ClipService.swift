//
//  ClipService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

protocol ClipServiceProtocol {
    func fetchClips(jobID: String) async throws -> [Clip]
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

    func generateClips(videoID: String) async throws -> Job {
        let body = ProcessVideoRequest(selectedFeatures: [.clips])
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
}

private struct ProcessVideoRequest: Encodable {
    let selectedFeatures: [ProcessingFeature]
}
