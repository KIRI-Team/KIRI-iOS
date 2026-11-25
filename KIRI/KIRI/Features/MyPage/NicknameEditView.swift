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
    @Environment(\.kiriTabBarSubscreenCount) private var tabBarSubscreenCount
    @State private var didRegisterSubscreen = false

    @Binding var nickname: String
    var onSave: ((String) async -> String?)? = nil

    @State private var editedNickname = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var isInputFocused: Bool

    init(
        nickname: Binding<String>,
        onSave: ((String) async -> String?)? = nil
    ) {
        self._nickname = nickname
        self.onSave = onSave
        self._editedNickname = State(initialValue: nickname.wrappedValue)
    }

    private var trimmedNickname: String {
        editedNickname.precomposedStringWithCanonicalMapping
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    private var isValid: Bool {
        isValidNickname(trimmedNickname)
    }

    private var normalizedCurrentNickname: String {
        nickname.precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasChanges: Bool {
        trimmedNickname != normalizedCurrentNickname
    }

    private var canSave: Bool {
        isValid && hasChanges && !isSaving
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

                        nicknameInput
                            .padding(.top, 40)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 44)
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
            if !didRegisterSubscreen {
                tabBarSubscreenCount.wrappedValue += 1
                didRegisterSubscreen = true
            }
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
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.Status.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            KIRIPrimaryButton(title: "저장하기", isEnabled: canSave) {
                // 한글 조합이 끝난 뒤 탭 시점의 값을 한 번 확정합니다.
                // 이후 비동기 요청에서는 SwiftUI State를 다시 읽지 않습니다.
                guard !isSaving else { return }
                isInputFocused = false
                let nicknameToSave = String(trimmedNickname)
                guard !nicknameToSave.isEmpty,
                      isValidNickname(nicknameToSave),
                      nicknameToSave != normalizedCurrentNickname else { return }
                let save = onSave
                isSaving = true
                #if DEBUG
                print("[KIRI][NicknameEdit] save tap normalizedLength=\(nicknameToSave.count)")
                #endif
                Task { @MainActor in
                    errorMessage = await save?(nicknameToSave)
                    if errorMessage == nil {
                        nickname = nicknameToSave
                        dismiss()
                    }
                    isSaving = false
                }
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("기본 정보")
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                KIRIBackButton {
                    dismiss()
                }
                Spacer()
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 62)
    }

    private var nicknameInput: some View {
        HStack(spacing: 4) {
            Text("지금닉네임:")
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .fontWeight(.bold)
                .foregroundStyle(KIRIColor.Input.placeholderDefault)
                .fixedSize()

            TextField("", text: $editedNickname)
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .fontWeight(.bold)
                .foregroundStyle(KIRIColor.Input.placeholderDefault)
                .tint(KIRIColor.Primary.default)
                .focused($isInputFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { isInputFocused = false }

            if !editedNickname.isEmpty {
                Button {
                    editedNickname = ""
                    isInputFocused = true
                } label: {
                    Image("figma_input_clear")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("닉네임 지우기")
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(KIRIColor.Input.backgroundFilled)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

    private func isValidNickname(_ value: String) -> Bool {
        value.count >= 2 &&
        value.count <= 12 &&
        containsOnlyAllowedCharacters(value)
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
