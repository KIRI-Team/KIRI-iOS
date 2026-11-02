//
// MARK: - 파일 가이드
// 파일: Core/Components/KIRIPrimaryButton.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

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
