//
//  AuthTokens.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 29.04.26.
//

import Foundation

struct AuthTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let accessTokenExpiresInSeconds: Int?
    let refreshTokenExpiresInSeconds: Int?
}

struct TokenRefreshResponse: Decodable {
    let tokens: AuthTokens

    private enum CodingKeys: String, CodingKey {
        case data
        case tokens
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            if let dataResponse = try container.decodeIfPresent(TokenRefreshResponse.self, forKey: .data) {
                self = dataResponse
                return
            }

            if let tokens = try container.decodeIfPresent(AuthTokens.self, forKey: .tokens) {
                self.tokens = tokens
                return
            }
        }

        self.tokens = try AuthTokens(from: decoder)
    }
}
