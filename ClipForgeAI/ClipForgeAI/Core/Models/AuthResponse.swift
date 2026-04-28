//
//  AuthResponse.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct AuthResponse: Codable, Equatable {
    let user: User
    let tokens: AuthTokens

    var accessToken: String {
        tokens.accessToken
    }

    var refreshToken: String {
        tokens.refreshToken
    }

    private enum CodingKeys: String, CodingKey {
        case data
        case user
        case tokens
    }

    init(user: User, tokens: AuthTokens) {
        self.user = user
        self.tokens = tokens
    }

    init(from decoder: Decoder) throws {
        if let rootContainer = try? decoder.container(keyedBy: CodingKeys.self),
           rootContainer.contains(.data) {
            let response = try rootContainer.decode(AuthResponse.self, forKey: .data)
            self = response
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.user = try container.decode(User.self, forKey: .user)
        self.tokens = try container.decode(AuthTokens.self, forKey: .tokens)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        try container.encode(tokens, forKey: .tokens)
    }
}
