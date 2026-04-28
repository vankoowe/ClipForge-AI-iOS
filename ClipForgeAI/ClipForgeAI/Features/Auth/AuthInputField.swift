//
//  AuthInputField.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct AuthInputField: View {
    let title: String
    let systemImage: String
    let text: Binding<String>
    let isSecure: Bool

    @FocusState.Binding var isFocused: Bool

    init(
        title: String,
        systemImage: String,
        text: Binding<String>,
        isSecure: Bool = false,
        isFocused: FocusState<Bool>.Binding
    ) {
        self.title = title
        self.systemImage = systemImage
        self.text = text
        self.isSecure = isSecure
        self._isFocused = isFocused
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isFocused ? Color(red: 0.31, green: 0.91, blue: 0.82) : .white.opacity(0.58))
                .frame(width: 24)

            Group {
                if isSecure {
                    SecureField(title, text: text)
                        .textContentType(.password)
                } else {
                    TextField(title, text: text)
                }
            }
            .focused($isFocused)
            .font(.body.weight(.medium))
            .foregroundStyle(.white)
            .tint(Color(red: 0.31, green: 0.91, blue: 0.82))
            .submitLabel(.next)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(isFocused ? 0.16 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isFocused ? Color(red: 0.31, green: 0.91, blue: 0.82).opacity(0.8) : Color.white.opacity(0.11), lineWidth: 1)
        )
    }
}
