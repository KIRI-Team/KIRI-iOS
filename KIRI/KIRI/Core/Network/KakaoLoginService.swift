//
// MARK: - 파일 가이드
// 파일: Core/Network/KakaoLoginService.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import Foundation
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser

enum KakaoLoginError: LocalizedError {
    case missingIDToken
    case cancelled
    case requestInProgress

    var errorDescription: String? {
        switch self {
        case .missingIDToken:
            return "카카오에서 OIDC ID Token을 받지 못했습니다. 카카오 개발자 콘솔에서 OpenID Connect를 활성화해 주세요."
        case .cancelled:
            return "카카오 로그인이 취소되었습니다."
        case .requestInProgress:
            return "이미 카카오 로그인이 진행 중입니다."
        }
    }
}

@MainActor
final class KakaoLoginService {
    static let shared = KakaoLoginService()

    private var isLoginInFlight = false

    private init() {}

    func login() async throws -> (identityToken: String, nonce: String) {
        guard !isLoginInFlight else {
            throw KakaoLoginError.requestInProgress
        }

        isLoginInFlight = true
        defer { isLoginInFlight = false }

        let nonce = Self.randomNonce()

        return try await withCheckedThrowingContinuation { continuation in
            let completion: (OAuthToken?, Error?) -> Void = { token, error in
                if let error {
                    if Self.isUserCancellation(error) {
                        continuation.resume(throwing: KakaoLoginError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
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

    private static func isUserCancellation(_ error: Error) -> Bool {
        if let sdkError = error as? SdkError,
           case .ClientFailed(reason: .Cancelled, errorMessage: _) = sdkError {
            return true
        }

        let nsError = error as NSError
        return nsError.domain == "com.apple.AuthenticationServices" && nsError.code == 1
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
