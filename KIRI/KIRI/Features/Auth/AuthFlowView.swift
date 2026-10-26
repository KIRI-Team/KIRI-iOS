import SwiftUI

struct AuthFlowView: View {
    enum Step {
        case login
        case terms
    }

    @State private var step: Step = .login
    @State private var hasConsumedLoginEntrance = false
    @State private var isAuthenticating = false
    @State private var authErrorMessage: String?
    @State private var termIDs: [Int] = []

    let animateLoginEntrance: Bool
    let onAuthenticated: () -> Void

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            switch step {
            case .login:
                LoginView(
                    animateButtonEntrance: animateLoginEntrance && !hasConsumedLoginEntrance,
                    onEntranceAnimationConsumed: {
                        hasConsumedLoginEntrance = true
                    },
                    onKakaoLogin: {
                        authErrorMessage = "카카오 로그인 SDK가 아직 프로젝트에 연결되지 않았습니다."
                    },
                    onGoogleLogin: {
                        authErrorMessage = "Google 로그인 SDK가 아직 프로젝트에 연결되지 않았습니다."
                    },
                    onAppleLogin: { identityToken, nonce in
                        handleAppleLogin(identityToken: identityToken, nonce: nonce)
                    },
                    onLoginFailure: { message in
                        authErrorMessage = message
                    }
                )

            case .terms:
                TermsAgreementView(
                    onBack: {
                        step = .login
                    },
                    onComplete: { agreements in
                        completeSignUp(agreements: agreements)
                    },
                    termIDs: termIDs
                )
            }
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: step
        )
        .alert(
            "로그인할 수 없습니다",
            isPresented: Binding(
                get: { authErrorMessage != nil },
                set: { if !$0 { authErrorMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(authErrorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
    }

    private func handleAppleLogin(identityToken: String, nonce: String) {
        guard !isAuthenticating else { return }
        isAuthenticating = true

        Task {
            defer { isAuthenticating = false }
            do {
                let result = try await AuthService.shared.login(
                    provider: .apple,
                    token: identityToken,
                    nonce: nonce
                )

                if result.termsAgreed {
                    onAuthenticated()
                } else {
                    loadTermsAndShow()
                }
            } catch {
                authErrorMessage = error.localizedDescription
            }
        }
    }

    private func loadTermsAndShow() {
        Task {
            do {
                let terms = try await AuthService.shared.terms()
                termIDs = terms.map(\.termId)
                step = .terms
            } catch {
                authErrorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Sign Up Complete

    private func completeSignUp(agreements: [TermAgreement]) {
        guard !isAuthenticating else { return }
        isAuthenticating = true

        Task {
            defer { isAuthenticating = false }
            do {
                try await AuthService.shared.agree(to: agreements)
                onAuthenticated()
            } catch {
                authErrorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AuthFlowView(
        animateLoginEntrance: false,
        onAuthenticated: {}
    )
}
