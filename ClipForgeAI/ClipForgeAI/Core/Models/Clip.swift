//
//  Clip.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct Clip: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let videoID: String
    let title: String
    let startTime: Double
    let endTime: Double
    let downloadURL: URL?
    let createdAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoID = "_id"
        case videoID
        case videoId
        case title
        case startTime
        case endTime
        case downloadURL
        case downloadUrl
        case createdAt
    }

    init(
        id: String,
        videoID: String,
        title: String,
        startTime: Double,
        endTime: Double,
        downloadURL: URL? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.videoID = videoID
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.downloadURL = downloadURL
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let id = try container.decodeFirstPresent(String.self, forKeys: [.id, .mongoID]) else {
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Clip id is required.")
            )
        }

        self.id = id
        self.videoID = try container.decodeFirstPresent(String.self, forKeys: [.videoID, .videoId]) ?? ""
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Generated clip"
        self.startTime = try container.decodeIfPresent(Double.self, forKey: .startTime) ?? 0
        self.endTime = try container.decodeIfPresent(Double.self, forKey: .endTime) ?? 0
        self.downloadURL = try container.decodeFirstPresent(URL.self, forKeys: [.downloadURL, .downloadUrl])
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(videoID, forKey: .videoID)
        try container.encode(title, forKey: .title)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encodeIfPresent(downloadURL, forKey: .downloadURL)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}
