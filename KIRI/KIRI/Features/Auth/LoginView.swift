import SwiftUI

struct LoginView: View {
    let onBack: () -> Void
    let onKakaoLogin: () -> Void
    let onGoogleLogin: () -> Void
    let onAppleLogin: () -> Void

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Spacer()

                logoSection

                Spacer()

                socialLoginSection
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 56)
    }

    // MARK: - Logo

    private var logoSection: some View {
        Text("KIRI")
            .font(
                .system(
                    size: 64,
                    weight: .black,
                    design: .rounded
                )
            )
            .tracking(-4)
            .foregroundStyle(KIRIColor.textPrimary)
    }

    // MARK: - Social Login Section

    private var socialLoginSection: some View {
        VStack(spacing: 12) {
            kakaoLoginButton
            googleLoginButton
            appleLoginButton
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 38)
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
                    .frame(width: 22, height: 22)
            }
            .frame(height: 56)
            .background(
                Color(
                    red: 254 / 255,
                    green: 229 / 255,
                    blue: 0 / 255
                )
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Google

    private var googleLoginButton: some View {
        Button(action: onGoogleLogin) {
            SocialLoginButtonContent(
                title: "Google로 로그인",
                foregroundColor: Color.black.opacity(0.82)
            ) {
                Image("google_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }
            .frame(height: 56)
            .background(Color.white)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Apple

    private var appleLoginButton: some View {
        Button(action: onAppleLogin) {
            SocialLoginButtonContent(
                title: "Apple로 로그인",
                foregroundColor: Color.white
            ) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(Color.white)
                    .frame(width: 22, height: 22)
            }
            .frame(height: 56)
            .background(Color.black)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        Color.white.opacity(0.18),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Social Login Button Content

private struct SocialLoginButtonContent<Logo: View>: View {
    let title: String
    let foregroundColor: Color

    @ViewBuilder
    let logo: () -> Logo

    var body: some View {
        ZStack {
            Text(title)
                .font(
                    .system(
                        size: 16,
                        weight: .medium
                    )
                )
                .foregroundStyle(foregroundColor)

            HStack {
                logo()
                    .frame(width: 24, height: 24)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
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
