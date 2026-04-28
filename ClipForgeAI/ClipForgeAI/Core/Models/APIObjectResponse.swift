//
//  APIObjectResponse.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct APIObjectResponse<Value: Decodable>: Decodable {
    let value: Value

    private enum CodingKeys: String, CodingKey {
        case data
        case item
        case result
        case user
        case video
        case clip
        case job
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let value = try? container.decode(Value.self) {
            self.value = value
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let value = try container.decodeFirstPresent(
            Value.self,
            forKeys: [.data, .item, .result, .user, .video, .clip, .job]
        ) else {
            throw DecodingError.keyNotFound(
                CodingKeys.data,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected object payload in API response."
                )
            )
        }

        self.value = value
    }
}
