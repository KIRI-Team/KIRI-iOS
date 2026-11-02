//
// MARK: - 파일 가이드
// 파일: Core/Components/KIRIValidationGuidance.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

struct KIRIValidationGuidance: View {

    enum ValidationState {
        case neutral
        case invalid
        case valid
    }

    var items: [String] = [
        "한글/영어/숫자 혼합 가능",
        "최소 2자 ~ 최대 12자 이내",
        "특수 문자 입력 불가능"
    ]
    var state: ValidationState = .neutral

    private var textColor: Color {
        switch state {
        case .neutral:
            return KIRIColor.Text.tertiary
        case .invalid:
            return KIRIColor.Status.error
        case .valid:
            return KIRIColor.Status.success
        }
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            ForEach(items, id: \.self) { item in
                Text("✓ \(item)")
                    .font(KIRITypography.captionMedium)
                    .tracking(-0.48)
                    .foregroundStyle(textColor)
                    .frame(
                        minHeight: 17,
                        alignment: .leading
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        KIRIValidationGuidance()
    }
}
