//
//  AuthSubmitButton.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct AuthSubmitButton: View {
    let title: String
    let systemImage: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .bold))
                }

                Text(title)
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.76, blue: 0.70),
                        Color(red: 0.89, green: 0.31, blue: 0.48)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: Color(red: 0.11, green: 0.78, blue: 0.72).opacity(0.27), radius: 18, y: 12)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.75 : 1)
    }
}
