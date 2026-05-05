//
//  RegisterView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        AuthScreenContainer(
            title: "Start sharper.",
            subtitle: "Create your ClipForge AI account.",
            showsArtwork: false
        ) {
            Button {
                dismiss()
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.11), in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            AuthFormCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create account")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Set up your workspace")
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
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .onSubmit {
                        createAccount()
                    }
                }

                if let errorMessage = authViewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                AuthSubmitButton(
                    title: "Create Account",
                    systemImage: "sparkles",
                    isLoading: authViewModel.isLoading,
                    action: createAccount
                )
            }
        }
    }

    private func createAccount() {
        Task {
            await authViewModel.register(email: email, password: password)
        }
    }
}

#Preview {
    let container = AppContainer()

    NavigationStack {
        RegisterView()
            .environmentObject(container.authViewModel)
    }
}
