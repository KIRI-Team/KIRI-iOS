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
