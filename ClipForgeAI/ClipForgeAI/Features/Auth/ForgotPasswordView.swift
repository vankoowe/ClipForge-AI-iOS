//
//  ForgotPasswordView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ForgotPasswordViewModel

    @State private var email = ""
    @FocusState private var isEmailFocused: Bool

    init(passwordResetService: any PasswordResetServiceProtocol) {
        _viewModel = StateObject(wrappedValue: ForgotPasswordViewModel(passwordResetService: passwordResetService))
    }

    var body: some View {
        AuthScreenContainer(
            title: "Recover access.",
            subtitle: "Reset your ClipForge AI password.",
            showsArtwork: false
        ) {
            AuthBackButton {
                dismiss()
            }

            AuthFormCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Forgot password")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Request reset email")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.didSubmit, let successMessage = viewModel.successMessage {
                    SuccessMessageView(message: successMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
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
                    .submitLabel(.send)
                    .onSubmit {
                        submit()
                    }

                    if let errorMessage = viewModel.errorMessage {
                        ErrorMessageView(message: errorMessage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    AuthSubmitButton(
                        title: "Send Reset Link",
                        systemImage: "paperplane.fill",
                        isLoading: viewModel.isLoading,
                        action: submit
                    )
                }

                NavigationLink(value: AuthRoute.resetPassword) {
                    Text("Enter reset token")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color(red: 0.47, green: 0.95, blue: 0.88))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    private func submit() {
        Task {
            await viewModel.submit(email: email)
        }
    }
}

#Preview {
    let container = AppContainer()

    NavigationStack {
        ForgotPasswordView(passwordResetService: container.passwordResetService)
    }
}
