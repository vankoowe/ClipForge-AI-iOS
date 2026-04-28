//
//  VideoService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

protocol VideoServiceProtocol {
    func fetchVideos() async throws -> [Video]
}

final class VideoService: VideoServiceProtocol {
    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchVideos() async throws -> [Video] {
        let endpoint = APIEndpoint(path: "/videos", method: .get)
        let response = try await apiClient.request(endpoint, as: APICollectionResponse<Video>.self)
        return response.items
    }
}
