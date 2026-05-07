//
//  UploadService.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import AVFoundation
import Foundation
import UniformTypeIdentifiers

protocol UploadServiceProtocol {
    func uploadVideo(fileURL: URL, title: String) async throws -> Video
}

final class UploadService: UploadServiceProtocol {
    private let apiClient: any APIClientProtocol
    private let uploadClient: any UploadClientProtocol

    init(apiClient: any APIClientProtocol, uploadClient: any UploadClientProtocol) {
        self.apiClient = apiClient
        self.uploadClient = uploadClient
    }

    func uploadVideo(fileURL: URL, title: String) async throws -> Video {
        let didStartSecurityScope = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartSecurityScope {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileName = fileURL.lastPathComponent
        let contentType = mimeType(for: fileURL)
        let fileSizeBytes = try fileSizeBytes(for: fileURL)
        let durationSeconds = try await durationSeconds(for: fileURL)
        NetworkLogger.logUploadStage(
            "started file=\"\(fileName)\" contentType=\"\(contentType)\" fileSizeBytes=\(fileSizeBytes) durationSeconds=\(durationSeconds)"
        )

        let uploadURLResponse = try await requestUploadURL(
            fileName: fileName,
            contentType: contentType,
            fileSizeBytes: fileSizeBytes
        )
        NetworkLogger.logUploadStage("presigned URL received file=\"\(fileName)\"")

        try await uploadClient.upload(
            fileURL: fileURL,
            to: uploadURLResponse.uploadURL,
            contentType: contentType
        )
        NetworkLogger.logUploadStage("raw upload completed file=\"\(fileName)\"")

        let video = try await createVideoRecord(
            fileKey: uploadURLResponse.fileKey,
            originalFileURL: uploadURLResponse.publicFileURL,
            fileName: fileName,
            durationSeconds: durationSeconds,
            fileSizeBytes: fileSizeBytes
        )
        NetworkLogger.logUploadStage("video record created id=\"\(video.id)\" file=\"\(fileName)\"")

        let processResponse = try await processVideo(videoID: video.id)
        NetworkLogger.logUploadStage("processing job created jobId=\"\(processResponse.jobID)\" videoId=\"\(video.id)\"")
        return video.with(latestJobID: processResponse.jobID, status: .processing)
    }

    private func requestUploadURL(
        fileName: String,
        contentType: String,
        fileSizeBytes: Int64
    ) async throws -> PresignedUploadResponse {
        let body = UploadURLRequest(
            fileName: fileName,
            contentType: contentType,
            fileSizeBytes: fileSizeBytes
        )
        let endpoint = APIEndpoint(
            path: "/videos/upload-url",
            method: .post,
            body: try APIEndpoint.jsonBody(body)
        )

        let response = try await apiClient.request(endpoint, as: APIObjectResponse<PresignedUploadResponse>.self)
        return response.value
    }

    private func createVideoRecord(
        fileKey: String,
        originalFileURL: URL,
        fileName: String,
        durationSeconds: Int,
        fileSizeBytes: Int64
    ) async throws -> Video {
        let body = CreateVideoRecordRequest(
            fileKey: fileKey,
            originalFileUrl: originalFileURL,
            fileName: fileName,
            durationSeconds: durationSeconds,
            fileSizeBytes: fileSizeBytes
        )
        let endpoint = APIEndpoint(
            path: "/videos",
            method: .post,
            body: try APIEndpoint.jsonBody(body)
        )

        let response = try await apiClient.request(endpoint, as: APIObjectResponse<Video>.self)
        return response.value
    }

    private func processVideo(videoID: String) async throws -> ProcessVideoResponse {
        let body = ProcessVideoRequest(selectedFeatures: ProcessingFeature.allCases)
        let endpoint = APIEndpoint(
            path: "/videos/\(videoID)/process",
            method: .post,
            body: try APIEndpoint.jsonBody(body)
        )

        let response = try await apiClient.request(endpoint, as: APIObjectResponse<ProcessVideoResponse>.self)
        return response.value
    }

    private func fileSizeBytes(for fileURL: URL) throws -> Int64 {
        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])

        if let fileSize = values.fileSize {
            return Int64(fileSize)
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        return (attributes[.size] as? NSNumber)?.int64Value ?? 0
    }

    private func durationSeconds(for fileURL: URL) async throws -> Int {
        let asset = AVURLAsset(url: fileURL)
        let duration = try await asset.load(.duration)
        let seconds = CMTimeGetSeconds(duration)

        guard seconds.isFinite else {
            return 0
        }

        return max(Int(ceil(seconds)), 0)
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
    let fileSizeBytes: Int64
}

private struct CreateVideoRecordRequest: Encodable {
    let fileKey: String
    let originalFileUrl: URL
    let fileName: String
    let durationSeconds: Int
    let fileSizeBytes: Int64
}

private struct ProcessVideoRequest: Encodable {
    let selectedFeatures: [ProcessingFeature]
}

private struct PresignedUploadResponse: Decodable {
    let uploadURL: URL
    let publicFileURL: URL
    let fileKey: String

    private enum CodingKeys: String, CodingKey {
        case uploadURL
        case uploadUrl
        case publicFileURL
        case publicFileUrl
        case fileKey
        case key
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let uploadURL = try container.decodeFirstPresent(URL.self, forKeys: [.uploadURL, .uploadUrl]) else {
            throw DecodingError.keyNotFound(
                CodingKeys.uploadURL,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Upload URL is required.")
            )
        }

        self.uploadURL = uploadURL

        guard let publicFileURL = try container.decodeFirstPresent(URL.self, forKeys: [.publicFileURL, .publicFileUrl]) else {
            throw DecodingError.keyNotFound(
                CodingKeys.publicFileUrl,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Public file URL is required.")
            )
        }

        guard let fileKey = try container.decodeFirstPresent(String.self, forKeys: [.fileKey, .key]) else {
            throw DecodingError.keyNotFound(
                CodingKeys.fileKey,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "File key is required.")
            )
        }

        self.publicFileURL = publicFileURL
        self.fileKey = fileKey
    }
}
