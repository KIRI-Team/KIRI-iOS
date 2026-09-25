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

    private var isValid: Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 10
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("끼리에서 사용할\n닉네임을 설정해주세요.")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("가족 안에서의 역할을 선택해주세요!")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.top, 12)

                KIRITextField(
                    placeholder: "이름을 입력하세요.",
                    text: $nickname
                )
                .padding(.top, 50)

                VStack(alignment: .leading, spacing: 6) {
                    Text("✓ 한글/영어/숫자 혼합 가능")
                    Text("✓ 최소 2자 ~ 최대 10자 이내")
                    Text("✓ 특수 문자 입력 불가능")
                }
                .font(KIRITypography.caption)
                .foregroundStyle(KIRIColor.textSecondary)
                .padding(.leading, 24)
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
        .navigationBarBackButtonHidden()
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
    @Previewable @State var nickname = "주연주"

    NicknameView(
        nickname: $nickname,
        onBack: {},
        onNext: {}
    )
    .background(KIRIColor.background)
}
