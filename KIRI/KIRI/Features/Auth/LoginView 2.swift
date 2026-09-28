//
//  LoginView 2.swift
//  KIRI
//
//  Created by namhyuk on 9/28/26.
//


import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""

    let onBack: () -> Void
    let onLogin: () -> Void
    let onSignUp: () -> Void

    private var isValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("다시 만나서\n반가워요!")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("KIRI 계정으로 로그인해주세요.")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.top, 12)

                VStack(spacing: 14) {
                    KIRITextField(
                        placeholder: "이메일",
                        text: $email
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)

                    SecureField("비밀번호", text: $password)
                        .font(KIRITypography.bodyMedium)
                        .foregroundStyle(KIRIColor.textPrimary)
                        .padding(.horizontal, 20)
                        .frame(height: 56)
                        .background(KIRIColor.surface)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: KIRIRadius.large
                            )
                        )
                }
                .padding(.top, 50)

                Spacer()

                VStack(spacing: 12) {
                    KIRIPrimaryButton(
                        title: "로그인",
                        isEnabled: isValid,
                        action: onLogin
                    )

                    Button(action: onSignUp) {
                        Text("아직 계정이 없나요? 회원가입")
                            .font(KIRITypography.caption)
                            .foregroundStyle(KIRIColor.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, KIRISpacing.horizontal)
            .padding(.bottom, 10)
        }
        .background(KIRIColor.background)
    }

    private var header: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 70)
    }
}

#Preview {
    LoginView(
        onBack: {},
        onLogin: {},
        onSignUp: {}
    )
}
