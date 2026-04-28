//
//  DecodingHelpers.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

extension KeyedDecodingContainer {
    func decodeFirstPresent<T: Decodable>(
        _ type: T.Type,
        forKeys keys: [Key]
    ) throws -> T? {
        for key in keys where contains(key) {
            if let value = try decodeIfPresent(T.self, forKey: key) {
                return value
            }
        }

        return nil
    }
}
