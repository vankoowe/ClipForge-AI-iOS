//
//  AuthResponse.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct AuthResponse: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let user: User

    private enum CodingKeys: String, CodingKey {
        case data
    }

    private enum PayloadKeys: String, CodingKey {
        case accessToken
        case token
        case jwt
        case refreshToken
        case user
    }

    init(accessToken: String, refreshToken: String? = nil, user: User) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.user = user
    }

    init(from decoder: Decoder) throws {
        if let rootContainer = try? decoder.container(keyedBy: CodingKeys.self),
           rootContainer.contains(.data) {
            let payload = try rootContainer.nestedContainer(keyedBy: PayloadKeys.self, forKey: .data)
            self = try AuthResponse.decode(from: payload, codingPath: decoder.codingPath)
            return
        }

        let payload = try decoder.container(keyedBy: PayloadKeys.self)
        self = try AuthResponse.decode(from: payload, codingPath: decoder.codingPath)
    }

    private static func decode(
        from container: KeyedDecodingContainer<PayloadKeys>,
        codingPath: [CodingKey]
    ) throws -> AuthResponse {
        guard let accessToken = try container.decodeFirstPresent(
            String.self,
            forKeys: [.accessToken, .token, .jwt]
        ) else {
            throw DecodingError.keyNotFound(
                PayloadKeys.accessToken,
                DecodingError.Context(codingPath: codingPath, debugDescription: "Access token is required.")
            )
        }

        let refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        let user = try container.decode(User.self, forKey: .user)

        return AuthResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: user
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PayloadKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try container.encode(user, forKey: .user)
    }
}
