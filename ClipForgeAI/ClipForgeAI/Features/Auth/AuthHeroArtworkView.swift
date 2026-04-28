//
//  AuthHeroArtworkView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct AuthHeroArtworkView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.28), radius: 32, y: 18)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.93, green: 0.35, blue: 0.49))
                        Circle()
                            .fill(Color(red: 0.98, green: 0.72, blue: 0.24))
                        Circle()
                            .fill(Color(red: 0.25, green: 0.86, blue: 0.68))
                    }
                    .frame(width: 52, height: 10)

                    Spacer()

                    Label("Live render", systemImage: "bolt.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(red: 0.47, green: 0.95, blue: 0.88))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1), in: Capsule())
                }

                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.16, green: 0.20, blue: 0.26),
                                    Color(red: 0.06, green: 0.09, blue: 0.13)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 88)

                    HStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(thumbnailGradient(index: index))
                                .overlay(alignment: .bottomLeading) {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(.white.opacity(0.55))
                                        .frame(width: CGFloat(22 + index * 7), height: 4)
                                        .padding(10)
                                }
                        }
                    }
                    .padding(.horizontal, 18)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 46, height: 46)
                        .shadow(color: Color.black.opacity(0.24), radius: 12, y: 6)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color(red: 0.04, green: 0.13, blue: 0.16))
                                .offset(x: 2)
                        }
                }

                VStack(spacing: 8) {
                    timelineRow(color: Color(red: 0.20, green: 0.82, blue: 0.74), width: 0.82)
                    timelineRow(color: Color(red: 0.93, green: 0.35, blue: 0.49), width: 0.58)
                    timelineRow(color: Color(red: 0.98, green: 0.72, blue: 0.24), width: 0.72)
                }

                HStack {
                    Label("8 clips", systemImage: "scissors")
                    Spacer()
                    Label("92%", systemImage: "chart.line.uptrend.xyaxis")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.76))
            }
            .padding(16)
        }
        .frame(height: 242)
    }

    private func thumbnailGradient(index: Int) -> LinearGradient {
        let palettes: [[Color]] = [
            [Color(red: 0.12, green: 0.60, blue: 0.77), Color(red: 0.11, green: 0.18, blue: 0.30)],
            [Color(red: 0.90, green: 0.31, blue: 0.43), Color(red: 0.20, green: 0.10, blue: 0.18)],
            [Color(red: 0.98, green: 0.66, blue: 0.20), Color(red: 0.18, green: 0.13, blue: 0.08)],
            [Color(red: 0.28, green: 0.80, blue: 0.60), Color(red: 0.08, green: 0.18, blue: 0.15)]
        ]

        return LinearGradient(
            colors: palettes[index % palettes.count],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func timelineRow(color: Color, width: CGFloat) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.09))

                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * width)
            }
        }
        .frame(height: 7)
    }
}

#Preview {
    ZStack {
        AuthBackgroundView()
        AuthHeroArtworkView()
            .padding()
    }
}
