//
// MARK: - 파일 가이드
// 파일: Features/Onboarding/FamilyCodeLoadingView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

//
//  FamilyCodeLoadingView 2.swift
//  KIRI
//
//  Created by namhyuk on 9/26/26.
//


import SwiftUI

struct FamilyCodeLoadingView: View {
    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                ProgressView()
                    .controlSize(.large)
                    .tint(KIRIColor.textPrimary)

                VStack(spacing: 10) {
                    Text("가족코드를\n생성하고 있어요!")
                        .font(KIRITypography.bodyMedium)
                        .foregroundStyle(KIRIColor.textPrimary)

                    Text("조금만 기다려주세요")
                        .font(KIRITypography.subtitle)
                        .foregroundStyle(KIRIColor.textSecondary)
                }
            }
        }
    }
}

#Preview {
    FamilyCodeLoadingView()
}
