//
//  AuthService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthResponse
    func register(name: String, email: String, password: String) async throws -> AuthResponse
    func restoreSession() async throws -> User?
    func logout() throws
}

final class AuthService: AuthServiceProtocol {
    private let apiClient: any APIClientProtocol
    private let tokenStore: any TokenStore

    init(apiClient: any APIClientProtocol, tokenStore: any TokenStore) {
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
        try tokenStore.saveToken(response.accessToken)
        return response
    }

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        let body = RegisterRequest(name: name, email: email, password: password)
        let endpoint = APIEndpoint(
            path: "/auth/register",
            method: .post,
            body: try APIEndpoint.jsonBody(body),
            requiresAuth: false
        )

        let response = try await apiClient.request(endpoint, as: AuthResponse.self)
        try tokenStore.saveToken(response.accessToken)
        return response
    }

    func restoreSession() async throws -> User? {
        guard tokenStore.readToken() != nil else {
            return nil
        }

        let endpoint = APIEndpoint(path: "/auth/me", method: .get)
        let response = try await apiClient.request(endpoint, as: APIObjectResponse<User>.self)
        return response.value
    }

    func logout() throws {
        try tokenStore.deleteToken()
    }
}

private struct LoginRequest: Encodable {
    let email: String
    let password: String
}

private struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
}
