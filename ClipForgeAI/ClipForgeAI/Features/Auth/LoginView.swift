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

    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .textContentType(.password)
            }

            if let errorMessage = authViewModel.errorMessage {
                ErrorMessageView(message: errorMessage)
            }

            Section {
                PrimaryButton(
                    title: "Sign In",
                    systemImage: "person.crop.circle",
                    isLoading: authViewModel.isLoading
                ) {
                    Task {
                        await authViewModel.login(email: email, password: password)
                    }
                }

                NavigationLink("Create account", value: AuthRoute.register)
            }
        }
        .navigationTitle("ClipForge AI")
    }
}

#Preview {
    let container = AppContainer()

    NavigationStack {
        LoginView()
            .environmentObject(container.authViewModel)
    }
}
