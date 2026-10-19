//
//  FamilyCodeInputView 2.swift
//  KIRI
//
//  Created by namhyuk on 9/28/26.
//

import SwiftUI

struct FamilyCodeInputView: View {

    @Binding var familyCode: String

    let onBack: () -> Void
    let onNext: () -> Void

    private var normalizedCode: String {
        familyCode
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .uppercased()
    }

    private var isValid: Bool {
        normalizedCode.count == 6 &&
        normalizedCode.allSatisfy { character in
            character.isASCII &&
            (character.isLetter || character.isNumber)
        }
    }

    private var validationState: KIRIValidationGuidance.ValidationState {
        guard !normalizedCode.isEmpty else { return .neutral }
        return isValid ? .valid : .invalid
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                Text("가족에게 받은\n코드를 입력해주세요.")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.Text.primary)
                    .lineSpacing(7)

                Text("가족코드를 입력하면 참여할 가족공간을 확인할 수 있어요.")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .padding(.top, 12)

                HStack {
                    Spacer()

                    KIRICodeInput(
                        text: $familyCode
                    )

                    Spacer()
                }
                .padding(.top, 50)

                Text("영문과 숫자로 구성된 6자리 코드를 입력해주세요.")
                    .font(KIRITypography.captionMedium)
                    .tracking(-0.48)
                    .foregroundStyle(validationColor)
                    .padding(.top, 10)

                Spacer()

                KIRIPrimaryButton(
                    title: "가족공간 확인하기",
                    isEnabled: isValid,
                    action: {
                        familyCode = normalizedCode
                        onNext()
                    }
                )
            }
            .padding(
                .horizontal,
                KIRISpacing.horizontal
            )
            .padding(.bottom, 10)
        }
        .background(KIRIColor.Background.base)
    }

    private var validationColor: Color {
        switch validationState {
        case .neutral:
            return KIRIColor.Text.tertiary
        case .invalid:
            return KIRIColor.Status.error
        case .valid:
            return KIRIColor.Status.success
        }
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
}

// MARK: - Preview

#Preview {
    @Previewable @State var familyCode = ""

    FamilyCodeInputView(
        familyCode: $familyCode,
        onBack: {},
        onNext: {}
    )
    .background(KIRIColor.Background.base)
}
