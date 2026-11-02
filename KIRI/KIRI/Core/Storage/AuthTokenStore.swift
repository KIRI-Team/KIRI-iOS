//
// MARK: - 파일 가이드
// 파일: Core/Storage/AuthTokenStore.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

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
