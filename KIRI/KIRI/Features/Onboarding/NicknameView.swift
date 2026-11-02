//
// MARK: - 파일 가이드
// 파일: Features/Onboarding/NicknameView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

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
        trimmedNickname.count <= 12 &&
        containsOnlyAllowedCharacters(trimmedNickname)
    }

    private var validationState: KIRIValidationGuidance.ValidationState {
        guard !trimmedNickname.isEmpty else { return .neutral }
        return isValid ? .valid : .invalid
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

                KIRIValidationGuidance(state: validationState)
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

        return String(filtered.prefix(12))
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
