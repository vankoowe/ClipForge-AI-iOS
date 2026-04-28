//
//  APIConfiguration.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct APIConfiguration {
    let baseURL: URL

    static let localDevelopment = APIConfiguration(
        baseURL: URL(string: "http://127.0.0.1:3000/api")!
    )

    static let production = APIConfiguration(
        baseURL: URL(string: "https://api.clipforge.ai/api")!
    )

    static var current: APIConfiguration {
        let configuredURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        let environmentURL = ProcessInfo.processInfo.environment["API_BASE_URL"]
        let rawValue = configuredURL ?? environmentURL

        guard
            let rawValue,
            let url = URL(string: rawValue)
        else {
            return .localDevelopment
        }

        return APIConfiguration(baseURL: url)
    }
}
