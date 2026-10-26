import Foundation
import KakaoSDKAuth
import KakaoSDKUser

enum KakaoLoginError: LocalizedError {
    case missingIDToken

    var errorDescription: String? {
        switch self {
        case .missingIDToken:
            return "카카오에서 OIDC ID Token을 받지 못했습니다. 카카오 개발자 콘솔에서 OpenID Connect를 활성화해 주세요."
        }
    }
}

@MainActor
final class KakaoLoginService {
    static let shared = KakaoLoginService()

    private init() {}

    func login() async throws -> (identityToken: String, nonce: String) {
        let nonce = Self.randomNonce()

        return try await withCheckedThrowingContinuation { continuation in
            let completion: (OAuthToken?, Error?) -> Void = { token, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let identityToken = token?.idToken,
                      !identityToken.isEmpty else {
                    continuation.resume(throwing: KakaoLoginError.missingIDToken)
                    return
                }

                continuation.resume(
                    returning: (identityToken: identityToken, nonce: nonce)
                )
            }

            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(
                    nonce: nonce,
                    completion: completion
                )
            } else {
                UserApi.shared.loginWithKakaoAccount(
                    nonce: nonce,
                    completion: completion
                )
            }
        }
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            result.append(charset[Int.random(in: 0..<charset.count)])
        }
        return result
    }
}
