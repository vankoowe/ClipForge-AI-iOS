//
//  APIConfiguration.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

struct APIConfiguration {
    let baseURL: URL

    static let production = APIConfiguration(
        baseURL: URL(string: "https://api.clipforge.ai")!
    )

    static var current: APIConfiguration {
        let configuredURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        let environmentURL = ProcessInfo.processInfo.environment["API_BASE_URL"]
        let rawValue = configuredURL ?? environmentURL

        guard
            let rawValue,
            let url = URL(string: rawValue)
        else {
            return .production
        }

        return APIConfiguration(baseURL: url)
    }
}
