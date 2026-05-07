//
//  AuthFlowView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

enum AuthRoute: Hashable {
    case register
    case forgotPassword
    case resetPassword
}

struct AuthFlowView: View {
    let passwordResetService: any PasswordResetServiceProtocol

    var body: some View {
        NavigationStack {
            LoginView()
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .register:
                        RegisterView()
                    case .forgotPassword:
                        ForgotPasswordView(passwordResetService: passwordResetService)
                    case .resetPassword:
                        ResetPasswordView(passwordResetService: passwordResetService)
                    }
                }
        }
    }
}

#Preview {
    let container = AppContainer()

    AuthFlowView(passwordResetService: container.passwordResetService)
        .environmentObject(container.authViewModel)
}
