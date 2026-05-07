//
//  AuthBackButton.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import SwiftUI

struct AuthBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Back", systemImage: "chevron.left")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.11), in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
