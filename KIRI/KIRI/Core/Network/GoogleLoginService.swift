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
        #if DEBUG
        print("[KIRI][Google] starting SDK sign-in: noncePresent=true")
        #endif
        return try await withCheckedThrowingContinuation { continuation in
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
                            + "domain=\(nsError.domain), code=\(nsError.code), "
                            + Self.safeOAuthErrorSummary(nsError)
                    )
                    #endif
                    continuation.resume(throwing: error)
                    return
                }

                guard let idToken = result?.user.idToken?.tokenString else {
                    #if DEBUG
                    print("[KIRI][Google] SDK sign-in succeeded without ID token")
                    #endif
                    continuation.resume(
                        throwing: GoogleLoginError.missingIDToken
                    )
                    return
                }

                #if DEBUG
                Self.logTokenMetadata(
                    idToken,
                    expectedAudience:
                        configuration.serverClientID ?? configuration.clientID,
                    nonce: nonce
                )
                #endif

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

    #if DEBUG
    private static func logTokenMetadata(
        _ token: String,
        expectedAudience: String,
        nonce: String
    ) {
        let segments = token.split(separator: ".")
        guard segments.count == 3,
              let payloadData = Data(
                base64URLEncoded: String(segments[1])
              ),
              let payload = try? JSONSerialization.jsonObject(
                with: payloadData
              ) as? [String: Any]
        else {
            print("[KIRI][Google] ID token metadata unavailable")
            return
        }

        let audienceMatches = payload["aud"] as? String == expectedAudience
        let nonceMatches = payload["nonce"] as? String == nonce
        let expiresAt = (payload["exp"] as? NSNumber)?.doubleValue
        let isExpired = expiresAt.map { $0 <= Date().timeIntervalSince1970 } ?? true

        print(
            "[KIRI][Google] ID token metadata: "
                + "audienceMatches=\(audienceMatches), "
                + "noncePresent=\(payload["nonce"] != nil), "
                + "nonceMatches=\(nonceMatches), "
                + "expired=\(isExpired)"
        )
    }

    private static func safeOAuthErrorSummary(_ error: NSError) -> String {
        var parts: [String] = []
        if let value = error.userInfo["error"] as? String {
            parts.append("oauthError=\(value)")
        }
        if let value = error.userInfo["error_description"] as? String {
            parts.append("oauthDescription=\(value)")
        }
        if let json = error.userInfo["json"] as? [String: Any] {
            if let value = json["error"] as? String {
                parts.append("oauthError=\(value)")
            }
            if let value = json["error_description"] as? String {
                parts.append("oauthDescription=\(value)")
            }
        }
        let keys = error.userInfo.keys
            .compactMap { $0 as? String }
            .sorted()
        parts.append("userInfoKeys=\(keys.joined(separator: ","))")
        return parts.joined(separator: ", ")
    }
    #endif
}

#if DEBUG
private extension Data {
    init?(base64URLEncoded value: String) {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        self.init(base64Encoded: base64)
    }
}
#endif
