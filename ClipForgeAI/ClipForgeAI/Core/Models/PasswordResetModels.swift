//
//  PasswordResetModels.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import Foundation

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct ResetPasswordRequest: Encodable {
    let token: String
    let newPassword: String
}

struct PasswordResetResponse: Decodable, Equatable {
    let message: String

    private enum CodingKeys: String, CodingKey {
        case data
        case message
    }

    init(message: String) {
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let response = try container.decodeIfPresent(PasswordResetResponse.self, forKey: .data) {
            self = response
            return
        }

        self.message = try container.decode(String.self, forKey: .message)
    }
}
