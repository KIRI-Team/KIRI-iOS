
import SwiftUI

struct NicknameEditView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var nickname: String
    var onSave: ((String) async -> String?)? = nil

    @State private var editedNickname = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var trimmedNickname: String {
        editedNickname
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    private var isValid: Bool {
        trimmedNickname.count >= 2 &&
        trimmedNickname.count <= 12 &&
        containsOnlyAllowedCharacters(
            trimmedNickname
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
                    Text("닉네임을 입력하세요")
                        .font(KIRITypography.title)
                        .foregroundStyle(
                            KIRIColor.textPrimary
                        )

                    Text("닉네임은 월 1회 수정 가능합니다")
                        .font(KIRITypography.subtitle)
                        .foregroundStyle(
                            KIRIColor.textSecondary
                        )
                        .padding(.top, 12)

                    KIRITextField(
                        placeholder: "이름을 입력하세요.",
                        text: $editedNickname,
                        state: editedNickname.isEmpty || isValid ? .normal : .error
                    )
                    .padding(.top, 40)

                    Spacer()

                    if let errorMessage {
                        Text(errorMessage).font(KIRITypography.caption).foregroundStyle(KIRIColor.Status.error)
                    }

                    KIRIPrimaryButton(
                        title: "다음",
                        isEnabled: isValid && !isSaving
                    ) {
                        Task { @MainActor in
                            isSaving = true
                            errorMessage = await onSave?(trimmedNickname)
                            if errorMessage == nil {
                                nickname = trimmedNickname
                                dismiss()
                            }
                            isSaving = false
                        }
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
            editedNickname = nickname
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
        let pattern = "^[가-힣A-Za-z0-9]+$"

        return value.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }
}

#Preview {
    @Previewable @State var nickname = "쥬123"

    NavigationStack {
        NicknameEditView(
            nickname: $nickname
        )
    }
}
