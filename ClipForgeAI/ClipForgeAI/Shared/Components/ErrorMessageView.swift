//
//  ErrorMessageView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct ErrorMessageView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.footnote)
            .foregroundStyle(.red)
            .accessibilityLabel(message)
    }
}

#Preview {
    ErrorMessageView(message: "Something went wrong.")
        .padding()
}
