//
//  BackendAPIErrorResponse.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import Foundation

struct BackendAPIErrorResponse: Decodable {
    let success: Bool?
    let error: BackendAPIError?
    let message: String?
    let timestamp: String?
    let path: String?

    var resolvedMessage: String? {
        guard let baseMessage = error?.message ?? message else {
            return error?.details?.joined(separator: "; ")
        }

        guard let details = error?.details, !details.isEmpty else {
            return baseMessage
        }

        return "\(baseMessage): \(details.joined(separator: "; "))"
    }

    static func decode(from data: Data) -> BackendAPIErrorResponse? {
        guard !data.isEmpty else {
            return nil
        }

        return try? JSONDecoder.apiDecoder.decode(BackendAPIErrorResponse.self, from: data)
    }
}

struct BackendAPIError: Decodable {
    let statusCode: Int?
    let message: String?
    let details: [String]?
}
