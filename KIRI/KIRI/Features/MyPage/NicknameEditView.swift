//
// MARK: - 파일 가이드
// 파일: Features/MyPage/NicknameEditView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

struct NicknameEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.kiriTabBarVisibility) private var tabBarVisibility

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

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("닉네임을 입력하세요")
                            .font(KIRITypography.title)
                            .foregroundStyle(KIRIColor.textPrimary)

                        Text("닉네임은 월 1회 수정 가능합니다")
                            .font(KIRITypography.subtitle)
                            .foregroundStyle(KIRIColor.textSecondary)
                            .padding(.top, 12)

                        KIRITextField(
                            placeholder: "이름을 입력하세요.",
                            text: $editedNickname,
                            state: editedNickname.isEmpty || isValid ? .normal : .error
                        )
                        .padding(.top, 40)
                    }
                    .padding(.horizontal, KIRISpacing.horizontal)
                    .padding(.top, 10)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    saveArea
                        .padding(.horizontal, KIRISpacing.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                        .background(KIRIColor.background)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility.wrappedValue = false
            editedNickname = nickname
        }
        .onDisappear { tabBarVisibility.wrappedValue = true }
    }

    private var saveArea: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.Status.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KIRIPrimaryButton(title: "다음", isEnabled: isValid && !isSaving) {
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
