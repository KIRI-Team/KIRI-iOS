//
//  FamilyInviteSheet 2.swift
//  KIRI
//
//  Created by namhyuk on 9/26/26.
//


import SwiftUI

struct FamilyInviteSheet: View {
    let familyName: String
    let familyCode: String

    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var didCopyCode = false

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(KIRIColor.textSecondary)
                .frame(width: 40, height: 4)
                .padding(.top, 10)

            VStack(spacing: 8) {
                Text("가족을 초대해보세요!")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(KIRIColor.textPrimary)

                Text("가족코드를 공유해서 가족공간을 완성해보세요.")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)

            VStack(spacing: 12) {
                Text(familyName)
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.textSecondary)

                Text(familyCode)
                    .font(.system(size: 26, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(KIRIColor.textPrimary)

                Button {
                    UIPasteboard.general.string = familyCode
                    didCopyCode = true
                } label: {
                    HStack(spacing: 7) {
                        Image(
                            systemName: didCopyCode
                                ? "checkmark"
                                : "doc.on.doc"
                        )

                        Text(
                            didCopyCode
                                ? "복사 완료"
                                : "가족코드 복사"
                        )
                    }
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.textPrimary)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(KIRIColor.surface)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KIRIRadius.xLarge
                )
            )
            .padding(.top, 30)

            Spacer()

            KIRIPrimaryButton(
                title: "초대 완료",
                action: onComplete
            )
        }
        .padding(.horizontal, KIRISpacing.horizontal)
        .padding(.bottom, 10)
        .background(KIRIColor.background)
        .presentationDetents([.fraction(0.52)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
    }
}

#Preview {
    FamilyInviteSheet(
        familyName: "끼리가족",
        familyCode: "A7K9P2",
        onComplete: {}
    )
}
