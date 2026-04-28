//
//  LoginView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        AuthScreenContainer(
            title: "Forge clips faster.",
            subtitle: "A focused workspace for video teams."
        ) {
            AuthFormCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome back")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Sign in to continue")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    AuthInputField(
                        title: "Email",
                        systemImage: "envelope.fill",
                        text: $email,
                        isFocused: $isEmailFocused
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        isPasswordFocused = true
                    }

                    AuthInputField(
                        title: "Password",
                        systemImage: "lock.fill",
                        text: $password,
                        isSecure: true,
                        isFocused: $isPasswordFocused
                    )
                    .textContentType(.password)
                    .submitLabel(.go)
                    .onSubmit {
                        signIn()
                    }
                }

                if let errorMessage = authViewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                AuthSubmitButton(
                    title: "Sign In",
                    systemImage: "arrow.right",
                    isLoading: authViewModel.isLoading,
                    action: signIn
                )

                NavigationLink(value: AuthRoute.register) {
                    HStack(spacing: 5) {
                        Text("New to ClipForge AI?")
                            .foregroundStyle(.white.opacity(0.68))

                        Text("Create account")
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.47, green: 0.95, blue: 0.88))
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
                }
                .disabled(authViewModel.isLoading)
            }
        }
    }

    private func signIn() {
        Task {
            await authViewModel.login(email: email, password: password)
        }
    }
}

#Preview {
    let container = AppContainer()

    NavigationStack {
        LoginView()
            .environmentObject(container.authViewModel)
    }
}
