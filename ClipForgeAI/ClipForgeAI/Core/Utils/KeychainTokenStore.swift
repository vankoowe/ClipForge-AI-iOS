//
//  KeychainTokenStore.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import Foundation
import Security

protocol AuthStore {
    func readTokens() -> AuthTokens?
    func saveTokens(_ tokens: AuthTokens) throws
    func deleteTokens() throws
}

final class KeychainTokenStore: AuthStore {
    private let service: String
    private let account: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.ClipForgeAI.ClipForgeAI",
        account: String = "auth_tokens"
    ) {
        self.service = service
        self.account = account
    }

    func readTokens() -> AuthTokens? {
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

        return try? JSONDecoder.apiDecoder.decode(AuthTokens.self, from: data)
    }

    func saveTokens(_ tokens: AuthTokens) throws {
        try deleteTokensIgnoringMissing()

        var query = baseQuery()
        query[kSecValueData] = try JSONEncoder.apiEncoder.encode(tokens)
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw AppError.keychain(status)
        }
    }

    func deleteTokens() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AppError.keychain(status)
        }
    }

    private func deleteTokensIgnoringMissing() throws {
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
