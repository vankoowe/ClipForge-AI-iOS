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

                HStack(spacing: 12) {
                    NavigationLink(value: AuthRoute.register) {
                        Text("Create account")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color(red: 0.47, green: 0.95, blue: 0.88))
                            .frame(maxWidth: .infinity)
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 1, height: 18)

                    NavigationLink(value: AuthRoute.forgotPassword) {
                        Text("Forgot password?")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.76))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 2)
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
