//
//  JobService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

protocol JobServiceProtocol {
    func fetchJob(id: String) async throws -> Job
}

final class JobService: JobServiceProtocol {
    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchJob(id: String) async throws -> Job {
        let endpoint = APIEndpoint(path: "/jobs/\(id)", method: .get)
        let response = try await apiClient.request(endpoint, as: APIObjectResponse<Job>.self)
        return response.value
    }
}
