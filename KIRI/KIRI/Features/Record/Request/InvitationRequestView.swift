//
// MARK: - 파일 가이드
// 파일: Features/Record/Request/InvitationRequestView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

struct InvitationRequestView: View {

    struct RequestData {
        let senderRole: String
        let title: String
        let date: String
        let participants: String
        let description: String
        let familyMessage: String
    }

    let request: RequestData

    let onBack: () -> Void
    let onCancel: () -> Void
    let onConfirmSchedule: () -> Void

    @State private var isAddScheduleSheetVisible = false

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {
                    content
                }
            }

            if isAddScheduleSheetVisible {
                AddScheduleSheet(
                    title: request.title,
                    date: request.date,
                    participants: request.participants,
                    onClose: {
                        closeAddScheduleSheet()
                    },
                    onCancel: {
                        closeAddScheduleSheet()
                    },
                    onConfirm: {
                        isAddScheduleSheetVisible = false
                        onConfirmSchedule()
                    }
                )
                .zIndex(20)
            }
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        ZStack {
            Text("요청알림")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)

            HStack {
                KIRIBackButton(
                    action: onBack
                )

                Spacer()
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 62)
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            Text("\(request.senderRole)이 저장한 미션이에요!")
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.primary)
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )

            activityCard
                .padding(.horizontal, 35)
                .padding(.top, 35)

            detailButton
                .padding(.horizontal, 36)
                .padding(.top, 16)

            descriptionSection
                .padding(.horizontal, 36)
                .padding(.top, 26)

            familyMessageSection
                .padding(.horizontal, 35)
                .padding(.top, 30)

            Spacer()
                .frame(height: 42)

            bottomButtons
                .padding(.horizontal, 18)

            Color.clear
                .frame(height: 34)
        }
        .padding(.top, 8)
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        VStack(
            alignment: .center,
            spacing: 0
        ) {
            Text("활동명")
                .font(KIRITypography.captionMedium)
                .tracking(-0.48)
                .foregroundStyle(KIRIColor.Text.tertiary)

            Text(request.title)
                .font(KIRITypography.headingLarge)
                .tracking(-0.96)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.top, 8)

            Spacer(minLength: 16)

            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(
                        KIRIColor.Icon.secondary
                    )
                    .frame(
                        width: 18,
                        height: 18
                    )

                Text(request.date)
                    .font(KIRITypography.bodySmall)
                    .tracking(-0.56)
                    .foregroundStyle(
                        KIRIColor.Text.secondary
                    )
            }

            HStack(spacing: 5) {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        KIRIColor.Icon.secondary
                    )
                    .frame(
                        width: 18,
                        height: 18
                    )

                Text(request.participants)
                    .font(KIRITypography.bodySmall)
                    .tracking(-0.56)
                    .foregroundStyle(
                        KIRIColor.Text.secondary
                    )
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(
            maxWidth: .infinity,
            minHeight: 167
        )
        .background(KIRIColor.Background.secondary)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    // MARK: - Detail

    private var detailButton: some View {
        Button {
            // TODO: 미션 상세 화면 연결
        } label: {
            Text("자세히 보러가기")
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(
                    KIRIColor.Background.tertiary
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(
            alignment: .leading,
            spacing: 2
        ) {
            Text("행사설명")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(
                    KIRIColor.Text.tertiary
                )

            Text(request.description)
                .font(KIRITypography.body)
                .tracking(-0.64)
                .foregroundStyle(
                    KIRIColor.Text.primary
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Family Message

    private var familyMessageSection: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("가족에게 한 줄")
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .foregroundStyle(
                    KIRIColor.Text.primary
                )

            Text(request.familyMessage)
                .font(KIRITypography.bodySmall)
                .tracking(-0.56)
                .foregroundStyle(
                    KIRIColor.Text.secondary
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
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
                        KIRIColor.Text.onGreen
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        KIRIColor.Primary.default
                    )
                    .clipShape(
                        Capsule()
                    )
            }
            .buttonStyle(.plain)

            Button {
                openAddScheduleSheet()
            } label: {
                Text("약속 확정하기")
                    .font(KIRITypography.button)
                    .tracking(-0.64)
                    .foregroundStyle(
                        KIRIColor.Text.onGreen
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        KIRIColor.Primary.default
                    )
                    .clipShape(
                        Capsule()
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func openAddScheduleSheet() {
        withAnimation(
            .easeOut(duration: 0.2)
        ) {
            isAddScheduleSheetVisible = true
        }
    }

    private func closeAddScheduleSheet() {
        withAnimation(
            .easeOut(duration: 0.2)
        ) {
            isAddScheduleSheetVisible = false
        }
    }
}

#Preview {
    InvitationRequestView(
        request: InvitationRequestView.RequestData(
            senderRole: "딸",
            title: "한강 뚜벅뚜벅 축제",
            date: "26.06.23",
            participants: "엄마, 아빠, 나",
            description: """
            2026 한강 뚜벅뚜벅 축제는 잠수교를 보행교로 전환해 시민이 직접 걸으며 공연·체험·미식 등 다양한 문화·여가 프로그램을 즐기는 서울 대표 한강 축제입니다.
            """,
            familyMessage: "엄마, 아빠 나 여기 가고싶은데 우리 10월 초에 갈래요??"
        ),
        onBack: {},
        onCancel: {},
        onConfirmSchedule: {}
    )
}
