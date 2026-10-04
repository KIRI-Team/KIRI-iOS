import SwiftUI

struct KIRIPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var leadingIcon: Image? = nil
    var trailingIcon: Image? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: KIRISpacing.small) {
                if let leadingIcon {
                    leadingIcon
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: 20,
                            height: 20
                        )
                }

                Text(title)
                    .font(KIRITypography.button)
                    .tracking(-0.64)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )

                if let trailingIcon {
                    trailingIcon
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: 20,
                            height: 20
                        )
                }
            }
            .padding(.horizontal, 16)
            .frame(
                maxWidth: .infinity,
                minHeight: 54,
                maxHeight: 54
            )
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
    }

    private func backgroundColor(
        isPressed: Bool
    ) -> Color {
        if !isEnabled {
            return KIRIColor.Button
                .FilledAccent
                .backgroundDisabled
        }

        if isPressed {
            return KIRIColor.Button
                .FilledAccent
                .backgroundPressed
        }

        return KIRIColor.Button
            .FilledAccent
            .backgroundDefault
    }

    private func contentColor(
        isPressed: Bool
    ) -> Color {
        if !isEnabled {
            return KIRIColor.Button
                .FilledAccent
                .contentDisabled
        }

        if isPressed {
            return KIRIColor.Button
                .FilledAccent
                .contentPressed
        }

        return KIRIColor.Button
            .FilledAccent
            .contentDefault
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        VStack(spacing: 16) {
            KIRIPrimaryButton(
                title: "동의하고 계속하기",
                action: {}
            )

            KIRIPrimaryButton(
                title: "다음",
                isEnabled: false,
                action: {}
            )
        }
        .padding(.horizontal, 18)
    }
}
