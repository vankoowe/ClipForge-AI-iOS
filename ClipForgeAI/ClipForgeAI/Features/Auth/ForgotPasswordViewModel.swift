//
//  ForgotPasswordViewModel.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import Combine
import Foundation

@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var successMessage: String?
    @Published var errorMessage: String?

    var didSubmit: Bool {
        successMessage != nil
    }

    private let passwordResetService: any PasswordResetServiceProtocol

    init(passwordResetService: any PasswordResetServiceProtocol) {
        self.passwordResetService = passwordResetService
    }

    func submit(email: String) async {
        guard email.trimmed.isValidEmail else {
            errorMessage = "Enter a valid email address."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer {
            isLoading = false
        }

        do {
            let response = try await passwordResetService.requestPasswordReset(email: email.trimmed)
            successMessage = response.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
