
import SwiftUI

struct FamilyNameEditView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var familyName: String

    @State private var editedFamilyName = ""

    private var trimmedFamilyName: String {
        editedFamilyName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
            .joined(separator: " ")
    }

    private var isValid: Bool {
        trimmedFamilyName.count >= 2 &&
        trimmedFamilyName.count <= 15 &&
        containsOnlyAllowedCharacters(
            trimmedFamilyName
        )
    }

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    Text("가족명을 다시 입력해주세요.")
                        .font(KIRITypography.title)
                        .foregroundStyle(
                            KIRIColor.textPrimary
                        )

                    Text("가족명은 월 1회 수정 가능합니다")
                        .font(KIRITypography.subtitle)
                        .foregroundStyle(
                            KIRIColor.textSecondary
                        )
                        .padding(.top, 12)

                    KIRITextField(
                        placeholder: "이름을 입력하세요.",
                        text: $editedFamilyName,
                        state: editedFamilyName.isEmpty || isValid ? .normal : .error
                    )
                    .padding(.top, 40)

                    Spacer()

                    KIRIPrimaryButton(
                        title: "다음",
                        isEnabled: isValid
                    ) {
                        familyName = trimmedFamilyName
                        dismiss()
                    }
                }
                .padding(
                    .horizontal,
                    KIRISpacing.horizontal
                )
                .padding(.bottom, 10)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            editedFamilyName = familyName
        }
    }

    private var header: some View {
        HStack {
            KIRIBackButton {
                dismiss()
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 70)
    }

    private func containsOnlyAllowedCharacters(
        _ value: String
    ) -> Bool {
        let pattern = "^[가-힣A-Za-z0-9 ]+$"

        return value.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }
}

#Preview {
    @Previewable @State var familyName = "끼리네 가족"

    NavigationStack {
        FamilyNameEditView(
            familyName: $familyName
        )
    }
}
