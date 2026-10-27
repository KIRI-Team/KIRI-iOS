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
    @State private var terms: [Term] = []
    @State private var loadedAgreements: [TermAgreement] = []
    @State private var pendingNewUser = false

    let animateLoginEntrance: Bool
    let initialTerms: [Term]?
    let initialAgreements: [TermAgreement]
    let onAuthenticated: (Bool) -> Void

    init(
        animateLoginEntrance: Bool,
        initialTerms: [Term]? = nil,
        initialAgreements: [TermAgreement] = [],
        onAuthenticated: @escaping (Bool) -> Void
    ) {
        self.animateLoginEntrance = animateLoginEntrance
        self.initialTerms = initialTerms
        self.initialAgreements = initialAgreements
        self.onAuthenticated = onAuthenticated
        _step = State(initialValue: initialTerms == nil ? .login : .terms)
        _terms = State(initialValue: initialTerms ?? [])
        _loadedAgreements = State(initialValue: initialAgreements)
    }

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
                        handleKakaoLogin()
                    },
                    onGoogleLogin: {
                        handleGoogleLogin()
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
                    terms: terms,
                    initialAgreements: loadedAgreements
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

                if result.isNewUser || !result.termsAgreed {
                    pendingNewUser = result.isNewUser
                    loadTermsAndShow()
                } else {
                    onAuthenticated(result.isNewUser)
                }
            } catch {
                authErrorMessage = error.localizedDescription
            }
        }
    }

    private func handleKakaoLogin() {
        guard !isAuthenticating else { return }
        isAuthenticating = true

        Task {
            defer { isAuthenticating = false }
            do {
                let credentials = try await KakaoLoginService.shared.login()
                let result = try await AuthService.shared.login(
                    provider: .kakao,
                    token: credentials.identityToken,
                    nonce: credentials.nonce
                )

                if result.isNewUser || !result.termsAgreed {
                    pendingNewUser = result.isNewUser
                    loadTermsAndShow()
                } else {
                    onAuthenticated(result.isNewUser)
                }
            } catch {
                authErrorMessage = error.localizedDescription
            }
        }
    }

    private func handleGoogleLogin() {
        guard !isAuthenticating else { return }
        isAuthenticating = true

        Task {
            defer { isAuthenticating = false }
            do {
                let credentials = try await GoogleLoginService.shared.login()
                let result = try await AuthService.shared.login(
                    provider: .google,
                    token: credentials.idToken,
                    nonce: credentials.nonce
                )

                if result.isNewUser || !result.termsAgreed {
                    pendingNewUser = result.isNewUser
                    loadTermsAndShow()
                } else {
                    onAuthenticated(result.isNewUser)
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
                let status: TermsAgreementStatus
                do {
                    status = try await AuthService.shared.agreementStatus()
                } catch APIError.serverError {
                    // 신규 사용자는 아직 동의 레코드가 없어 404가 반환될 수 있다.
                    // 약관 목록 자체를 숨기지 않고 미동의 상태로 표시한다.
                    status = TermsAgreementStatus(termsAgreed: false, agreements: [])
                }
                self.terms = terms
                self.loadedAgreements = status.agreements
                step = .terms
                #if DEBUG
                print("[KIRI][Auth] terms loaded: count=\(terms.count), agreements=\(status.agreements.count)")
                #endif
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
                onAuthenticated(pendingNewUser)
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
        onAuthenticated: { _ in }
    )
}
