//
//  PrimaryButton.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let isLoading: Bool
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                } else if let systemImage {
                    Image(systemName: systemImage)
                }

                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
    }
}

#Preview {
    PrimaryButton(title: "Upload", systemImage: "square.and.arrow.up") {}
        .padding()
}
