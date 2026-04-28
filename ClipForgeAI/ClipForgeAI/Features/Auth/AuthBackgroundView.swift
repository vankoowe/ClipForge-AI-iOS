//
//  AuthBackgroundView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct AuthBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.09),
                    Color(red: 0.03, green: 0.13, blue: 0.16),
                    Color(red: 0.12, green: 0.08, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            TimelinePattern()
                .opacity(0.22)
                .blendMode(.screen)

            LinearGradient(
                colors: [
                    .clear,
                    Color(red: 0.01, green: 0.02, blue: 0.03).opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private struct TimelinePattern: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            VStack(spacing: 18) {
                ForEach(0..<10, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(index.isMultiple(of: 2) ? Color.cyan : Color.orange)
                        .frame(width: width * CGFloat(0.32 + Double(index % 3) * 0.12), height: 5)
                        .frame(maxWidth: .infinity, alignment: index.isMultiple(of: 2) ? .leading : .trailing)
                        .offset(x: index.isMultiple(of: 2) ? -24 : 24)
                }
            }
            .rotationEffect(.degrees(-14))
            .offset(y: geometry.size.height * 0.1)
        }
    }
}

#Preview {
    AuthBackgroundView()
}
