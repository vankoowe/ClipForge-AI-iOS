//
//  ClipService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

protocol ClipServiceProtocol {
    func fetchClips(videoID: String) async throws -> [Clip]
    func generateClips(videoID: String) async throws -> Job
}

final class ClipService: ClipServiceProtocol {
    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchClips(videoID: String) async throws -> [Clip] {
        let endpoint = APIEndpoint(path: "/videos/\(videoID)/clips", method: .get)
        let response = try await apiClient.request(endpoint, as: APICollectionResponse<Clip>.self)
        return response.items
    }

    func generateClips(videoID: String) async throws -> Job {
        let endpoint = APIEndpoint(path: "/videos/\(videoID)/clips", method: .post)
        let response = try await apiClient.request(endpoint, as: APIObjectResponse<Job>.self)
        return response.value
    }
}
