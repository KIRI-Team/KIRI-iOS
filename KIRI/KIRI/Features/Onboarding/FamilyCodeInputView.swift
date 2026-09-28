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
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private var isValid: Bool {
        normalizedCode.count == 6 &&
        normalizedCode.allSatisfy { $0.isLetter || $0.isNumber }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("가족에게 받은\n코드를 입력해주세요.")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("가족코드를 입력하면 참여할 가족공간을 확인할 수 있어요.")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.top, 12)

                KIRITextField(
                    placeholder: "가족코드 6자리",
                    text: $familyCode
                )
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(.top, 50)
                .onChange(of: familyCode) { _, newValue in
                    familyCode = sanitize(newValue)
                }

                Text("영문과 숫자로 구성된 6자리 코드를 입력해주세요.")
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.leading, 24)
                    .padding(.top, 10)

                Spacer()

                KIRIPrimaryButton(
                    title: "가족공간 확인하기",
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

    private func sanitize(_ value: String) -> String {
        let filtered = value
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }

        return String(filtered.prefix(6))
    }
}

#Preview {
    @Previewable @State var familyCode = ""

    FamilyCodeInputView(
        familyCode: $familyCode,
        onBack: {},
        onNext: {}
    )
    .background(KIRIColor.background)
}
