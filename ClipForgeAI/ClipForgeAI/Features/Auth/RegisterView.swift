//
//  RegisterView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .textContentType(.name)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
            }

            if let errorMessage = authViewModel.errorMessage {
                ErrorMessageView(message: errorMessage)
            }

            Section {
                PrimaryButton(
                    title: "Create Account",
                    systemImage: "person.badge.plus",
                    isLoading: authViewModel.isLoading
                ) {
                    Task {
                        await authViewModel.register(name: name, email: email, password: password)
                    }
                }
            }
        }
        .navigationTitle("Register")
    }
}

#Preview {
    let container = AppContainer()

    NavigationStack {
        RegisterView()
            .environmentObject(container.authViewModel)
    }
}
