//
// MARK: - 파일 가이드
// 파일: Features/Onboarding/FamilyJoinConfirmView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

//
//  FamilyJoinConfirmView 2.swift
//  KIRI
//
//  Created by namhyuk on 9/28/26.
//


import SwiftUI

struct FamilyJoinConfirmView: View {
    let familyName: String
    let familyCode: String

    let onBack: () -> Void
    let onJoin: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("이 가족공간이\n맞나요?")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("가족공간 정보를 확인한 뒤 참여해주세요.")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.top, 12)

                familyCard
                    .padding(.top, 50)

                Spacer()

                KIRIPrimaryButton(
                    title: "가족공간 참여하기",
                    action: onJoin
                )
            }
            .padding(.horizontal, KIRISpacing.horizontal)
            .padding(.bottom, 10)
        }
        .background(KIRIColor.background)
    }

    private var header: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 70)
    }

    private var familyCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(KIRIColor.background)
                    .frame(width: 64, height: 64)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(KIRIColor.textSecondary)
            }

            VStack(spacing: 8) {
                Text(familyName)
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.textPrimary)

                Text("가족코드 \(familyCode)")
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(KIRIColor.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KIRIRadius.xLarge
            )
        )
    }
}

#Preview {
    FamilyJoinConfirmView(
        familyName: "끼리가족",
        familyCode: "KIRI24",
        onBack: {},
        onJoin: {}
    )
    .background(KIRIColor.background)
}
