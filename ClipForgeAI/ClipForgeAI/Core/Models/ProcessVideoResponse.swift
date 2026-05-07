//
//  ProcessVideoResponse.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 29.04.26.
//

import Foundation

struct ProcessVideoResponse: Decodable, Equatable {
    let jobID: String
    let reservedCredits: Int?
    let estimatedBreakdown: EstimatedBreakdown?

    private enum CodingKeys: String, CodingKey {
        case jobID
        case jobId
        case reservedCredits
        case estimatedBreakdown
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let jobID = try container.decodeFirstPresent(String.self, forKeys: [.jobID, .jobId]) else {
            throw DecodingError.keyNotFound(
                CodingKeys.jobId,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Processing job id is required.")
            )
        }

        self.jobID = jobID
        self.reservedCredits = try container.decodeIfPresent(Int.self, forKey: .reservedCredits)
        self.estimatedBreakdown = try container.decodeIfPresent(EstimatedBreakdown.self, forKey: .estimatedBreakdown)
    }
}

struct EstimatedBreakdown: Decodable, Equatable {
    let perFeatureBreakdown: [FeatureCreditBreakdown]?
    let totalCredits: Int?
}

struct FeatureCreditBreakdown: Decodable, Equatable {
    let feature: ProcessingFeature
    let billedMinutes: Int
    let creditsPerMinute: Int
    let credits: Int
}
