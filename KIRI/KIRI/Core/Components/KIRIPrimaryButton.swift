import SwiftUI

struct KIRIPrimaryButton: View {

    let title: String
    var isEnabled: Bool = true

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(KIRITypography.button)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .buttonStyle(
            KIRIPrimaryButtonStyle(
                isEnabled: isEnabled
            )
        )
        .disabled(!isEnabled)
    }
}

// MARK: - Button Style

private struct KIRIPrimaryButtonStyle: ButtonStyle {

    let isEnabled: Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .foregroundStyle(
                contentColor(
                    isPressed: configuration.isPressed
                )
            )
            .background(
                backgroundColor(
                    isPressed: configuration.isPressed
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KIRIRadius.small
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: KIRIRadius.small
                )
            )
            .scaleEffect(
                configuration.isPressed && isEnabled
                ? 0.995
                : 1
            )
            .animation(
                .easeOut(duration: 0.1),
                value: configuration.isPressed
            )
    }

    private func backgroundColor(
        isPressed: Bool
    ) -> Color {
        if !isEnabled {
            return KIRIColor.Button.FilledAccent
                .backgroundDisabled
        }

        if isPressed {
            return KIRIColor.Button.FilledAccent
                .backgroundPressed
        }

        return KIRIColor.Button.FilledAccent
            .backgroundDefault
    }

    private func contentColor(
        isPressed: Bool
    ) -> Color {
        if !isEnabled {
            return KIRIColor.Button.FilledAccent
                .contentDisabled
        }

        if isPressed {
            return KIRIColor.Button.FilledAccent
                .contentPressed
        }

        return KIRIColor.Button.FilledAccent
            .contentDefault
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        VStack(spacing: KIRISpacing.regular) {
            KIRIPrimaryButton(
                title: "동의하고 계속하기"
            ) {}

            KIRIPrimaryButton(
                title: "동의하고 계속하기",
                isEnabled: false
            ) {}
        }
        .padding(.horizontal, KIRISpacing.horizontal)
    }
}
