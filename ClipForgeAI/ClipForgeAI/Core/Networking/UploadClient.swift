//
//  UploadClient.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 29.04.26.
//

import Foundation

protocol UploadClientProtocol {
    func upload(fileURL: URL, to uploadURL: URL, contentType: String) async throws
}

final class UploadClient: UploadClientProtocol {
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func upload(fileURL: URL, to uploadURL: URL, contentType: String) async throws {
        var request = URLRequest(url: uploadURL)
        request.httpMethod = HTTPMethod.put.rawValue
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        NetworkLogger.logRawUploadRequest(fileURL: fileURL, uploadURL: uploadURL, contentType: contentType)

        let (_, response) = try await urlSession.upload(for: request, fromFile: fileURL)
        NetworkLogger.logRawUploadResponse(response)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AppError.uploadFailed(statusCode: httpResponse.statusCode)
        }
    }
}
