//
//  ProcessingFeature.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 29.04.26.
//

import Foundation

enum ProcessingFeature: String, Codable, CaseIterable {
    case transcription
    case subtitles
    case clips
    case rendering

    var displayName: String {
        switch self {
        case .transcription:
            return "Transcription"
        case .subtitles:
            return "Subtitles"
        case .clips:
            return "Clips"
        case .rendering:
            return "Rendering"
        }
    }

    var description: String {
        switch self {
        case .transcription:
            return "Extract speech for AI analysis."
        case .subtitles:
            return "Generate captions for the edit."
        case .clips:
            return "Find highlight moments."
        case .rendering:
            return "Export final video files."
        }
    }

    var systemImage: String {
        switch self {
        case .transcription:
            return "waveform"
        case .subtitles:
            return "captions.bubble"
        case .clips:
            return "scissors"
        case .rendering:
            return "film.stack"
        }
    }
}
