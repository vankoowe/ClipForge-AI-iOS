//
//  NetworkLogger.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import Foundation

enum NetworkLogger {
    static func logRequest(_ request: URLRequest, endpoint: APIEndpoint, isRetry: Bool = false) {
        #if DEBUG
        let method = request.httpMethod ?? endpoint.method.rawValue
        let auth = endpoint.requiresAuth ? "required" : "none"
        let retry = isRetry ? " retry=true" : ""
        print("[ClipForgeAPI] -> \(method) \(sanitizedURL(request.url)) auth=\(auth)\(retry)")
        #endif
    }

    static func logResponse(_ response: URLResponse, data: Data, endpoint: APIEndpoint) {
        #if DEBUG
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[ClipForgeAPI] <- invalid response for \(endpoint.method.rawValue) \(endpoint.path)")
            return
        }

        let errorResponse = BackendAPIErrorResponse.decode(from: data)
        let message = errorResponse?.resolvedMessage
        let details = errorResponse?.error?.details?.joined(separator: "; ")
        let detailSuffix = details.map { " details=\"\($0)\"" } ?? ""
        let messageSuffix = message.map { " message=\"\($0)\"" } ?? ""

        print("[ClipForgeAPI] <- \(httpResponse.statusCode) \(endpoint.method.rawValue) \(endpoint.path)\(messageSuffix)\(detailSuffix)")
        #endif
    }

    static func logRefreshAttempt() {
        #if DEBUG
        print("[ClipForgeAPI] token refresh started")
        #endif
    }

    static func logUploadStage(_ message: String) {
        #if DEBUG
        print("[ClipForgeUpload] \(message)")
        #endif
    }

    static func logRawUploadRequest(fileURL: URL, uploadURL: URL, contentType: String) {
        #if DEBUG
        let fileName = fileURL.lastPathComponent
        print("[ClipForgeUpload] raw PUT started file=\"\(fileName)\" contentType=\"\(contentType)\" destination=\"\(sanitizedURL(uploadURL))\"")
        #endif
    }

    static func logRawUploadResponse(_ response: URLResponse) {
        #if DEBUG
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[ClipForgeUpload] raw PUT invalid response")
            return
        }

        print("[ClipForgeUpload] raw PUT finished status=\(httpResponse.statusCode)")
        #endif
    }

    private static func sanitizedURL(_ url: URL?) -> String {
        guard let url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return "unknown-url"
        }

        components.query = nil
        components.fragment = nil
        return components.url?.absoluteString ?? "unknown-url"
    }
}
