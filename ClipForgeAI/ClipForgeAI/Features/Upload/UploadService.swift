//
//  UploadService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation
import UniformTypeIdentifiers

protocol UploadServiceProtocol {
    func uploadVideo(fileURL: URL, title: String) async throws -> Video
}

final class UploadService: UploadServiceProtocol {
    private let apiClient: any APIClientProtocol
    private let urlSession: URLSession

    init(apiClient: any APIClientProtocol, urlSession: URLSession) {
        self.apiClient = apiClient
        self.urlSession = urlSession
    }

    func uploadVideo(fileURL: URL, title: String) async throws -> Video {
        let fileName = fileURL.lastPathComponent
        let contentType = mimeType(for: fileURL)
        let uploadURLResponse = try await requestUploadURL(fileName: fileName, contentType: contentType)

        try await uploadFile(fileURL, to: uploadURLResponse.uploadURL, contentType: contentType)

        return try await createVideoRecord(
            title: title,
            fileName: fileName,
            storageKey: uploadURLResponse.storageKey,
            sourceURL: uploadURLResponse.fileURL
        )
    }

    private func requestUploadURL(fileName: String, contentType: String) async throws -> PresignedUploadResponse {
        let body = UploadURLRequest(fileName: fileName, contentType: contentType)
        let endpoint = APIEndpoint(
            path: "/videos/upload-url",
            method: .post,
            body: try APIEndpoint.jsonBody(body)
        )

        let response = try await apiClient.request(endpoint, as: APIObjectResponse<PresignedUploadResponse>.self)
        return response.value
    }

    private func uploadFile(_ fileURL: URL, to uploadURL: URL, contentType: String) async throws {
        var request = URLRequest(url: uploadURL)
        request.httpMethod = HTTPMethod.put.rawValue
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let didStartSecurityScope = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartSecurityScope {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let (_, response) = try await urlSession.upload(for: request, fromFile: fileURL)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AppError.uploadFailed(statusCode: httpResponse.statusCode)
        }
    }

    private func createVideoRecord(
        title: String,
        fileName: String,
        storageKey: String,
        sourceURL: URL?
    ) async throws -> Video {
        let body = CreateVideoRecordRequest(
            title: title,
            fileName: fileName,
            storageKey: storageKey,
            sourceURL: sourceURL
        )
        let endpoint = APIEndpoint(
            path: "/videos",
            method: .post,
            body: try APIEndpoint.jsonBody(body)
        )

        let response = try await apiClient.request(endpoint, as: APIObjectResponse<Video>.self)
        return response.value
    }

    private func mimeType(for fileURL: URL) -> String {
        guard let type = UTType(filenameExtension: fileURL.pathExtension) else {
            return "video/mp4"
        }

        return type.preferredMIMEType ?? "video/mp4"
    }
}

private struct UploadURLRequest: Encodable {
    let fileName: String
    let contentType: String
}

private struct CreateVideoRecordRequest: Encodable {
    let title: String
    let fileName: String
    let storageKey: String
    let sourceURL: URL?
}

private struct PresignedUploadResponse: Decodable {
    let uploadURL: URL
    let fileURL: URL?
    let storageKey: String

    private enum CodingKeys: String, CodingKey {
        case uploadURL
        case uploadUrl
        case url
        case fileURL
        case fileUrl
        case storageKey
        case key
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let uploadURL = try container.decodeFirstPresent(URL.self, forKeys: [.uploadURL, .uploadUrl, .url]) else {
            throw DecodingError.keyNotFound(
                CodingKeys.uploadURL,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Upload URL is required.")
            )
        }

        self.uploadURL = uploadURL
        self.fileURL = try container.decodeFirstPresent(URL.self, forKeys: [.fileURL, .fileUrl])
        self.storageKey = try container.decodeFirstPresent(String.self, forKeys: [.storageKey, .key])
            ?? uploadURL.lastPathComponent
    }
}
