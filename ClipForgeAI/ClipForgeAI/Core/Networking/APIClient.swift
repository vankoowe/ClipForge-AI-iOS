//
//  APIClient.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

@MainActor
protocol APIClientProtocol {
    func request<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response

    func request(_ endpoint: APIEndpoint) async throws
}

final class APIClient: APIClientProtocol {
    private let configuration: APIConfiguration
    private let urlSession: URLSession
    private let authTokenProvider: () -> String?

    init(
        configuration: APIConfiguration,
        urlSession: URLSession = .shared,
        authTokenProvider: @escaping () -> String?
    ) {
        self.configuration = configuration
        self.urlSession = urlSession
        self.authTokenProvider = authTokenProvider
    }

    func request<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        let request = try buildRequest(for: endpoint)

        do {
            let (data, response) = try await urlSession.data(for: request)
            try validate(response: response, data: data)

            if Response.self == EmptyResponse.self, data.isEmpty {
                return EmptyResponse() as! Response
            }

            do {
                return try JSONDecoder.apiDecoder.decode(Response.self, from: data)
            } catch {
                throw AppError.decoding(error)
            }
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.requestFailed(error)
        }
    }

    func request(_ endpoint: APIEndpoint) async throws {
        let _: EmptyResponse = try await request(endpoint, as: EmptyResponse.self)
    }

    private func buildRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        let normalizedPath = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpointURL = configuration.baseURL.appendingPathComponent(normalizedPath)

        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            throw AppError.invalidURL
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url else {
            throw AppError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if endpoint.requiresAuth {
            guard let token = authTokenProvider(), !token.isEmpty else {
                throw AppError.missingToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let apiError = try? JSONDecoder.apiDecoder.decode(APIErrorResponse.self, from: data)

            switch httpResponse.statusCode {
            case 401:
                throw AppError.unauthorized
            case 403:
                throw AppError.forbidden
            case 404:
                throw AppError.notFound
            default:
                throw AppError.server(
                    statusCode: httpResponse.statusCode,
                    message: apiError?.message
                )
            }
        }
    }
}

struct EmptyResponse: Decodable {}

private struct APIErrorResponse: Decodable {
    let message: String?
}
