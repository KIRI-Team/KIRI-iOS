//
// MARK: - 파일 가이드
// 파일: Core/Network/GoogleLoginService.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import Foundation
import GoogleSignIn
import UIKit

enum GoogleLoginError: LocalizedError {
    case missingConfiguration
    case missingPresentingViewController
    case missingIDToken
    case requestInProgress

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Google 로그인 설정을 확인할 수 없습니다."
        case .missingPresentingViewController:
            return "Google 로그인 화면을 표시할 수 없습니다."
        case .missingIDToken:
            return "Google 인증 토큰을 확인할 수 없습니다."
        case .requestInProgress:
            return "이미 Google 로그인이 진행 중입니다."
        }
    }
}

struct GoogleLoginCredentials: Sendable {
    let idToken: String
    let nonce: String
}

@MainActor
final class GoogleLoginService {
    static let shared = GoogleLoginService()

    private static let expectedIOSClientID =
        "932646982366-gmqn82k2fqe0b4umi3fskh3p15f662ct.apps.googleusercontent.com"
    private static let expectedServerClientID =
        "932646982366-u4d2vt0gmg1boulr74jrd21ajjokij2s.apps.googleusercontent.com"

    // Google 인증이 끝날 때까지 presenting controller를 강하게 유지합니다.
    // SwiftUI 상태 갱신으로 로그인 화면이 다시 계산되어도
    // SFAuthenticationViewController의 presentation 기반을 잃지 않게 합니다.
    private var activePresentingViewController: UIViewController?
    private var isLoginInFlight = false

    private init() {}

    func login() async throws -> GoogleLoginCredentials {
        guard !isLoginInFlight else {
            throw GoogleLoginError.requestInProgress
        }
        isLoginInFlight = true
        defer { isLoginInFlight = false }

        guard let configuration = loadConfiguration() else {
            throw GoogleLoginError.missingConfiguration
        }

        GIDSignIn.sharedInstance.configuration = configuration

        guard let presentingViewController = presentingViewController() else {
            throw GoogleLoginError.missingPresentingViewController
        }

        let nonce = UUID().uuidString
        #if DEBUG
        print("[KIRI][Google] SDK sign-in request started")
        #endif
        activePresentingViewController = presentingViewController
        return try await withCheckedThrowingContinuation { continuation in
            let finish: (Result<GoogleLoginCredentials, Error>) -> Void = {
                [weak self] result in
                self?.activePresentingViewController = nil
                continuation.resume(with: result)
            }

            GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController,
                hint: nil,
                additionalScopes: nil,
                nonce: nonce,
                claims: nil
            ) { result, error in
                if let error {
                    #if DEBUG
                    let nsError = error as NSError
                    print(
                        "[KIRI][Google] SDK sign-in failed: "
                            + "domain=\(nsError.domain), code=\(nsError.code)"
                    )
                    #endif
                    finish(.failure(error))
                    return
                }

                guard let idToken = result?.user.idToken?.tokenString else {
                    #if DEBUG
                    print("[KIRI][Google] SDK sign-in succeeded without ID token")
                    #endif
                    finish(.failure(GoogleLoginError.missingIDToken))
                    return
                }

                finish(.success(GoogleLoginCredentials(
                        idToken: idToken,
                        nonce: nonce
                    )))
            }
        }
    }

    private func loadConfiguration() -> GIDConfiguration? {
        guard let path = Bundle.main.path(
            forResource: "GoogleService-Info",
            ofType: "plist"
        ),
        let values = NSDictionary(contentsOfFile: path),
        let clientID = values["CLIENT_ID"] as? String,
        !clientID.isEmpty else {
            return nil
        }

        let rawServerClientID = values["SERVER_CLIENT_ID"] as? String
        let serverClientID = rawServerClientID?.trimmingCharacters(in: .whitespacesAndNewlines)

        #if DEBUG
        let omitServerClientID = ProcessInfo.processInfo.arguments.contains(
            "-kiri-google-omit-server-client-id"
        )
        let bundleID = Bundle.main.bundleIdentifier
        let plistBundleID = values["BUNDLE_ID"] as? String
        let reversedClientID = values["REVERSED_CLIENT_ID"] as? String
        let reversedSchemePresent = Self.urlSchemes().contains {
            $0 == reversedClientID
        }
        print(
            "[KIRI][Google] configuration: "
                + "clientIDPresent=true, "
                + "serverClientIDPresent=\(serverClientID != nil), "
                + "clientIDMatchesExpected=\(clientID == Self.expectedIOSClientID), "
                + "serverClientIDMatchesExpected=\(serverClientID == Self.expectedServerClientID), "
                + "clientIDHasWhitespace=\(clientID != clientID.trimmingCharacters(in: .whitespacesAndNewlines)), "
                + "serverClientIDHasWhitespace=\(rawServerClientID != serverClientID), "
                + "bundleIDMatchesPlist=\(bundleID == plistBundleID), "
                + "reversedURLSchemePresent=\(reversedSchemePresent), "
                + "omitServerClientID=\(omitServerClientID)"
        )
        let effectiveServerClientID = omitServerClientID ? nil : serverClientID
        #else
        let effectiveServerClientID = serverClientID
        #endif

        return GIDConfiguration(
            clientID: clientID,
            serverClientID: effectiveServerClientID
        )
    }

    private func presentingViewController() -> UIViewController? {
        let activeScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        let window = activeScenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow && !$0.isHidden && $0.alpha > 0 }

        guard let rootViewController = window?.rootViewController else {
            return nil
        }

        return topViewController(from: rootViewController)
    }

    private func topViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController,
           !presented.isBeingDismissed {
            return topViewController(from: presented)
        }
        if let navigation = viewController as? UINavigationController,
           let visible = navigation.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = viewController as? UITabBarController,
           let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return viewController
    }

    #if DEBUG
    private static func urlSchemes() -> [String] {
        let types = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleURLTypes"
        ) as? [[String: Any]] ?? []
        return types.flatMap { type in
            type["CFBundleURLSchemes"] as? [String] ?? []
        }
    }
    #endif
}
