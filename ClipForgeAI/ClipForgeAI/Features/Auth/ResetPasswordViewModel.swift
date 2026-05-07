//
//  ResetPasswordViewModel.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import Combine
import Foundation

@MainActor
final class ResetPasswordViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var successMessage: String?
    @Published var errorMessage: String?

    private let passwordResetService: any PasswordResetServiceProtocol

    init(passwordResetService: any PasswordResetServiceProtocol) {
        self.passwordResetService = passwordResetService
    }

    func submit(token: String, newPassword: String, confirmPassword: String) async {
        guard !token.trimmed.isEmpty else {
            errorMessage = "Enter the reset token."
            return
        }

        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer {
            isLoading = false
        }

        do {
            let response = try await passwordResetService.resetPassword(
                token: token.trimmed,
                newPassword: newPassword
            )
            successMessage = response.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
