//
//  KeychainTokenStore.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation
import Security

protocol TokenStore {
    func readToken() -> String?
    func saveToken(_ token: String) throws
    func deleteToken() throws
}

final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.ClipForgeAI.ClipForgeAI",
        account: String = "jwt"
    ) {
        self.service = service
        self.account = account
    }

    func readToken() -> String? {
        var query = baseQuery()
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard
            status == errSecSuccess,
            let data = item as? Data
        else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func saveToken(_ token: String) throws {
        try deleteTokenIgnoringMissing()

        var query = baseQuery()
        query[kSecValueData] = Data(token.utf8)
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw AppError.keychain(status)
        }
    }

    func deleteToken() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AppError.keychain(status)
        }
    }

    private func deleteTokenIgnoringMissing() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AppError.keychain(status)
        }
    }

    private func baseQuery() -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
    }
}
