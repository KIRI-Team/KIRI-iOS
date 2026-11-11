//
// MARK: - 파일 가이드
// 파일: Features/MyPage/FamilyNameEditView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

struct FamilyNameEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.kiriTabBarVisibility) private var tabBarVisibility
    @Environment(\.kiriTabBarSubscreenCount) private var tabBarSubscreenCount
    @State private var didRegisterSubscreen = false

    @Binding var familyName: String
    var onSave: ((String) async -> String?)? = nil

    @State private var editedFamilyName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

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

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("가족명을 다시 입력해주세요.")
                            .font(KIRITypography.title)
                            .foregroundStyle(KIRIColor.textPrimary)

                        Text("가족명은 월 1회 수정 가능합니다")
                            .font(KIRITypography.subtitle)
                            .foregroundStyle(KIRIColor.textSecondary)
                            .padding(.top, 12)

                        KIRITextField(
                            placeholder: "이름을 입력하세요.",
                            text: $editedFamilyName,
                            state: editedFamilyName.isEmpty || isValid ? .normal : .error
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
        .alert("가족명 저장 실패", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "가족명을 저장하지 못했습니다.")
        }
        .onAppear {
            tabBarVisibility.wrappedValue = false
            if !didRegisterSubscreen {
                tabBarSubscreenCount.wrappedValue += 1
                didRegisterSubscreen = true
            }
            editedFamilyName = familyName
        }
        .onDisappear {
            if didRegisterSubscreen {
                tabBarSubscreenCount.wrappedValue = max(0, tabBarSubscreenCount.wrappedValue - 1)
                didRegisterSubscreen = false
            }
            tabBarVisibility.wrappedValue = tabBarSubscreenCount.wrappedValue == 0
        }
    }

    private var saveArea: some View {
        KIRIPrimaryButton(title: "다음", isEnabled: isValid && !isSaving) {
            isSaving = true
            Task {
                let error = await onSave?(trimmedFamilyName)
                await MainActor.run {
                    isSaving = false
                    if let error {
                        errorMessage = error
                    } else {
                        familyName = trimmedFamilyName
                        dismiss()
                    }
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
