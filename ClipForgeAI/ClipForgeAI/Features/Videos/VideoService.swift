//
//  VideoService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

protocol VideoServiceProtocol {
    func fetchVideos() async throws -> [Video]
    func fetchVideo(id: String) async throws -> Video
    func deleteVideo(id: String) async throws
}

final class VideoService: VideoServiceProtocol {
    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchVideos() async throws -> [Video] {
        let endpoint = APIEndpoint(
            path: "/videos",
            method: .get,
            queryItems: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "pageSize", value: "20")
            ]
        )
        let response = try await apiClient.request(endpoint, as: APICollectionResponse<Video>.self)
        return response.items
    }

    func fetchVideo(id: String) async throws -> Video {
        let endpoint = APIEndpoint(path: "/videos/\(id)", method: .get)
        let response = try await apiClient.request(endpoint, as: APIObjectResponse<Video>.self)
        return response.value
    }

    func deleteVideo(id: String) async throws {
        let endpoint = APIEndpoint(path: "/videos/\(id)", method: .delete)
        try await apiClient.request(endpoint)
    }
}
