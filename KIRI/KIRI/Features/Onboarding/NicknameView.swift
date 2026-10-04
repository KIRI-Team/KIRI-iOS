//
//  NicknameView 2.swift
//  KIRI
//
//  Created by namhyuk on 9/26/26.
//

import SwiftUI

struct NicknameView: View {

    @Binding var nickname: String

    let onBack: () -> Void
    let onNext: () -> Void

    private var trimmedNickname: String {
        nickname.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var isValid: Bool {
        trimmedNickname.count >= 2 &&
        trimmedNickname.count <= 10 &&
        containsOnlyAllowedCharacters(trimmedNickname)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                Text("끼리에서 사용할\n닉네임을 설정해주세요.")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.Text.primary)
                    .lineSpacing(7)

                Text("가족 안에서의 역할을 선택해주세요!")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .padding(.top, 12)

                KIRITextField(
                    placeholder: "이름을 입력하세요.",
                    text: $nickname
                )
                .padding(.top, 50)
                .onChange(of: nickname) { _, newValue in
                    nickname = sanitize(newValue)
                }

                KIRIValidationGuidance()
                    .padding(.leading, 24)
                    .padding(.top, 10)

                Spacer()

                KIRIPrimaryButton(
                    title: "다음",
                    isEnabled: isValid,
                    action: onNext
                )
            }
            .padding(
                .horizontal,
                KIRISpacing.horizontal
            )
            .padding(.bottom, 10)
        }
        .background(KIRIColor.Background.base)
        .navigationBarBackButtonHidden()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            KIRIBackButton(
                action: onBack
            )

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 70)
    }

    // MARK: - Validation

    private func containsOnlyAllowedCharacters(
        _ value: String
    ) -> Bool {
        let pattern = "^[가-힣A-Za-z0-9]+$"

        return value.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }

    private func sanitize(
        _ value: String
    ) -> String {
        let filtered = value.filter { character in
            String(character).range(
                of: "[가-힣A-Za-z0-9]",
                options: .regularExpression
            ) != nil
        }

        return String(filtered.prefix(10))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var nickname = "주연주"

    NicknameView(
        nickname: $nickname,
        onBack: {},
        onNext: {}
    )
    .background(KIRIColor.Background.base)
}
