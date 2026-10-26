import Foundation
import GoogleSignIn
import UIKit

enum GoogleLoginError: LocalizedError {
    case missingConfiguration
    case missingPresentingViewController
    case missingIDToken

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Google 로그인 설정을 확인할 수 없습니다."
        case .missingPresentingViewController:
            return "Google 로그인 화면을 표시할 수 없습니다."
        case .missingIDToken:
            return "Google 인증 토큰을 확인할 수 없습니다."
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

    private init() {}

    func login() async throws -> GoogleLoginCredentials {
        guard let configuration = loadConfiguration() else {
            throw GoogleLoginError.missingConfiguration
        }

        GIDSignIn.sharedInstance.configuration = configuration

        guard let presentingViewController = presentingViewController() else {
            throw GoogleLoginError.missingPresentingViewController
        }

        let nonce = UUID().uuidString
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController,
                hint: nil,
                additionalScopes: nil,
                nonce: nonce,
                claims: nil
            ) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let idToken = result?.user.idToken?.tokenString else {
                    continuation.resume(
                        throwing: GoogleLoginError.missingIDToken
                    )
                    return
                }

                continuation.resume(
                    returning: GoogleLoginCredentials(
                        idToken: idToken,
                        nonce: nonce
                    )
                )
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

        let serverClientID = values["SERVER_CLIENT_ID"] as? String
        return GIDConfiguration(
            clientID: clientID,
            serverClientID: serverClientID
        )
    }

    private func presentingViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        let window = scenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        return window?.rootViewController
    }
}
