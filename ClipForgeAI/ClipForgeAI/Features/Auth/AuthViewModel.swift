//
//  AuthViewModel.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var authState: AuthState = .checkingSession
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let authService: any AuthServiceProtocol
    private var didAttemptSessionRestore = false

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    func restoreSessionIfNeeded() async {
        guard !didAttemptSessionRestore else {
            return
        }

        didAttemptSessionRestore = true

        do {
            if let user = try await authService.restoreSession() {
                authState = .loggedIn(user)
            } else {
                authState = .loggedOut
            }
        } catch {
            authState = .loggedOut
            errorMessage = nil
        }
    }

    func login(email: String, password: String) async {
        guard validate(email: email, password: password) else {
            return
        }

        await performAuthAction {
            try await authService.login(email: email.trimmed, password: password)
        }
    }

    func register(email: String, password: String) async {
        guard validate(email: email, password: password) else {
            return
        }

        await performAuthAction {
            try await authService.register(email: email.trimmed, password: password)
        }
    }

    func logout() {
        do {
            try authService.logout()
        } catch {
            errorMessage = error.localizedDescription
        }

        authState = .loggedOut
    }

    private func validate(email: String, password: String) -> Bool {
        guard email.trimmed.isValidEmail else {
            errorMessage = "Enter a valid email address."
            return false
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return false
        }

        return true
    }

    private func performAuthAction(_ action: () async throws -> AuthResponse) async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let response = try await action()
            authState = .loggedIn(response.user)
        } catch {
            authState = .loggedOut
            errorMessage = error.localizedDescription
        }
    }
}
