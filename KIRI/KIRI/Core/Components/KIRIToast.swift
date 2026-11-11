//
// MARK: - 파일 가이드
// 파일: Core/Components/KIRIToast.swift
// 담당 화면: 저장·변경·복사 완료 및 실패에 대한 공통 상단 토스트
// 주요 역할: Figma KIRI/Toast(9898:21872)의 배경, 여백, 아이콘, 문구 스타일을 공통 제공
// UI 수정 위치: 토스트 크기·여백은 body의 padding/frame, 표시 위치는 호출부 overlay의 safeAreaPadding
// Asset: Assets.xcassets/figma_toast_check.imageset
//

import SwiftUI

struct KIRIToast: View {
    let message: String
    var isError: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if !isError {
                Image("figma_toast_check")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            Text(message)
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 18)
        .padding(.bottom, 17)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}
