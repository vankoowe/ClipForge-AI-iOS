//
//  AuthFlowView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

enum AuthRoute: Hashable {
    case register
}

struct AuthFlowView: View {
    var body: some View {
        NavigationStack {
            LoginView()
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .register:
                        RegisterView()
                    }
                }
        }
    }
}

#Preview {
    let container = AppContainer()

    AuthFlowView()
        .environmentObject(container.authViewModel)
}
