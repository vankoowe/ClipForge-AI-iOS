//
//  PasswordResetService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import Foundation

protocol PasswordResetServiceProtocol {
    func requestPasswordReset(email: String) async throws -> PasswordResetResponse
    func resetPassword(token: String, newPassword: String) async throws -> PasswordResetResponse
}

final class PasswordResetService: PasswordResetServiceProtocol {
    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    func requestPasswordReset(email: String) async throws -> PasswordResetResponse {
        let body = ForgotPasswordRequest(email: email)
        let endpoint = APIEndpoint(
            path: "/auth/forgot-password",
            method: .post,
            body: try APIEndpoint.jsonBody(body),
            requiresAuth: false
        )

        return try await apiClient.request(endpoint, as: PasswordResetResponse.self)
    }

    func resetPassword(token: String, newPassword: String) async throws -> PasswordResetResponse {
        let body = ResetPasswordRequest(token: token, newPassword: newPassword)
        let endpoint = APIEndpoint(
            path: "/auth/reset-password",
            method: .post,
            body: try APIEndpoint.jsonBody(body),
            requiresAuth: false
        )

        return try await apiClient.request(endpoint, as: PasswordResetResponse.self)
    }
}
