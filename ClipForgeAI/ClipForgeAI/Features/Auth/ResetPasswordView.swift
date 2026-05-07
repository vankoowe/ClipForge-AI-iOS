//
//  ResetPasswordView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ResetPasswordViewModel

    @State private var token = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @FocusState private var isTokenFocused: Bool
    @FocusState private var isNewPasswordFocused: Bool
    @FocusState private var isConfirmPasswordFocused: Bool

    init(passwordResetService: any PasswordResetServiceProtocol) {
        _viewModel = StateObject(wrappedValue: ResetPasswordViewModel(passwordResetService: passwordResetService))
    }

    var body: some View {
        AuthScreenContainer(
            title: "Set a new key.",
            subtitle: "Finish resetting your password.",
            showsArtwork: false
        ) {
            AuthBackButton {
                dismiss()
            }

            AuthFormCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reset password")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Use your reset token")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    AuthInputField(
                        title: "Reset token",
                        systemImage: "number",
                        text: $token,
                        isFocused: $isTokenFocused
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        isNewPasswordFocused = true
                    }

                    AuthInputField(
                        title: "New password",
                        systemImage: "lock.fill",
                        text: $newPassword,
                        isSecure: true,
                        isFocused: $isNewPasswordFocused
                    )
                    .textContentType(.newPassword)
                    .onSubmit {
                        isConfirmPasswordFocused = true
                    }

                    AuthInputField(
                        title: "Confirm password",
                        systemImage: "lock.rotation",
                        text: $confirmPassword,
                        isSecure: true,
                        isFocused: $isConfirmPasswordFocused
                    )
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .onSubmit {
                        submit()
                    }
                }

                if let successMessage = viewModel.successMessage {
                    SuccessMessageView(message: successMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                AuthSubmitButton(
                    title: "Reset Password",
                    systemImage: "checkmark",
                    isLoading: viewModel.isLoading,
                    action: submit
                )
            }
        }
    }

    private func submit() {
        Task {
            await viewModel.submit(
                token: token,
                newPassword: newPassword,
                confirmPassword: confirmPassword
            )
        }
    }
}

#Preview {
    let container = AppContainer()

    NavigationStack {
        ResetPasswordView(passwordResetService: container.passwordResetService)
    }
}
