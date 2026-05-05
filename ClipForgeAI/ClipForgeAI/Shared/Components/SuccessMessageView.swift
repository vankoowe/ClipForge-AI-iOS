//
//  SuccessMessageView.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import SwiftUI

struct SuccessMessageView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.footnote.weight(.medium))
            .foregroundStyle(Color(red: 0.31, green: 0.91, blue: 0.82))
            .accessibilityLabel(message)
    }
}

#Preview {
    SuccessMessageView(message: "Done.")
        .padding()
}
