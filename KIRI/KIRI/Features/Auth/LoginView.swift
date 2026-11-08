//
// MARK: - 파일 가이드
// 파일: Features/Auth/LoginView.swift
// 담당 화면: 카카오·Google·Apple 소셜 로그인 화면
// 주요 책임: 로그인 버튼 레이아웃과 Apple 인증 요청 결과 전달을 담당합니다.
// UI 수정 위치: 버튼 높이/모서리는 각 버튼의 frame·clipShape, 아이콘 기준선은
// SocialLoginButtonContent, 화면 여백은 상위 VStack의 padding에서 조정합니다.
// 데이터 흐름: AuthFlowView가 로그인 클로저를 주입하고, 성공한 credential만 상위로 전달합니다.
// 주의: 버튼 UI만 수정하며 OAuth 요청·nonce·토큰 처리 로직은 변경하지 않습니다.
//


import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    let animateButtonEntrance: Bool
    let onEntranceAnimationConsumed: (() -> Void)?
    let onKakaoLogin: () -> Void
    let onGoogleLogin: () -> Void
    let onAppleLogin: (_ identityToken: String, _ nonce: String) -> Void
    let onLoginFailure: (_ message: String) -> Void

    @State private var kakaoButtonVisible = false
    @State private var googleButtonVisible = false
    @State private var appleButtonVisible = false
    @State private var hasStartedEntrance = false
    @State private var appleNonce: String?

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Image("kiri_character")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)

                Spacer(minLength: 36)

                Image("kiri_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 202, height: 73)
                    .frame(height: 128)

                Spacer(minLength: 44)

                socialLoginSection
            }
            .padding(.horizontal, KIRISpacing.horizontal)
            .padding(.top, 80)
            .padding(.bottom, 24)
        }
        .onAppear {
            guard animateButtonEntrance else {
                kakaoButtonVisible = true
                googleButtonVisible = true
                appleButtonVisible = true
                return
            }
            guard !hasStartedEntrance else { return }

            hasStartedEntrance = true
            onEntranceAnimationConsumed?()
            kakaoButtonVisible = false
            googleButtonVisible = false
            appleButtonVisible = false
            withAnimation(.easeOut(duration: 0.45)) {
                kakaoButtonVisible = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.08)) {
                googleButtonVisible = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.16)) {
                appleButtonVisible = true
            }
        }
    }

    // MARK: - Social Login

    private var socialLoginSection: some View {
        VStack(spacing: 12) {
            kakaoLoginButton

            googleLoginButton

            // Apple 로그인은 서비스 요구사항에 따라 유지한다.
            appleLoginButton
        }
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
                    .frame(width: 20, height: 20)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(
            Color(
                red: 254.0 / 255.0,
                green: 229.0 / 255.0,
                blue: 0.0
            )
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
        .contentShape(
            RoundedRectangle(cornerRadius: 12)
        )
        .accessibilityLabel("카카오 로그인")
        .opacity(kakaoButtonVisible ? 1 : 0)
        .offset(y: kakaoButtonVisible ? 0 : 16)
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
                    .frame(width: 20, height: 20)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    Color(
                        red: 217.0 / 255.0,
                        green: 217.0 / 255.0,
                        blue: 217.0 / 255.0
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
        .contentShape(
            RoundedRectangle(cornerRadius: 12)
        )
        .accessibilityLabel("Google로 로그인")
        .opacity(googleButtonVisible ? 1 : 0)
        .offset(y: googleButtonVisible ? 0 : 16)
    }

    // MARK: - Apple

    private var appleLoginButton: some View {
        ZStack {
            // 공식 Apple 인증 컨트롤의 요청/완료 동작은 유지하고,
            // 서비스에서 사용하는 한국어 라벨은 앞쪽의 공통 콘텐츠로 표시합니다.
            SocialLoginButtonContent(
                title: "Apple로 로그인",
                foregroundColor: .black
            ) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(.black)
            }
            .accessibilityHidden(true)

            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    let nonce = Self.randomNonce()
                    appleNonce = nonce
                    request.nonce = Self.sha256(nonce)
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
            // 시스템 버튼은 투명하게 유지해 인증 hit target과 Apple의 요청 흐름을 보존합니다.
            .opacity(0.001)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(Color.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
        .accessibilityLabel("Apple로 로그인")
        .opacity(appleButtonVisible ? 1 : 0)
        .offset(y: appleButtonVisible ? 0 : 16)
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
                onLoginFailure("Apple 인증 정보를 확인할 수 없습니다.")
                return
            }

            guard let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8),
                  let nonce = appleNonce else {
                onLoginFailure("Apple 인증 토큰을 확인할 수 없습니다.")
                return
            }

            onAppleLogin(identityToken, nonce)

        case .failure(let error):
            onLoginFailure(error.localizedDescription)
        }
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            result.append(charset[Int.random(in: 0..<charset.count)])
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Social Login Content

private struct SocialLoginButtonContent<Logo: View>: View {
    let title: String
    let foregroundColor: Color

    @ViewBuilder
    let logo: () -> Logo

    var body: some View {
        ZStack {
            Text(title)
                .font(KIRITypography.button)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 0) {
                logo()
                    .frame(width: 20, height: 20)
                Spacer(minLength: 0)
            }
            .padding(.leading, 24)
        }
        .frame(height: 54)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    LoginView(
        animateButtonEntrance: false,
        onEntranceAnimationConsumed: nil,
        onKakaoLogin: {},
        onGoogleLogin: {},
        onAppleLogin: { _, _ in },
        onLoginFailure: { _ in }
    )
}
