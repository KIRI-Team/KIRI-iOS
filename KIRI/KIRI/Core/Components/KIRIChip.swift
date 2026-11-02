//
// MARK: - 파일 가이드
// 파일: Core/Components/KIRIChip.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

struct KIRIChip: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(KIRITypography.bodySmallMedium)
                .tracking(-0.56)
                .foregroundStyle(
                    isSelected
                        ? KIRIColor.Chip.contentSelected
                        : KIRIColor.Chip.contentDefault
                )
                .frame(height: 20)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? KIRIColor.Chip.backgroundSelected
                        : KIRIColor.Chip.backgroundDefault
                )
                .clipShape(Capsule())
        }
        .buttonStyle(KIRIChipButtonStyle())
        .accessibilityAddTraits(
            isSelected
                ? .isSelected
                : []
        )
    }
}

private struct KIRIChipButtonStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .opacity(
                configuration.isPressed
                    ? 0.8
                    : 1
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        HStack(spacing: 8) {
            KIRIChip(
                title: "전체",
                isSelected: true,
                action: {}
            )

            KIRIChip(
                title: "전시·문화",
                isSelected: false,
                action: {}
            )
        }
    }
}
