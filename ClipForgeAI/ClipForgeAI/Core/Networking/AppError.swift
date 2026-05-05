//
//  AppError.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

enum AppError: LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case unauthorized(message: String?)
    case forbidden
    case notFound
    case server(statusCode: Int, message: String?)
    case decoding(Error)
    case encoding(Error)
    case keychain(OSStatus)
    case missingToken
    case missingFile
    case uploadFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The server URL is invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .requestFailed(let error):
            return error.localizedDescription
        case .unauthorized(let message):
            return message ?? "Your session has expired. Please sign in again."
        case .forbidden:
            return "You do not have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .server(let statusCode, let message):
            return message ?? "The server returned an error. Status code: \(statusCode)."
        case .decoding:
            return "The app could not read the server response."
        case .encoding:
            return "The app could not prepare the request."
        case .keychain:
            return "The app could not access secure storage."
        case .missingToken:
            return "No active session was found."
        case .missingFile:
            return "Choose a video file before uploading."
        case .uploadFailed(let statusCode):
            return "The upload failed. Status code: \(statusCode)."
        }
    }
}
