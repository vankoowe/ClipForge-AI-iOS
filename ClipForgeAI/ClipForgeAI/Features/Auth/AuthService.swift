//
//  AuthService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthResponse
    func register(email: String, password: String) async throws -> AuthResponse
    func restoreSession() async throws -> User?
    func logout() throws
}

final class AuthService: AuthServiceProtocol {
    private let apiClient: any APIClientProtocol
    private let tokenStore: any AuthStore

    init(apiClient: any APIClientProtocol, tokenStore: any AuthStore) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password)
        let endpoint = APIEndpoint(
            path: "/auth/login",
            method: .post,
            body: try APIEndpoint.jsonBody(body),
            requiresAuth: false
        )

        let response = try await apiClient.request(endpoint, as: AuthResponse.self)
        try tokenStore.saveTokens(response.tokens)
        return response
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        let body = RegisterRequest(email: email, password: password)
        let endpoint = APIEndpoint(
            path: "/auth/register",
            method: .post,
            body: try APIEndpoint.jsonBody(body),
            requiresAuth: false
        )

        let response = try await apiClient.request(endpoint, as: AuthResponse.self)
        try tokenStore.saveTokens(response.tokens)
        return response
    }

    func restoreSession() async throws -> User? {
        guard tokenStore.readTokens() != nil else {
            return nil
        }

        let endpoint = APIEndpoint(path: "/users/me", method: .get)
        let response = try await apiClient.request(endpoint, as: APIObjectResponse<User>.self)
        return response.value
    }

    func logout() throws {
        try tokenStore.deleteTokens()
    }
}

private struct LoginRequest: Encodable {
    let email: String
    let password: String
}

private struct RegisterRequest: Encodable {
    let email: String
    let password: String
}
