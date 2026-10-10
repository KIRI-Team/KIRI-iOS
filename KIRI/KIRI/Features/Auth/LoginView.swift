import SwiftUI
import AuthenticationServices

struct LoginView: View {
    let onBack: () -> Void
    let onKakaoLogin: () -> Void
    let onGoogleLogin: () -> Void
    let onAppleLogin: () -> Void

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            header

            VStack(spacing: 0) {
                Image("kiri_character")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)

                Spacer()
                    .frame(height: 24)

                Image("kiri_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 54)

                Spacer()
                    .frame(height: 172)

                socialLoginSection
            }
            .padding(.top, 271)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()
        }
        .padding(.horizontal, KIRISpacing.xSmall)
        .frame(height: 56)
    }

    // MARK: - Social Login

    private var socialLoginSection: some View {
        VStack(spacing: 12) {
            kakaoLoginButton

            googleLoginButton

            // 명세상 Apple 로그인이 필요하지만, 기준 Figma 프레임
            // (8159:13178)에는 두 버튼만 있다. 현재 버튼은 유지하되
            // Figma 비교 시 별도 차이로 기록한다.
            appleLoginButton
        }
        .padding(.horizontal, KIRISpacing.horizontal)
        .padding(.bottom, 0)
    }

    // MARK: - Kakao

    private var kakaoLoginButton: some View {
        Button(action: onKakaoLogin) {
            SocialLoginButtonContent(
                title: "카카오 로그인",
                foregroundColor: Color.black.opacity(0.85)
            ) {
                Image("kakao_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 20,
                        height: 20
                    )
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            Color(
                red: 254 / 255,
                green: 229 / 255,
                blue: 0 / 255
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .contentShape(Capsule())
        .accessibilityLabel("카카오 로그인")
    }

    // MARK: - Google

    private var googleLoginButton: some View {
        Button(action: onGoogleLogin) {
            SocialLoginButtonContent(
                title: "Google로 로그인",
                foregroundColor: Color.black.opacity(0.85)
            ) {
                Image("google_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 20,
                        height: 20
                    )
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .stroke(
                    Color(red: 217 / 255, green: 217 / 255, blue: 217 / 255),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .contentShape(Capsule())
        .accessibilityLabel("Google로 로그인")
    }

    // MARK: - Apple

    private var appleLoginButton: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                request.requestedScopes = [
                    .fullName,
                    .email
                ]
            },
            onCompletion: { result in
                handleAppleSignInResult(result)
            }
        )
        .signInWithAppleButtonStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .accessibilityLabel("Apple로 로그인")
    }

    // MARK: - Apple Result

    private func handleAppleSignInResult(
        _ result: Result<ASAuthorization, Error>
    ) {
        switch result {
        case .success(let authorization):
            guard let credential =
                authorization.credential
                as? ASAuthorizationAppleIDCredential
            else {
                return
            }

            let userIdentifier = credential.user
            let identityToken = credential.identityToken
            let authorizationCode = credential.authorizationCode
            let fullName = credential.fullName
            let email = credential.email

            // TODO:
            // 실제 서버 연동 시 AuthService로 이동한다.
            //
            // identityToken / authorizationCode
            // → KIRI Server
            //
            // fullName / email은 최초 Apple 승인 시에만
            // 전달될 수 있으므로 최초 로그인 시 처리한다.

            _ = userIdentifier
            _ = identityToken
            _ = authorizationCode
            _ = fullName
            _ = email

            onAppleLogin()

        case .failure(let error):
            print(
                "Apple Sign In Error: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - Social Login Content

private struct SocialLoginButtonContent<Logo: View>: View {
    let title: String
    let foregroundColor: Color

    @ViewBuilder
    let logo: () -> Logo

    var body: some View {
        HStack(spacing: KIRISpacing.small) {
            logo()
                .frame(
                    width: 20,
                    height: 20
                )

            Text(title)
                .font(KIRITypography.button)
                .foregroundStyle(foregroundColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    LoginView(
        onBack: {},
        onKakaoLogin: {},
        onGoogleLogin: {},
        onAppleLogin: {}
    )
}
