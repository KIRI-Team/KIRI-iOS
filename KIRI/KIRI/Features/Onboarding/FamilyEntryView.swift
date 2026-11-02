//
// MARK: - 파일 가이드
// 파일: Features/Onboarding/FamilyEntryView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

struct FamilyEntryView: View {
    enum Mode: Equatable {
        case all
        case creationOnly
    }

    var mode: Mode = .all
    let onBack: () -> Void
    let onCreateFamily: () -> Void
    let onEnterFamilyCode: () -> Void
    let onBrowse: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("지금 바로 가족공간을\n만들어봐요!")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("관심가지고 있는 분야에 대해 알려주세요!")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.top, 12)

                VStack(spacing: 14) {
                    entryCard(
                        title: "가족공간 만들러 가기",
                        subtitle: "지금 바로 가족들을 초대해주세요!",
                        action: onCreateFamily
                    )

                    if mode == .all {
                        entryCard(
                            title: "가족코드 입력하기",
                            subtitle: "전달받은 가족코드를 입력해주세요!",
                            action: onEnterFamilyCode
                        )

                        entryCard(
                            title: "먼저 둘러보러가기",
                            subtitle: "할 수 있는 미션을 먼저 살펴봐요!",
                            action: onBrowse
                        )
                    }
                }
                .padding(.horizontal, mode == .creationOnly ? 20 : 17)
                .padding(.top, mode == .creationOnly ? 55 : 55)

                Spacer()
            }
            .padding(.horizontal, KIRISpacing.horizontal)
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

    private func entryCard(
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(KIRIColor.background)
                        .frame(width: 52, height: 52)

                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(KIRIColor.textSecondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(KIRITypography.bodyMedium)
                        .foregroundStyle(KIRIColor.textPrimary)

                    Text(subtitle)
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(KIRIColor.textPrimary)
            }
            .padding(.horizontal, 20)
            .frame(height: 87)
            .background(KIRIColor.Background.primary)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KIRIRadius.large
                )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FamilyEntryView(
        onBack: {},
        onCreateFamily: {},
        onEnterFamilyCode: {},
        onBrowse: {}
    )
    .background(KIRIColor.background)
}
