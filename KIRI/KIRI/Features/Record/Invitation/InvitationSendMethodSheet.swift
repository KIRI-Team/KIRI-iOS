//
// MARK: - 파일 가이드
// 파일: Features/Record/Invitation/InvitationSendMethodSheet.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

struct InvitationSendMethodSheet: View {

    let onClose: () -> Void
    let onSendInApp: () -> Void
    let onSendKakao: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }

            sheetContent
                .transition(.move(edge: .bottom))
        }
        .ignoresSafeArea()
    }

    private var sheetContent: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 25)

            VStack(spacing: 24) {
                methodCard(
                    icon: "bell.fill",
                    title: "앱으로 보내기",
                    description: "앱 내에서 푸시 알람이 발송돼요!",
                    action: onSendInApp
                )

                methodCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "카카오톡으로 보내기",
                    description: "카카오톡으로 초대 링크를 발송해요",
                    action: onSendKakao
                )
            }
            .padding(.horizontal, 39)
            .padding(.top, 35)

            Spacer(minLength: 0)

            Capsule()
                .fill(KIRIColor.Primitive.neutral50)
                .frame(
                    width: 134,
                    height: 5
                )
                .padding(.bottom, 8)
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 388)
        .background(KIRIColor.Background.primary)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 30,
                topTrailingRadius: 30
            )
        )
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("초대장 발송 방법을 선택해주세요")
                .font(KIRITypography.headingMedium)
                .tracking(-0.8)
                .foregroundStyle(KIRIColor.Text.strong)

            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(
                        .system(
                            size: 17,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        KIRIColor.Text.tertiary
                    )
                    .frame(
                        width: 44,
                        height: 44
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 33)
        .padding(.trailing, 17)
        .frame(height: 44)
    }

    private func methodCard(
        icon: String,
        title: String,
        description: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(KIRIColor.Background.secondary)

                    Image(systemName: icon)
                        .font(
                            .system(
                                size: 19,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            KIRIColor.Icon.primary
                        )
                }
                .frame(
                    width: 48,
                    height: 48
                )

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(title)
                        .font(KIRITypography.headingSmall)
                        .tracking(-0.72)
                        .foregroundStyle(
                            KIRIColor.Text.strong
                        )

                    Text(description)
                        .font(KIRITypography.caption)
                        .tracking(-0.48)
                        .foregroundStyle(
                            KIRIColor.Text.tertiary
                        )
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        KIRIColor.Icon.secondary
                    )
            }
            .padding(.horizontal, 16)
            .frame(
                maxWidth: .infinity,
                minHeight: 87
            )
            .background(
                KIRIColor.Background.tertiary
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        InvitationSendMethodSheet(
            onClose: {},
            onSendInApp: {},
            onSendKakao: {}
        )
    }
}
