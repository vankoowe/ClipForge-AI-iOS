//
//  APICollectionResponse.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct APICollectionResponse<Item: Decodable>: Decodable {
    let items: [Item]

    private enum CodingKeys: String, CodingKey {
        case data
        case items
        case results
        case videos
        case clips
        case jobs
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let items = try? container.decode([Item].self) {
            self.items = items
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.items = try container.decodeFirstPresent(
            [Item].self,
            forKeys: [.data, .items, .results, .videos, .clips, .jobs]
        ) ?? []
    }
}
