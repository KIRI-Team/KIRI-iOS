import SwiftUI

struct FamilyNameView: View {

    @Binding var familyName: String

    let onBack: () -> Void
    let onNext: () -> Void

    private var trimmedFamilyName: String {
        familyName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var isValid: Bool {
        trimmedFamilyName.count >= 2 &&
        trimmedFamilyName.count <= 10 &&
        containsOnlyAllowedCharacters(trimmedFamilyName)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                Text("우리 가족의\n가족명을 설정해주세요.")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.Text.primary)
                    .lineSpacing(7)

                Text("우리 가족만의 이름을 만들어주세요!")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .padding(.top, 12)

                KIRITextField(
                    placeholder: "가족명을 입력하세요.",
                    text: $familyName
                )
                .padding(.top, 50)
                .onChange(of: familyName) { _, newValue in
                    familyName = sanitize(newValue)
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
    @Previewable @State var familyName = "주연이가족"

    FamilyNameView(
        familyName: $familyName,
        onBack: {},
        onNext: {}
    )
    .background(KIRIColor.Background.base)
}
