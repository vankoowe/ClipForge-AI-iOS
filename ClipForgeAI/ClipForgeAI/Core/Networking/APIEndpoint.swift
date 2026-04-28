//
//  APIEndpoint.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: Data?
    let requiresAuth: Bool

    init(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.requiresAuth = requiresAuth
    }

    static func jsonBody<T: Encodable>(_ value: T) throws -> Data {
        do {
            return try JSONEncoder.apiEncoder.encode(value)
        } catch {
            throw AppError.encoding(error)
        }
    }
}
