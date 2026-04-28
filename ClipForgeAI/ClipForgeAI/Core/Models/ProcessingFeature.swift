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
}
