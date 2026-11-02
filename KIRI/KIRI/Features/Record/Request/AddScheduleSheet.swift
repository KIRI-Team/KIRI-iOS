//
// MARK: - 파일 가이드
// 파일: Features/Record/Request/AddScheduleSheet.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

struct AddScheduleSheet: View {

    let title: String
    let date: String
    let participants: String

    let onClose: () -> Void
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }

            sheetContent
                .transition(
                    .move(edge: .bottom)
                )
        }
        .ignoresSafeArea()
    }

    // MARK: - Sheet

    private var sheetContent: some View {
        ZStack(alignment: .top) {
            KIRIColor.Background.primary

            VStack(spacing: 0) {
                titleSection

                activityCard
                    .padding(.top, 20)

                notificationText
                    .padding(.top, 19)

                Spacer(minLength: 0)

                bottomButtons
                    .padding(.bottom, 45)
            }
            .padding(.horizontal, 33)
            .padding(.top, 48)

            closeButton
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 405)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 30,
                topTrailingRadius: 30
            )
        )
    }

    // MARK: - Header

    private var titleSection: some View {
        Text("캘린더에 일정을 추가하시겠습니까?")
            .font(KIRITypography.headingMedium)
            .tracking(-0.8)
            .foregroundStyle(
                KIRIColor.Text.strong
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
    }

    private var closeButton: some View {
        HStack {
            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(
                        .system(
                            size: 19,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        KIRIColor.Icon.disabled
                    )
                    .frame(
                        width: 44,
                        height: 44
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 3)
        .padding(.trailing, 17)
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("활동명")
                    .font(KIRITypography.caption)
                    .tracking(-0.48)
                    .foregroundStyle(
                        KIRIColor.Text.tertiary
                    )

                Text(title)
                    .font(KIRITypography.headingLarge)
                    .tracking(-0.48)
                    .foregroundStyle(
                        KIRIColor.Text.strong
                    )
            }

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(
                            .system(
                                size: 14,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(
                            KIRIColor.Icon.secondary
                        )
                        .frame(
                            width: 18,
                            height: 18
                        )

                    Text(date)
                        .font(KIRITypography.bodySmall)
                        .tracking(-0.56)
                        .foregroundStyle(
                            KIRIColor.Text.secondary
                        )
                }

                HStack(spacing: 5) {
                    Image(systemName: "person.fill")
                        .font(
                            .system(
                                size: 14,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(
                            KIRIColor.Icon.secondary
                        )
                        .frame(
                            width: 18,
                            height: 18
                        )

                    Text(participants)
                        .font(KIRITypography.bodySmall)
                        .tracking(-0.56)
                        .foregroundStyle(
                            KIRIColor.Text.secondary
                        )
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            KIRIColor.Background.tertiary
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10
            )
        )
    }

    // MARK: - Notification

    private var notificationText: some View {
        Text("초대된 가족 구성원에게도 알림이 발송됩니다")
            .font(KIRITypography.bodySmall)
            .tracking(-0.56)
            .foregroundStyle(
                KIRIColor.Text.secondary
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 8) {
            Button {
                onCancel()
            } label: {
                Text("취소")
                    .font(KIRITypography.button)
                    .tracking(-0.64)
                    .foregroundStyle(
                        KIRIColor.Text.primary
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 54)
                    .background(
                        KIRIColor.Background.elevated
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 8
                        )
                    )
            }
            .buttonStyle(.plain)

            Button {
                onConfirm()
            } label: {
                Text("확인")
                    .font(KIRITypography.button)
                    .tracking(-0.64)
                    .foregroundStyle(
                        KIRIColor.Text.onGreen
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 54)
                    .background(
                        KIRIColor.Background.elevated
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 8
                        )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, -15)
    }
}

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        AddScheduleSheet(
            title: "한강 뚜벅뚜벅 축제",
            date: "26.06.23",
            participants: "엄마, 아빠, 나",
            onClose: {},
            onCancel: {},
            onConfirm: {}
        )
    }
}
