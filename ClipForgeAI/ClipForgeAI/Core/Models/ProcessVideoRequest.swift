//
//  ProcessVideoRequest.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 07.05.26.
//

import Foundation

struct ProcessVideoRequest: Encodable {
    let selectedFeatures: [ProcessingFeature]
    let clipSettings: ClipSettingsRequest?
}

struct ClipSettingsRequest: Encodable, Equatable {
    let targetClipCount: Int
    let minDurationSeconds: Int
    let maxDurationSeconds: Int
    let preferredDurationSeconds: Int

    static let balanced = ClipSettingsRequest(
        targetClipCount: 3,
        minDurationSeconds: 15,
        maxDurationSeconds: 45,
        preferredDurationSeconds: 30
    )

    func validate() throws {
        guard (1...20).contains(targetClipCount) else {
            throw ClipSettingsValidationError("Target clip count must be between 1 and 20.")
        }

        guard (5...120).contains(minDurationSeconds) else {
            throw ClipSettingsValidationError("Minimum duration must be between 5 and 120 seconds.")
        }

        guard (5...120).contains(maxDurationSeconds) else {
            throw ClipSettingsValidationError("Maximum duration must be between 5 and 120 seconds.")
        }

        guard minDurationSeconds <= maxDurationSeconds else {
            throw ClipSettingsValidationError("Minimum duration must be less than or equal to maximum duration.")
        }

        guard (minDurationSeconds...maxDurationSeconds).contains(preferredDurationSeconds) else {
            throw ClipSettingsValidationError("Preferred duration must be between minimum and maximum duration.")
        }
    }
}

struct ClipSettingsValidationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

