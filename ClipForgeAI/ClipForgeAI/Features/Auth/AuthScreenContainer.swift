//
//  AuthScreenContainer.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct AuthScreenContainer<Content: View>: View {
    let title: String
    let subtitle: String
    let showsArtwork: Bool
    let content: Content

    init(
        title: String,
        subtitle: String,
        showsArtwork: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsArtwork = showsArtwork
        self.content = content()
    }

    var body: some View {
        ZStack {
            AuthBackgroundView()

            ScrollView {
                VStack(spacing: 22) {
                    AuthBrandHeaderView(title: title, subtitle: subtitle)

                    if showsArtwork {
                        AuthHeroArtworkView()
                    }

                    content
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 28)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
