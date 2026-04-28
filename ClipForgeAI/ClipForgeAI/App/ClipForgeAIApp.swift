//
//  ClipForgeAIApp.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

@main
struct ClipForgeAIApp: App {
    @StateObject private var appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(appContainer: appContainer)
                .environmentObject(appContainer.authViewModel)
        }
    }
}
