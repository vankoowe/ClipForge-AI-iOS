//
//  User.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct User: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let email: String
    let name: String?
    let role: String?
    let createdAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoID = "_id"
        case email
        case name
        case role
        case createdAt
    }

    init(
        id: String,
        email: String,
        name: String? = nil,
        role: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let id = try container.decodeFirstPresent(String.self, forKeys: [.id, .mongoID]) else {
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "User id is required.")
            )
        }

        self.id = id
        self.email = try container.decode(String.self, forKey: .email)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.role = try container.decodeIfPresent(String.self, forKey: .role)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}
