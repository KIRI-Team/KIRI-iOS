import SwiftUI

struct AuthFlowView: View {
    enum Step {
        case login
        case terms
    }

    @State private var step: Step = .login

    let onAuthenticated: () -> Void

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            switch step {
            case .login:
                LoginView(
                    onBack: {},
                    onKakaoLogin: {
                        handleSocialLogin(provider: .kakao)
                    },
                    onGoogleLogin: {
                        handleSocialLogin(provider: .google)
                    },
                    onAppleLogin: {
                        handleSocialLogin(provider: .apple)
                    }
                )

            case .terms:
                TermsAgreementView(
                    onBack: {
                        step = .login
                    },
                    onComplete: {
                        completeSignUp()
                    }
                )
            }
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: step
        )
    }

    // MARK: - Social Login

    private func handleSocialLogin(
        provider: SocialLoginProvider
    ) {
        switch provider {
        case .kakao:
            // TODO:
            // Kakao SDK 로그인
            // → 카카오 access token 획득
            // → KIRI Server 전달
            // → 신규/기존 회원 여부 확인
            break

        case .google:
            // TODO:
            // Google Sign-In
            // → Google ID Token 획득
            // → KIRI Server 전달
            // → 신규/기존 회원 여부 확인
            break

        case .apple:
            // TODO:
            // Sign in with Apple
            // → identityToken / authorizationCode 획득
            // → KIRI Server 전달
            // → 신규/기존 회원 여부 확인
            break
        }

        // MARK: Temporary Flow
        //
        // 현재는 소셜 로그인 UI/온보딩 플로우 확인 단계이므로
        // 세 로그인 모두 신규 회원으로 가정한다.
        //
        // API 연결 이후 서버 응답에 따라 아래처럼 분기:
        //
        // 신규 회원:
        // step = .terms
        //
        // 기존 회원:
        // onAuthenticated()

        step = .terms
    }

    // MARK: - Sign Up Complete

    private func completeSignUp() {
        // TODO:
        // 약관 동의 API 연결
        //
        // 서버 저장 대상:
        //
        // 1. 서비스 이용약관
        // 2. 개인정보 수집·이용 동의
        // 3. 개인정보 처리방침 확인
        // 4. 위치정보 이용 동의 여부
        //
        // 저장 완료 후 KIRI 온보딩으로 이동

        onAuthenticated()
    }
}

// MARK: - Social Login Provider

enum SocialLoginProvider {
    case kakao
    case google
    case apple
}

// MARK: - Preview

#Preview {
    AuthFlowView(
        onAuthenticated: {}
    )
}
