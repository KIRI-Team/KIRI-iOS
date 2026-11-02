//
// MARK: - 파일 가이드
// 파일: Core/Components/KIRITextField.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

struct KIRITextField: View {

    enum State {
        case normal
        case error
        case disabled
    }

    let placeholder: String

    @Binding var text: String

    var state: State
    var helperText: String?
    var trailingIcon: Image?

    @FocusState private var isFocused: Bool

    // MARK: - Initializer

    init(
        placeholder: String,
        text: Binding<String>,
        state: State = .normal,
        helperText: String? = nil,
        trailingIcon: Image? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.state = state
        self.helperText = helperText
        self.trailingIcon = trailingIcon
    }

    // MARK: - State

    private var isDisabled: Bool {
        state == .disabled
    }

    private var isError: Bool {
        state == .error
    }

    private var backgroundColor: Color {
        if isDisabled {
            return KIRIColor.Input.backgroundDisabled
        }

        if isError {
            return KIRIColor.Input.backgroundError
        }

        if isFocused {
            return KIRIColor.Input.backgroundFocus
        }

        if !text.isEmpty {
            return KIRIColor.Input.backgroundFilled
        }

        return KIRIColor.Input.backgroundDefault
    }

    private var borderColor: Color {
        if isDisabled {
            return KIRIColor.Input.borderDisabled
        }

        if isError {
            return KIRIColor.Input.borderError
        }

        if isFocused {
            return KIRIColor.Input.borderFocus
        }

        if !text.isEmpty {
            return KIRIColor.Input.borderFilled
        }

        return KIRIColor.Input.borderDefault
    }

    private var borderWidth: CGFloat {
        if isFocused || isError {
            return 2
        }

        return 1
    }

    private var contentColor: Color {
        if isDisabled {
            return KIRIColor.Input.contentDisabled
        }

        if isError {
            return KIRIColor.Input.contentError
        }

        if isFocused {
            return KIRIColor.Input.contentFocus
        }

        if !text.isEmpty {
            return KIRIColor.Input.contentFilled
        }

        return KIRIColor.Input.contentDefault
    }

    private var placeholderColor: Color {
        if isDisabled {
            return KIRIColor.Input.placeholderDisabled
        }

        if isError {
            return KIRIColor.Input.placeholderError
        }

        if isFocused {
            return KIRIColor.Input.placeholderFocus
        }

        return KIRIColor.Input.placeholderDefault
    }

    private var helperColor: Color {
        if isDisabled {
            return KIRIColor.Input.helperDisabled
        }

        if isError {
            return KIRIColor.Input.helperError
        }

        if isFocused {
            return KIRIColor.Input.helperFocus
        }

        if !text.isEmpty {
            return KIRIColor.Input.helperFilled
        }

        return KIRIColor.Input.helperDefault
    }

    private var trailingIconColor: Color {
        if isDisabled {
            return KIRIColor.Icon.disabled
        }

        return KIRIColor.Icon.secondary
    }

    // MARK: - Body

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: KIRISpacing.small
        ) {
            inputField

            if let helperText,
               !helperText.isEmpty {
                helperLabel(helperText)
            }
        }
    }

    // MARK: - Input Field

    private var inputField: some View {
        HStack(spacing: 4) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(KIRITypography.bodyMedium)
                        .tracking(-0.64)
                        .foregroundStyle(placeholderColor)
                        .allowsHitTesting(false)
                }

                TextField("", text: $text)
                    .font(KIRITypography.bodyMedium)
                    .tracking(-0.64)
                    .foregroundStyle(contentColor)
                    .tint(KIRIColor.Primary.default)
                    .focused($isFocused)
                    .disabled(isDisabled)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if let trailingIcon {
                trailingIcon
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 24,
                        height: 24
                    )
                    .foregroundStyle(trailingIconColor)
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 54)
        .background(backgroundColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KIRIRadius.small
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: KIRIRadius.small
            )
            .stroke(
                borderColor,
                lineWidth: borderWidth
            )
        }
    }

    // MARK: - Helper

    private func helperLabel(
        _ text: String
    ) -> some View {
        Text(text)
            .font(KIRITypography.captionMedium)
            .tracking(-0.48)
            .foregroundStyle(helperColor)
            .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    KIRITextFieldPreview()
}

private struct KIRITextFieldPreview: View {

    @State private var defaultText = ""
    @State private var filledText = "지금 닉네임 : 쥬123"
    @State private var errorText = ""
    @State private var disabledText = ""

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 20) {
                KIRITextField(
                    placeholder: "이름을 입력하세요.",
                    text: $defaultText
                )

                KIRITextField(
                    placeholder: "이름을 입력하세요.",
                    text: $filledText
                )

                KIRITextField(
                    placeholder: "이름을 입력하세요.",
                    text: $errorText,
                    state: .error,
                    helperText: "사용할 수 없는 이름입니다."
                )

                KIRITextField(
                    placeholder: "이름을 입력하세요.",
                    text: $disabledText,
                    state: .disabled
                )
            }
            .padding(.horizontal, 18)
        }
    }
}
