import Foundation
import Security

struct AuthTokens: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
}

protocol AuthTokenStoring {
    func read() throws -> AuthTokens?
    func save(_ tokens: AuthTokens) throws
    func clear() throws
}

enum AuthTokenStoreError: Error {
    case encodingFailed
    case decodingFailed
    case keychain(OSStatus)
}

final class KeychainAuthTokenStore: AuthTokenStoring {
    static let shared = KeychainAuthTokenStore()

    private let service: String
    private let account: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.kiriteam.KIRI",
        account: String = "auth.tokens"
    ) {
        self.service = service
        self.account = account
    }

    func read() throws -> AuthTokens? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw AuthTokenStoreError.keychain(status)
        }

        guard let data = result as? Data else {
            throw AuthTokenStoreError.decodingFailed
        }

        do {
            return try JSONDecoder().decode(AuthTokens.self, from: data)
        } catch {
            throw AuthTokenStoreError.decodingFailed
        }
    }

    func save(_ tokens: AuthTokens) throws {
        let data: Data

        do {
            data = try JSONEncoder().encode(tokens)
        } catch {
            throw AuthTokenStoreError.encodingFailed
        }

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            updateAttributes as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw AuthTokenStoreError.keychain(updateStatus)
        }

        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

        guard addStatus == errSecSuccess else {
            throw AuthTokenStoreError.keychain(addStatus)
        }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthTokenStoreError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
