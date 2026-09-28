//
//  TermsAgreementView 2.swift
//  KIRI
//
//  Created by namhyuk on 9/28/26.
//


import SwiftUI

struct TermsAgreementView: View {
    @State private var isRequiredTermsAgreed = false

    let onBack: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("KIRI 이용을 위해\n약관에 동의해주세요.")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("서비스 이용에 필요한 필수 약관을 확인해주세요.")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.top, 12)

                Button {
                    isRequiredTermsAgreed.toggle()
                } label: {
                    HStack(spacing: 14) {
                        Image(
                            systemName: isRequiredTermsAgreed
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .font(.system(size: 22))
                        .foregroundStyle(
                            isRequiredTermsAgreed
                                ? KIRIColor.textPrimary
                                : KIRIColor.textSecondary
                        )

                        VStack(alignment: .leading, spacing: 5) {
                            Text("필수 약관 전체 동의")
                                .font(KIRITypography.bodyMedium)
                                .foregroundStyle(KIRIColor.textPrimary)

                            Text("KIRI 서비스 이용에 필요한 필수 항목입니다.")
                                .font(KIRITypography.caption)
                                .foregroundStyle(KIRIColor.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 88)
                    .background(KIRIColor.surface)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: KIRIRadius.large
                        )
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 50)

                Spacer()

                KIRIPrimaryButton(
                    title: "동의하고 시작하기",
                    isEnabled: isRequiredTermsAgreed,
                    action: onComplete
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
}

#Preview {
    TermsAgreementView(
        onBack: {},
        onComplete: {}
    )
}
