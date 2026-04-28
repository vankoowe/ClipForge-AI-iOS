//
//  RootView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct RootView: View {
    let appContainer: AppContainer

    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .checkingSession:
                LoadingStateView(message: "Checking session")

            case .loggedOut:
                AuthFlowView()

            case .loggedIn:
                DashboardView(
                    videoService: appContainer.videoService,
                    uploadService: appContainer.uploadService,
                    jobService: appContainer.jobService,
                    clipService: appContainer.clipService
                )
            }
        }
        .task {
            await authViewModel.restoreSessionIfNeeded()
        }
    }
}

#Preview {
    let container = AppContainer()

    RootView(appContainer: container)
        .environmentObject(container.authViewModel)
}
