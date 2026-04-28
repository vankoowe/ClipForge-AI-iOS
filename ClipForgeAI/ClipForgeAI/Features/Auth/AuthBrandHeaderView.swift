//
//  AuthBrandHeaderView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct AuthBrandHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.18, green: 0.85, blue: 0.78),
                                    Color(red: 0.93, green: 0.35, blue: 0.49)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "play.rectangle.on.rectangle.fill")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)
                .shadow(color: Color.cyan.opacity(0.28), radius: 18, y: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ClipForge")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("AI")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 0.47, green: 0.95, blue: 0.88))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)

                Text(subtitle)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        AuthBackgroundView()
        AuthBrandHeaderView(
            title: "Forge clips faster.",
            subtitle: "A focused workspace for video teams."
        )
        .padding()
    }
}
