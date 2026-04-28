//
//  String+Validation.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfEmpty: String? {
        trimmed.isEmpty ? nil : trimmed
    }

    var isValidEmail: Bool {
        let parts = trimmed.split(separator: "@")
        guard parts.count == 2 else {
            return false
        }

        return parts[1].contains(".")
    }
}
