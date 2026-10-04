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
                        handleSocialLogin(
                            provider: .kakao
                        )
                    },
                    onGoogleLogin: {
                        handleSocialLogin(
                            provider: .google
                        )
                    },
                    onAppleLogin: {
                        handleSocialLogin(
                            provider: .apple
                        )
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
            // Kakao SDK 인증
            //
            // 1. Kakao 로그인
            // 2. Kakao Access Token 획득
            // 3. KIRI Server 전달
            // 4. 서버에서 신규/기존 회원 판단
            break

        case .google:
            // TODO:
            // Google Sign-In 인증
            //
            // 1. Google 로그인
            // 2. Google ID Token 획득
            // 3. KIRI Server 전달
            // 4. 서버에서 신규/기존 회원 판단
            break

        case .apple:
            // Apple 인증 자체는
            // LoginView의 SignInWithAppleButton에서 수행한다.
            //
            // 추후 LoginView에서 받은 Apple Credential을
            // AuthService/ViewModel 쪽으로 이동시킬 예정이다.
            break
        }

        // MARK: - Temporary Authentication Flow
        //
        // 현재는 서버 인증 API가 연결되지 않았으므로
        // 로그인에 성공했다고 가정하고 신규 회원 플로우로 이동한다.
        //
        // 실제 서버 연결 후에는 다음처럼 처리:
        //
        // 신규 회원
        // → step = .terms
        //
        // 기존 회원
        // → onAuthenticated()

        step = .terms
    }

    // MARK: - Sign Up Complete

    private func completeSignUp() {
        // TODO:
        // 약관 동의 API 연결
        //
        // 서버에 다음 동의 여부를 전달:
        //
        // 1. 서비스 이용약관
        // 2. 개인정보 수집·이용
        // 3. 개인정보 처리방침 확인
        // 4. 위치정보 이용 동의 여부
        //
        // 서버 저장 완료 후
        // KIRI 온보딩으로 이동한다.

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
