//
//  Job.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct Job: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let videoID: String?
    let type: String?
    let status: JobStatus
    let progress: Double
    let message: String?
    let errorMessage: String?
    let isTerminal: Bool
    let clipsCount: Int?
    let clips: [Clip]?
    let createdAt: Date?
    let updatedAt: Date?
    let completedAt: Date?

    var normalizedProgress: Double {
        let rawValue = progress > 1 ? progress / 100 : progress
        return min(max(rawValue, 0), 1)
    }

    var progressPercentage: Int {
        Int((normalizedProgress * 100).rounded())
    }

    var displayStatus: JobStatus {
        if hasProcessingError, !status.isTerminal {
            return .failed
        }

        return status
    }

    var displayMessage: String? {
        errorMessage ?? message
    }

    var shouldStopPolling: Bool {
        isTerminal || hasProcessingError
    }

    private var hasProcessingError: Bool {
        errorMessage?.nilIfEmpty != nil
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoID = "_id"
        case videoID
        case videoId
        case type
        case status
        case progress
        case progressPercent
        case message
        case errorMessage
        case isTerminal
        case clipsCount
        case clips
        case createdAt
        case updatedAt
        case completedAt
    }

    init(
        id: String,
        videoID: String? = nil,
        type: String? = nil,
        status: JobStatus = .unknown,
        progress: Double = 0,
        message: String? = nil,
        errorMessage: String? = nil,
        isTerminal: Bool? = nil,
        clipsCount: Int? = nil,
        clips: [Clip]? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.videoID = videoID
        self.type = type
        self.status = status
        self.progress = progress
        self.message = message
        self.errorMessage = errorMessage
        self.isTerminal = isTerminal ?? status.isTerminal
        self.clipsCount = clipsCount
        self.clips = clips
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let id = try container.decodeFirstPresent(String.self, forKeys: [.id, .mongoID]) else {
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Job id is required.")
            )
        }

        self.id = id
        self.videoID = try container.decodeFirstPresent(String.self, forKeys: [.videoID, .videoId])
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        let decodedStatus = try container.decodeIfPresent(JobStatus.self, forKey: .status) ?? .unknown
        self.status = decodedStatus
        self.progress = try container.decodeFirstPresent(Double.self, forKeys: [.progressPercent, .progress]) ?? 0
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        self.isTerminal = try container.decodeIfPresent(Bool.self, forKey: .isTerminal) ?? decodedStatus.isTerminal
        self.clipsCount = try container.decodeIfPresent(Int.self, forKey: .clipsCount)
        self.clips = try container.decodeIfPresent([Clip].self, forKey: .clips)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        self.completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(videoID, forKey: .videoID)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encode(progress, forKey: .progress)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encode(isTerminal, forKey: .isTerminal)
        try container.encodeIfPresent(clipsCount, forKey: .clipsCount)
        try container.encodeIfPresent(clips, forKey: .clips)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
    }
}

enum JobStatus: String, Codable, CaseIterable {
    case pending
    case queued
    case processing
    case completed
    case failed
    case cancelled
    case unknown

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .queued:
            return "Queued"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        case .unknown:
            return "Unknown"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .pending, .queued, .processing, .unknown:
            return false
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()
        self = JobStatus(rawValue: value) ?? .unknown
    }
}
