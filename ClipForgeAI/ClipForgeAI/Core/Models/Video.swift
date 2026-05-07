//
//  Video.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct Video: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let fileName: String?
    let status: VideoStatus
    let durationSeconds: Double?
    let thumbnailURL: URL?
    let sourceURL: URL?
    let latestJobID: String?
    let createdAt: Date?
    let updatedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoID = "_id"
        case title
        case fileName
        case status
        case durationSeconds
        case duration
        case thumbnailURL
        case thumbnailUrl
        case sourceURL
        case sourceUrl
        case originalFileURL
        case originalFileUrl
        case publicFileURL
        case publicFileUrl
        case latestJobID
        case latestJobId
        case jobID
        case jobId
        case createdAt
        case updatedAt
    }

    init(
        id: String,
        title: String,
        fileName: String? = nil,
        status: VideoStatus = .unknown,
        durationSeconds: Double? = nil,
        thumbnailURL: URL? = nil,
        sourceURL: URL? = nil,
        latestJobID: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.status = status
        self.durationSeconds = durationSeconds
        self.thumbnailURL = thumbnailURL
        self.sourceURL = sourceURL
        self.latestJobID = latestJobID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let id = try container.decodeFirstPresent(String.self, forKeys: [.id, .mongoID]) else {
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Video id is required.")
            )
        }

        self.id = id
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Untitled video"
        self.fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        self.status = try container.decodeIfPresent(VideoStatus.self, forKey: .status) ?? .unknown
        self.durationSeconds = try container.decodeFirstPresent(Double.self, forKeys: [.durationSeconds, .duration])
        self.thumbnailURL = try container.decodeFirstPresent(URL.self, forKeys: [.thumbnailURL, .thumbnailUrl])
        self.sourceURL = try container.decodeFirstPresent(
            URL.self,
            forKeys: [.sourceURL, .sourceUrl, .originalFileURL, .originalFileUrl, .publicFileURL, .publicFileUrl]
        )
        self.latestJobID = try container.decodeFirstPresent(
            String.self,
            forKeys: [.latestJobID, .latestJobId, .jobID, .jobId]
        )
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(fileName, forKey: .fileName)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(durationSeconds, forKey: .durationSeconds)
        try container.encodeIfPresent(thumbnailURL, forKey: .thumbnailURL)
        try container.encodeIfPresent(sourceURL, forKey: .sourceURL)
        try container.encodeIfPresent(latestJobID, forKey: .latestJobID)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    func with(latestJobID: String?, status: VideoStatus? = nil) -> Video {
        Video(
            id: id,
            title: title,
            fileName: fileName,
            status: status ?? self.status,
            durationSeconds: durationSeconds,
            thumbnailURL: thumbnailURL,
            sourceURL: sourceURL,
            latestJobID: latestJobID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

enum VideoStatus: String, Codable, CaseIterable {
    case uploading
    case uploaded
    case queued
    case processing
    case processed
    case completed
    case ready
    case failed
    case unknown

    var displayName: String {
        switch self {
        case .uploading:
            return "Uploading"
        case .uploaded:
            return "Uploaded"
        case .queued:
            return "Queued"
        case .processing:
            return "Processing"
        case .processed:
            return "Processed"
        case .completed:
            return "Completed"
        case .ready:
            return "Ready"
        case .failed:
            return "Failed"
        case .unknown:
            return "Unknown"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()
        self = VideoStatus(rawValue: value) ?? .unknown
    }
}
