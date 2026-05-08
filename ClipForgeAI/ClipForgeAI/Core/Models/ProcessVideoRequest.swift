//
//  ProcessVideoRequest.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 07.05.26.
//

import Foundation

struct ProcessVideoRequest: Encodable {
    let selectedFeatures: [ProcessingFeature]
    let languageHint: String
    let clipSettings: ClipSettingsRequest?
}

struct ClipSettingsRequest: Encodable, Equatable {
    let targetClipCount: Int
    let minDurationSeconds: Int
    let maxDurationSeconds: Int
    let preferredDurationSeconds: Int
    let captionsEnabled: Bool
    let aspectRatio: String?

    static let balanced = ClipSettingsRequest(
        targetClipCount: 2,
        minDurationSeconds: 15,
        maxDurationSeconds: 35,
        preferredDurationSeconds: 25,
        captionsEnabled: true,
        aspectRatio: ClipAspectRatio.vertical.rawValue
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

extension ProcessVideoRequest {
    var loggableJSONString: String {
        guard let data = try? JSONEncoder.apiEncoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return string
    }
}

enum ProcessingLanguageHint: String, Codable, CaseIterable, Identifiable {
    case auto
    case english = "en"
    case bulgarian = "bg"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .auto:
            return "Auto"
        case .english:
            return "English"
        case .bulgarian:
            return "Bulgarian"
        }
    }

    func validate() throws {
        try Self.validate(rawValue)
    }

    static func validate(_ rawValue: String) throws {
        guard rawValue == "auto" || rawValue.range(of: #"^[a-z]{2}$"#, options: .regularExpression) != nil else {
            throw ClipSettingsValidationError("Language must be auto or a 2-letter lowercase code.")
        }
    }
}

enum ClipAspectRatio: String, Codable, CaseIterable, Identifiable {
    case vertical = "9:16"
    case square = "1:1"
    case widescreen = "16:9"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .vertical:
            return "9:16"
        case .square:
            return "1:1"
        case .widescreen:
            return "16:9"
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
