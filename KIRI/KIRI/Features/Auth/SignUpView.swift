
//
//  SignUpView 2.swift
//  KIRI
//
//  Created by namhyuk on 9/28/26.
//


import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""

    let onBack: () -> Void
    let onNext: () -> Void

    private var isValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        return !trimmedEmail.isEmpty &&
        password.count >= 8 &&
        password == passwordConfirmation
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("KIRI를\n시작해볼까요?")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("로그인에 사용할 계정을 만들어주세요.")
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

                    SecureField(
                        "비밀번호 확인",
                        text: $passwordConfirmation
                    )
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

                Text("비밀번호는 8자 이상 입력해주세요.")
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.leading, 20)
                    .padding(.top, 10)

                Spacer()

                KIRIPrimaryButton(
                    title: "다음",
                    isEnabled: isValid,
                    action: onNext
                )
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
    SignUpView(
        onBack: {},
        onNext: {}
    )
}
