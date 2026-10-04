import SwiftUI

struct KIRITextField: View {

    enum State {
        case normal
        case error
        case disabled
    }

    let placeholder: String

    @Binding var text: String

    var state: State = .normal
    var helperText: String?
    var trailingIcon: String?

    @FocusState private var isFocused: Bool

    private var isDisabled: Bool {
        state == .disabled
    }

    private var hasError: Bool {
        state == .error
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: KIRISpacing.small
        ) {
            field

            if let helperText {
                helperLabel(helperText)
            }
        }
    }

    // MARK: - Field

    private var field: some View {
        HStack(spacing: KIRISpacing.medium) {
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundStyle(placeholderColor)
            )
            .font(KIRITypography.body)
            .foregroundStyle(contentColor)
            .focused($isFocused)
            .disabled(isDisabled)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(
                        .system(
                            size: 18,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(iconColor)
                    .frame(
                        width: 24,
                        height: 24
                    )
            }
        }
        .padding(.horizontal, KIRISpacing.xLarge)
        .frame(height: 56)
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
        .animation(
            .easeInOut(duration: 0.15),
            value: isFocused
        )
    }

    // MARK: - Helper

    private func helperLabel(
        _ text: String
    ) -> some View {
        Text(text)
            .font(KIRITypography.caption)
            .foregroundStyle(helperColor)
            .padding(.horizontal, 2)
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        if isDisabled {
            return KIRIColor.Input.backgroundDisabled
        }

        if hasError {
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

        if hasError {
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
        if isFocused || hasError {
            return 1.5
        }

        return 1
    }

    private var contentColor: Color {
        if isDisabled {
            return KIRIColor.Input.contentDisabled
        }

        if hasError {
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

        if hasError {
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

        if hasError {
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

    private var iconColor: Color {
        if isDisabled {
            return KIRIColor.Icon.disabled
        }

        if isFocused {
            return KIRIColor.Icon.accent
        }

        return KIRIColor.Icon.secondary
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var defaultText = ""
    @Previewable @State var filledText = "지금 닉네임 : 쥬123"
    @Previewable @State var errorText = ""

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
                helperText: "사용할 수 없는 이름이에요."
            )

            KIRITextField(
                placeholder: "이름을 입력하세요.",
                text: .constant(""),
                state: .disabled
            )
        }
        .padding(.horizontal, KIRISpacing.horizontal)
    }
}
