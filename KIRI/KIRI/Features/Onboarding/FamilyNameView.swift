
import SwiftUI

struct FamilyNameView: View {
    @Binding var familyName: String

    let onBack: () -> Void
    let onNext: () -> Void

    private var trimmedFamilyName: String {
        familyName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        trimmedFamilyName.count >= 2 &&
        trimmedFamilyName.count <= 10 &&
        containsOnlyAllowedCharacters(trimmedFamilyName)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("우리 가족의\n가족명을 설정해주세요.")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("우리 가족만의 이름을 만들어주세요!")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.top, 12)

                KIRITextField(
                    placeholder: "가족명을 입력하세요.",
                    text: $familyName
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
    }

    private var header: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 70)
    }

    private func containsOnlyAllowedCharacters(_ value: String) -> Bool {
        let pattern = "^[가-힣A-Za-z0-9]+$"

        return value.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }
}

#Preview {
    @Previewable @State var familyName = "주연이가족"

    FamilyNameView(
        familyName: $familyName,
        onBack: {},
        onNext: {}
    )
    .background(KIRIColor.background)
}
